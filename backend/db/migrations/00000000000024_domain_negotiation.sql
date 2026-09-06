-- P2-A-02: doc 04 §8 negotiation state machine, doc 03 §4 RPCs + Broadcast negotiation:*,
-- Edge negotiation-clock (timeouts, roaming radius lapse), fare_corrections on accept.

-- ---------------------------------------------------------------------------
-- Realtime negotiation topic authz (doc 03 §4)
-- ---------------------------------------------------------------------------
create or replace function realtime_negotiation_party(p_topic text, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from price_negotiations n
    where p_topic = 'negotiation:' || n.id::text
      and (n.rider_id = p_user_id or n.driver_id = p_user_id)
  )
$$;

revoke all on function realtime_negotiation_party(text, uuid) from public;
grant execute on function realtime_negotiation_party(text, uuid) to authenticated, service_role;

drop policy if exists realtime_negotiation_broadcast_select on realtime.messages;
create policy realtime_negotiation_broadcast_select
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'negotiation:%'
    and realtime_negotiation_party((select realtime.topic()), (select auth.uid()))
  );

drop policy if exists realtime_negotiation_broadcast_insert on realtime.messages;
create policy realtime_negotiation_broadcast_insert
  on realtime.messages for insert to authenticated
  with check (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'negotiation:%'
    and realtime_negotiation_party((select realtime.topic()), (select auth.uid()))
  );

-- ---------------------------------------------------------------------------
-- Negotiation helpers
-- ---------------------------------------------------------------------------
create or replace function _negotiation_parse_endpoint(p_value jsonb)
returns table (stage_id uuid, point geography)
language plpgsql
immutable
set search_path = public, extensions
as $$
begin
  if p_value is null then
    return;
  end if;

  if p_value ? 'stage_id' then
    stage_id := (p_value->>'stage_id')::uuid;
  end if;

  if p_value ? 'lat' and p_value ? 'lng' then
    point := st_setsrid(
      st_makepoint((p_value->>'lng')::double precision, (p_value->>'lat')::double precision),
      4326
    )::geography;
  end if;

  if stage_id is not null or point is not null then
    return next;
    return;
  end if;

  raise exception 'VALIDATION' using errcode = 'P0001';
end;
$$;

create or replace function _negotiation_chip_steps(p_city_id uuid)
returns numeric[]
language sql
stable
set search_path = public
as $$
  select coalesce(
    (
      select array_agg(value::numeric order by ord)
      from jsonb_array_elements_text(cfg('negotiation.chip_steps', p_city_id)) with ordinality t(value, ord)
    ),
    array[]::numeric[]
  )
$$;

create or replace function _negotiation_actor_role(p_negotiation_id uuid, p_user_id uuid)
returns actor_type
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_n record;
begin
  select rider_id, driver_id into v_n
  from price_negotiations
  where id = p_negotiation_id;

  if v_n.rider_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if p_user_id = v_n.rider_id then
    return 'rider'::actor_type;
  elsif p_user_id = v_n.driver_id then
    return 'driver'::actor_type;
  end if;

  raise exception 'FORBIDDEN' using errcode = 'P0001';
end;
$$;

create or replace function _negotiation_last_round(p_negotiation_id uuid)
returns price_negotiation_rounds
language sql
stable
security definer
set search_path = public
as $$
  select r.*
  from price_negotiation_rounds r
  where r.negotiation_id = p_negotiation_id
  order by r.round_number desc
  limit 1
$$;

create or replace function _negotiation_round_count(p_negotiation_id uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int
  from price_negotiation_rounds
  where negotiation_id = p_negotiation_id
$$;

create or replace function _negotiation_pricing_source()
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  select id into v_id
  from data_sources
  where source_type = 'pricing_negotiation'
  order by created_at
  limit 1;

  if v_id is null then
    insert into data_sources (source_type, notes)
    values ('pricing_negotiation', 'Along Pricing agreed fares')
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

create or replace function private.broadcast_negotiation(p_negotiation_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_n price_negotiations%rowtype;
  v_last price_negotiation_rounds%rowtype;
begin
  select * into v_n from price_negotiations where id = p_negotiation_id;
  if v_n.id is null then
    return;
  end if;

  select * into v_last from _negotiation_last_round(p_negotiation_id);

  perform realtime.send(
    jsonb_build_object(
      'round', coalesce(v_last.round_number, 0),
      'amount', coalesce(v_last.amount, v_n.anchor_amount),
      'proposed_by', coalesce(v_last.proposed_by::text, 'rider'),
      'expires_at', v_n.expires_at,
      'status', v_n.status
    ),
    'negotiation_update',
    'negotiation:' || p_negotiation_id::text,
    true
  );
end;
$$;

revoke all on function private.broadcast_negotiation(uuid) from public;
grant execute on function private.broadcast_negotiation(uuid) to service_role;

create or replace function _negotiation_post_fare_correction(
  p_negotiation price_negotiations,
  p_trip_id uuid,
  p_agreed_amount numeric
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_ref jsonb := p_negotiation.candidate_ref;
  v_source uuid := _negotiation_pricing_source();
begin
  insert into fare_corrections (
    route_id,
    from_stage_id,
    to_stage_id,
    trip_id,
    submitted_by,
    submitter_role,
    proposed_fare,
    currency,
    fare_shown,
    source_id
  ) values (
    (v_ref->>'route_id')::uuid,
    (v_ref->>'from_stage_id')::uuid,
    (v_ref->>'to_stage_id')::uuid,
    p_trip_id,
    p_negotiation.rider_id,
    'system',
    p_agreed_amount,
    p_negotiation.currency,
    p_negotiation.anchor_amount,
    v_source
  );
end;
$$;

create or replace function _negotiation_create_trip(
  p_negotiation price_negotiations,
  p_agreed_amount numeric,
  p_quote_id uuid,
  p_acceptor actor_type
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_ref jsonb := p_negotiation.candidate_ref;
  v_city_id uuid := (v_ref->>'city_id')::uuid;
  v_mode text := v_ref->>'mode_code';
  v_journey_id uuid;
  v_trip_id uuid;
  v_na record;
  v_commission_rate numeric;
  v_status trip_status;
  v_from geography;
  v_to geography;
begin
  select * into v_na
  from generate_na_me_pairing(p_negotiation.driver_id, p_negotiation.rider_id, v_city_id);

  v_commission_rate := cfg_num('commission.rate', v_city_id);

  if v_ref ? 'from_location' then
    v_from := st_setsrid(
      st_makepoint(
        (v_ref->'from_location'->>'lng')::double precision,
        (v_ref->'from_location'->>'lat')::double precision
      ),
      4326
    )::geography;
  end if;

  if v_ref ? 'to_location' then
    v_to := st_setsrid(
      st_makepoint(
        (v_ref->'to_location'->>'lng')::double precision,
        (v_ref->'to_location'->>'lat')::double precision
      ),
      4326
    )::geography;
  end if;

  insert into journeys (
    rider_id, city_id, status, origin, destination, plan_snapshot,
    load_flagged, women_only
  ) values (
    p_negotiation.rider_id,
    v_city_id,
    'planning',
    coalesce(v_from, st_setsrid(st_makepoint(0, 0), 4326)::geography),
    coalesce(v_to, st_setsrid(st_makepoint(0, 0), 4326)::geography),
    jsonb_build_object('negotiation_id', p_negotiation.id),
    false,
    false
  )
  returning id into v_journey_id;

  v_status := case
    when p_acceptor = 'driver' then 'accepted'::trip_status
    else 'requested'::trip_status
  end;

  insert into trips (
    journey_id,
    journey_sequence,
    rider_id,
    driver_id,
    vehicle_id,
    mode_code,
    route_id,
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
    women_only
  )
  select
    v_journey_id,
    1,
    p_negotiation.rider_id,
    p_negotiation.driver_id,
    coalesce(dp.vehicle_id, dv.vehicle_id),
    v_mode,
    (v_ref->>'route_id')::uuid,
    (v_ref->>'from_stage_id')::uuid,
    (v_ref->>'to_stage_id')::uuid,
    v_from,
    v_to,
    p_quote_id,
    p_agreed_amount,
    p_negotiation.currency,
    3::smallint,
    v_commission_rate,
    v_status,
    now() + make_interval(secs => cfg_num('dispatch.request_ttl_s', v_city_id)::int),
    v_na.color_token,
    v_na.shape,
    false
  from drivers d
  left join driver_presence dp on dp.driver_id = d.id
  left join lateral (
    select dv2.vehicle_id
    from driver_vehicles dv2
    where dv2.driver_id = d.id and dv2.active
    limit 1
  ) dv on true
  where d.id = p_negotiation.driver_id
  returning id into v_trip_id;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, meta)
  values (
    v_trip_id,
    null,
    v_status,
    p_acceptor,
    case when p_acceptor = 'driver' then p_negotiation.driver_id else p_negotiation.rider_id end,
    jsonb_build_object('negotiation_id', p_negotiation.id, 'agreed_amount', p_agreed_amount)
  );

  if v_status = 'requested' then
    perform private.notify_driver_trip_request(v_trip_id);
  end if;

  return v_trip_id;
end;
$$;

create or replace function _negotiation_lapse(p_negotiation_id uuid, p_reason text default 'timeout')
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_n price_negotiations%rowtype;
  v_last price_negotiation_rounds%rowtype;
begin
  select * into v_n
  from price_negotiations
  where id = p_negotiation_id
    and status = 'open'
  for update;

  if v_n.id is null then
    return;
  end if;

  update price_negotiations
  set status = 'lapsed',
      resolved_at = now()
  where id = p_negotiation_id;

  perform private.broadcast_negotiation(p_negotiation_id);
end;
$$;

create or replace function _negotiation_roaming_params(
  p_driver_id uuid,
  p_rider_location geography,
  p_city_id uuid
)
returns table (
  eta_band eta_band,
  round_cap smallint,
  round_timeout_s smallint,
  pickup_radius_m int,
  expires_at timestamptz,
  open_distance_m double precision
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_presence record;
  v_eta_s numeric;
  v_eta_none numeric;
  v_eta_single numeric;
  v_timeout int;
  v_cap int;
  v_dist double precision;
  v_pickup int;
  v_band eta_band;
begin
  select dp.current_location, coalesce(dp.speed_mps, 0) as speed_mps
  into v_presence
  from driver_presence dp
  where dp.driver_id = p_driver_id;

  if v_presence.current_location is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_dist := distance_m(v_presence.current_location, p_rider_location);
  v_eta_s := v_dist / greatest(coalesce(v_presence.speed_mps, 0), 3);
  v_eta_none := cfg_num('negotiation.roaming.eta_none_s', p_city_id);
  v_eta_single := cfg_num('negotiation.roaming.eta_single_s', p_city_id);
  v_timeout := cfg_num('negotiation.roaming.round_timeout_s', p_city_id)::int;
  v_pickup := cfg_num('negotiation.roaming.pickup_radius_m', p_city_id)::int;

  if v_eta_s <= v_eta_none then
    v_band := 'none';
    v_cap := 0;
  elsif v_eta_s <= v_eta_single then
    v_band := 'single';
    v_cap := 1;
  else
    v_band := 'full';
    v_cap := cfg_num('negotiation.roaming.round_cap', p_city_id)::int;
  end if;

  return query
  select
    v_band,
    v_cap::smallint,
    v_timeout::smallint,
    v_pickup,
    now() + make_interval(secs => greatest(v_cap + 1, 1) * v_timeout),
    v_dist;
end;
$$;

create or replace function _negotiation_build_view(p_negotiation_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_n price_negotiations%rowtype;
  v_last price_negotiation_rounds%rowtype;
  v_steps numeric[];
  v_trip jsonb;
begin
  select * into v_n from price_negotiations where id = p_negotiation_id;
  if v_n.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select * into v_last from _negotiation_last_round(p_negotiation_id);
  v_steps := _negotiation_chip_steps((v_n.candidate_ref->>'city_id')::uuid);

  if v_n.resulting_trip_id is not null then
    v_trip := build_trip_view(v_n.resulting_trip_id, auth.uid());
  end if;

  return jsonb_build_object(
    'negotiation_id', v_n.id,
    'status', v_n.status,
    'context', v_n.context,
    'anchor', jsonb_build_object('amount', v_n.anchor_amount, 'currency', v_n.currency),
    'agreed_amount', v_n.agreed_amount,
    'round_cap', v_n.round_cap,
    'round_timeout_s', v_n.round_timeout_s,
    'eta_band', v_n.eta_band,
    'expires_at', v_n.expires_at,
    'round', coalesce(v_last.round_number, 0),
    'amount', coalesce(v_last.amount, v_n.anchor_amount),
    'proposed_by', coalesce(v_last.proposed_by::text, 'rider'),
    'chip_steps', (
      select coalesce(jsonb_agg(jsonb_build_object('amount', s, 'currency', v_n.currency)), '[]'::jsonb)
      from unnest(v_steps) s
    ),
    'trip', v_trip
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- open_negotiation — doc 03 §4, doc 04 §8
-- ---------------------------------------------------------------------------
create or replace function open_negotiation(
  p_context negotiation_context,
  p_from jsonb,
  p_to jsonb,
  p_client_ref uuid,
  p_driver_id uuid default null,
  p_candidate_token text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_rider_id uuid := auth.uid();
  v_driver_id uuid := p_driver_id;
  v_from record;
  v_to record;
  v_route_id uuid;
  v_from_stage uuid;
  v_to_stage uuid;
  v_from_point geography;
  v_to_point geography;
  v_city_id uuid;
  v_mode text := 'car';
  v_fare fare_resolution;
  v_profile_id uuid;
  v_round_cap smallint;
  v_timeout smallint;
  v_eta eta_band;
  v_pickup int;
  v_expires timestamptz;
  v_open_dist double precision;
  v_rider_loc geography;
  v_neg_id uuid;
  v_steps numeric[];
  v_ref jsonb;
  v_presence record;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (select 1 from riders where id = v_rider_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_from from _negotiation_parse_endpoint(p_from);
  select * into v_to from _negotiation_parse_endpoint(p_to);

  v_from_stage := v_from.stage_id;
  v_to_stage := v_to.stage_id;
  v_from_point := v_from.point;
  v_to_point := v_to.point;

  if p_context = 'roaming' then
    if v_driver_id is null and p_candidate_token is not null then
      select dp.driver_id into v_driver_id
      from driver_presence dp
      where dp.session_id::text = p_candidate_token
         or dp.driver_id::text = p_candidate_token
      limit 1;
    end if;

    if v_driver_id is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    if v_from_point is null and v_from_stage is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select d.city_id, dp.declared_route_profile_id, dp.current_location
    into v_presence
    from drivers d
    join driver_presence dp on dp.driver_id = d.id
    where d.id = v_driver_id;

    v_city_id := v_presence.city_id;

    v_rider_loc := coalesce(
      v_from_point,
      (select rs.location from route_stages rs where rs.id = v_from_stage)
    );

    if v_to_stage is not null then
      select rs.route_id into v_route_id from route_stages rs where rs.id = v_to_stage;
    elsif v_to_point is not null then
      select snap_stage(v_to_point, null, v_city_id) into v_to_stage;
      if v_to_stage is not null then
        select rs.route_id into v_route_id from route_stages rs where rs.id = v_to_stage;
      end if;
    end if;

    if v_from_stage is null and v_from_point is not null then
      select snap_stage(v_from_point, null, v_city_id) into v_from_stage;
    end if;

    if v_presence.declared_route_profile_id is not null then
      v_profile_id := v_presence.declared_route_profile_id;
    end if;

    if v_profile_id is not null then
      v_fare := resolve_fare(
        p_profile_id := v_profile_id,
        p_from_stage_id := v_from_stage,
        p_to_stage_id := v_to_stage,
        p_from_point := case when v_from_stage is null then v_from_point else null end,
        p_to_point := case when v_to_stage is null then v_to_point else null end,
        p_mode_code := v_mode,
        p_city_id := v_city_id,
        p_rider_id := v_rider_id,
        p_driver_id := v_driver_id
      );
      if v_fare.tier <= 2 then
        raise exception 'STATE_INVALID' using errcode = 'P0001';
      end if;
    elsif v_route_id is not null and v_from_stage is not null and v_to_stage is not null then
      v_fare := resolve_fare(
        p_route_id := v_route_id,
        p_from_stage_id := v_from_stage,
        p_to_stage_id := v_to_stage,
        p_mode_code := v_mode,
        p_city_id := v_city_id,
        p_rider_id := v_rider_id,
        p_driver_id := v_driver_id
      );
      if v_fare.tier <= 2 then
        raise exception 'STATE_INVALID' using errcode = 'P0001';
      end if;
    else
      v_fare := resolve_fare(
        p_from_point := v_from_point,
        p_to_point := coalesce(v_to_point, v_from_point),
        p_mode_code := v_mode,
        p_city_id := v_city_id,
        p_rider_id := v_rider_id,
        p_driver_id := v_driver_id
      );
      if v_fare.tier <= 2 then
        raise exception 'STATE_INVALID' using errcode = 'P0001';
      end if;
    end if;

    select rp.eta_band, rp.round_cap, rp.round_timeout_s, rp.pickup_radius_m, rp.expires_at, rp.open_distance_m
    into v_eta, v_round_cap, v_timeout, v_pickup, v_expires, v_open_dist
    from _negotiation_roaming_params(v_driver_id, v_rider_loc, v_city_id) rp;

  elsif p_context in ('park', 'extension', 'load_surcharge') then
    if v_driver_id is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select d.city_id into v_city_id from drivers d where d.id = v_driver_id;

    if v_from_stage is not null then
      select rs.route_id into v_route_id from route_stages rs where rs.id = v_from_stage;
    end if;

    if v_route_id is null or v_from_stage is null or v_to_stage is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    v_fare := resolve_fare(
      p_route_id := v_route_id,
      p_from_stage_id := v_from_stage,
      p_to_stage_id := v_to_stage,
      p_mode_code := v_mode,
      p_city_id := v_city_id,
      p_rider_id := v_rider_id,
      p_driver_id := v_driver_id
    );

    if v_fare.tier <= 2 then
      raise exception 'STATE_INVALID' using errcode = 'P0001';
    end if;

    v_round_cap := cfg_num('negotiation.park.round_cap', v_city_id)::smallint;
    v_timeout := cfg_num('negotiation.park.round_timeout_s', v_city_id)::smallint;
    v_eta := null;
    v_pickup := null;
    v_expires := now() + make_interval(secs => (v_round_cap + 1) * v_timeout);
    v_open_dist := null;
    v_rider_loc := null;
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_ref := jsonb_build_object(
    'route_id', v_route_id,
    'from_stage_id', v_from_stage,
    'to_stage_id', v_to_stage,
    'mode_code', v_mode,
    'city_id', v_city_id,
    'client_ref', p_client_ref,
    'open_distance_m', v_open_dist
  );

  if v_from_point is not null then
    v_ref := v_ref || jsonb_build_object(
      'from_location', jsonb_build_object(
        'lat', st_y(v_from_point::geometry),
        'lng', st_x(v_from_point::geometry)
      ),
      'rider_location', jsonb_build_object(
        'lat', st_y(v_from_point::geometry),
        'lng', st_x(v_from_point::geometry)
      )
    );
  end if;

  if v_to_point is not null then
    v_ref := v_ref || jsonb_build_object(
      'to_location', jsonb_build_object(
        'lat', st_y(v_to_point::geometry),
        'lng', st_x(v_to_point::geometry)
      )
    );
  end if;

  insert into price_negotiations (
    rider_id, driver_id, context, candidate_ref,
    anchor_amount, currency, anchor_quote_id,
    round_cap, round_timeout_s, eta_band, pickup_radius_m, expires_at
  ) values (
    v_rider_id, v_driver_id, p_context, v_ref,
    v_fare.amount, v_fare.currency, v_fare.quote_id,
    v_round_cap, v_timeout, v_eta, v_pickup, v_expires
  )
  returning id into v_neg_id;

  insert into price_negotiation_rounds (
    negotiation_id, round_number, proposed_by, amount
  ) values (
    v_neg_id, 1, 'rider', v_fare.amount
  );

  update fare_quotes
  set negotiation_id = v_neg_id
  where id = v_fare.quote_id;

  perform private.broadcast_negotiation(v_neg_id);

  v_steps := _negotiation_chip_steps(v_city_id);

  return jsonb_build_object(
    'negotiation_id', v_neg_id,
    'anchor', jsonb_build_object('amount', v_fare.amount, 'currency', v_fare.currency),
    'chip_steps', (
      select coalesce(jsonb_agg(jsonb_build_object('amount', s, 'currency', v_fare.currency)), '[]'::jsonb)
      from unnest(v_steps) s
    ),
    'round_cap', v_round_cap,
    'round_timeout_s', v_timeout,
    'eta_band', coalesce(v_eta::text, 'null'),
    'expires_at', v_expires
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- negotiation_round — doc 03 §4, doc 04 §8.3
-- ---------------------------------------------------------------------------
create or replace function negotiation_round(
  p_negotiation_id uuid,
  p_action text,
  p_amount numeric default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_uid uuid := auth.uid();
  v_role actor_type;
  v_n price_negotiations%rowtype;
  v_last price_negotiation_rounds%rowtype;
  v_steps numeric[];
  v_city_id uuid;
  v_new_round smallint;
  v_quote_id uuid;
  v_trip_id uuid;
  v_valid_counter boolean := false;
  v_step numeric;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_n
  from price_negotiations
  where id = p_negotiation_id
  for update;

  if v_n.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_n.status <> 'open' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_n.expires_at <= now() then
    perform _negotiation_lapse(p_negotiation_id, 'timeout');
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_role := _negotiation_actor_role(p_negotiation_id, v_uid);
  select * into v_last from _negotiation_last_round(p_negotiation_id);
  v_city_id := (v_n.candidate_ref->>'city_id')::uuid;
  v_steps := _negotiation_chip_steps(v_city_id);

  if p_action = 'decline' then
    update price_negotiations
    set status = 'declined', resolved_at = now()
    where id = p_negotiation_id;

    perform private.broadcast_negotiation(p_negotiation_id);
    return _negotiation_build_view(p_negotiation_id);
  end if;

  if p_action = 'accept' then
    insert into fare_quotes (
      rider_id, driver_id, route_id, from_stage_id, to_stage_id,
      from_location, to_location, mode_code, tier, amount, currency,
      components, confidence, negotiation_id
    )
    select
      v_n.rider_id, v_n.driver_id,
      (v_n.candidate_ref->>'route_id')::uuid,
      (v_n.candidate_ref->>'from_stage_id')::uuid,
      (v_n.candidate_ref->>'to_stage_id')::uuid,
      case when v_n.candidate_ref ? 'from_location'
        then st_setsrid(st_makepoint(
          (v_n.candidate_ref->'from_location'->>'lng')::double precision,
          (v_n.candidate_ref->'from_location'->>'lat')::double precision
        ), 4326)::geography else null end,
      case when v_n.candidate_ref ? 'to_location'
        then st_setsrid(st_makepoint(
          (v_n.candidate_ref->'to_location'->>'lng')::double precision,
          (v_n.candidate_ref->'to_location'->>'lat')::double precision
        ), 4326)::geography else null end,
      v_n.candidate_ref->>'mode_code',
      3, v_last.amount, v_n.currency,
      jsonb_build_array(jsonb_build_object('kind', 'negotiated', 'amount', v_last.amount)),
      0.3, p_negotiation_id
    returning id into v_quote_id;

    v_trip_id := _negotiation_create_trip(v_n, v_last.amount, v_quote_id, v_role);

    perform _negotiation_post_fare_correction(v_n, v_trip_id, v_last.amount);

    update price_negotiations
    set status = 'agreed',
        agreed_amount = v_last.amount,
        resulting_trip_id = v_trip_id,
        resolved_at = now()
    where id = p_negotiation_id;

    perform private.broadcast_negotiation(p_negotiation_id);
    return _negotiation_build_view(p_negotiation_id);
  end if;

  if p_action <> 'counter' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if v_n.round_cap = 0 then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if _negotiation_round_count(p_negotiation_id) >= v_n.round_cap then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_last.proposed_by = v_role then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_amount is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  foreach v_step in array v_steps loop
    if p_amount = v_last.amount + v_step or p_amount = v_last.amount - v_step then
      v_valid_counter := true;
      exit;
    end if;
  end loop;

  if not v_valid_counter then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_new_round := v_last.round_number + 1;

  insert into price_negotiation_rounds (
    negotiation_id, round_number, proposed_by, amount
  ) values (
    p_negotiation_id, v_new_round, v_role, p_amount
  );

  update price_negotiations
  set expires_at = now() + make_interval(secs => v_n.round_timeout_s)
  where id = p_negotiation_id;

  perform private.broadcast_negotiation(p_negotiation_id);
  return _negotiation_build_view(p_negotiation_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- negotiation_split — doc 03 §4, doc 04 §8.3
-- ---------------------------------------------------------------------------
create or replace function negotiation_split(p_negotiation_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_uid uuid := auth.uid();
  v_n price_negotiations%rowtype;
  v_last price_negotiation_rounds%rowtype;
  v_rider_amt numeric;
  v_driver_amt numeric;
  v_mid numeric;
  v_city_id uuid;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  perform _negotiation_actor_role(p_negotiation_id, v_uid);

  select * into v_n
  from price_negotiations
  where id = p_negotiation_id
  for update;

  if v_n.status <> 'open' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if _negotiation_round_count(p_negotiation_id) <> v_n.round_cap then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_last from _negotiation_last_round(p_negotiation_id);

  select amount into v_rider_amt
  from price_negotiation_rounds
  where negotiation_id = p_negotiation_id and proposed_by = 'rider'
  order by round_number desc
  limit 1;

  select amount into v_driver_amt
  from price_negotiation_rounds
  where negotiation_id = p_negotiation_id and proposed_by = 'driver'
  order by round_number desc
  limit 1;

  v_city_id := (v_n.candidate_ref->>'city_id')::uuid;
  v_mid := round_to_minor((coalesce(v_rider_amt, v_n.anchor_amount) + coalesce(v_driver_amt, v_last.amount)) / 2.0, v_city_id);

  insert into price_negotiation_rounds (
    negotiation_id, round_number, proposed_by, amount
  ) values (
    p_negotiation_id, v_last.round_number + 1, 'system', v_mid
  );

  update price_negotiations
  set expires_at = now() + make_interval(secs => v_n.round_timeout_s)
  where id = p_negotiation_id;

  perform private.broadcast_negotiation(p_negotiation_id);
  return _negotiation_build_view(p_negotiation_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- negotiation_clock_tick — timeouts + roaming radius lapse (doc 03 §12, doc 04 §8.3)
-- ---------------------------------------------------------------------------
create or replace function negotiation_clock_tick()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_neg record;
  v_pres record;
  v_lapsed int := 0;
  v_rider_loc geography;
  v_cur_dist double precision;
  v_open_dist double precision;
  v_heading_ok boolean;
  v_city_id uuid;
begin
  for v_neg in
    select id from price_negotiations
    where status = 'open' and expires_at <= now()
    for update skip locked
  loop
    perform _negotiation_lapse(v_neg.id, 'timeout');
    v_lapsed := v_lapsed + 1;
  end loop;

  for v_neg in
    select n.*
    from price_negotiations n
    where n.status = 'open'
      and n.context = 'roaming'
      and n.pickup_radius_m is not null
    for update skip locked
  loop
    select dp.current_location, coalesce(dp.speed_mps, 0) as speed_mps, dp.heading
    into v_pres
    from driver_presence dp
    where dp.driver_id = v_neg.driver_id;

    if v_pres.current_location is null then
      continue;
    end if;

    if v_neg.candidate_ref ? 'rider_location' then
      v_rider_loc := st_setsrid(
        st_makepoint(
          (v_neg.candidate_ref->'rider_location'->>'lng')::double precision,
          (v_neg.candidate_ref->'rider_location'->>'lat')::double precision
        ),
        4326
      )::geography;
    else
      continue;
    end if;

    v_city_id := (v_neg.candidate_ref->>'city_id')::uuid;
    v_cur_dist := distance_m(v_pres.current_location, v_rider_loc);
    v_open_dist := coalesce((v_neg.candidate_ref->>'open_distance_m')::double precision, v_cur_dist);

    v_heading_ok := coalesce(v_pres.speed_mps, 0) >= cfg_num('boarding.min_speed_mps', v_city_id)
      and angle_diff(
        coalesce(v_pres.heading, 0)::double precision,
        bearing_deg(v_pres.current_location, v_rider_loc)
      ) > 90;

    if v_cur_dist > v_neg.pickup_radius_m
       and (v_cur_dist > v_open_dist + 5 or v_heading_ok) then
      perform _negotiation_lapse(v_neg.id, 'vehicle_out_of_range');
      v_lapsed := v_lapsed + 1;
    end if;
  end loop;

  return jsonb_build_object('lapsed', v_lapsed);
end;
$$;

revoke all on function negotiation_clock_tick() from public;
grant execute on function negotiation_clock_tick() to service_role;

revoke all on function open_negotiation(negotiation_context, jsonb, jsonb, uuid, uuid, text) from public;
grant execute on function open_negotiation(negotiation_context, jsonb, jsonb, uuid, uuid, text) to authenticated;

revoke all on function negotiation_round(uuid, text, numeric) from public;
grant execute on function negotiation_round(uuid, text, numeric) to authenticated;

revoke all on function negotiation_split(uuid) from public;
grant execute on function negotiation_split(uuid) to authenticated;
