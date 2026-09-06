-- P4-C-01 follow-up: nearby_settlement_agents for D-20 agent list (doc 06)

create or replace function nearby_settlement_agents(p_location jsonb default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_city_id uuid;
  v_origin geography;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select d.city_id
  into v_city_id
  from drivers d
  where d.id = v_driver_id;

  if v_city_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if p_location is not null
     and p_location ? 'lat'
     and p_location ? 'lng' then
    v_origin := _point_from_json(p_location);
  else
    select dp.current_location
    into v_origin
    from driver_presence dp
    where dp.driver_id = v_driver_id;
  end if;

  if v_origin is null then
    select c.centroid
    into v_origin
    from cities c
    where c.id = v_city_id;
  end if;

  return coalesce(
    (
      select jsonb_agg(row order by (row->>'distance_m')::int)
      from (
        select jsonb_build_object(
          'id', sa.id,
          'business_name', sa.business_name,
          'distance_m', round(st_distance(sa.location, v_origin))::int
        ) as row
        from settlement_agents sa
        where sa.active
          and sa.city_id = v_city_id
          and sa.location is not null
        order by st_distance(sa.location, v_origin)
        limit 20
      ) ranked
    ),
    '[]'::jsonb
  );
end;
$$;

grant execute on function nearby_settlement_agents(jsonb) to authenticated;
