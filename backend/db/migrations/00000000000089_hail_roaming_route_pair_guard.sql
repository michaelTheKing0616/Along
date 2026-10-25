-- hail_roaming: price by route only when the snapped board and alight stages
-- form a forward pair on the same route. Previously a pair spanning two routes
-- (or reversed) made resolve_fare raise 'invalid stage pair', failing the hail.
-- Body otherwise identical to 00000000000052.

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
  v_route_pair_ok boolean := false;
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

  -- Board and alight are snapped independently, so they can land on different
  -- routes or in reverse order. Route pricing only applies to a forward pair on
  -- one route; anything else is priced point to point.
  if v_route_id is not null and v_board_stage is not null then
    select exists (
      select 1
      from route_stages b
      join route_stages a on a.id = v_alight_stage
      where b.id = v_board_stage
        and b.route_id = v_route_id
        and a.route_id = v_route_id
        and b.sequence < a.sequence
    ) into v_route_pair_ok;
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
  elsif v_route_pair_ok then
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

