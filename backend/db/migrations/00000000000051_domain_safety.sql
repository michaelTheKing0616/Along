-- P5-A-01: SOS, trip sharing, incidents (doc 02 §11, doc 03 §8, doc 12 §1 T10)

-- ---------------------------------------------------------------------------
-- Enums & tables (doc 02 §11 — skip ratings, itineraries)
-- ---------------------------------------------------------------------------
create type sos_status as enum ('open','acknowledged','resolved','false_alarm');
create type incident_type as enum (
  'safety','fare_dispute','vehicle_quality','driver_behavior','rider_behavior','lost_item','other'
);
create type incident_status as enum ('open','triaged','resolved','dismissed');

create table trip_shares (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references journeys(id),
  rider_id uuid not null references riders(id),
  token_hash bytea not null unique,
  contact_name text,
  contact_phone_e164 text,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table sos_alerts (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references trips(id),
  journey_id uuid references journeys(id),
  raised_by uuid not null references profiles(id),
  raised_role text not null check (raised_role in ('rider','driver')),
  location geography(Point,4326) not null,
  accuracy_m numeric(6,1),
  status sos_status not null default 'open',
  acknowledged_by uuid references admin_users(id),
  acknowledged_at timestamptz,
  resolved_at timestamptz,
  resolution_note text,
  created_at timestamptz not null default now()
);
create index sos_open on sos_alerts(created_at) where status in ('open','acknowledged');

create table incidents (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references trips(id),
  type incident_type not null,
  severity smallint not null default 2 check (severity between 1 and 4),
  status incident_status not null default 'open',
  reported_by uuid not null references profiles(id),
  reported_role text not null,
  description text check (char_length(description) <= 2000),
  attachment_paths text[] not null default '{}',
  assigned_to uuid references admin_users(id),
  reported_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolution_note text,
  updated_at timestamptz not null default now()
);

create trigger incidents_set_updated_at before update on incidents
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- Storage bucket (doc 03 §13 — reporter write, safety read)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'incidents',
  'incidents',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy incidents_objects_insert_own
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'incidents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy incidents_objects_select_own
  on storage.objects for select to authenticated
  using (
    bucket_id = 'incidents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy incidents_objects_select_safety
  on storage.objects for select to authenticated
  using (
    bucket_id = 'incidents'
    and has_admin_role(array['safety', 'ops_lead', 'ops_agent', 'superadmin'])
  );

-- ---------------------------------------------------------------------------
-- RLS — trip_shares, sos_alerts, incidents (doc 02 §11 / §16)
-- ---------------------------------------------------------------------------
alter table trip_shares enable row level security;
alter table sos_alerts enable row level security;
alter table incidents enable row level security;

create policy trip_shares_select_own
  on trip_shares for select to authenticated
  using (rider_id = auth.uid());

create policy trip_shares_no_client_write
  on trip_shares for all to authenticated
  using (false)
  with check (false);

create policy sos_alerts_select_raiser
  on sos_alerts for select to authenticated
  using (raised_by = auth.uid());

create policy sos_alerts_select_admin
  on sos_alerts for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead'])
    and (
      trip_id is null
      or admin_can_access_city((
        select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = sos_alerts.trip_id
      ))
      or (
        journey_id is not null
        and admin_can_access_city((
          select j.city_id from journeys j where j.id = sos_alerts.journey_id
        ))
      )
    )
  );

create policy sos_alerts_no_client_write
  on sos_alerts for all to authenticated
  using (false)
  with check (false);

create policy incidents_select_reporter
  on incidents for select to authenticated
  using (reported_by = auth.uid());

create policy incidents_select_admin
  on incidents for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent'])
    and (
      trip_id is null
      or admin_can_access_city((
        select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = incidents.trip_id
      ))
    )
  );

create policy incidents_no_client_write
  on incidents for all to authenticated
  using (false)
  with check (false);

grant select on trip_shares to authenticated;
grant select on sos_alerts to authenticated;
grant select on incidents to authenticated;

create trigger audit_sos_alerts after insert or update or delete on sos_alerts
  for each row execute function audit_admin_write();
create trigger audit_incidents after insert or update or delete on incidents
  for each row execute function audit_admin_write();

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function private.first_name_from_display(p_display_name text)
returns text
language sql
immutable
as $$
  select coalesce(nullif(split_part(coalesce(p_display_name, ''), ' ', 1), ''), 'Rider')
$$;

create or replace function private.share_origin_url(p_city_id uuid default null)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_origin text;
begin
  v_origin := nullif(btrim(replace(cfg('public.origin', p_city_id)::text, '"', '')), '');
  if v_origin is null or v_origin = '' then
    return '';
  end if;
  return rtrim(v_origin, '/');
end;
$$;

revoke all on function private.share_origin_url(uuid) from public;
grant execute on function private.share_origin_url(uuid) to authenticated, service_role;

create or replace function private.enqueue_notify_sos(p_sos_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_url text;
  v_key text;
begin
  begin
    v_url := nullif(current_setting('app.settings.api_external_url', true), '');
    v_key := nullif(current_setting('app.settings.service_role_key', true), '');
  exception
    when others then
      return;
  end;

  if v_url is null or v_key is null then
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/notify',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'kind', 'sos',
      'sos_id', p_sos_id
    )
  );
exception
  when others then
    null;
end;
$$;

revoke all on function private.enqueue_notify_sos(uuid) from public;
grant execute on function private.enqueue_notify_sos(uuid) to service_role;

create or replace function private.shared_trip_legs_progress(p_journey_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'leg_index', leg->>'leg_index',
        'status', coalesce(t.status::text, 'pending'),
        'mode', leg->'mode'
      )
      order by (leg->>'leg_index')::int
    ),
    '[]'::jsonb
  )
  from journeys j
  cross join lateral jsonb_array_elements(coalesce(j.plan_snapshot->'legs', '[]'::jsonb)) leg
  left join trips t
    on t.journey_id = j.id
   and t.journey_sequence = ((leg->>'leg_index')::int + 1)
  where j.id = p_journey_id
$$;

revoke all on function private.shared_trip_legs_progress(uuid) from public;
grant execute on function private.shared_trip_legs_progress(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- raise_sos — never rate-limited; ≤ 300 B payload; notify safety on-call
-- ---------------------------------------------------------------------------
create or replace function raise_sos(
  p_trip_id uuid default null,
  p_journey_id uuid default null,
  p_location jsonb default null,
  p_accuracy_m numeric default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_t trips%rowtype;
  v_j journeys%rowtype;
  v_city_id uuid;
  v_sos_id uuid;
  v_emergency text;
  v_lat double precision;
  v_lng double precision;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_location is null or not (p_location ? 'lat') or not (p_location ? 'lng') then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'location required';
  end if;

  v_lat := (p_location->>'lat')::double precision;
  v_lng := (p_location->>'lng')::double precision;

  if p_accuracy_m is not null and (p_accuracy_m < 0 or p_accuracy_m > 500) then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'accuracy out of range';
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
    p_journey_id := coalesce(p_journey_id, v_t.journey_id);
  elsif p_journey_id is not null then
    select * into v_j from journeys where id = p_journey_id;
    if v_j.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001';
    end if;
    if v_j.rider_id = v_user_id then
      v_role := 'rider';
    else
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
  else
    if exists (select 1 from riders r where r.id = v_user_id) then
      v_role := 'rider';
    elsif exists (select 1 from drivers d where d.id = v_user_id) then
      v_role := 'driver';
    else
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
  end if;

  if p_journey_id is not null and v_j.id is null then
    select * into v_j from journeys where id = p_journey_id;
  end if;

  v_city_id := coalesce(v_j.city_id, (
    select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = p_trip_id
  ));

  v_emergency := replace(cfg('sos.emergency_number', v_city_id)::text, '"', '');

  insert into sos_alerts (
    trip_id,
    journey_id,
    raised_by,
    raised_role,
    location,
    accuracy_m,
    status
  ) values (
    p_trip_id,
    p_journey_id,
    v_user_id,
    v_role,
    st_setsrid(st_makepoint(v_lng, v_lat), 4326)::geography,
    p_accuracy_m,
    'open'
  )
  returning id into v_sos_id;

  perform private.enqueue_notify_sos(v_sos_id);

  return jsonb_build_object(
    'sos_id', v_sos_id,
    'emergency_number', v_emergency
  );
end;
$$;

revoke all on function raise_sos(uuid, uuid, jsonb, numeric) from public;
grant execute on function raise_sos(uuid, uuid, jsonb, numeric) to authenticated;

-- ---------------------------------------------------------------------------
-- update_sos — hold-to-cancel → false_alarm (never delete)
-- ---------------------------------------------------------------------------
create or replace function update_sos(p_sos_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_sos sos_alerts%rowtype;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_sos from sos_alerts where id = p_sos_id for update;
  if v_sos.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_sos.raised_by <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_sos.status not in ('open', 'acknowledged') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  update sos_alerts
  set status = 'false_alarm',
      resolved_at = now(),
      resolution_note = coalesce(resolution_note, 'cancelled by raiser')
  where id = p_sos_id;

  return jsonb_build_object('sos_id', p_sos_id, 'status', 'false_alarm');
end;
$$;

revoke all on function update_sos(uuid) from public;
grant execute on function update_sos(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- create_trip_share / revoke_trip_share
-- ---------------------------------------------------------------------------
create or replace function create_trip_share(
  p_journey_id uuid,
  p_contact_name text default null,
  p_contact_phone text default null
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
  v_ttl_hours numeric;
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

  v_ttl_hours := cfg_num('share.link_ttl_hours', v_j.city_id);
  v_expires := now() + make_interval(hours => v_ttl_hours::int);

  v_token := encode(gen_random_bytes(32), 'base64');
  v_token_hash := digest(v_token, 'sha256');

  insert into trip_shares (
    journey_id,
    rider_id,
    token_hash,
    contact_name,
    contact_phone_e164,
    expires_at
  ) values (
    p_journey_id,
    v_user_id,
    v_token_hash,
    nullif(btrim(p_contact_name), ''),
    nullif(btrim(p_contact_phone), ''),
    v_expires
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
    'share_id', v_share_id
  );
end;
$$;

revoke all on function create_trip_share(uuid, text, text) from public;
grant execute on function create_trip_share(uuid, text, text) to authenticated;

create or replace function revoke_trip_share(p_share_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_share trip_shares%rowtype;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_share from trip_shares where id = p_share_id for update;
  if v_share.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_share.rider_id <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  update trip_shares
  set revoked_at = coalesce(revoked_at, now())
  where id = p_share_id;

  return jsonb_build_object('share_id', p_share_id, 'revoked_at', now());
end;
$$;

revoke all on function revoke_trip_share(uuid) from public;
grant execute on function revoke_trip_share(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- shared_trip_view — anon; minimal disclosure while journey active + token valid
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

  if v_alight is not null then
    v_eta_s := greatest(0, (st_distance(v_loc, v_alight) / greatest(cfg_num('planner.baseline_speed_mps', v_j.city_id), 3))::int);
  end if;

  return jsonb_build_object(
    'rider_first_name', v_rider_first,
    'status', v_t.status::text,
    'mode', _mode_ref(v_t.mode_code),
    'vehicle', jsonb_build_object('plate', coalesce(v_plate, ''), 'color', v_color),
    'driver_first_name', v_driver_first,
    'current_location', jsonb_build_object(
      'lat', st_y(v_loc::geometry),
      'lng', st_x(v_loc::geometry)
    ),
    'destination_label', v_dest_label,
    'eta_s', v_eta_s,
    'legs_progress', private.shared_trip_legs_progress(v_j.id)
  );
end;
$$;

revoke all on function shared_trip_view(text) from public;
grant execute on function shared_trip_view(text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- report_incident
-- ---------------------------------------------------------------------------
create or replace function report_incident(
  p_trip_id uuid default null,
  p_type text default null,
  p_description text default null,
  p_attachment_paths text[] default '{}'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_t trips%rowtype;
  v_incident_id uuid;
  v_path text;
  v_prefix text;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_type is null or p_type = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_description is not null and char_length(p_description) > 2000 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'description too long';
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
  if p_attachment_paths is not null then
    foreach v_path in array p_attachment_paths loop
      if v_path is null or not v_path like v_prefix || '%' then
        raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid attachment path';
      end if;
    end loop;
  end if;

  insert into incidents (
    trip_id,
    type,
    reported_by,
    reported_role,
    description,
    attachment_paths
  ) values (
    p_trip_id,
    p_type::incident_type,
    v_user_id,
    v_role,
    nullif(btrim(p_description), ''),
    coalesce(p_attachment_paths, '{}')
  )
  returning id into v_incident_id;

  return jsonb_build_object('incident_id', v_incident_id);
end;
$$;

revoke all on function report_incident(uuid, text, text, text[]) from public;
grant execute on function report_incident(uuid, text, text, text[]) to authenticated;
