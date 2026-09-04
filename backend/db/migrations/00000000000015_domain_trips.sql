-- P1-A-05: doc 04 §10 (requested/accepted/declined/expired/cancelled subset), §16 Na Me,
-- doc 03 §4–5 — request_trip (parked/profile), respond/cancel, expire_requests,
-- trip_transition, TripView, driver_is_matchable (verification-only until Phase 4 ledger).

-- ---------------------------------------------------------------------------
-- Planner candidate storage (populated by plan-trip in P1-A-06; read by request_trip)
-- ---------------------------------------------------------------------------
alter table planner_queries
  add column if not exists candidates jsonb not null default '[]'::jsonb;

-- ---------------------------------------------------------------------------
-- Na Me helpers — doc 04 §16
-- ---------------------------------------------------------------------------
create or replace function _na_me_token_label(p_token text)
returns text
language sql
immutable
as $$
  select initcap(
    coalesce(
      nullif(regexp_replace(p_token, '^.*\.', ''), ''),
      p_token
    )
  )
$$;

create or replace function _na_me_label(p_color_token text, p_shape text, p_locale text default 'en-NG')
returns text
language sql
immutable
as $$
  select _na_me_token_label(p_color_token) || ' ' || initcap(p_shape)
$$;

create or replace function generate_na_me_pairing(
  p_driver_id uuid,
  p_rider_id uuid,
  p_city_id uuid
)
returns table (color_token text, shape text, label text)
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_colors jsonb;
  v_shapes jsonb;
  v_used_colors text[];
  v_used_pairs text[];
  v_color text;
  v_shape text;
  v_pair text;
begin
  v_colors := cfg('name.colors', p_city_id);
  v_shapes := cfg('name.shapes', p_city_id);

  select
    coalesce(array_agg(distinct t.id_signal_color), '{}'::text[]),
    coalesce(array_agg(distinct t.id_signal_color || ':' || t.id_signal_shape), '{}'::text[])
  into v_used_colors, v_used_pairs
  from trips t
  where t.status in ('requested', 'accepted', 'boarded', 'in_transit')
    and (
      t.driver_id = p_driver_id
      or t.rider_id = p_rider_id
    );

  for v_color in select jsonb_array_elements_text(v_colors) loop
    exit when v_color = any (v_used_colors);
    for v_shape in select jsonb_array_elements_text(v_shapes) loop
      v_pair := v_color || ':' || v_shape;
      if not (v_pair = any (v_used_pairs)) then
        return query
        select
          v_color,
          v_shape,
          _na_me_label(v_color, v_shape, coalesce((select locale from profiles where id = p_rider_id), 'en-NG'));
        return;
      end if;
    end loop;
  end loop;

  for v_color in select jsonb_array_elements_text(v_colors) loop
    for v_shape in select jsonb_array_elements_text(v_shapes) loop
      v_pair := v_color || ':' || v_shape;
      if not (v_pair = any (v_used_pairs)) then
        return query
        select
          v_color,
          v_shape,
          _na_me_label(v_color, v_shape, coalesce((select locale from profiles where id = p_rider_id), 'en-NG'));
        return;
      end if;
    end loop;
  end loop;

  raise exception 'Na Me palette exhausted for driver/rider pair'
    using errcode = 'P0001';
end;
$$;

-- ---------------------------------------------------------------------------
-- Plan candidate resolution
-- ---------------------------------------------------------------------------
create or replace function _find_plan_leg(
  p_rider_id uuid,
  p_candidate_id uuid,
  p_leg_index int,
  out candidate jsonb,
  out leg jsonb,
  out planner_query_id uuid,
  out journey_id uuid,
  out city_id uuid,
  out origin geography,
  out destination geography
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_j record;
  v_c jsonb;
  v_l jsonb;
begin
  select j.id, j.city_id, j.origin, j.destination, j.plan_snapshot
  into v_j
  from journeys j
  where j.rider_id = p_rider_id
    and j.status in ('planning', 'active', 'transfer')
  order by j.created_at desc
  limit 1;

  if v_j.id is not null then
    for v_c in
      select value
      from jsonb_array_elements(
        case
          when v_j.plan_snapshot ? 'candidates'
            then v_j.plan_snapshot->'candidates'
          else jsonb_build_array(v_j.plan_snapshot)
        end
      )
    loop
      if (v_c->>'candidate_id')::uuid = p_candidate_id then
        select l.value
        into v_l
        from jsonb_array_elements(v_c->'legs') l(value)
        where (l.value->>'leg_index')::int = p_leg_index
        limit 1;

        if v_l is not null then
          candidate := v_c;
          leg := v_l;
          journey_id := v_j.id;
          city_id := v_j.city_id;
          origin := v_j.origin;
          destination := v_j.destination;
          return;
        end if;
      end if;
    end loop;
  end if;

  select pq.id, pq.city_id, pq.origin, pq.destination, c.value
  into planner_query_id, city_id, origin, destination, v_c
  from planner_queries pq
  cross join lateral jsonb_array_elements(pq.candidates) c(value)
  where pq.rider_id = p_rider_id
    and (c.value->>'candidate_id')::uuid = p_candidate_id
    and pq.created_at > now() - interval '15 minutes'
  order by pq.created_at desc
  limit 1;

  if planner_query_id is null then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  select l.value
  into v_l
  from jsonb_array_elements(v_c->'legs') l(value)
  where (l.value->>'leg_index')::int = p_leg_index
  limit 1;

  if v_l is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  candidate := v_c;
  leg := v_l;
end;
$$;

create or replace function _resolve_trip_driver(
  p_source text,
  p_leg jsonb,
  p_candidate jsonb,
  p_city_id uuid
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
  v_route uuid := (p_leg->>'route_id')::uuid;
  v_mode text := coalesce(p_leg->'mode'->>'code', p_leg->>'mode_code');
begin
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

create or replace function _validate_load_flag(
  p_load jsonb,
  p_mode_code text,
  p_city_id uuid
)
returns void
language plpgsql
stable
as $$
declare
  v_flagged boolean := coalesce((p_load->>'flagged')::boolean, false);
  v_size text := p_load->>'size';
  v_capacity text;
  v_warn jsonb;
  v_ack boolean := coalesce((p_load->>'acknowledged_warning')::boolean, false);
begin
  if not v_flagged or v_size is null then
    return;
  end if;

  select m.load_capacity into v_capacity
  from mode_config m
  where m.code = p_mode_code;

  v_warn := cfg('load.warn_capacities', p_city_id);

  if v_warn ? v_size
     and v_capacity = any (
       select jsonb_array_elements_text(v_warn->v_size)
     )
     and not v_ack then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- TripView builder — doc 03 §5
-- ---------------------------------------------------------------------------
create or replace function build_trip_view(p_trip_id uuid, p_viewer_id uuid default auth.uid())
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_t record;
  v_is_rider boolean;
  v_is_driver boolean;
  v_show_vehicle boolean;
  v_rider_name text;
  v_driver_name text;
  v_plate text;
  v_vehicle_color text;
  v_make_model text;
  v_seat_capacity int;
  v_board jsonb;
  v_alight jsonb;
begin
  select
    t.*,
    j.city_id
  into v_t
  from trips t
  join journeys j on j.id = t.journey_id
  where t.id = p_trip_id;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_is_rider := p_viewer_id = v_t.rider_id;
  v_is_driver := p_viewer_id = v_t.driver_id;

  if not v_is_rider and not v_is_driver then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_show_vehicle := v_is_driver or v_t.status in ('accepted', 'boarded', 'in_transit', 'completed');

  select coalesce(p.display_name, 'Rider') into v_rider_name
  from profiles p where p.id = v_t.rider_id;

  select coalesce(p.display_name, 'Driver') into v_driver_name
  from profiles p where p.id = v_t.driver_id;

  select v.plate_number, coalesce(v.color, ''), coalesce(v.make_model, ''), v.seat_capacity
  into v_plate, v_vehicle_color, v_make_model, v_seat_capacity
  from vehicles v
  where v.id = v_t.vehicle_id;

  if v_t.boarding_stage_id is not null then
    select jsonb_build_object(
      'stage_id', rs.id,
      'name', rs.name,
      'location', jsonb_build_object(
        'lat', st_y(rs.location::geometry),
        'lng', st_x(rs.location::geometry)
      ),
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', true
    )
    into v_board
    from route_stages rs
    where rs.id = v_t.boarding_stage_id;
  elsif v_t.boarding_location is not null then
    v_board := jsonb_build_object(
      'stage_id', null,
      'name', 'Pickup',
      'location', jsonb_build_object(
        'lat', st_y(v_t.boarding_location::geometry),
        'lng', st_x(v_t.boarding_location::geometry)
      ),
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', false
    );
  else
    v_board := jsonb_build_object(
      'stage_id', null,
      'name', '',
      'location', jsonb_build_object('lat', 0, 'lng', 0),
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', false
    );
  end if;

  if v_t.alighting_stage_id is not null then
    select jsonb_build_object(
      'stage_id', rs.id,
      'name', rs.name,
      'location', jsonb_build_object(
        'lat', st_y(rs.location::geometry),
        'lng', st_x(rs.location::geometry)
      )
    )
    into v_alight
    from route_stages rs
    where rs.id = v_t.alighting_stage_id;
  elsif v_t.alighting_location is not null then
    v_alight := jsonb_build_object(
      'stage_id', null,
      'name', 'Drop-off',
      'location', jsonb_build_object(
        'lat', st_y(v_t.alighting_location::geometry),
        'lng', st_x(v_t.alighting_location::geometry)
      )
    );
  else
    v_alight := jsonb_build_object(
      'stage_id', null,
      'name', '',
      'location', jsonb_build_object('lat', 0, 'lng', 0)
    );
  end if;

  return jsonb_build_object(
    'trip_id', v_t.id,
    'journey_id', v_t.journey_id,
    'journey_sequence', v_t.journey_sequence,
    'status', v_t.status,
    'mode', _mode_ref(v_t.mode_code),
    'rider', jsonb_build_object(
      'display_name', v_rider_name,
      'rating', 0,
      'trip_count', coalesce((select r.trip_count from riders r where r.id = v_t.rider_id), 0)
    ),
    'driver', jsonb_build_object(
      'display_name', case when v_is_rider then v_driver_name else v_driver_name end,
      'rating', coalesce((select d.rating from drivers d where d.id = v_t.driver_id), 0),
      'trips_completed', coalesce((
        select count(*)::int from trips tx
        where tx.driver_id = v_t.driver_id and tx.status = 'completed'
      ), 0),
      'photo_url', null
    ),
    'vehicle', case
      when v_show_vehicle and v_plate is not null then jsonb_build_object(
        'plate_number', v_plate,
        'color', v_vehicle_color,
        'make_model', v_make_model,
        'seat_capacity', v_seat_capacity
      )
      else jsonb_build_object(
        'plate_number', '',
        'color', '',
        'make_model', '',
        'seat_capacity', 0
      )
    end,
    'board', v_board,
    'alight', v_alight,
    'route_leg_ids', to_jsonb(coalesce(v_t.route_leg_ids, '{}'::uuid[])),
    'fare', jsonb_build_object(
      'amount', v_t.fare_shown,
      'currency', v_t.fare_currency,
      'tier', v_t.fare_tier,
      'quote_id', v_t.fare_quote_id,
      'unconfirmed', v_t.fare_tier = 3
    ),
    'load', jsonb_build_object(
      'flagged', v_t.load_flagged,
      'size', v_t.load_size,
      'note', v_t.load_note
    ),
    'women_only', v_t.women_only,
    'na_me', jsonb_build_object(
      'color_token', v_t.id_signal_color,
      'shape', v_t.id_signal_shape,
      'label', _na_me_label(v_t.id_signal_color, v_t.id_signal_shape)
    ),
    'live_channel', 'trip:' || v_t.id::text,
    'expires_at', v_t.expires_at,
    'timestamps', jsonb_strip_nulls(jsonb_build_object(
      'requested_at', v_t.requested_at,
      'accepted_at', v_t.accepted_at,
      'boarded_at', v_t.boarded_at,
      'started_at', v_t.started_at,
      'ended_at', v_t.ended_at,
      'cancelled_at', v_t.cancelled_at
    )),
    'extension', null,
    'payment_method', v_t.payment_method
  );
end;
$$;

create or replace function trip_snapshot(p_trip_id uuid)
returns jsonb
language sql
volatile
security definer
set search_path = public
as $$
  select build_trip_view(p_trip_id)
$$;

-- ---------------------------------------------------------------------------
-- Trip state machine — doc 04 §10 (Phase 1 subset)
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
set search_path = public
as $$
declare
  v_t trips%rowtype;
  v_allowed boolean := false;
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
    else false
  end;

  if not v_allowed then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  perform set_config('along.in_transition', 'on', true);

  update trips
  set
    status = p_to_status,
    accepted_at = case when p_to_status = 'accepted' then now() else accepted_at end,
    cancelled_at = case when p_to_status::text like 'cancelled_%' or p_to_status in ('declined', 'expired')
      then now() else cancelled_at end,
    ended_at = case when p_to_status in ('declined', 'expired', 'cancelled_by_rider', 'cancelled_by_driver')
      then now() else ended_at end,
    cancel_reason = case
      when p_to_status = 'cancelled_by_rider' or p_to_status = 'cancelled_by_driver' then p_reason
      else cancel_reason
    end,
    decline_reason = case when p_to_status = 'declined' then p_reason else decline_reason end
  where id = p_trip_id;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, reason, meta)
  values (p_trip_id, v_t.status, p_to_status, p_actor_type, p_actor_id, p_reason, p_meta);

  if p_to_status = 'accepted' and v_t.journey_sequence = 1 then
    update journeys
    set status = 'active', updated_at = now()
    where id = v_t.journey_id
      and status = 'planning';
  end if;

  perform set_config('along.in_transition', '', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- request_trip — parked/profile sources only (roaming deferred Phase 2)
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
set search_path = public
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

  return build_trip_view(v_trip_id, v_rider_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- respond_to_trip / cancel_trip
-- ---------------------------------------------------------------------------
create or replace function respond_to_trip(
  p_trip_id uuid,
  p_action text,
  p_decline_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_reasons jsonb;
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

  if v_t.status <> 'requested' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_action = 'accept' then
    perform trip_transition(p_trip_id, 'accepted', 'driver', v_driver_id);
  elsif p_action = 'decline' then
    if p_decline_reason is not null then
      v_reasons := cfg('decline.reasons');
      if p_decline_reason <> 'no_room_for_load'
         and not v_reasons ?| array[p_decline_reason] then
        raise exception 'VALIDATION' using errcode = 'P0001';
      end if;
    end if;
    perform trip_transition(p_trip_id, 'declined', 'driver', v_driver_id, p_decline_reason);
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  return build_trip_view(p_trip_id, v_driver_id);
end;
$$;

create or replace function cancel_trip(
  p_trip_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_to trip_status;
  v_actor actor_type;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_uid = v_t.rider_id then
    v_actor := 'rider';
    if v_t.status = 'requested' then
      v_to := 'cancelled_by_rider';
    elsif v_t.status = 'accepted' then
      v_to := 'cancelled_by_rider';
    else
      raise exception 'STATE_INVALID' using errcode = 'P0001';
    end if;
  elsif v_uid = v_t.driver_id then
    v_actor := 'driver';
    if v_t.status = 'accepted' then
      v_to := 'cancelled_by_driver';
    else
      raise exception 'STATE_INVALID' using errcode = 'P0001';
    end if;
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  perform trip_transition(p_trip_id, v_to, v_actor, v_uid, p_reason);
  return build_trip_view(p_trip_id, v_uid);
end;
$$;

-- ---------------------------------------------------------------------------
-- expire_requests — doc 03 §12
-- ---------------------------------------------------------------------------
create or replace function expire_requests()
returns int
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_trip uuid;
  v_count int := 0;
begin
  for v_trip in
    select id from trips
    where status = 'requested'
      and expires_at <= now()
    for update skip locked
  loop
    perform trip_transition(v_trip, 'expired', 'system');
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'expire_requests' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'expire_requests',
    '* * * * *',
    $cron$select expire_requests()$cron$
  );
exception
  when undefined_table or undefined_object then
    raise notice 'pg_cron unavailable — schedule expire_requests manually (doc 03 §12)';
end;
$$;

revoke execute on function expire_requests() from authenticated;
grant execute on function expire_requests() to service_role;

grant execute on function generate_na_me_pairing(uuid, uuid, uuid) to authenticated;
grant execute on function build_trip_view(uuid, uuid) to authenticated;
grant execute on function trip_snapshot(uuid) to authenticated;
grant execute on function trip_transition(uuid, trip_status, actor_type, uuid, text, jsonb) to authenticated;
grant execute on function request_trip(uuid, int, boolean, uuid, jsonb) to authenticated;
grant execute on function respond_to_trip(uuid, text, text) to authenticated;
grant execute on function cancel_trip(uuid, text) to authenticated;
