-- Phase A: emergency contacts (owner-only) and a live trip share minted with SOS.
-- raise_sos stays a small payload (TS-SOS-01 ≤ 300 B). Contacts are listed separately
-- so a 2G raise does not carry every phone number.

create table emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  phone_e164 text not null check (phone_e164 ~ '^\+[1-9][0-9]{7,14}$'),
  created_at timestamptz not null default now(),
  unique (profile_id, phone_e164)
);

create index emergency_contacts_profile on emergency_contacts (profile_id, created_at);

alter table emergency_contacts enable row level security;

create policy emergency_contacts_owner
  on emergency_contacts for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

grant select, insert, update, delete on emergency_contacts to authenticated;

create or replace function private.guard_emergency_contact_cap()
returns trigger
language plpgsql
as $$
begin
  if (
    select count(*)
    from emergency_contacts
    where profile_id = new.profile_id
  ) >= 5 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'at most 5 emergency contacts';
  end if;
  return new;
end;
$$;

create trigger emergency_contacts_cap
  before insert on emergency_contacts
  for each row execute function private.guard_emergency_contact_cap();

revoke all on function private.guard_emergency_contact_cap() from public;

alter table sos_alerts
  add column share_id uuid references trip_shares(id);

-- ---------------------------------------------------------------------------
-- Owner RPCs
-- ---------------------------------------------------------------------------
create or replace function list_emergency_contacts()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', id,
          'name', display_name,
          'phone_e164', phone_e164
        )
        order by created_at
      )
      from emergency_contacts
      where profile_id = v_user_id
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function list_emergency_contacts() from public;
grant execute on function list_emergency_contacts() to authenticated;

create or replace function upsert_emergency_contact(
  p_display_name text,
  p_phone_e164 text,
  p_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text := btrim(p_display_name);
  v_phone text := btrim(p_phone_e164);
  v_row emergency_contacts%rowtype;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if v_name is null or char_length(v_name) < 1 or char_length(v_name) > 80 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'name required';
  end if;
  if v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'phone must be E.164';
  end if;

  if p_id is not null then
    select * into v_row from emergency_contacts where id = p_id for update;
    if v_row.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001';
    end if;
    if v_row.profile_id <> v_user_id then
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
    update emergency_contacts
    set display_name = v_name,
        phone_e164 = v_phone
    where id = p_id
    returning * into v_row;
  else
    if (
      select count(*) from emergency_contacts where profile_id = v_user_id
    ) >= 5 then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'at most 5 emergency contacts';
    end if;
    insert into emergency_contacts (profile_id, display_name, phone_e164)
    values (v_user_id, v_name, v_phone)
    on conflict (profile_id, phone_e164) do update
      set display_name = excluded.display_name
    returning * into v_row;
  end if;

  return jsonb_build_object(
    'id', v_row.id,
    'name', v_row.display_name,
    'phone_e164', v_row.phone_e164
  );
end;
$$;

revoke all on function upsert_emergency_contact(text, text, uuid) from public;
grant execute on function upsert_emergency_contact(text, text, uuid) to authenticated;

create or replace function delete_emergency_contact(p_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row emergency_contacts%rowtype;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_row from emergency_contacts where id = p_id for update;
  if v_row.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_row.profile_id <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  delete from emergency_contacts where id = p_id;
  return jsonb_build_object('id', p_id, 'deleted', true);
end;
$$;

revoke all on function delete_emergency_contact(uuid) from public;
grant execute on function delete_emergency_contact(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- raise_sos — same contract, plus a rider live-location share when the journey
-- is active. Share failure must not block the alert.
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
  v_share_id uuid;
  v_share_url text;
  v_token text;
  v_token_hash bytea;
  v_ttl_hours numeric;
  v_expires timestamptz;
  v_origin text;
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

  if v_role = 'rider' and v_j.id is not null and v_j.status in ('active', 'transfer') then
    begin
      v_ttl_hours := cfg_num('share.link_ttl_hours', v_j.city_id);
      v_expires := now() + make_interval(hours => greatest(coalesce(v_ttl_hours, 12), 1)::int);
      v_token := encode(gen_random_bytes(32), 'base64');
      v_token_hash := digest(v_token, 'sha256');

      insert into trip_shares (
        journey_id,
        rider_id,
        token_hash,
        contact_name,
        expires_at
      ) values (
        v_j.id,
        v_user_id,
        v_token_hash,
        'SOS',
        v_expires
      )
      returning id into v_share_id;

      update sos_alerts set share_id = v_share_id where id = v_sos_id;

      v_origin := private.share_origin_url(v_j.city_id);
      if v_origin <> '' then
        v_share_url := v_origin || '/s/' || v_token;
      else
        v_share_url := '/s/' || v_token;
      end if;
    exception
      when others then
        v_share_url := null;
    end;
  end if;

  perform private.enqueue_notify_sos(v_sos_id);

  return jsonb_strip_nulls(jsonb_build_object(
    'sos_id', v_sos_id,
    'emergency_number', v_emergency,
    'share_url', v_share_url
  ));
end;
$$;

revoke all on function raise_sos(uuid, uuid, jsonb, numeric) from public;
grant execute on function raise_sos(uuid, uuid, jsonb, numeric) to authenticated;
