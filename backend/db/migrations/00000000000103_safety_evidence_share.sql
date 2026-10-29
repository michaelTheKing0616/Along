-- Safety slice: incident photo evidence, guardian live share controls.
-- - trip_shares.share_plate lets the rider hide the plate from a share link.
-- - create_trip_share takes the plate choice and a rider-chosen expiry,
--   clamped to [15 min, share.link_ttl_hours].
-- - incidents.client_ref makes report_incident idempotent so the offline
--   queue can replay a report without creating a duplicate.
-- - report_incident caps photos at 4 and requires each one to be an object
--   the caller uploaded to the private incidents bucket under their folder.
-- - Reporters may delete their own incident photos that are not yet
--   attached to a report (retake / discard before sending).

alter table trip_shares
  add column share_plate boolean not null default true;

alter table incidents
  add column client_ref uuid;

create unique index incidents_client_ref_uniq
  on incidents (reported_by, client_ref)
  where client_ref is not null;

-- ---------------------------------------------------------------------------
-- create_trip_share(journey, contact, phone, share_plate, ttl_minutes)
-- ---------------------------------------------------------------------------
drop function if exists create_trip_share(uuid, text, text);

create or replace function create_trip_share(
  p_journey_id uuid,
  p_contact_name text default null,
  p_contact_phone text default null,
  p_share_plate boolean default true,
  p_ttl_minutes int default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_j journeys%rowtype;
  v_token text;
  v_token_hash bytea;
  v_max_minutes int;
  v_minutes int;
  v_expires timestamptz;
  v_origin text;
  v_url text;
  v_share_id uuid;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_j from journeys where id = p_journey_id;
  if v_j.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_j.rider_id <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_j.status not in ('active', 'transfer') then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'journey not active';
  end if;

  v_max_minutes := greatest(15, (cfg_num('share.link_ttl_hours', v_j.city_id) * 60)::int);
  if p_ttl_minutes is null then
    v_minutes := v_max_minutes;
  elsif p_ttl_minutes < 15 or p_ttl_minutes > v_max_minutes then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'ttl out of range';
  else
    v_minutes := p_ttl_minutes;
  end if;
  v_expires := now() + make_interval(mins => v_minutes);

  v_token := encode(gen_random_bytes(32), 'base64');
  v_token_hash := digest(v_token, 'sha256');

  insert into trip_shares (
    journey_id,
    rider_id,
    token_hash,
    contact_name,
    contact_phone_e164,
    expires_at,
    share_plate
  ) values (
    p_journey_id,
    v_user_id,
    v_token_hash,
    nullif(btrim(p_contact_name), ''),
    nullif(btrim(p_contact_phone), ''),
    v_expires,
    coalesce(p_share_plate, true)
  )
  returning id into v_share_id;

  v_origin := private.share_origin_url(v_j.city_id);
  if v_origin <> '' then
    v_url := v_origin || '/s/' || v_token;
  else
    v_url := '/s/' || v_token;
  end if;

  return jsonb_build_object(
    'url', v_url,
    'expires_at', v_expires,
    'share_id', v_share_id,
    'share_plate', coalesce(p_share_plate, true)
  );
end;
$$;

revoke all on function create_trip_share(uuid, text, text, boolean, int) from public;
grant execute on function create_trip_share(uuid, text, text, boolean, int) to authenticated;

-- ---------------------------------------------------------------------------
-- shared_trip_view: honour share_plate
-- ---------------------------------------------------------------------------
create or replace function shared_trip_view(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_share trip_shares%rowtype;
  v_j journeys%rowtype;
  v_t trips%rowtype;
  v_loc geography(Point,4326);
  v_loc_ts timestamptz;
  v_plate text;
  v_color text;
  v_rider_first text;
  v_driver_first text;
  v_dest_label text;
  v_eta_s int := 0;
  v_eta jsonb;
  v_alight geography(Point,4326);
begin
  if p_token is null or btrim(p_token) = '' then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_share
  from trip_shares
  where token_hash = digest(btrim(p_token), 'sha256');

  if v_share.id is null then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  if v_share.revoked_at is not null or v_share.expires_at <= now() then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_j from journeys where id = v_share.journey_id;
  if v_j.id is null or v_j.status not in ('active', 'transfer') then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_t
  from trips t
  where t.journey_id = v_j.id
    and t.status in ('accepted', 'boarded', 'in_transit')
  order by t.journey_sequence desc
  limit 1;

  if v_t.id is null then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select private.first_name_from_display(p.display_name)
  into v_rider_first
  from profiles p where p.id = v_j.rider_id;

  select private.first_name_from_display(p.display_name)
  into v_driver_first
  from profiles p where p.id = v_t.driver_id;

  select v.plate_number, coalesce(v.color, '')
  into v_plate, v_color
  from vehicles v
  where v.id = v_t.vehicle_id;

  select dp.current_location, dp.last_ping_at
  into v_loc, v_loc_ts
  from driver_presence dp
  where dp.driver_id = v_t.driver_id
    and dp.last_ping_at >= now() - interval '30 seconds';

  if v_loc is null then
    select s.location, s.ts
    into v_loc, v_loc_ts
    from trip_location_samples s
    where s.trip_id = v_t.id
      and s.actor_type = 'driver'
      and s.ts >= now() - interval '30 seconds'
    order by s.ts desc
    limit 1;
  end if;

  if v_loc is null then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  v_dest_label := coalesce(
    v_j.destination_label,
    (select rs.name from route_stages rs where rs.id = v_t.alighting_stage_id),
    'Destination'
  );

  v_alight := coalesce(
    v_t.alighting_location,
    (select rs.location from route_stages rs where rs.id = v_t.alighting_stage_id)
  );

  v_eta := v_t.meta->'eta';
  if v_eta is null or v_eta->>'status' is distinct from 'ready' then
    v_eta := jsonb_build_object(
      'status', 'calculating',
      'pickup', null,
      'trip', null,
      'stops', '[]'::jsonb,
      'updated_at', to_jsonb(now())
    );
    v_eta_s := 0;
  else
    v_eta_s := coalesce(
      nullif(v_eta #>> '{trip,low_s}', '')::int,
      nullif(v_eta #>> '{pickup,low_s}', '')::int,
      0
    );
  end if;

  return jsonb_build_object(
    'rider_first_name', v_rider_first,
    'status', v_t.status::text,
    'mode', _mode_ref(v_t.mode_code),
    'vehicle', jsonb_build_object(
      'plate', case when v_share.share_plate then coalesce(v_plate, '') else '' end,
      'color', v_color
    ),
    'driver_first_name', v_driver_first,
    'current_location', jsonb_build_object(
      'lat', st_y(v_loc::geometry),
      'lng', st_x(v_loc::geometry)
    ),
    'destination_label', v_dest_label,
    'eta_s', v_eta_s,
    'eta', v_eta,
    'legs_progress', private.shared_trip_legs_progress(v_j.id)
  );
end;
$$;

revoke all on function shared_trip_view(text) from public;
grant execute on function shared_trip_view(text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- report_incident(trip, type, description, paths, client_ref)
-- ---------------------------------------------------------------------------
drop function if exists report_incident(uuid, text, text, text[]);

create or replace function report_incident(
  p_trip_id uuid default null,
  p_type text default null,
  p_description text default null,
  p_attachment_paths text[] default '{}',
  p_client_ref uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_t trips%rowtype;
  v_incident_id uuid;
  v_path text;
  v_prefix text;
  v_paths text[] := coalesce(p_attachment_paths, '{}');
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_client_ref is not null then
    select i.id into v_incident_id
    from incidents i
    where i.reported_by = v_user_id and i.client_ref = p_client_ref;
    if v_incident_id is not null then
      return jsonb_build_object('incident_id', v_incident_id, 'replayed', true);
    end if;
  end if;

  if p_type is null or p_type = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_description is not null and char_length(p_description) > 2000 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'description too long';
  end if;

  if cardinality(v_paths) > 4 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'too many photos';
  end if;

  if p_trip_id is not null then
    select * into v_t from trips where id = p_trip_id;
    if v_t.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001';
    end if;
    if v_t.rider_id = v_user_id then
      v_role := 'rider';
    elsif v_t.driver_id = v_user_id then
      v_role := 'driver';
    else
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
  elsif exists (select 1 from riders r where r.id = v_user_id) then
    v_role := 'rider';
  elsif exists (select 1 from drivers d where d.id = v_user_id) then
    v_role := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_prefix := 'incidents/' || v_user_id::text || '/';
  foreach v_path in array v_paths loop
    if v_path is null
      or not v_path like v_prefix || '%'
      or position('..' in v_path) > 0
    then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid attachment path';
    end if;
    if not exists (
      select 1 from storage.objects o
      where o.bucket_id = 'incidents'
        and o.name = substr(v_path, char_length('incidents/') + 1)
    ) then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'photo not uploaded';
    end if;
  end loop;

  insert into incidents (
    trip_id,
    type,
    reported_by,
    reported_role,
    description,
    attachment_paths,
    client_ref
  ) values (
    p_trip_id,
    p_type::incident_type,
    v_user_id,
    v_role,
    nullif(btrim(p_description), ''),
    v_paths,
    p_client_ref
  )
  returning id into v_incident_id;

  return jsonb_build_object('incident_id', v_incident_id, 'replayed', false);
end;
$$;

revoke all on function report_incident(uuid, text, text, text[], uuid) from public;
grant execute on function report_incident(uuid, text, text, text[], uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Storage: reporter may discard a photo not yet attached to a report.
-- ---------------------------------------------------------------------------
create policy incidents_objects_delete_own_unattached
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'incidents'
    and (storage.foldername(name))[1] = auth.uid()::text
    and not exists (
      select 1 from public.incidents i
      where i.reported_by = auth.uid()
        and ('incidents/' || storage.objects.name) = any (i.attachment_paths)
    )
  );
