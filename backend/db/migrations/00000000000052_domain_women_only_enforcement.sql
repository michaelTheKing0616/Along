-- P5-A-02: women-only matching — request/hail enforcement + regulatory flag gating (doc 04 §5, doc 03 §1)

-- ---------------------------------------------------------------------------
-- Regulatory + driver eligibility guards (shared by request_trip / hail_roaming)
-- ---------------------------------------------------------------------------
create or replace function women_only_matching_enabled(p_city_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (c.regulatory_flags->>'women_only_matching')::boolean,
    false
  )
  from cities ci
  join countries c on c.code = ci.country_code
  where ci.id = p_city_id;
$$;

create or replace function _assert_women_only_regulatory(
  p_women_only boolean,
  p_city_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not coalesce(p_women_only, false) then
    return;
  end if;

  if not women_only_matching_enabled(p_city_id) then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function _assert_driver_women_only_eligible(
  p_women_only boolean,
  p_driver_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not coalesce(p_women_only, false) then
    return;
  end if;

  if p_driver_id is null then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from drivers d
    where d.id = p_driver_id
      and d.women_only_eligible
  ) then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- _resolve_trip_driver — honour women_only at resolve time (parked / profile / roaming)
-- ---------------------------------------------------------------------------
create or replace function _resolve_trip_driver(
  p_source text,
  p_leg jsonb,
  p_candidate jsonb,
  p_city_id uuid,
  p_women_only boolean default false
)
returns table (driver_id uuid, vehicle_id uuid, profile_id uuid)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_supply jsonb := coalesce(p_leg->'supply', '{}'::jsonb);
  v_driver uuid;
  v_vehicle uuid;
  v_profile uuid;
  v_board_stage uuid := (p_leg->'board'->>'stage_id')::uuid;
  v_token text := v_supply->>'candidate_token';
  v_verified record;
begin
  if p_source = 'roaming' then
    if v_token is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select * into v_verified from verify_candidate_token(v_token, p_city_id);

    select rp.driver_id, rp.vehicle_id, rp.profile_id
    into v_driver, v_vehicle, v_profile
    from _resolve_roaming_presence(
      v_verified.driver_id,
      v_verified.session_id,
      p_city_id,
      null,
      p_women_only
    ) rp;

    return query select v_driver, v_vehicle, v_profile;
    return;
  end if;

  if p_source = 'driver_profile' then
    v_profile := coalesce(
      (v_supply->>'profile_id')::uuid,
      (p_candidate->>'profile_id')::uuid,
      (p_candidate->>'driver_route_profile_id')::uuid
    );
    if v_profile is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select drp.driver_id into v_driver
    from driver_route_profiles drp
    where drp.id = v_profile
      and drp.active;

    if v_driver is null then
      raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
    end if;
  elsif p_source = 'parked' then
    v_driver := (v_supply->>'driver_id')::uuid;

    if v_driver is null then
      select dp.driver_id, dp.vehicle_id
      into v_driver, v_vehicle
      from driver_presence dp
      join drivers d on d.id = dp.driver_id
      where dp.status = 'at_park'
        and dp.nearest_stage_id = v_board_stage
        and d.city_id = p_city_id
        and driver_is_matchable(dp.driver_id)
        and (not p_women_only or d.women_only_eligible)
      order by dp.started_at
      limit 1;
    end if;

    if v_driver is null then
      raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
    end if;
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if not driver_is_matchable(v_driver) then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  perform _assert_driver_women_only_eligible(p_women_only, v_driver);

  if v_vehicle is null then
    select dp.vehicle_id into v_vehicle
    from driver_presence dp
    where dp.driver_id = v_driver;

    if v_vehicle is null then
      select dv.vehicle_id into v_vehicle
      from driver_vehicles dv
      where dv.driver_id = v_driver
        and dv.active
      limit 1;
    end if;
  end if;

  if v_vehicle is null then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  return query select v_driver, v_vehicle, v_profile;
end;
$$;

-- ---------------------------------------------------------------------------
-- hail_roaming — regulatory gate before resolve
-- ---------------------------------------------------------------------------
create or replace function hail_roaming(
  p_candidate_token text,
  p_destination jsonb,
  p_women_only boolean,
  p_client_ref uuid,
  p_load jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_rider_id uuid := auth.uid();
  v_verified record;
  v_presence record;
  v_city_id uuid;
  v_destination geography;
  v_origin geography;
  v_fare fare_resolution;
  v_quote_id uuid;
  v_trip_id uuid;
  v_journey_id uuid;
  v_na record;
  v_ttl int;
  v_commission_rate numeric;
  v_load_flagged boolean := coalesce((p_load->>'flagged')::boolean, false);
  v_load_size load_size;
  v_load_note text := p_load->>'note';
  v_board_stage uuid;
  v_alight_stage uuid;
  v_route_id uuid;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  v_destination := _point_from_json(p_destination);
  if v_destination is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_city_id := city_for_point(v_destination);

  perform _assert_women_only_regulatory(p_women_only, v_city_id);

  select * into v_verified from verify_candidate_token(p_candidate_token, v_city_id);

  select * into v_presence
  from _resolve_roaming_presence(
    v_verified.driver_id,
    v_verified.session_id,
    v_city_id,
    v_destination,
    p_women_only
  );

  v_origin := v_presence.current_location;
  perform _validate_load_flag(p_load, v_presence.mode_code, v_city_id);

  if v_load_flagged and p_load ? 'size' then
    begin
      v_load_size := (p_load->>'size')::load_size;
    exception
      when invalid_text_representation then
        raise exception 'VALIDATION' using errcode = 'P0001';
    end;
  end if;

  v_board_stage := snap_stage(v_origin, null, v_city_id);
  v_alight_stage := snap_stage(v_destination, null, v_city_id);

  if v_alight_stage is not null then
    select rs.route_id into v_route_id from route_stages rs where rs.id = v_alight_stage;
  end if;

  if v_presence.profile_id is not null then
    v_fare := resolve_fare(
      p_profile_id := v_presence.profile_id,
      p_from_stage_id := v_board_stage,
      p_to_stage_id := v_alight_stage,
      p_from_point := case when v_board_stage is null then v_origin else null end,
      p_to_point := case when v_alight_stage is null then v_destination else null end,
      p_mode_code := v_presence.mode_code,
      p_city_id := v_city_id,
      p_load := p_load,
      p_rider_id := v_rider_id,
      p_driver_id := v_presence.driver_id
    );
  elsif v_route_id is not null and v_board_stage is not null and v_alight_stage is not null then
    v_fare := resolve_fare(
      p_route_id := v_route_id,
      p_from_stage_id := v_board_stage,
      p_to_stage_id := v_alight_stage,
      p_mode_code := v_presence.mode_code,
      p_city_id := v_city_id,
      p_load := p_load,
      p_rider_id := v_rider_id,
      p_driver_id := v_presence.driver_id
    );
  else
    v_fare := resolve_fare(
      p_from_point := v_origin,
      p_to_point := v_destination,
      p_mode_code := v_presence.mode_code,
      p_city_id := v_city_id,
      p_load := p_load,
      p_rider_id := v_rider_id,
      p_driver_id := v_presence.driver_id
    );
  end if;

  if v_fare.tier = 3 and v_fare.unconfirmed then
    raise exception 'FARE_UNRESOLVED' using errcode = 'P0001';
  end if;

  v_quote_id := v_fare.quote_id;
  select * into v_na from generate_na_me_pairing(v_presence.driver_id, v_rider_id, v_city_id);
  v_ttl := cfg_num('dispatch.request_ttl_s', v_city_id)::int;
  v_commission_rate := cfg_num('commission.rate', v_city_id);

  insert into journeys (
    rider_id, city_id, status, origin, destination, plan_snapshot,
    load_flagged, load_size, load_note, women_only
  ) values (
    v_rider_id,
    v_city_id,
    'planning',
    v_origin,
    v_destination,
    jsonb_build_object('source', 'roaming', 'candidate_token', p_candidate_token),
    v_load_flagged,
    v_load_size,
    v_load_note,
    p_women_only
  )
  returning id into v_journey_id;

  insert into trips (
    journey_id,
    journey_sequence,
    rider_id,
    driver_id,
    vehicle_id,
    mode_code,
    route_id,
    driver_route_profile_id,
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
    1,
    v_rider_id,
    v_presence.driver_id,
    v_presence.vehicle_id,
    v_presence.mode_code,
    v_route_id,
    v_presence.profile_id,
    v_board_stage,
    v_alight_stage,
    v_origin,
    v_destination,
    v_quote_id,
    v_fare.amount,
    v_fare.currency,
    v_fare.tier,
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

  insert into trip_dispatch_context (
    trip_id, origin, destination, ambient_cell, mode_code, tried_driver_ids
  ) values (
    v_trip_id,
    v_origin,
    v_destination,
    v_presence.ambient_cell,
    v_presence.mode_code,
    array[v_presence.driver_id]
  );

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, meta)
  values (
    v_trip_id,
    null,
    'requested',
    'rider',
    v_rider_id,
    jsonb_build_object('client_ref', p_client_ref, 'hail_source', 'roaming')
  );

  perform private.notify_driver_trip_request(v_trip_id);

  return build_trip_view(v_trip_id, v_rider_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- request_trip — regulatory gate + driver eligibility before trip insert
-- ---------------------------------------------------------------------------
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
set search_path = public, extensions, private
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
  v_presence record;
  v_token text;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select *
  into v_candidate, v_leg, v_planner_query_id, v_journey_id, v_city_id, v_origin, v_destination
  from _find_plan_leg(v_rider_id, p_candidate_id, p_leg_index);

  perform _assert_women_only_regulatory(p_women_only, v_city_id);

  v_source := v_candidate->>'source';
  if v_source not in ('parked', 'driver_profile', 'roaming') then
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

  if v_source = 'roaming' then
    v_token := v_leg->'supply'->>'candidate_token';
    perform verify_candidate_token(v_token, v_city_id);
  end if;

  select rd.driver_id, rd.vehicle_id, rd.profile_id
  into v_driver_id, v_vehicle_id, v_profile_id
  from _resolve_trip_driver(v_source, v_leg, v_candidate, v_city_id, p_women_only) rd;

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

  if v_source = 'roaming' then
    select * into v_presence
    from _resolve_roaming_presence(
      v_driver_id,
      (select session_id from driver_presence where driver_id = v_driver_id),
      v_city_id,
      v_destination,
      p_women_only
    );

    insert into trip_dispatch_context (
      trip_id, origin, destination, ambient_cell, mode_code, tried_driver_ids
    ) values (
      v_trip_id,
      coalesce(v_origin, v_presence.current_location),
      v_destination,
      v_presence.ambient_cell,
      v_mode_code,
      array[v_driver_id]
    );
  end if;

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
