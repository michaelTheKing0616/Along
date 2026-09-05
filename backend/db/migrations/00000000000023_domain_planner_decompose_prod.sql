-- P2-A-01: doc 04 §4.3 production planner_decompose (k-shortest, transfer edges,
-- ≤ cfg.planner.max_legs, no route reuse) + lat/lng wrapper for plan-trip v2.

-- Enrich leg JSON with route_leg_ids and time estimates for Edge metrics.
create or replace function _planner_build_itinerary(
  p_stage_path uuid[],
  p_route_path uuid[],
  p_origin_park_id uuid,
  p_destination_park_id uuid,
  p_city_id uuid
)
returns jsonb
language plpgsql
volatile
as $$
declare
  v_legs jsonb := '[]'::jsonb;
  v_transfers jsonb := '[]'::jsonb;
  v_i int;
  v_j int;
  v_leg_from uuid;
  v_leg_to uuid;
  v_route uuid;
  v_mode text;
  v_fare fare_resolution;
  v_tp record;
  v_leg_ids uuid[];
  v_in_vehicle int;
  v_wait int;
begin
  if p_origin_park_id = p_destination_park_id then
    return jsonb_build_object(
      'kind', 'multi_leg',
      'origin_park_id', p_origin_park_id,
      'destination_park_id', p_destination_park_id,
      'legs', '[]'::jsonb,
      'transfers', '[]'::jsonb
    );
  end if;

  if coalesce(array_length(p_stage_path, 1), 0) = 0 then
    return null;
  end if;

  v_i := 1;
  while v_i <= array_length(p_stage_path, 1) loop
    v_route := p_route_path[v_i];
    v_j := v_i;
    while v_j < array_length(p_stage_path, 1) and p_route_path[v_j + 1] = v_route loop
      v_j := v_j + 1;
    end loop;

    v_leg_from := p_stage_path[v_i];
    v_leg_to := p_stage_path[v_j];

    select r.mode_code into v_mode from routes r where r.id = v_route;
    v_leg_ids := _route_leg_ids_between(v_route, v_leg_from, v_leg_to);
    v_in_vehicle := _planner_in_vehicle_s(v_route, v_leg_from, v_leg_to);
    v_wait := _planner_wait_s(v_route, v_leg_from, v_leg_to, p_city_id);

    begin
      v_fare := resolve_fare(
        p_route_id => v_route,
        p_from_stage_id => v_leg_from,
        p_to_stage_id => v_leg_to,
        p_mode_code => v_mode,
        p_city_id => p_city_id
      );
    exception
      when others then
        v_fare := null;
    end;

    v_legs := v_legs || jsonb_build_array(
      jsonb_strip_nulls(jsonb_build_object(
        'route_id', v_route,
        'mode_code', v_mode,
        'from_stage_id', v_leg_from,
        'to_stage_id', v_leg_to,
        'route_leg_ids', to_jsonb(v_leg_ids),
        'in_vehicle_time_estimate_s', v_in_vehicle,
        'avg_wait_time_estimate_s', v_wait,
        'fare', case
          when v_fare is null then null
          else jsonb_build_object(
            'amount', v_fare.amount,
            'currency', v_fare.currency,
            'tier', v_fare.tier,
            'confidence', v_fare.confidence,
            'unconfirmed', v_fare.unconfirmed
          )
        end
      ))
    );

    if v_j < array_length(p_stage_path, 1) then
      select
        tp_from.park_id,
        tp_from.route_id as from_route_id,
        tp_to.route_id as to_route_id,
        tp_from.stage_id as from_stage_id,
        tp_to.stage_id as to_stage_id,
        tp_to.walk_distance_m,
        tp_to.transfer_time_s
      into v_tp
      from transfer_points tp_from
      join transfer_points tp_to
        on tp_to.park_id = tp_from.park_id
       and tp_to.route_id = p_route_path[v_j + 1]
      where tp_from.stage_id = p_stage_path[v_j]
        and tp_from.route_id = p_route_path[v_j]
      order by tp_to.transfer_time_s
      limit 1;

      if found then
        v_transfers := v_transfers || jsonb_build_array(
          jsonb_build_object(
            'park_id', v_tp.park_id,
            'from_route_id', v_tp.from_route_id,
            'to_route_id', v_tp.to_route_id,
            'from_stage_id', v_tp.from_stage_id,
            'to_stage_id', v_tp.to_stage_id,
            'walk_distance_m', v_tp.walk_distance_m,
            'transfer_time_s', v_tp.transfer_time_s
          )
        );
      end if;
    end if;

    v_i := v_j + 1;
  end loop;

  return jsonb_build_object(
    'kind', 'multi_leg',
    'origin_park_id', p_origin_park_id,
    'destination_park_id', p_destination_park_id,
    'legs', v_legs,
    'transfers', v_transfers
  );
end;
$$;

-- Internal: enumerate up to k lowest-cost paths between two parks.
create or replace function _planner_search_paths(
  p_origin_park_id uuid,
  p_destination_park_id uuid,
  p_city_id uuid,
  p_k int
)
returns table (
  stage_path uuid[],
  route_path uuid[],
  transfer_count int,
  cost numeric
)
language plpgsql
stable
as $$
declare
  v_max_legs int;
  v_max_transfers int;
  v_default_wait numeric;
  v_walk_speed numeric;
begin
  v_max_legs := cfg_num('planner.max_legs', p_city_id)::int;
  v_max_transfers := greatest(0, v_max_legs - 1);
  v_default_wait := cfg_num('planner.default_wait_s', p_city_id);
  v_walk_speed := cfg_num('planner.walk_speed_mps', p_city_id);

  return query
  with recursive
  origin_stages as (
    select * from _planner_stages_at_park(p_origin_park_id, p_city_id)
  ),
  dest_stages as (
    select stage_id from _planner_stages_at_park(p_destination_park_id, p_city_id)
  ),
  search as (
    select
      os.stage_id,
      os.route_id,
      array[os.route_id] as routes_used,
      array[os.stage_id] as stage_path,
      array[os.route_id] as route_path,
      0 as transfer_count,
      0::numeric as cost,
      (os.stage_id in (select stage_id from dest_stages)) as is_goal
    from origin_stages os

    union all

    select
      nxt.stage_id,
      nxt.route_id,
      nxt.routes_used,
      nxt.stage_path,
      nxt.route_path,
      nxt.transfer_count,
      nxt.cost,
      (nxt.stage_id in (select stage_id from dest_stages)) as is_goal
    from search s
    cross join lateral (
      select
        rl.to_stage_id as stage_id,
        s.route_id,
        s.routes_used,
        s.stage_path || rl.to_stage_id as stage_path,
        s.route_path || s.route_id as route_path,
        s.transfer_count,
        s.cost
          + coalesce(rl.in_vehicle_time_estimate_s, 0)
          + coalesce(rl.avg_wait_time_estimate_s, v_default_wait) as cost,
        s.transfer_count as xfer
      from route_legs rl
      where rl.from_stage_id = s.stage_id
        and rl.route_id = s.route_id
        and not rl.to_stage_id = any(s.stage_path)
        and cardinality(s.routes_used) <= v_max_legs

      union all

      select
        tp_to.stage_id,
        tp_to.route_id,
        s.routes_used || tp_to.route_id,
        s.stage_path || tp_to.stage_id,
        s.route_path || tp_to.route_id,
        s.transfer_count + 1,
        s.cost
          + coalesce(tp_to.transfer_time_s, 0)
          + coalesce(tp_to.walk_distance_m, 0) / greatest(v_walk_speed, 0.1),
        s.transfer_count + 1
      from transfer_points tp_from
      join transfer_points tp_to
        on tp_to.park_id = tp_from.park_id
       and tp_to.route_id <> s.route_id
      where tp_from.stage_id = s.stage_id
        and tp_from.route_id = s.route_id
        and not tp_to.route_id = any(s.routes_used)
        and not tp_to.stage_id = any(s.stage_path)
        and s.transfer_count < v_max_transfers
        and cardinality(s.routes_used || tp_to.route_id) <= v_max_legs
    ) nxt
    where not s.is_goal
  ),
  goals as (
    select distinct on (s.route_path)
      s.stage_path,
      s.route_path,
      s.transfer_count,
      s.cost
    from search s
    where s.is_goal
    order by
      s.route_path,
      cardinality(s.route_path),
      s.transfer_count,
      s.cost,
      array_length(s.stage_path, 1)
  )
  select g.stage_path, g.route_path, g.transfer_count, g.cost
  from goals g
  order by
    cardinality(g.route_path),
    g.transfer_count,
    g.cost,
    array_length(g.stage_path, 1)
  limit greatest(p_k, 1);
end;
$$;

-- Production k-shortest decomposition between two parks.
drop function if exists planner_decompose(uuid, uuid, uuid);
create or replace function planner_decompose(
  p_origin_park_id uuid,
  p_destination_park_id uuid,
  p_city_id uuid default null
)
returns setof jsonb
language plpgsql
volatile
as $$
declare
  v_city_id uuid;
  v_k int;
  v_path record;
  v_itinerary jsonb;
begin
  select p.city_id into v_city_id
  from parks p
  where p.id = p_origin_park_id and p.active;

  if v_city_id is null then
    raise exception 'planner_decompose: unknown or inactive origin park %', p_origin_park_id
      using errcode = '22023';
  end if;

  v_city_id := coalesce(p_city_id, v_city_id);

  if not exists (
    select 1 from parks p
    where p.id = p_destination_park_id and p.city_id = v_city_id and p.active
  ) then
    raise exception 'planner_decompose: destination park % not in city %', p_destination_park_id, v_city_id
      using errcode = '22023';
  end if;

  if p_origin_park_id = p_destination_park_id then
    return next _planner_build_itinerary(
      array[]::uuid[], array[]::uuid[],
      p_origin_park_id, p_destination_park_id, v_city_id
    );
    return;
  end if;

  v_k := cfg_num('planner.max_candidates', v_city_id)::int;

  for v_path in
    select * from _planner_search_paths(
      p_origin_park_id, p_destination_park_id, v_city_id, v_k
    )
  loop
    v_itinerary := _planner_build_itinerary(
      v_path.stage_path,
      v_path.route_path,
      p_origin_park_id,
      p_destination_park_id,
      v_city_id
    );
    if v_itinerary is not null then
      return next v_itinerary;
    end if;
  end loop;
end;
$$;

-- Lat/lng wrapper: decompose across park pairs near origin/destination.
create or replace function planner_decompose_latlng(
  p_origin_lat double precision,
  p_origin_lng double precision,
  p_dest_lat double precision,
  p_dest_lng double precision,
  p_city_id uuid,
  p_filters jsonb default '{}'::jsonb
)
returns setof jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_origin geography;
  v_dest geography;
  v_walk_radius numeric;
  v_dest_radius numeric;
  v_k int;
  v_modes text[];
  v_modes_filter boolean;
  v_row record;
begin
  v_origin := st_setsrid(st_makepoint(p_origin_lng, p_origin_lat), 4326)::geography;
  v_dest := st_setsrid(st_makepoint(p_dest_lng, p_dest_lng), 4326)::geography;
  v_walk_radius := cfg_num('planner.walk_radius_m', p_city_id);
  v_dest_radius := cfg_num('planner.dest_radius_m', p_city_id);
  v_k := cfg_num('planner.max_candidates', p_city_id)::int;

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
  origin_parks as (
    select p.id
    from parks p
    where p.city_id = p_city_id
      and p.active
      and st_dwithin(p.location, v_origin, v_walk_radius)
  ),
  dest_parks as (
    select p.id
    from parks p
    where p.city_id = p_city_id
      and p.active
      and st_dwithin(p.location, v_dest, v_dest_radius)
  ),
  pairs as (
    select op.id as origin_park_id, dp.id as dest_park_id
    from origin_parks op
    cross join dest_parks dp
    where op.id <> dp.id
  ),
  raw as (
    select pd.itin
    from pairs pr
    cross join lateral planner_decompose(pr.origin_park_id, pr.dest_park_id, p_city_id) pd(itin)
    where pd.itin is not null
  ),
  filtered as (
    select
      r.itin,
      (
        select string_agg(leg->>'route_id', ',' order by ord)
        from jsonb_array_elements(r.itin->'legs') with ordinality as t(leg, ord)
      ) as route_sig,
      jsonb_array_length(r.itin->'legs') as leg_count,
      jsonb_array_length(r.itin->'transfers') as transfer_count
    from raw r
    where (
      not v_modes_filter
      or not exists (
        select 1
        from jsonb_array_elements(r.itin->'legs') leg
        where leg->>'mode_code' <> all (v_modes)
      )
    )
  ),
  deduped as (
    select distinct on (f.route_sig)
      f.itin
    from filtered f
    where f.route_sig is not null
    order by f.route_sig, f.leg_count, f.transfer_count
  )
  select d.itin
  from deduped d
  limit v_k;
end;
$$;

grant execute on function _planner_search_paths(uuid, uuid, uuid, int) to authenticated, anon, service_role;
grant execute on function planner_decompose(uuid, uuid, uuid) to authenticated, anon, service_role;
grant execute on function planner_decompose_latlng(double precision, double precision, double precision, double precision, uuid, jsonb)
  to authenticated, anon, service_role;
