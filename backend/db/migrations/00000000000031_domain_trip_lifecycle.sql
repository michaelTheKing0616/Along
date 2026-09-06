-- P3-A-01: full trip lifecycle — location samples, auto-boarding, dedicated RPCs,
-- path materialisation, no_show, driver_manifest (doc 04 §9–§10, doc 03 §5)

select config_default('boarding.in_transit_min_speed_mps', '3');
select config_default('boarding.in_transit_duration_s', '30');
select config_default('boarding.sample_max_age_s', '15');
select config_default('boarding.sample_max_accuracy_m', '50');

alter table trips
  add column if not exists meta jsonb not null default '{}'::jsonb;

-- ---------------------------------------------------------------------------
-- Path materialisation (doc 04 §10)
-- ---------------------------------------------------------------------------
create or replace function _materialize_trip_paths(p_trip_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_path geography;
  v_rider_path geography;
begin
  select st_makeline(location::geometry order by ts)
  into v_driver_path
  from trip_location_samples
  where trip_id = p_trip_id
    and actor_type = 'driver';

  select st_makeline(location::geometry order by ts)
  into v_rider_path
  from trip_location_samples
  where trip_id = p_trip_id
    and actor_type = 'rider';

  update trips
  set
    driver_live_path = case
      when v_driver_path is not null and st_npoints(v_driver_path::geometry) >= 2
      then v_driver_path
      else driver_live_path
    end,
    rider_live_path = case
      when v_rider_path is not null and st_npoints(v_rider_path::geometry) >= 2
      then v_rider_path
      else rider_live_path
    end
  where id = p_trip_id;
end;
$$;

create or replace function _trip_boarding_point(p_trip trips)
returns geography
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_point geography;
begin
  if p_trip.boarding_location is not null then
    return p_trip.boarding_location;
  end if;

  if p_trip.boarding_stage_id is not null then
    select rs.location into v_point
    from route_stages rs
    where rs.id = p_trip.boarding_stage_id;
    return v_point;
  end if;

  return null;
end;
$$;

create or replace function _latest_trip_sample(
  p_trip_id uuid,
  p_actor_type actor_type
)
returns trip_location_samples
language sql
stable
security definer
set search_path = public
as $$
  select s.*
  from trip_location_samples s
  join trips t on t.id = s.trip_id
  join journeys j on j.id = t.journey_id
  where s.trip_id = p_trip_id
    and s.actor_type = p_actor_type
    and s.ts >= now() - make_interval(
      secs => cfg_num('boarding.sample_max_age_s', j.city_id)::int
    )
    and coalesce(s.accuracy_m, 0) <= cfg_num('boarding.sample_max_accuracy_m', j.city_id)
  order by s.ts desc
  limit 1;
$$;

-- ---------------------------------------------------------------------------
-- Auto-boarding / auto in-transit (doc 04 §9)
-- ---------------------------------------------------------------------------
create or replace function auto_boarding_check(p_trip_id uuid)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_rider trip_location_samples%rowtype;
  v_driver trip_location_samples%rowtype;
  v_radius_m numeric;
  v_duration_s int;
  v_min_speed numeric;
  v_colocated_since timestamptz;
  v_distance_m numeric;
begin
  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null or v_t.status <> 'accepted' then
    return false;
  end if;

  select * into v_rider from _latest_trip_sample(p_trip_id, 'rider');
  select * into v_driver from _latest_trip_sample(p_trip_id, 'driver');

  if v_rider.trip_id is null or v_driver.trip_id is null then
    update trips
    set meta = coalesce(meta, '{}'::jsonb) - 'colocated_since'
    where id = p_trip_id;
    return false;
  end if;

  v_radius_m := cfg_num('boarding.colocation_radius_m', (
    select j.city_id from journeys j where j.id = v_t.journey_id
  ));
  v_duration_s := cfg_num('boarding.colocation_duration_s', (
    select j.city_id from journeys j where j.id = v_t.journey_id
  ))::int;
  v_min_speed := cfg_num('boarding.min_speed_mps', (
    select j.city_id from journeys j where j.id = v_t.journey_id
  ));

  v_distance_m := st_distance(v_rider.location, v_driver.location);

  if v_distance_m > v_radius_m then
    update trips
    set meta = coalesce(meta, '{}'::jsonb) - 'colocated_since'
    where id = p_trip_id;
    return false;
  end if;

  v_colocated_since := nullif(coalesce(v_t.meta, '{}'::jsonb)->>'colocated_since', '')::timestamptz;
  if v_colocated_since is null then
    v_colocated_since := least(v_rider.ts, v_driver.ts);
    update trips
    set meta = coalesce(meta, '{}'::jsonb) || jsonb_build_object('colocated_since', v_colocated_since)
    where id = p_trip_id;
  end if;

  if extract(epoch from (greatest(v_rider.ts, v_driver.ts) - v_colocated_since)) < v_duration_s then
    return false;
  end if;

  if coalesce(v_driver.speed_mps, 0) < v_min_speed
     and coalesce(v_rider.speed_mps, 0) < v_min_speed then
    return false;
  end if;

  perform trip_transition(
    p_trip_id,
    'boarded',
    'system',
    null,
    null,
    jsonb_build_object('boarded_via', 'auto_colocation')
  );
  return true;
end;
$$;

create or replace function auto_in_transit_check(p_trip_id uuid)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_driver trip_location_samples%rowtype;
  v_min_speed numeric;
  v_duration_s int;
  v_moving_since timestamptz;
begin
  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null or v_t.status <> 'boarded' then
    return false;
  end if;

  select * into v_driver from _latest_trip_sample(p_trip_id, 'driver');
  if v_driver.trip_id is null then
    update trips
    set meta = coalesce(meta, '{}'::jsonb) - 'moving_since'
    where id = p_trip_id;
    return false;
  end if;

  v_min_speed := cfg_num('boarding.in_transit_min_speed_mps', (
    select j.city_id from journeys j where j.id = v_t.journey_id
  ));
  v_duration_s := cfg_num('boarding.in_transit_duration_s', (
    select j.city_id from journeys j where j.id = v_t.journey_id
  ))::int;

  if coalesce(v_driver.speed_mps, 0) < v_min_speed then
    update trips
    set meta = coalesce(meta, '{}'::jsonb) - 'moving_since'
    where id = p_trip_id;
    return false;
  end if;

  v_moving_since := nullif(coalesce(v_t.meta, '{}'::jsonb)->>'moving_since', '')::timestamptz;
  if v_moving_since is null then
    v_moving_since := v_driver.ts;
    update trips
    set meta = coalesce(meta, '{}'::jsonb) || jsonb_build_object('moving_since', v_moving_since)
    where id = p_trip_id;
    return false;
  end if;

  if extract(epoch from (v_driver.ts - v_moving_since)) < v_duration_s then
    return false;
  end if;

  perform trip_transition(p_trip_id, 'in_transit', 'system');
  return true;
end;
$$;

-- ---------------------------------------------------------------------------
-- trip_location_sample — doc 03 §5
-- ---------------------------------------------------------------------------
create or replace function trip_location_sample(
  p_trip_id uuid,
  p_points jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_actor actor_type;
  v_point jsonb;
  v_ts timestamptz;
  v_loc geography;
  v_boarded_auto boolean := false;
  v_in_transit_auto boolean := false;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_uid = v_t.rider_id then
    v_actor := 'rider';
  elsif v_uid = v_t.driver_id then
    v_actor := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status not in ('accepted', 'boarded', 'in_transit') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if jsonb_array_length(p_points) < 1 or jsonb_array_length(p_points) > 5 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  for v_point in select value from jsonb_array_elements(p_points) loop
    v_ts := coalesce((v_point->>'ts')::timestamptz, now());
    v_loc := st_setsrid(
      st_makepoint(
        (v_point->>'lng')::double precision,
        (v_point->>'lat')::double precision
      ),
      4326
    )::geography;

    insert into trip_location_samples (
      trip_id,
      actor_type,
      ts,
      location,
      accuracy_m,
      speed_mps,
      heading
    ) values (
      p_trip_id,
      v_actor,
      v_ts,
      v_loc,
      (v_point->>'accuracy_m')::numeric,
      (v_point->>'speed_mps')::numeric,
      (v_point->>'heading')::smallint
    );
  end loop;

  v_boarded_auto := auto_boarding_check(p_trip_id);
  v_in_transit_auto := auto_in_transit_check(p_trip_id);

  return jsonb_build_object('boarded_auto', v_boarded_auto);
end;
$$;

-- ---------------------------------------------------------------------------
-- Dedicated lifecycle RPCs — doc 03 §5
-- ---------------------------------------------------------------------------
create or replace function mark_boarded(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_actor actor_type;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_uid = v_t.rider_id then
    v_actor := 'rider';
  elsif v_uid = v_t.driver_id then
    v_actor := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'accepted' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  perform trip_transition(p_trip_id, 'boarded', v_actor, v_uid);
  return build_trip_view(p_trip_id, v_uid);
end;
$$;

create or replace function start_trip(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from trips t
    where t.id = p_trip_id
      and t.driver_id = v_driver_id
      and t.status = 'boarded'
  ) then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  perform trip_transition(p_trip_id, 'in_transit', 'driver', v_driver_id);
  return build_trip_view(p_trip_id, v_driver_id);
end;
$$;

create or replace function complete_trip(
  p_trip_id uuid,
  p_alighting jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_commission numeric;
  v_fare numeric;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.driver_id is distinct from v_driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'in_transit' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_alighting is not null then
    update trips
    set
      alighting_location = st_setsrid(
        st_makepoint(
          (p_alighting->>'lng')::double precision,
          (p_alighting->>'lat')::double precision
        ),
        4326
      )::geography,
      alighting_stage_id = nullif(p_alighting->>'stage_id', '')::uuid
    where id = p_trip_id;
  end if;

  perform trip_transition(p_trip_id, 'completed', 'driver', v_driver_id);

  select * into v_t from trips where id = p_trip_id;
  v_fare := v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0);
  v_commission := coalesce(v_t.commission_amount, round(v_fare * v_t.commission_rate, 2));

  return jsonb_build_object(
    'trip', build_trip_view(p_trip_id, v_driver_id),
    'commission', jsonb_build_object('amount', v_commission, 'currency', v_t.fare_currency),
    'fare', jsonb_build_object('amount', v_fare, 'currency', v_t.fare_currency)
  );
end;
$$;

create or replace function mark_no_show(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_city_id uuid;
  v_no_show_after_s int;
  v_boarding geography;
  v_driver_sample trip_location_samples%rowtype;
  v_radius_m numeric;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select j.city_id into v_city_id
  from journeys j
  where j.id = v_t.journey_id;

  if v_t.driver_id is distinct from v_driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'accepted' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_no_show_after_s := cfg_num('dispatch.no_show_after_s', v_city_id)::int;
  if coalesce(v_t.accepted_at, v_t.requested_at) + make_interval(secs => v_no_show_after_s) > now() then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_boarding := _trip_boarding_point(v_t);
  if v_boarding is not null then
    select * into v_driver_sample from _latest_trip_sample(p_trip_id, 'driver');
    v_radius_m := cfg_num('boarding.colocation_radius_m', v_city_id);

    if v_driver_sample.trip_id is null
       or st_distance(v_driver_sample.location, v_boarding) > v_radius_m then
      raise exception 'STATE_INVALID' using errcode = 'P0001';
    end if;
  end if;

  perform trip_transition(p_trip_id, 'no_show', 'driver', v_driver_id);
  return build_trip_view(p_trip_id, v_driver_id);
end;
$$;

create or replace function driver_manifest()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'trip_id', t.id,
          'status', t.status,
          'journey_sequence', t.journey_sequence,
          'rider', jsonb_build_object(
            'display_name', coalesce(p.display_name, 'Rider'),
            'rating', 0,
            'trip_count', coalesce(r.trip_count, 0)
          ),
          'board', case
            when t.boarding_stage_id is not null then (
              select jsonb_build_object(
                'stage_id', rs.id,
                'name', rs.name,
                'location', jsonb_build_object(
                  'lat', st_y(rs.location::geometry),
                  'lng', st_x(rs.location::geometry)
                )
              )
              from route_stages rs
              where rs.id = t.boarding_stage_id
            )
            when t.boarding_location is not null then jsonb_build_object(
              'stage_id', null,
              'name', 'Pickup',
              'location', jsonb_build_object(
                'lat', st_y(t.boarding_location::geometry),
                'lng', st_x(t.boarding_location::geometry)
              )
            )
            else jsonb_build_object('stage_id', null, 'name', '', 'location', null)
          end,
          'na_me', jsonb_build_object(
            'color_token', t.id_signal_color,
            'shape', t.id_signal_shape,
            'label', _na_me_label(t.id_signal_color, t.id_signal_shape)
          ),
          'expires_at', t.expires_at
        )
        order by t.accepted_at nulls last, t.requested_at
      )
      from trips t
      join profiles p on p.id = t.rider_id
      join riders r on r.id = t.rider_id
      where t.driver_id = v_driver_id
        and t.status in ('accepted', 'boarded', 'in_transit')
    ),
    '[]'::jsonb
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- trip_transition — extend §10 (no_show, path materialisation; commission stub)
-- ---------------------------------------------------------------------------
create or replace function trip_transition(
  p_trip_id uuid,
  p_to_status trip_status,
  p_actor_type actor_type,
  p_actor_id uuid default null,
  p_reason text default null,
  p_meta jsonb default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_t trips%rowtype;
  v_allowed boolean := false;
  v_commission numeric;
begin
  select * into v_t from trips where id = p_trip_id for update;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.status = p_to_status then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_allowed := case
    when v_t.status = 'requested' and p_to_status = 'accepted'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id and driver_is_matchable(v_t.driver_id)
    when v_t.status = 'requested' and p_to_status = 'declined'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'requested' and p_to_status = 'expired'
      then p_actor_type = 'system'
    when v_t.status = 'requested' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    when v_t.status = 'accepted' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    when v_t.status = 'accepted' and p_to_status = 'cancelled_by_driver'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'accepted' and p_to_status = 'no_show'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'accepted' and p_to_status = 'boarded'
      then p_actor_type in ('system', 'rider', 'driver')
        and (p_actor_type = 'system' or p_actor_id in (v_t.rider_id, v_t.driver_id))
    when v_t.status = 'boarded' and p_to_status = 'in_transit'
      then p_actor_type in ('system', 'driver') and (p_actor_type = 'system' or p_actor_id = v_t.driver_id)
    when v_t.status = 'boarded' and p_to_status = 'cancelled_by_driver'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'boarded' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    when v_t.status = 'in_transit' and p_to_status = 'completed'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'in_transit' and p_to_status = 'cancelled_by_driver'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'in_transit' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    else false
  end;

  if not v_allowed then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  perform set_config('along.in_transition', 'on', true);

  v_commission := round((v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0)) * v_t.commission_rate, 2);

  update trips
  set
    status = p_to_status,
    accepted_at = case when p_to_status = 'accepted' then now() else accepted_at end,
    boarded_at = case when p_to_status = 'boarded' then now() else boarded_at end,
    started_at = case when p_to_status = 'in_transit' then coalesce(started_at, now()) else started_at end,
    ended_at = case
      when p_to_status = 'completed'
        or p_to_status in ('declined', 'expired', 'cancelled_by_rider', 'cancelled_by_driver', 'no_show')
      then now()
      else ended_at
    end,
    cancelled_at = case when p_to_status::text like 'cancelled_%' or p_to_status in ('declined', 'expired')
      then now() else cancelled_at end,
    boarded_via = case
      when p_to_status = 'boarded' and p_actor_type = 'system' then 'auto_colocation'
      when p_to_status = 'boarded' and p_actor_type = 'rider' then 'manual_rider'
      when p_to_status = 'boarded' and p_actor_type = 'driver' then 'manual_driver'
      else boarded_via
    end,
    commission_amount = case when p_to_status = 'completed' then v_commission else commission_amount end,
    cancel_reason = case
      when p_to_status = 'cancelled_by_rider' or p_to_status = 'cancelled_by_driver' then p_reason
      else cancel_reason
    end,
    decline_reason = case when p_to_status = 'declined' then p_reason else decline_reason end,
    meta = case
      when p_to_status = 'boarded' then coalesce(meta, '{}'::jsonb) - 'colocated_since'
      when p_to_status = 'in_transit' then coalesce(meta, '{}'::jsonb) - 'moving_since'
      else meta
    end
  where id = p_trip_id;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, reason, meta)
  values (p_trip_id, v_t.status, p_to_status, p_actor_type, p_actor_id, p_reason, p_meta);

  if p_to_status = 'accepted' then
    if v_t.journey_sequence = 1 then
      update journeys
      set status = 'active', updated_at = now()
      where id = v_t.journey_id
        and status = 'planning';
    else
      update journeys
      set status = 'active', updated_at = now()
      where id = v_t.journey_id
        and status = 'transfer';
    end if;
  elsif p_to_status = 'completed' then
    perform _materialize_trip_paths(p_trip_id);
    select * into v_t from trips where id = p_trip_id;
    perform _advance_journey_on_trip_complete(v_t);
    update riders
    set trip_count = trip_count + 1
    where id = v_t.rider_id;
  elsif p_to_status = 'in_transit' then
    perform private.maybe_enqueue_transfer_prefetch(p_trip_id);
  end if;

  perform set_config('along.in_transition', '', true);
end;
$$;

grant execute on function trip_location_sample(uuid, jsonb) to authenticated;
grant execute on function mark_boarded(uuid) to authenticated;
grant execute on function start_trip(uuid) to authenticated;
grant execute on function complete_trip(uuid, jsonb) to authenticated;
grant execute on function mark_no_show(uuid) to authenticated;
grant execute on function driver_manifest() to authenticated;
grant execute on function auto_boarding_check(uuid) to service_role;
grant execute on function auto_in_transit_check(uuid) to service_role;
