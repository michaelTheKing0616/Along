-- Phase D. Guardian checks, a qualifying rest, and masked trip messages
-- are data the person sets. Illegal trip edges stay in trip_transition.
-- Writes are idempotent so an offline replay cannot double-post.

create table rider_guardian_prefs (
  profile_id uuid primary key references profiles(id) on delete cascade,
  enabled boolean not null default false,
  off_route_m int,
  long_stop_minutes int,
  check_in_minutes int,
  safe_word text,
  updated_at timestamptz not null default now(),
  constraint rider_guardian_prefs_off_route
    check (off_route_m is null or off_route_m between 20 and 5000),
  constraint rider_guardian_prefs_long_stop
    check (long_stop_minutes is null or long_stop_minutes between 1 and 180),
  constraint rider_guardian_prefs_check_in
    check (check_in_minutes is null or check_in_minutes between 1 and 180),
  constraint rider_guardian_prefs_word
    check (safe_word is null or char_length(btrim(safe_word)) between 2 and 40)
);

alter table rider_guardian_prefs enable row level security;

create policy rider_guardian_prefs_owner
  on rider_guardian_prefs for select to authenticated
  using (profile_id = auth.uid() or is_admin());

grant select on rider_guardian_prefs to authenticated;
revoke insert, update, delete on rider_guardian_prefs from authenticated, anon;

create table guardian_events (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  rider_id uuid not null references profiles(id),
  kind text not null check (
    kind in ('off_route', 'long_stop', 'check_in', 'missed', 'safe_word', 'silent_taps')
  ),
  idempotency_key text not null check (char_length(idempotency_key) between 8 and 80),
  escalated boolean not null default false,
  created_at timestamptz not null default now(),
  unique (rider_id, idempotency_key)
);

create index guardian_events_trip on guardian_events (trip_id, created_at);

alter table guardian_events enable row level security;

create policy guardian_events_read
  on guardian_events for select to authenticated
  using (
    rider_id = auth.uid()
    or is_admin()
    or exists (
      select 1 from trips t
      where t.id = trip_id and t.driver_id = auth.uid()
    )
  );

grant select on guardian_events to authenticated;
revoke insert, update, delete on guardian_events from authenticated, anon;

create table driver_rest_prefs (
  driver_id uuid primary key references drivers(id) on delete cascade,
  drive_minutes int,
  rest_minutes int,
  updated_at timestamptz not null default now(),
  constraint driver_rest_prefs_drive
    check (drive_minutes is null or drive_minutes between 30 and 720),
  constraint driver_rest_prefs_rest
    check (rest_minutes is null or rest_minutes between 5 and 180)
);

alter table driver_rest_prefs enable row level security;

create policy driver_rest_prefs_owner
  on driver_rest_prefs for select to authenticated
  using (driver_id = auth.uid() or is_admin());

grant select on driver_rest_prefs to authenticated;
revoke insert, update, delete on driver_rest_prefs from authenticated, anon;

create table driver_rests (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  qualified boolean not null,
  priority_until timestamptz,
  idempotency_key text not null check (char_length(idempotency_key) between 8 and 80),
  created_at timestamptz not null default now(),
  unique (driver_id, idempotency_key),
  check (ended_at > started_at)
);

create index driver_rests_driver on driver_rests (driver_id, ended_at desc);

alter table driver_rests enable row level security;

create policy driver_rests_read
  on driver_rests for select to authenticated
  using (driver_id = auth.uid() or is_admin());

grant select on driver_rests to authenticated;
revoke insert, update, delete on driver_rests from authenticated, anon;

create table trip_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id) on delete cascade,
  author_id uuid not null references profiles(id),
  author_role text not null check (author_role in ('rider', 'driver')),
  body text not null check (char_length(btrim(body)) between 1 and 280),
  client_ref text not null check (char_length(client_ref) between 8 and 80),
  created_at timestamptz not null default now(),
  unique (author_id, client_ref)
);

create index trip_messages_trip on trip_messages (trip_id, created_at);

alter table trip_messages enable row level security;

create policy trip_messages_party
  on trip_messages for select to authenticated
  using (
    is_admin()
    or exists (
      select 1 from trips t
      where t.id = trip_id
        and (t.rider_id = auth.uid() or t.driver_id = auth.uid())
    )
  );

grant select on trip_messages to authenticated;
revoke insert, update, delete on trip_messages from authenticated, anon;

-- ---------------------------------------------------------------------------
create function save_guardian_prefs(
  p_enabled boolean,
  p_off_route_m integer default null,
  p_long_stop_minutes integer default null,
  p_check_in_minutes integer default null,
  p_safe_word text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_word text := nullif(btrim(p_safe_word), '');
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_off_route_m is not null and p_off_route_m not between 20 and 5000 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_long_stop_minutes is not null and p_long_stop_minutes not between 1 and 180 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_check_in_minutes is not null and p_check_in_minutes not between 1 and 180 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_word is not null and char_length(v_word) not between 2 and 40 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  insert into rider_guardian_prefs (
    profile_id, enabled, off_route_m, long_stop_minutes, check_in_minutes, safe_word
  )
  values (
    v_user, coalesce(p_enabled, false), p_off_route_m, p_long_stop_minutes,
    p_check_in_minutes, v_word
  )
  on conflict (profile_id) do update set
    enabled = excluded.enabled,
    off_route_m = excluded.off_route_m,
    long_stop_minutes = excluded.long_stop_minutes,
    check_in_minutes = excluded.check_in_minutes,
    safe_word = excluded.safe_word,
    updated_at = now();

  return jsonb_build_object('idempotency_key', p_idempotency_key, 'enabled', coalesce(p_enabled, false));
end;
$$;

revoke all on function save_guardian_prefs(boolean, integer, integer, integer, text, text) from public;
grant execute on function save_guardian_prefs(boolean, integer, integer, integer, text, text) to authenticated;

create function record_guardian_event(
  p_trip_id uuid,
  p_kind text,
  p_idempotency_key text,
  p_escalate boolean default false,
  p_location jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_trip trips%rowtype;
  v_id uuid;
  v_escalated boolean;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 80 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_kind is null or p_kind not in (
    'off_route', 'long_stop', 'check_in', 'missed', 'safe_word', 'silent_taps'
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select * into v_trip from trips where id = p_trip_id;
  if v_trip.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_trip.rider_id <> v_user then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  insert into guardian_events (trip_id, rider_id, kind, idempotency_key, escalated)
  values (p_trip_id, v_user, p_kind, p_idempotency_key, false)
  on conflict (rider_id, idempotency_key) do nothing
  returning id into v_id;

  if v_id is null then
    select id, escalated into v_id, v_escalated
    from guardian_events
    where rider_id = v_user and idempotency_key = p_idempotency_key;
    return jsonb_build_object('id', v_id, 'escalated', v_escalated, 'replayed', true);
  end if;

  v_escalated := false;
  if coalesce(p_escalate, false) then
    if p_location is null or not (p_location ? 'lat') or not (p_location ? 'lng') then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
    perform raise_sos(p_trip_id, v_trip.journey_id, p_location, null);
    update guardian_events set escalated = true where id = v_id;
    v_escalated := true;
  end if;

  return jsonb_build_object('id', v_id, 'escalated', v_escalated, 'replayed', false);
end;
$$;

revoke all on function record_guardian_event(uuid, text, text, boolean, jsonb) from public;
grant execute on function record_guardian_event(uuid, text, text, boolean, jsonb) to authenticated;

create function save_rest_prefs(
  p_drive_minutes integer default null,
  p_rest_minutes integer default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not exists (select 1 from drivers where id = v_user) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_drive_minutes is not null and p_drive_minutes not between 30 and 720 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_rest_minutes is not null and p_rest_minutes not between 5 and 180 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  insert into driver_rest_prefs (driver_id, drive_minutes, rest_minutes)
  values (v_user, p_drive_minutes, p_rest_minutes)
  on conflict (driver_id) do update set
    drive_minutes = excluded.drive_minutes,
    rest_minutes = excluded.rest_minutes,
    updated_at = now();

  return jsonb_build_object(
    'drive_minutes', p_drive_minutes,
    'rest_minutes', p_rest_minutes,
    'idempotency_key', p_idempotency_key
  );
end;
$$;

revoke all on function save_rest_prefs(integer, integer, text) from public;
grant execute on function save_rest_prefs(integer, integer, text) to authenticated;

create function record_driver_rest(
  p_started_at timestamptz,
  p_ended_at timestamptz,
  p_idempotency_key text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_rest_minutes int;
  v_elapsed numeric;
  v_qualified boolean := false;
  v_until timestamptz;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not exists (select 1 from drivers where id = v_user) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 80 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_started_at is null or p_ended_at is null or p_ended_at <= p_started_at then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select id into v_id
  from driver_rests
  where driver_id = v_user and idempotency_key = p_idempotency_key;
  if v_id is not null then
    select qualified, priority_until into v_qualified, v_until
    from driver_rests where id = v_id;
    return jsonb_build_object(
      'id', v_id, 'qualified', v_qualified, 'priority_until', v_until, 'replayed', true
    );
  end if;

  select rest_minutes into v_rest_minutes
  from driver_rest_prefs where driver_id = v_user;
  v_elapsed := extract(epoch from (p_ended_at - p_started_at)) / 60.0;
  v_qualified := v_rest_minutes is not null and v_elapsed >= v_rest_minutes;
  if v_qualified then
    v_until := p_ended_at + make_interval(mins => v_rest_minutes);
  end if;

  insert into driver_rests (
    driver_id, started_at, ended_at, qualified, priority_until, idempotency_key
  )
  values (v_user, p_started_at, p_ended_at, v_qualified, v_until, p_idempotency_key)
  returning id into v_id;

  return jsonb_build_object(
    'id', v_id,
    'qualified', v_qualified,
    'priority_until', v_until,
    'replayed', false
  );
end;
$$;

revoke all on function record_driver_rest(timestamptz, timestamptz, text) from public;
grant execute on function record_driver_rest(timestamptz, timestamptz, text) to authenticated;

create function my_rest_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_drive int;
  v_rest int;
  v_until timestamptz;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select drive_minutes, rest_minutes into v_drive, v_rest
  from driver_rest_prefs where driver_id = v_user;
  select max(priority_until) into v_until
  from driver_rests
  where driver_id = v_user and qualified and priority_until > now();
  return jsonb_build_object(
    'drive_minutes', v_drive,
    'rest_minutes', v_rest,
    'priority_until', v_until
  );
end;
$$;

revoke all on function my_rest_status() from public;
grant execute on function my_rest_status() to authenticated;

create function post_trip_message(
  p_trip_id uuid,
  p_body text,
  p_client_ref text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_trip trips%rowtype;
  v_role text;
  v_body text := btrim(p_body);
  v_id uuid;
  v_at timestamptz;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_client_ref is null or char_length(p_client_ref) not between 8 and 80 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_body is null or char_length(v_body) not between 1 and 280 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select * into v_trip from trips where id = p_trip_id;
  if v_trip.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_trip.rider_id = v_user then
    v_role := 'rider';
  elsif v_trip.driver_id = v_user then
    v_role := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_trip.ended_at is null or now() > v_trip.ended_at + interval '48 hours' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select id, created_at into v_id, v_at
  from trip_messages
  where author_id = v_user and client_ref = p_client_ref;
  if v_id is not null then
    return jsonb_build_object(
      'id', v_id, 'author_role', v_role, 'body', v_body, 'created_at', v_at, 'replayed', true
    );
  end if;

  insert into trip_messages (trip_id, author_id, author_role, body, client_ref)
  values (p_trip_id, v_user, v_role, v_body, p_client_ref)
  returning id, created_at into v_id, v_at;

  return jsonb_build_object(
    'id', v_id, 'author_role', v_role, 'body', v_body, 'created_at', v_at, 'replayed', false
  );
end;
$$;

revoke all on function post_trip_message(uuid, text, text) from public;
grant execute on function post_trip_message(uuid, text, text) to authenticated;

create function list_trip_messages(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_trip trips%rowtype;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_trip from trips where id = p_trip_id;
  if v_trip.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_trip.rider_id <> v_user and v_trip.driver_id <> v_user and not is_admin() then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', m.id,
      'author_role', m.author_role,
      'body', m.body,
      'created_at', m.created_at
    ) order by m.created_at)
    from trip_messages m
    where m.trip_id = p_trip_id
  ), '[]'::jsonb);
end;
$$;

revoke all on function list_trip_messages(uuid) from public;
grant execute on function list_trip_messages(uuid) to authenticated;
