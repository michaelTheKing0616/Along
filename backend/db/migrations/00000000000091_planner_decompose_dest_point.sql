-- planner_decompose_latlng built the destination point as (lng, lng), so no park
-- ever matched the real destination and multi-leg itineraries never came back.
-- Body otherwise identical to 00000000000023.

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
  v_dest := st_setsrid(st_makepoint(p_dest_lng, p_dest_lat), 4326)::geography;
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
