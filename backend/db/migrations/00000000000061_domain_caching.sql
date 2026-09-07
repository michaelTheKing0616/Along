-- P7-A-01: caching config defaults + graph-bundle RPCs (doc 07 §4, doc 03 §3).

select config_default('cache.plan_trip_ttl_s', '60');
select config_default('cache.places_ttl_s', '86400');
select config_default('cache.graph_bundle_ttl_s', '3600');
select config_default('cache.graph_bundle_max_parks', '500');
select config_default('cache.graph_bundle_max_stages', '2000');
select config_default('cache.graph_bundle_max_legs', '5000');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  ('cache.plan_trip_ttl_s', '{"type":"number","minimum":1,"maximum":3600}', 'plan-trip hot OD pair cache TTL (seconds)', array['global','city']::config_scope[], false),
  ('cache.places_ttl_s', '{"type":"number","minimum":60,"maximum":604800}', 'places-search Edge KV TTL (seconds)', array['global','city']::config_scope[], false),
  ('cache.graph_bundle_ttl_s', '{"type":"number","minimum":60,"maximum":86400}', 'graph-bundle Edge cache TTL (seconds)', array['global','city']::config_scope[], false),
  ('cache.graph_bundle_max_parks', '{"type":"number","minimum":10,"maximum":5000}', 'graph-bundle max parks per city', array['global','city']::config_scope[], false),
  ('cache.graph_bundle_max_stages', '{"type":"number","minimum":10,"maximum":20000}', 'graph-bundle max stages per city', array['global','city']::config_scope[], false),
  ('cache.graph_bundle_max_legs', '{"type":"number","minimum":10,"maximum":50000}', 'graph-bundle max legs per city', array['global','city']::config_scope[], false)
on conflict (key) do nothing;

-- Version token for mobile graph_cache refresh (doc 07 §4).
create or replace function city_graph_version(p_city_id uuid)
returns text
language sql
stable
security definer
set search_path = public, extensions
as $$
  select encode(
    digest(
      coalesce(
        (
          select max(ts)::text
          from (
            select updated_at as ts from parks where city_id = p_city_id and active
            union all
            select updated_at from routes where city_id = p_city_id and active
            union all
            select rs.updated_at
            from route_stages rs
            join routes r on r.id = rs.route_id
            where r.city_id = p_city_id and r.active
            union all
            select rl.updated_at
            from route_legs rl
            join routes r on r.id = rl.route_id
            where r.city_id = p_city_id and r.active
          ) u
        ),
        '0'
      )
      || ':' || (select count(*)::text from parks where city_id = p_city_id and active)
      || ':' || (
        select count(*)::text
        from route_stages rs
        join routes r on r.id = rs.route_id
        where r.city_id = p_city_id and r.active
      )
      || ':' || (
        select count(*)::text
        from route_legs rl
        join routes r on r.id = rl.route_id
        where r.city_id = p_city_id and r.active
      ),
      'sha256'
    ),
    'hex'
  );
$$;

revoke all on function city_graph_version(uuid) from public;
grant execute on function city_graph_version(uuid) to authenticated, service_role;

-- Compact per-city graph for mobile offline cache — no PII, bounded (doc 07 §4).
create or replace function graph_bundle_compact(
  p_city_id uuid,
  p_max_parks int,
  p_max_stages int,
  p_max_legs int
)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  with park_rows as (
    select
      p.id,
      p.name,
      round(st_y(p.location::geometry)::numeric, 6) as lat,
      round(st_x(p.location::geometry)::numeric, 6) as lng
    from parks p
    where p.city_id = p_city_id
      and p.active
    order by p.name
    limit greatest(p_max_parks, 0)
  ),
  stage_rows as (
    select
      rs.id,
      rs.route_id,
      rs.sequence,
      rs.name,
      rs.is_official_park,
      round(st_y(rs.location::geometry)::numeric, 6) as lat,
      round(st_x(rs.location::geometry)::numeric, 6) as lng
    from route_stages rs
    join routes r on r.id = rs.route_id
    where r.city_id = p_city_id
      and r.active
    order by r.id, rs.sequence
    limit greatest(p_max_stages, 0)
  ),
  leg_rows as (
    select
      rl.id,
      rl.route_id,
      rl.from_stage_id,
      rl.to_stage_id,
      rl.mode_code,
      rl.fare_amount,
      rl.fare_currency,
      rl.in_vehicle_time_estimate_s,
      rl.avg_wait_time_estimate_s
    from route_legs rl
    join routes r on r.id = rl.route_id
    where r.city_id = p_city_id
      and r.active
    order by rl.route_id, rl.from_stage_id
    limit greatest(p_max_legs, 0)
  ),
  counts as (
    select
      (select count(*) from parks where city_id = p_city_id and active) as park_total,
      (
        select count(*)
        from route_stages rs
        join routes r on r.id = rs.route_id
        where r.city_id = p_city_id and r.active
      ) as stage_total,
      (
        select count(*)
        from route_legs rl
        join routes r on r.id = rl.route_id
        where r.city_id = p_city_id and r.active
      ) as leg_total
  )
  select jsonb_build_object(
    'parks', coalesce((select jsonb_agg(to_jsonb(p)) from park_rows p), '[]'::jsonb),
    'stages', coalesce((select jsonb_agg(to_jsonb(s)) from stage_rows s), '[]'::jsonb),
    'legs', coalesce((select jsonb_agg(to_jsonb(l)) from leg_rows l), '[]'::jsonb),
    'truncated',
      (select
        (c.park_total > p_max_parks)
        or (c.stage_total > p_max_stages)
        or (c.leg_total > p_max_legs)
       from counts c)
  );
$$;

revoke all on function graph_bundle_compact(uuid, int, int, int) from public;
grant execute on function graph_bundle_compact(uuid, int, int, int) to authenticated, service_role;
