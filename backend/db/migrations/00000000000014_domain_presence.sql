-- P1-A-04: doc 04 §7, doc 03 §2/§6 — presence RPCs, ambient aggregation, plausibility, stale job.

-- ---------------------------------------------------------------------------
-- Config (doc 02 §2.3 — no literals for intervals/thresholds)
-- ---------------------------------------------------------------------------
select config_default('presence.ping_min_interval_s', '2');
select config_default('presence.at_park_radius_m', '150');

-- ---------------------------------------------------------------------------
-- Geometry helpers (doc 04 §1)
-- ---------------------------------------------------------------------------
create or replace function bearing_deg(a geography, b geography)
returns double precision
language sql
immutable
parallel safe
set search_path = public, extensions
as $$
  select case
    when degrees(st_azimuth(a::geometry, b::geometry)) < 0
      then degrees(st_azimuth(a::geometry, b::geometry)) + 360
    else degrees(st_azimuth(a::geometry, b::geometry))
  end
$$;

create or replace function angle_diff(h1 double precision, h2 double precision)
returns double precision
language sql
immutable
parallel safe
as $$
  select least(abs(h1 - h2), 360 - abs(h1 - h2))
$$;

create or replace function along_geohash(p geography, p_precision int)
returns text
language sql
immutable
parallel safe
set search_path = public, extensions
as $$
  select st_geohash(p::geometry, p_precision)
$$;

create or replace function geohash_centroid(p_geohash text, p_precision int)
returns geography
language sql
immutable
parallel safe
set search_path = public, extensions
as $$
  select st_setsrid(st_centroid(st_geomfromgeohash(p_geohash, p_precision)::geometry), 4326)::geography
$$;

create or replace function sector8(p_bearing double precision)
returns int
language sql
immutable
parallel safe
as $$
  select (floor((p_bearing + 22.5) / 45)::int % 8 + 8) % 8
$$;

create or replace function ambient_count_bucket(p_count int)
returns text
language sql
immutable
parallel safe
as $$
  select case
    when p_count <= 2 then '1-2'
    when p_count <= 5 then '3-5'
    else '6+'
  end
$$;

create or replace function heading_sector_counts(p_sectors int[])
returns jsonb
language sql
immutable
parallel safe
as $$
  select jsonb_agg(coalesce(c.cnt, 0) order by gs.i)
  from generate_series(0, 7) gs(i)
  left join lateral (
    select count(*)::int as cnt
    from unnest(p_sectors) s
    where s = gs.i
  ) c on true
$$;

create or replace function _mode_ref(p_mode_code text)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'code', m.code,
    'label', m.label,
    'icon_key', m.icon_key,
    'color_token', m.color_token
  )
  from mode_config m
  where m.code = p_mode_code
$$;

-- ---------------------------------------------------------------------------
-- Matchability stub (P1-A-05 expands with ledger; verification-only for now)
-- ---------------------------------------------------------------------------
create or replace function driver_is_matchable(p_driver_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select d.verified_status = 'verified'
       and d.standing in ('good_standing', 'warned')
    from drivers d
    where d.id = p_driver_id
  ), false)
$$;

-- ---------------------------------------------------------------------------
-- Freshness & plausibility (doc 04 §7.1–7.2)
-- ---------------------------------------------------------------------------
create or replace function presence_is_fresh(p_last_ping_at timestamptz, p_city_id uuid)
returns boolean
language sql
stable
as $$
  select p_last_ping_at >= now() - make_interval(secs => cfg_num('presence.stale_after_s', p_city_id)::int)
$$;

create or replace function presence_plausible(
  p_location geography,
  p_heading smallint,
  p_speed_mps numeric,
  p_nearest_stage_id uuid,
  p_declared_route_profile_id uuid,
  p_declared_route_leg_id uuid,
  p_destination geography,
  p_city_id uuid
)
returns boolean
language plpgsql
stable
set search_path = public, extensions
as $$
declare
  v_route_id uuid;
  v_nearest_seq int;
begin
  if p_destination is null then
    return true;
  end if;

  if p_declared_route_leg_id is not null then
    select rl.route_id into v_route_id
    from route_legs rl
    where rl.id = p_declared_route_leg_id;
  elsif p_declared_route_profile_id is not null then
    select drp.route_id into v_route_id
    from driver_route_profiles drp
    where drp.id = p_declared_route_profile_id;
  end if;

  if v_route_id is not null and p_nearest_stage_id is not null then
    select rs.sequence into v_nearest_seq
    from route_stages rs
    where rs.id = p_nearest_stage_id;

    return exists (
      select 1
      from route_stages rs
      where rs.route_id = v_route_id
        and rs.sequence > v_nearest_seq
        and st_dwithin(rs.location, p_destination, cfg_num('planner.dest_radius_m', p_city_id))
    );
  end if;

  if coalesce(p_speed_mps, 0) < 1 then
    return true;
  end if;

  return angle_diff(
    coalesce(p_heading, 0)::double precision,
    bearing_deg(p_location, p_destination)
  ) <= cfg_num('planner.heading_tolerance_deg', p_city_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- set_presence / presence_ping (doc 04 §7.1, doc 03 §6)
-- ---------------------------------------------------------------------------
create or replace function set_presence(
  p_status text,
  p_location jsonb,
  p_seats_available smallint,
  p_heading smallint default null,
  p_park_id uuid default null,
  p_declared_route_profile_id uuid default null,
  p_declared_route_leg_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_status presence_status;
  v_point geography;
  v_city_id uuid;
  v_vehicle_id uuid;
  v_session_id uuid;
  v_snap_radius numeric;
  v_nearest_stage uuid;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  begin
    v_status := p_status::presence_status;
  exception
    when invalid_text_representation then
      raise exception 'VALIDATION' using errcode = 'P0001';
  end;

  if v_status = 'offline' then
    delete from driver_presence where driver_id = v_driver_id;
    return jsonb_build_object('session_id', null, 'status', 'offline');
  end if;

  select d.city_id into v_city_id
  from drivers d
  where d.id = v_driver_id;

  if v_city_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not driver_is_matchable(v_driver_id) then
    raise exception 'LEDGER_BLOCKED' using errcode = 'P0001';
  end if;

  select dv.vehicle_id
  into v_vehicle_id
  from driver_vehicles dv
  where dv.driver_id = v_driver_id
    and dv.active
  limit 1;

  if v_vehicle_id is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_point := _point_from_json(p_location);
  v_snap_radius := cfg_num('graph.snap_radius_m', v_city_id) * 2;
  v_nearest_stage := snap_stage(v_point, v_snap_radius, v_city_id);

  if v_status = 'at_park' then
    if p_park_id is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    if not exists (
      select 1
      from parks pk
      where pk.id = p_park_id
        and st_dwithin(pk.location, v_point, cfg_num('presence.at_park_radius_m', v_city_id))
    ) then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
  end if;

  if p_declared_route_profile_id is not null and not exists (
    select 1 from driver_route_profiles drp
    where drp.id = p_declared_route_profile_id and drp.driver_id = v_driver_id
  ) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_declared_route_leg_id is not null and not exists (
    select 1
    from route_legs rl
    join routes r on r.id = rl.route_id
    where rl.id = p_declared_route_leg_id
      and r.city_id = v_city_id
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  insert into driver_presence (
    driver_id,
    vehicle_id,
    session_id,
    status,
    current_location,
    heading,
    park_id,
    declared_route_profile_id,
    declared_route_leg_id,
    nearest_stage_id,
    seats_available,
    last_ping_at,
    started_at
  ) values (
    v_driver_id,
    v_vehicle_id,
    gen_random_uuid(),
    v_status,
    v_point,
    p_heading,
    p_park_id,
    p_declared_route_profile_id,
    p_declared_route_leg_id,
    v_nearest_stage,
    p_seats_available,
    now(),
    now()
  )
  on conflict (driver_id) do update set
    vehicle_id = excluded.vehicle_id,
    status = excluded.status,
    current_location = excluded.current_location,
    heading = excluded.heading,
    park_id = excluded.park_id,
    declared_route_profile_id = excluded.declared_route_profile_id,
    declared_route_leg_id = excluded.declared_route_leg_id,
    nearest_stage_id = excluded.nearest_stage_id,
    seats_available = excluded.seats_available,
    last_ping_at = now(),
    updated_at = now()
  returning session_id into v_session_id;

  perform ensure_partitions();

  insert into driver_presence_history (
    driver_id, session_id, ts, location, heading, speed_mps, status
  ) values (
    v_driver_id, v_session_id, now(), v_point, p_heading, null, v_status
  );

  return jsonb_build_object('session_id', v_session_id, 'status', v_status::text);
end;
$$;

create or replace function presence_ping(
  p_location jsonb,
  p_heading smallint,
  p_speed_mps numeric,
  p_accuracy_m numeric,
  p_seats_available smallint default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_row driver_presence%rowtype;
  v_point geography;
  v_city_id uuid;
  v_min_interval numeric;
  v_snap_radius numeric;
  v_nearest_stage uuid;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_row
  from driver_presence
  where driver_id = v_driver_id;

  if not found then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select d.city_id into v_city_id
  from drivers d
  where d.id = v_driver_id;

  v_min_interval := cfg_num('presence.ping_min_interval_s', v_city_id);

  if v_row.last_ping_at > now() - make_interval(secs => v_min_interval::int) then
    return jsonb_build_object('accepted', false);
  end if;

  v_point := _point_from_json(p_location);
  v_snap_radius := cfg_num('graph.snap_radius_m', v_city_id) * 2;
  v_nearest_stage := snap_stage(v_point, v_snap_radius, v_city_id);

  update driver_presence
  set
    current_location = v_point,
    heading = p_heading,
    speed_mps = p_speed_mps,
    accuracy_m = p_accuracy_m,
    nearest_stage_id = v_nearest_stage,
    seats_available = coalesce(p_seats_available, seats_available),
    last_ping_at = now(),
    updated_at = now()
  where driver_id = v_driver_id;

  perform ensure_partitions();

  insert into driver_presence_history (
    driver_id, session_id, ts, location, heading, speed_mps, status
  ) values (
    v_driver_id, v_row.session_id, now(), v_point, p_heading, p_speed_mps, v_row.status
  );

  return jsonb_build_object('accepted', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- Ambient aggregation (doc 04 §7.3–7.4, doc 03 §2)
-- ---------------------------------------------------------------------------
create or replace function ambient_vehicles(
  p_lat double precision,
  p_lng double precision,
  p_radius_m int,
  p_dest_lat double precision default null,
  p_dest_lng double precision default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_origin geography := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  v_destination geography;
  v_city_id uuid;
  v_precision int;
  v_cells jsonb;
begin
  if p_radius_m is null or p_radius_m <= 0 or p_radius_m > 3000 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_city_id := city_for_point(v_origin);

  if p_dest_lat is not null and p_dest_lng is not null then
    v_destination := st_setsrid(st_makepoint(p_dest_lng, p_dest_lat), 4326)::geography;
  end if;

  v_precision := cfg_num('presence.ambient_cell_precision', v_city_id)::int;

  with fresh as (
    select
      dp.*,
      v.mode_code,
      along_geohash(dp.current_location, v_precision) as cell,
      coalesce(dp.speed_mps, 0) as eff_speed
    from driver_presence dp
    join vehicles v on v.id = dp.vehicle_id
    join drivers d on d.id = dp.driver_id
    where d.city_id = v_city_id
      and driver_is_matchable(dp.driver_id)
      and presence_is_fresh(dp.last_ping_at, v_city_id)
      and st_dwithin(dp.current_location, v_origin, p_radius_m)
      and dp.status in ('at_park', 'roaming_available')
      and dp.seats_available >= 1
  ),
  vehicle_sectors as (
    select
      f.*,
      case
        when f.eff_speed < 1 and f.nearest_stage_id is not null then
          sector8(bearing_deg(f.current_location, rs.location))
        when f.heading is not null then
          sector8(f.heading::double precision)
        else null
      end as sector
    from fresh f
    left join route_stages rs on rs.id = f.nearest_stage_id
  ),
  grouped as (
    select
      vs.cell,
      vs.mode_code,
      count(*)::int as vehicle_count,
      min(
        ceil(
          distance_m(vs.current_location, v_origin)
          / greatest(vs.eff_speed, 3)
          / 60.0
        ) * 60
      )::int as eta_band_s,
      bool_or(
        presence_plausible(
          vs.current_location,
          vs.heading,
          vs.speed_mps,
          vs.nearest_stage_id,
          vs.declared_route_profile_id,
          vs.declared_route_leg_id,
          v_destination,
          v_city_id
        )
      ) as serves_destination,
      array_agg(vs.sector) filter (where vs.sector is not null) as sectors
    from vehicle_sectors vs
    group by vs.cell, vs.mode_code
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'cell', g.cell,
      'centroid', jsonb_build_object(
        'lat', st_y(geohash_centroid(g.cell, v_precision)::geometry),
        'lng', st_x(geohash_centroid(g.cell, v_precision)::geometry)
      ),
      'mode', _mode_ref(g.mode_code),
      'count_bucket', ambient_count_bucket(g.vehicle_count),
      'heading_sectors', heading_sector_counts(g.sectors),
      'serves_destination', coalesce(g.serves_destination, false),
      'eta_band_s', g.eta_band_s
    )
    order by g.cell, g.mode_code
  ), '[]'::jsonb)
  into v_cells
  from grouped g;

  return jsonb_build_object('as_of', to_jsonb(now()), 'cells', v_cells);
end;
$$;

create or replace function ambient_demand(
  p_lat double precision,
  p_lng double precision,
  p_radius_m int
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_origin geography := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  v_city_id uuid;
  v_precision int;
  v_cells jsonb;
begin
  if p_radius_m is null or p_radius_m <= 0 or p_radius_m > 3000 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_city_id := city_for_point(v_origin);
  v_precision := cfg_num('presence.ambient_cell_precision', v_city_id)::int;

  with recent as (
    select
      pq.origin,
      pq.destination,
      along_geohash(pq.origin, v_precision) as cell
    from planner_queries pq
    where pq.city_id = v_city_id
      and pq.created_at > now() - interval '15 minutes'
      and st_dwithin(pq.origin, v_origin, p_radius_m)
  ),
  sector_counts as (
    select
      r.cell,
      sector8(bearing_deg(r.origin, r.destination)) as sector,
      count(*)::int as cnt
    from recent r
    group by r.cell, sector8(bearing_deg(r.origin, r.destination))
  ),
  top_dirs as (
    select
      sc.cell,
      array_agg(sc.sector order by sc.cnt desc, sc.sector) as dirs
    from (
      select
        sc.*,
        row_number() over (partition by sc.cell order by sc.cnt desc, sc.sector) as rn
      from sector_counts sc
    ) sc
    where sc.rn <= 2
    group by sc.cell
  ),
  grouped as (
    select
      r.cell,
      count(*)::int as search_count,
      coalesce(td.dirs, '{}'::int[]) as top_dirs
    from recent r
    left join top_dirs td on td.cell = r.cell
    group by r.cell, td.dirs
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'cell', g.cell,
      'centroid', jsonb_build_object(
        'lat', st_y(geohash_centroid(g.cell, v_precision)::geometry),
        'lng', st_x(geohash_centroid(g.cell, v_precision)::geometry)
      ),
      'searches_last_15m_bucket', ambient_count_bucket(g.search_count),
      'top_destination_directions', to_jsonb(g.top_dirs)
    )
    order by g.cell
  ), '[]'::jsonb)
  into v_cells
  from grouped g;

  return jsonb_build_object('cells', v_cells);
end;
$$;

-- ---------------------------------------------------------------------------
-- Stale/offline cleanup (doc 03 §12 presence_stale)
-- ---------------------------------------------------------------------------
create or replace function presence_stale()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row record;
begin
  for v_row in
    select dp.driver_id, d.city_id, dp.last_ping_at
    from driver_presence dp
    join drivers d on d.id = dp.driver_id
    where dp.last_ping_at < now() - make_interval(
      secs => cfg_num('presence.offline_after_s', d.city_id)::int
    )
  loop
    delete from driver_presence where driver_id = v_row.driver_id;
  end loop;
end;
$$;

do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'presence_stale' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'presence_stale',
    '*/15 * * * * *',
    $cron$select presence_stale()$cron$
  );
end;
$$;

revoke execute on function presence_stale() from authenticated;
grant execute on function presence_stale() to service_role;

grant execute on function bearing_deg(geography, geography) to authenticated, anon;
grant execute on function angle_diff(double precision, double precision) to authenticated, anon;
grant execute on function along_geohash(geography, int) to authenticated, anon;
grant execute on function geohash_centroid(text, int) to authenticated, anon;
grant execute on function sector8(double precision) to authenticated, anon;
grant execute on function ambient_count_bucket(int) to authenticated, anon;
grant execute on function heading_sector_counts(int[]) to authenticated, anon;
grant execute on function driver_is_matchable(uuid) to authenticated, anon;
grant execute on function presence_is_fresh(timestamptz, uuid) to authenticated, anon;
grant execute on function presence_plausible(geography, smallint, numeric, uuid, uuid, uuid, geography, uuid) to authenticated, anon;
grant execute on function set_presence(text, jsonb, smallint, smallint, uuid, uuid, uuid) to authenticated;
grant execute on function presence_ping(jsonb, smallint, numeric, numeric, smallint) to authenticated;
grant execute on function ambient_vehicles(double precision, double precision, int, double precision, double precision) to authenticated;
grant execute on function ambient_demand(double precision, double precision, int) to authenticated;
