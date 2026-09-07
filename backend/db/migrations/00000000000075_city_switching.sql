-- P9-B-01: Persist rider home city and driver city via validated RPCs.

create or replace function set_home_city(p_city_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'UNAUTHORIZED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from cities c
    where c.id = p_city_id
      and c.status in ('alpha', 'beta', 'live')
  ) then
    raise exception 'VALIDATION: city not found or not active' using errcode = 'P0001';
  end if;

  insert into riders (id, home_city_id)
  values (v_uid, p_city_id)
  on conflict (id) do update
    set home_city_id = excluded.home_city_id,
        updated_at = now();
end;
$$;

grant execute on function set_home_city(uuid) to authenticated;

create or replace function set_driver_city(p_city_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'UNAUTHORIZED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from cities c
    where c.id = p_city_id
      and c.status in ('alpha', 'beta', 'live')
  ) then
    raise exception 'VALIDATION: city not found or not active' using errcode = 'P0001';
  end if;

  if not exists (select 1 from drivers d where d.id = v_uid) then
    raise exception 'VALIDATION: driver profile not found' using errcode = 'P0001';
  end if;

  update drivers
  set city_id = p_city_id,
      updated_at = now()
  where id = v_uid;
end;
$$;

grant execute on function set_driver_city(uuid) to authenticated;
