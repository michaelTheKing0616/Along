-- P1-A-08: Realtime broadcast authz, presence-fanout targets, register_device_token,
-- driver trip-request Realtime notify + FCM enqueue (doc 03 §2, §5; doc 07 §5, §8).

-- ---------------------------------------------------------------------------
-- Config (doc 03 §2 — fan-out cadence; not listed in doc 02 §2.3 table)
-- ---------------------------------------------------------------------------
insert into app_config (key, scope_type, scope_id, value) values
  ('presence.fanout_interval_s', 'global', '*', '10'),
  ('presence.fanout_radius_m', 'global', '*', '3000')
on conflict (key, scope_type, scope_id) do update set value = excluded.value;

-- ---------------------------------------------------------------------------
-- Realtime topic authorization helpers
-- ---------------------------------------------------------------------------
create or replace function realtime_trip_party(p_topic text, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from trips t
    where p_topic = 'trip:' || t.id::text
      and (t.rider_id = p_user_id or t.driver_id = p_user_id)
  )
$$;

create or replace function realtime_driver_self(p_topic text, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from drivers d
    where p_topic = 'driver:' || d.id::text
      and d.id = p_user_id
  )
$$;

create or replace function realtime_ambient_topic(p_topic text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_topic ~ '^ambient:[^:]+:[a-z0-9]+$'
$$;

revoke all on function realtime_trip_party(text, uuid) from public;
revoke all on function realtime_driver_self(text, uuid) from public;
revoke all on function realtime_ambient_topic(text) from public;
grant execute on function realtime_trip_party(text, uuid) to authenticated, service_role;
grant execute on function realtime_driver_self(text, uuid) to authenticated, service_role;
grant execute on function realtime_ambient_topic(text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Realtime Broadcast RLS (doc 03 §2, §5; doc 12 §realtime)
-- negotiation:* and admin:* remain unauthorized until later phases.
-- ---------------------------------------------------------------------------
create policy realtime_trip_broadcast_select
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'trip:%'
    and realtime_trip_party((select realtime.topic()), (select auth.uid()))
  );

create policy realtime_trip_broadcast_insert
  on realtime.messages for insert to authenticated
  with check (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'trip:%'
    and realtime_trip_party((select realtime.topic()), (select auth.uid()))
  );

create policy realtime_driver_broadcast_select
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'driver:%'
    and realtime_driver_self((select realtime.topic()), (select auth.uid()))
  );

create policy realtime_driver_broadcast_insert
  on realtime.messages for insert to authenticated
  with check (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'driver:%'
    and realtime_driver_self((select realtime.topic()), (select auth.uid()))
  );

create policy realtime_ambient_broadcast_select
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension = 'broadcast'
    and (select realtime.topic()) like 'ambient:%'
    and realtime_ambient_topic((select realtime.topic()))
  );

-- ---------------------------------------------------------------------------
-- register_device_token — doc 03 §1
-- ---------------------------------------------------------------------------
create or replace function register_device_token(
  p_platform text,
  p_token text,
  p_app text
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_platform is null or p_platform not in ('android', 'ios') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_app is null or p_app not in ('rider', 'driver') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_token is null or length(btrim(p_token)) = 0 or length(p_token) > 4096 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  insert into device_tokens (profile_id, platform, token, app, updated_at)
  values (auth.uid(), p_platform, btrim(p_token), p_app, now())
  on conflict (profile_id, token) do update set
    platform = excluded.platform,
    app = excluded.app,
    updated_at = now();
end;
$$;

revoke all on function register_device_token(text, text, text) from public;
grant execute on function register_device_token(text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- presence-fanout targets — active geohash5 cells per city (doc 03 §2, doc 04 §7.3)
-- ---------------------------------------------------------------------------
create or replace function presence_fanout_targets()
returns table (
  city_id uuid,
  city_slug text,
  geohash5 text,
  centroid_lat double precision,
  centroid_lng double precision,
  radius_m int
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_default_radius int;
begin
  v_default_radius := cfg_num('presence.fanout_radius_m', null)::int;

  return query
  with fresh as (
    select
      d.city_id,
      left(along_geohash(
        dp.current_location,
        cfg_num('presence.ambient_cell_precision', d.city_id)::int
      ), 5) as gh5,
      dp.current_location
    from driver_presence dp
    join drivers d on d.id = dp.driver_id
    where driver_is_matchable(dp.driver_id)
      and presence_is_fresh(dp.last_ping_at, d.city_id)
      and dp.status in ('at_park', 'roaming_available')
      and dp.seats_available >= 1
  ),
  cells as (
    select
      f.city_id,
      f.gh5,
      st_y(st_centroid(st_collect(f.current_location::geometry))) as lat,
      st_x(st_centroid(st_collect(f.current_location::geometry))) as lng
    from fresh f
    where f.gh5 is not null and length(f.gh5) >= 5
    group by f.city_id, f.gh5
  )
  select
    c.city_id,
    ci.slug,
    c.gh5,
    c.lat,
    c.lng,
    v_default_radius
  from cells c
  join cities ci on ci.id = c.city_id;
end;
$$;

revoke all on function presence_fanout_targets() from public;
grant execute on function presence_fanout_targets() to service_role;

-- ---------------------------------------------------------------------------
-- Driver trip-request Realtime broadcast (doc 03 §5 driver:{id})
-- ---------------------------------------------------------------------------
create or replace function private.broadcast_driver_trip_request(p_trip_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_t record;
  v_view jsonb;
begin
  select t.id, t.driver_id, t.expires_at, t.status
  into v_t
  from trips t
  where t.id = p_trip_id;

  if v_t.id is null or v_t.status <> 'requested' then
    return;
  end if;

  v_view := build_trip_view(p_trip_id, v_t.driver_id);

  perform realtime.send(
    jsonb_build_object(
      'type', 'trip_request',
      'trip', v_view,
      'expires_at', v_t.expires_at
    ),
    'trip_request',
    'driver:' || v_t.driver_id::text,
    true
  );
end;
$$;

revoke all on function private.broadcast_driver_trip_request(uuid) from public;
grant execute on function private.broadcast_driver_trip_request(uuid) to service_role;

create or replace function private.enqueue_fcm_trip_request(p_trip_id uuid)
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
      'kind', 'trip_request',
      'trip_id', p_trip_id
    )
  );
exception
  when others then
    null;
end;
$$;

revoke all on function private.enqueue_fcm_trip_request(uuid) from public;
grant execute on function private.enqueue_fcm_trip_request(uuid) to service_role;

create or replace function private.notify_driver_trip_request(p_trip_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
begin
  perform private.broadcast_driver_trip_request(p_trip_id);
  perform private.enqueue_fcm_trip_request(p_trip_id);
end;
$$;

revoke all on function private.notify_driver_trip_request(uuid) from public;
grant execute on function private.notify_driver_trip_request(uuid) to service_role;

-- Wire driver notification into request_trip (doc 03 §5).
create or replace function request_trip(
  p_candidate_id uuid,
  p_leg_index int,
  p_women_only boolean,
  p_client_ref uuid,
  p_load jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_rider_id uuid := auth.uid();
  v_candidate jsonb;
  v_leg jsonb;
  v_planner_query_id uuid;
  v_journey_id uuid;
  v_city_id uuid;
  v_origin geography;
  v_destination geography;
  v_source text;
  v_driver_id uuid;
  v_vehicle_id uuid;
  v_profile_id uuid;
  v_quote_id uuid;
  v_quote record;
  v_trip_id uuid;
  v_na record;
  v_ttl int;
  v_commission_rate numeric;
  v_mode_code text;
  v_journey_seq smallint := 1;
  v_load_flagged boolean := coalesce((p_load->>'flagged')::boolean, false);
  v_load_size load_size;
  v_load_note text := p_load->>'note';
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select *
  into v_candidate, v_leg, v_planner_query_id, v_journey_id, v_city_id, v_origin, v_destination
  from _find_plan_leg(v_rider_id, p_candidate_id, p_leg_index);

  v_source := v_candidate->>'source';
  if v_source not in ('parked', 'driver_profile') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_mode_code := coalesce(v_leg->'mode'->>'code', v_leg->>'mode_code');
  perform _validate_load_flag(p_load, v_mode_code, v_city_id);

  if v_load_flagged and p_load ? 'size' then
    begin
      v_load_size := (p_load->>'size')::load_size;
    exception
      when invalid_text_representation then
        raise exception 'VALIDATION' using errcode = 'P0001';
    end;
  end if;

  v_quote_id := (v_leg->'fare'->>'quote_id')::uuid;
  select fq.* into v_quote
  from fare_quotes fq
  where fq.id = v_quote_id;

  if v_quote.id is null or v_quote.expires_at <= now() then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  select rd.driver_id, rd.vehicle_id, rd.profile_id
  into v_driver_id, v_vehicle_id, v_profile_id
  from _resolve_trip_driver(v_source, v_leg, v_candidate, v_city_id) rd;

  select * into v_na
  from generate_na_me_pairing(v_driver_id, v_rider_id, v_city_id);

  v_ttl := cfg_num('dispatch.request_ttl_s', v_city_id)::int;
  v_commission_rate := cfg_num('commission.rate', v_city_id);

  if v_journey_id is null then
    insert into journeys (
      rider_id, city_id, status, origin, destination, plan_snapshot,
      planner_query_id, load_flagged, load_size, load_note, women_only
    ) values (
      v_rider_id,
      v_city_id,
      'planning',
      v_origin,
      v_destination,
      v_candidate,
      v_planner_query_id,
      v_load_flagged,
      v_load_size,
      v_load_note,
      p_women_only
    )
    returning id into v_journey_id;

    if v_planner_query_id is not null then
      update planner_queries
      set chosen_candidate_id = p_candidate_id
      where id = v_planner_query_id;
    end if;
  else
    select coalesce(max(journey_sequence), 0) + 1
    into v_journey_seq
    from trips
    where journey_id = v_journey_id;
  end if;

  insert into trips (
    journey_id,
    journey_sequence,
    rider_id,
    driver_id,
    vehicle_id,
    mode_code,
    route_id,
    driver_route_profile_id,
    route_leg_ids,
    boarding_stage_id,
    alighting_stage_id,
    boarding_location,
    alighting_location,
    fare_quote_id,
    fare_shown,
    fare_currency,
    fare_tier,
    commission_rate,
    status,
    expires_at,
    id_signal_color,
    id_signal_shape,
    load_flagged,
    load_size,
    load_note,
    women_only
  ) values (
    v_journey_id,
    v_journey_seq,
    v_rider_id,
    v_driver_id,
    v_vehicle_id,
    v_mode_code,
    (v_leg->>'route_id')::uuid,
    v_profile_id,
    coalesce(
      (
        select array_agg(x::uuid)
        from jsonb_array_elements_text(coalesce(v_leg->'route_leg_ids', '[]'::jsonb)) t(x)
      ),
      '{}'::uuid[]
    ),
    (v_leg->'board'->>'stage_id')::uuid,
    (v_leg->'alight'->>'stage_id')::uuid,
    case when v_leg->'board' ? 'location'
      then _point_from_json(v_leg->'board'->'location') else null end,
    case when v_leg->'alight' ? 'location'
      then _point_from_json(v_leg->'alight'->'location') else null end,
    v_quote_id,
    v_quote.amount,
    v_quote.currency,
    v_quote.tier,
    v_commission_rate,
    'requested',
    now() + make_interval(secs => v_ttl),
    v_na.color_token,
    v_na.shape,
    v_load_flagged,
    v_load_size,
    v_load_note,
    p_women_only
  )
  returning id into v_trip_id;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, meta)
  values (
    v_trip_id,
    null,
    'requested',
    'rider',
    v_rider_id,
    jsonb_build_object('client_ref', p_client_ref, 'candidate_id', p_candidate_id)
  );

  perform private.notify_driver_trip_request(v_trip_id);

  return build_trip_view(v_trip_id, v_rider_id);
end;
$$;
