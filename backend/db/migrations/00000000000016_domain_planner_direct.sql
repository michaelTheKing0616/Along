-- P1-A-06: doc 04 §4.2 direct candidates (parked/profile/graph), §19 coverage gap.
-- Roaming deferred to P2-A-01 plan-trip v2; multi-leg merge deferred to P2-A-01.

-- Leg ids on a route between two stages (inclusive board, inclusive alight hop chain).
create or replace function _route_leg_ids_between(
  p_route_id uuid,
  p_from_stage_id uuid,
  p_to_stage_id uuid
)
returns uuid[]
language sql
stable
as $$
  with bounds as (
    select
      (select sequence from route_stages where id = p_from_stage_id and route_id = p_route_id) as from_seq,
      (select sequence from route_stages where id = p_to_stage_id and route_id = p_route_id) as to_seq
  )
  select coalesce(
    array_agg(rl.id order by rs_from.sequence),
    '{}'::uuid[]
  )
  from route_legs rl
  join route_stages rs_from on rs_from.id = rl.from_stage_id
  join route_stages rs_to on rs_to.id = rl.to_stage_id
  cross join bounds b
  where rl.route_id = p_route_id
    and b.from_seq is not null
    and b.to_seq is not null
    and b.from_seq < b.to_seq
    and rs_from.sequence >= b.from_seq
    and rs_to.sequence <= b.to_seq
$$;

create or replace function _planner_stage_point(p_stage_id uuid)
returns geography
language sql
stable
set search_path = public, extensions
as $$
  select rs.location from route_stages rs where rs.id = p_stage_id
$$;

create or replace function _planner_in_vehicle_s(
  p_route_id uuid,
  p_from_stage_id uuid,
  p_to_stage_id uuid
)
returns int
language sql
stable
as $$
  with bounds as (
    select
      (select sequence from route_stages where id = p_from_stage_id and route_id = p_route_id) as from_seq,
      (select sequence from route_stages where id = p_to_stage_id and route_id = p_route_id) as to_seq
  )
  select coalesce(
    sum(coalesce(rl.in_vehicle_time_estimate_s, 0))::int,
    0
  )
  from route_legs rl
  join route_stages rs_from on rs_from.id = rl.from_stage_id
  join route_stages rs_to on rs_to.id = rl.to_stage_id
  cross join bounds b
  where rl.route_id = p_route_id
    and b.from_seq is not null
    and b.to_seq is not null
    and b.from_seq < b.to_seq
    and rs_from.sequence >= b.from_seq
    and rs_to.sequence <= b.to_seq
$$;

create or replace function _planner_wait_s(
  p_route_id uuid,
  p_from_stage_id uuid,
  p_to_stage_id uuid,
  p_city_id uuid
)
returns int
language sql
stable
as $$
  with bounds as (
    select
      (select sequence from route_stages where id = p_from_stage_id and route_id = p_route_id) as from_seq,
      (select sequence from route_stages where id = p_to_stage_id and route_id = p_route_id) as to_seq
  ),
  legs as (
    select coalesce(rl.avg_wait_time_estimate_s, cfg_num('planner.default_wait_s', p_city_id)) as wait_s
    from route_legs rl
    join route_stages rs_from on rs_from.id = rl.from_stage_id
    join route_stages rs_to on rs_to.id = rl.to_stage_id
    cross join bounds b
    where rl.route_id = p_route_id
      and b.from_seq is not null
      and b.to_seq is not null
      and b.from_seq < b.to_seq
      and rs_from.sequence >= b.from_seq
      and rs_to.sequence <= b.to_seq
  )
  select coalesce(sum(wait_s), cfg_num('planner.default_wait_s', p_city_id))::int from legs
$$;

create or replace function _parked_supply_bucket(p_count int)
returns text
language sql
immutable
as $$
  select ambient_count_bucket(greatest(p_count, 1))
$$;

create or replace function city_for_lat_lng(p_lat double precision, p_lng double precision)
returns uuid
language sql
stable
set search_path = public, extensions
as $$
  select city_for_point(st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography)
$$;

grant execute on function city_for_lat_lng(double precision, double precision)
  to authenticated, anon, service_role;

create or replace function stage_points(p_stage_ids uuid[])
returns table(id uuid, name text, lat double precision, lng double precision)
language sql
stable
set search_path = public, extensions
as $$
  select
    rs.id,
    rs.name,
    st_y(rs.location::geometry) as lat,
    st_x(rs.location::geometry) as lng
  from route_stages rs
  where rs.id = any (p_stage_ids)
$$;

grant execute on function stage_points(uuid[]) to authenticated, anon, service_role;

-- Direct candidates: parked, driver_profile, graph (v1 — no roaming).
create or replace function planner_direct_candidates(
  p_origin geography,
  p_destination geography,
  p_city_id uuid,
  p_filters jsonb default '{}'::jsonb
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_walk_radius numeric;
  v_dest_radius numeric;
  v_women_only boolean;
  v_modes text[];
  v_modes_filter boolean;
begin
  v_walk_radius := cfg_num('planner.walk_radius_m', p_city_id);
  v_dest_radius := cfg_num('planner.dest_radius_m', p_city_id);
  v_women_only := coalesce((p_filters->>'women_only')::boolean, false);

  if p_filters ? 'modes'
     and p_filters->'modes' is not null
     and jsonb_typeof(p_filters->'modes') = 'array'
     and jsonb_array_length(p_filters->'modes') > 0 then
    v_modes_filter := true;
    select coalesce(array_agg(value), '{}'::text[])
    into v_modes
    from jsonb_array_elements_text(p_filters->'modes') as t(value);
  else
    v_modes_filter := false;
    v_modes := '{}'::text[];
  end if;

  return query
  with
  origin_stages as (
    select
      rs.id as stage_id,
      rs.route_id,
      rs.sequence,
      rs.name,
      rs.location,
      r.mode_code
    from route_stages rs
    join routes r on r.id = rs.route_id
    where r.city_id = p_city_id
      and r.active
      and st_dwithin(rs.location, p_origin, v_walk_radius)
  ),
  dest_stages as (
    select rs.id as stage_id, rs.route_id, rs.sequence
    from route_stages rs
    join routes r on r.id = rs.route_id
    where r.city_id = p_city_id
      and r.active
      and st_dwithin(rs.location, p_destination, v_dest_radius)
  ),
  parked as (
    select distinct on (os.stage_id, r.id, alight.stage_id)
      'parked'::text as source,
      r.id as route_id,
      null::uuid as profile_id,
      os.stage_id as board_stage_id,
      alight.stage_id as alight_stage_id,
      r.mode_code,
      (
        select count(*)::int
        from driver_presence dp
        join drivers d on d.id = dp.driver_id
        where dp.status = 'at_park'
          and dp.nearest_stage_id = os.stage_id
          and d.city_id = p_city_id
          and driver_is_matchable(dp.driver_id)
          and (not v_women_only or d.women_only_eligible)
      ) as parked_count,
      false as profile_present,
      3 as source_rank
    from origin_stages os
    join routes r on r.id = os.route_id
    cross join lateral (
      select ds.stage_id, ds.sequence
      from dest_stages ds
      where ds.route_id = r.id
        and ds.sequence > os.sequence
      order by ds.sequence
      limit 1
    ) alight
    where exists (
      select 1
      from driver_presence dp
      join drivers d on d.id = dp.driver_id
      where dp.status = 'at_park'
        and dp.nearest_stage_id = os.stage_id
        and d.city_id = p_city_id
        and driver_is_matchable(dp.driver_id)
        and (not v_women_only or d.women_only_eligible)
    )
      and (not v_modes_filter or r.mode_code = any (v_modes))
    order by os.stage_id, r.id, alight.stage_id, alight.sequence
  ),
  profile_candidates as (
    select distinct on (drp.id, b.id, a.id)
      'driver_profile'::text as source,
      drp.route_id,
      drp.id as profile_id,
      coalesce(b.route_stage_id, snap_stage(b.location, v_walk_radius, p_city_id)) as board_stage_id,
      coalesce(a.route_stage_id, snap_stage(a.location, v_dest_radius, p_city_id)) as alight_stage_id,
      drp.mode_code,
      0 as parked_count,
      exists (
        select 1
        from driver_presence dp
        where dp.driver_id = drp.driver_id
          and dp.status <> 'offline'
          and presence_is_fresh(dp.last_ping_at, p_city_id)
      ) as profile_present,
      case
        when exists (
          select 1
          from driver_presence dp
          where dp.driver_id = drp.driver_id
            and dp.status <> 'offline'
            and presence_is_fresh(dp.last_ping_at, p_city_id)
        ) then 2
        else 4
      end as source_rank
    from driver_route_profiles drp
    join drivers d on d.id = drp.driver_id
    join driver_route_stop_location b on b.profile_id = drp.id
    join driver_route_stop_location a
      on a.profile_id = drp.id
     and a.sequence > b.sequence
    where drp.active
      and d.city_id = p_city_id
      and driver_is_matchable(drp.driver_id)
      and (not v_women_only or d.women_only_eligible)
      and (not v_modes_filter or drp.mode_code = any (v_modes))
      and st_dwithin(b.location, p_origin, v_walk_radius)
      and st_dwithin(a.location, p_destination, v_dest_radius)
      and coalesce(b.route_stage_id, snap_stage(b.location, v_walk_radius, p_city_id)) is not null
      and coalesce(a.route_stage_id, snap_stage(a.location, v_dest_radius, p_city_id)) is not null
    order by drp.id, b.id, a.id, a.sequence
  ),
  graph_only as (
    select distinct on (os.stage_id, r.id, alight.stage_id)
      'graph'::text as source,
      r.id as route_id,
      null::uuid as profile_id,
      os.stage_id as board_stage_id,
      alight.stage_id as alight_stage_id,
      r.mode_code,
      0 as parked_count,
      false as profile_present,
      5 as source_rank
    from origin_stages os
    join routes r on r.id = os.route_id
    cross join lateral (
      select ds.stage_id, ds.sequence
      from dest_stages ds
      where ds.route_id = r.id
        and ds.sequence > os.sequence
      order by ds.sequence
      limit 1
    ) alight
    where (not v_modes_filter or r.mode_code = any (v_modes))
    order by os.stage_id, r.id, alight.stage_id, alight.sequence
  ),
  unioned as (
    select * from parked
    union all
    select * from profile_candidates
    union all
    select * from graph_only
  ),
  deduped as (
    select distinct on (
      coalesce(route_id::text, profile_id::text),
      board_stage_id,
      alight_stage_id
    )
      source,
      route_id,
      profile_id,
      board_stage_id,
      alight_stage_id,
      mode_code,
      parked_count,
      profile_present,
      source_rank
    from unioned
    where board_stage_id is not null
      and alight_stage_id is not null
      and board_stage_id <> alight_stage_id
    order by
      coalesce(route_id::text, profile_id::text),
      board_stage_id,
      alight_stage_id,
      source_rank
  )
  select jsonb_strip_nulls(
    jsonb_build_object(
      'source', d.source,
      'route_id', d.route_id,
      'profile_id', d.profile_id,
      'board_stage_id', d.board_stage_id,
      'alight_stage_id', d.alight_stage_id,
      'mode_code', d.mode_code,
      'route_leg_ids', case
        when d.route_id is not null
          then _route_leg_ids_between(d.route_id, d.board_stage_id, d.alight_stage_id)
        else '{}'::uuid[]
      end,
      'in_vehicle_time_estimate_s', case
        when d.route_id is not null
          then _planner_in_vehicle_s(d.route_id, d.board_stage_id, d.alight_stage_id)
        else 0
      end,
      'avg_wait_time_estimate_s', case
        when d.route_id is not null
          then _planner_wait_s(d.route_id, d.board_stage_id, d.alight_stage_id, p_city_id)
        else cfg_num('planner.default_wait_s', p_city_id)::int
      end,
      'supply', case d.source
        when 'parked' then jsonb_build_object(
          'kind', 'parked',
          'vehicles_bucket', _parked_supply_bucket(d.parked_count)
        )
        when 'driver_profile' then jsonb_build_object(
          'kind', 'driver_profile',
          'profile_id', d.profile_id,
          'profile_present', d.profile_present
        )
        else jsonb_build_object('kind', 'graph')
      end
    )
  )
  from deduped d
  where d.route_id is not null or d.profile_id is not null;
end;
$$;

create or replace function record_coverage_gap(
  p_rider_id uuid,
  p_origin geography,
  p_destination geography,
  p_city_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_walk_radius numeric;
  v_nearest record;
  v_ambient int;
  v_report_id uuid;
begin
  v_walk_radius := cfg_num('planner.walk_radius_m', p_city_id);

  select count(*)::int
  into v_ambient
  from driver_presence dp
  join drivers d on d.id = dp.driver_id
  where d.city_id = p_city_id
    and dp.status in ('at_park', 'roaming_available')
    and st_dwithin(dp.current_location, p_origin, v_walk_radius)
    and presence_is_fresh(dp.last_ping_at, p_city_id);

  select
    rs.id,
    rs.name,
    rs.location,
    round(distance_m(rs.location, p_origin))::int as distance_m
  into v_nearest
  from route_stages rs
  join routes r on r.id = rs.route_id
  where r.city_id = p_city_id
    and r.active
  order by st_distance(rs.location, p_origin)
  limit 1;

  insert into coverage_gap_reports (
    rider_id,
    city_id,
    searched_location,
    searched_destination,
    nearest_known_stage_id,
    nearest_known_stage_distance_m,
    ambient_vehicle_count
  ) values (
    p_rider_id,
    p_city_id,
    p_origin,
    p_destination,
    v_nearest.id,
    v_nearest.distance_m,
    v_ambient
  )
  returning id into v_report_id;

  return jsonb_build_object(
    'report_id', v_report_id,
    'nearest_stage', jsonb_build_object(
      'stage_id', v_nearest.id,
      'name', v_nearest.name,
      'location', jsonb_build_object(
        'lat', st_y(v_nearest.location::geometry),
        'lng', st_x(v_nearest.location::geometry)
      ),
      'distance_m', v_nearest.distance_m
    ),
    'ambient_vehicle_count', v_ambient
  );
end;
$$;

grant execute on function planner_direct_candidates(geography, geography, uuid, jsonb)
  to authenticated, anon, service_role;
grant execute on function record_coverage_gap(uuid, geography, geography, uuid)
  to authenticated, service_role;

-- Lat/lng wrappers for Edge Functions (avoid geography serialisation quirks).
create or replace function planner_direct_candidates_latlng(
  p_origin_lat double precision,
  p_origin_lng double precision,
  p_dest_lat double precision,
  p_dest_lng double precision,
  p_city_id uuid,
  p_filters jsonb default '{}'::jsonb
)
returns setof jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select planner_direct_candidates(
    st_setsrid(st_makepoint(p_origin_lng, p_origin_lat), 4326)::geography,
    st_setsrid(st_makepoint(p_dest_lng, p_dest_lat), 4326)::geography,
    p_city_id,
    p_filters
  )
$$;

create or replace function record_coverage_gap_latlng(
  p_rider_id uuid,
  p_origin_lat double precision,
  p_origin_lng double precision,
  p_dest_lat double precision,
  p_dest_lng double precision,
  p_city_id uuid
)
returns jsonb
language sql
volatile
security definer
set search_path = public, extensions
as $$
  select record_coverage_gap(
    p_rider_id,
    st_setsrid(st_makepoint(p_origin_lng, p_origin_lat), 4326)::geography,
    st_setsrid(st_makepoint(p_dest_lng, p_dest_lat), 4326)::geography,
    p_city_id
  )
$$;

grant execute on function planner_direct_candidates_latlng(double precision, double precision, double precision, double precision, uuid, jsonb)
  to authenticated, anon, service_role;
grant execute on function record_coverage_gap_latlng(uuid, double precision, double precision, double precision, double precision, uuid)
  to authenticated, service_role;

create or replace function insert_planner_query(
  p_id uuid,
  p_rider_id uuid,
  p_city_id uuid,
  p_origin_lat double precision,
  p_origin_lng double precision,
  p_dest_lat double precision,
  p_dest_lng double precision,
  p_filters jsonb,
  p_candidates jsonb,
  p_candidate_count int,
  p_direct_count int,
  p_degraded boolean,
  p_latency_ms int
)
returns uuid
language sql
volatile
security definer
set search_path = public, extensions
as $$
  insert into planner_queries (
    id,
    rider_id,
    city_id,
    origin,
    destination,
    filters,
    candidates,
    candidate_count,
    direct_count,
    degraded,
    latency_ms
  ) values (
    p_id,
    p_rider_id,
    p_city_id,
    st_setsrid(st_makepoint(p_origin_lng, p_origin_lat), 4326)::geography,
    st_setsrid(st_makepoint(p_dest_lng, p_dest_lat), 4326)::geography,
    p_filters,
    p_candidates,
    p_candidate_count,
    p_direct_count,
    p_degraded,
    p_latency_ms
  )
  returning id
$$;

grant execute on function insert_planner_query(uuid, uuid, uuid, double precision, double precision, double precision, double precision, jsonb, jsonb, int, int, boolean, int)
  to service_role;
