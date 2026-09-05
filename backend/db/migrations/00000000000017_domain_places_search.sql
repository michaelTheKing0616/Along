-- P1-A-07: doc 03 §3 — places-search graph RPC (trigram on parks/stages).

select config_default('places.search_radius_m', '5000');
select config_default('places.trigram_min_similarity', '0.2');
select config_default('places.photon_timeout_ms', '800');

create or replace function places_search_graph(
  p_q text,
  p_near_lat double precision,
  p_near_lng double precision,
  p_city_id uuid,
  p_limit int,
  p_radius_m numeric,
  p_min_similarity numeric
)
returns table (
  kind text,
  id uuid,
  name text,
  area text,
  lat double precision,
  lng double precision,
  distance_m numeric,
  rank_score numeric
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with near_point as (
    select st_setsrid(st_makepoint(p_near_lng, p_near_lat), 4326)::geography as g
  ),
  park_hits as (
    select
      'park'::text as kind,
      p.id,
      p.name,
      c.name as area,
      st_y(p.location::geometry) as lat,
      st_x(p.location::geometry) as lng,
      st_distance(p.location, np.g) as distance_m,
      greatest(
        similarity(p.name, p_q),
        coalesce((
          select max(similarity(alias, p_q))
          from unnest(p.name_aliases) as alias
        ), 0)
      ) as rank_score
    from parks p
    join cities c on c.id = p.city_id
    cross join near_point np
    where p.city_id = p_city_id
      and p.active
      and st_dwithin(p.location, np.g, p_radius_m)
      and (
        p.name ilike '%' || p_q || '%'
        or similarity(p.name, p_q) >= p_min_similarity
        or exists (
          select 1
          from unnest(p.name_aliases) as alias
          where alias ilike '%' || p_q || '%'
            or similarity(alias, p_q) >= p_min_similarity
        )
      )
  ),
  stage_hits as (
    select
      'stage'::text as kind,
      rs.id,
      rs.name,
      c.name as area,
      st_y(rs.location::geometry) as lat,
      st_x(rs.location::geometry) as lng,
      st_distance(rs.location, np.g) as distance_m,
      similarity(rs.name, p_q) as rank_score
    from route_stages rs
    join routes r on r.id = rs.route_id
    join cities c on c.id = r.city_id
    cross join near_point np
    where r.city_id = p_city_id
      and r.active
      and rs.name is not null
      and st_dwithin(rs.location, np.g, p_radius_m)
      and (
        rs.name ilike '%' || p_q || '%'
        or similarity(rs.name, p_q) >= p_min_similarity
      )
  ),
  combined as (
    select * from park_hits
    union all
    select * from stage_hits
  )
  select
    kind,
    id,
    name,
    area,
    lat,
    lng,
    round(distance_m::numeric) as distance_m,
    rank_score
  from combined
  order by rank_score desc, distance_m asc
  limit p_limit;
$$;

grant execute on function places_search_graph(
  text, double precision, double precision, uuid, int, numeric, numeric
) to authenticated, service_role;
