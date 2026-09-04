-- P0-A-06: doc 04 §4.3 — planner_decompose MVP (single shortest path over route_legs +
-- transfer_points; bounded by cfg.planner.max_legs; no route reuse). Production k-shortest
-- (Yen) refinements deferred to P2-A-01.

-- Stages boardable/alightable at a park (official stage park_id + transfer_points).
create or replace function _planner_stages_at_park(p_park_id uuid, p_city_id uuid)
returns table (stage_id uuid, route_id uuid, mode_code text)
language sql
stable
as $$
  select distinct rs.id, r.id, r.mode_code
  from route_stages rs
  join routes r on r.id = rs.route_id
  where rs.park_id = p_park_id
    and r.city_id = p_city_id
    and r.active
  union
  select distinct tp.stage_id, r.id, r.mode_code
  from transfer_points tp
  join routes r on r.id = tp.route_id
  where tp.park_id = p_park_id
    and r.city_id = p_city_id
    and r.active
$$;

-- Convert a stage walk (parallel stage_id / route_id arrays) into legs + transfers JSON.
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

-- MVP multi-leg path query: one lowest-cost path within cfg.planner.max_legs (transfers ≤ max_legs−1).
create or replace function planner_decompose(
  p_origin_park_id uuid,
  p_destination_park_id uuid,
  p_city_id uuid default null
)
returns jsonb
language plpgsql
volatile
as $$
declare
  v_city_id uuid;
  v_max_legs int;
  v_max_transfers int;
  v_default_wait numeric;
  v_walk_speed numeric;
  v_best record;
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
    return _planner_build_itinerary(
      array[]::uuid[], array[]::uuid[],
      p_origin_park_id, p_destination_park_id, v_city_id
    );
  end if;

  v_max_legs := cfg_num('planner.max_legs', v_city_id)::int;
  v_max_transfers := greatest(0, v_max_legs - 1);
  v_default_wait := cfg_num('planner.default_wait_s', v_city_id);
  v_walk_speed := cfg_num('planner.walk_speed_mps', v_city_id);

  with recursive
  origin_stages as (
    select * from _planner_stages_at_park(p_origin_park_id, v_city_id)
  ),
  dest_stages as (
    select stage_id from _planner_stages_at_park(p_destination_park_id, v_city_id)
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
      -- In-route: follow the next adjacent leg on the same route.
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

      -- Transfer: switch to another route at the same park (no route reuse).
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
  )
  select s.stage_path, s.route_path
  into v_best
  from search s
  where s.is_goal
  order by cardinality(s.routes_used), s.transfer_count, s.cost, array_length(s.stage_path, 1)
  limit 1;

  if not found then
    return null;
  end if;

  return _planner_build_itinerary(
    v_best.stage_path,
    v_best.route_path,
    p_origin_park_id,
    p_destination_park_id,
    v_city_id
  );
end;
$$;

grant execute on function planner_decompose(uuid, uuid, uuid) to authenticated;
grant execute on function planner_decompose(uuid, uuid, uuid) to anon;
