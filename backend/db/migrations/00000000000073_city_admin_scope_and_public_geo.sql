-- P9-A-01: city_admin must not inherit deployment-wide scope; vehicles admin RLS city-scoped;
-- public geo helpers for apps (centroid, anon country dial metadata).

-- city_admin never gets deployment-wide access when city_scope is null.
create or replace function admin_can_access_city(p_city uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from admin_users a
    left join cities c on c.id = p_city
    left join countries k on k.code = c.country_code
    where a.id = auth.uid()
      and a.disabled_at is null
      and (
        a.role = 'superadmin'
        or (
          a.role = 'city_admin'
          and a.city_scope is not null
          and p_city = any(a.city_scope)
        )
        or (
          a.role <> 'city_admin'
          and (
            (a.city_scope is null and a.deployment_id = k.deployment_id)
            or (p_city = any(a.city_scope))
          )
        )
      )
  )
$$;

-- City centroid for map bootstrap (no hardcoded Abuja in apps).
create or replace function city_centroid(p_city_id uuid)
returns jsonb
language sql
stable
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'lat', st_y(c.centroid::geometry),
    'lng', st_x(c.centroid::geometry)
  )
  from cities c
  where c.id = p_city_id
$$;

grant execute on function city_centroid(uuid) to authenticated, anon, service_role;

-- Anon may read active country dial/currency metadata for pre-auth onboarding.
grant select on countries to anon;

drop policy if exists countries_select_anon_active on countries;
create policy countries_select_anon_active
  on countries for select to anon
  using (active);

-- Vehicles: city-scoped admins must not read vehicles outside their cities.
drop policy if exists vehicles_select_admin on vehicles;
create policy vehicles_select_admin
  on vehicles for select to authenticated
  using (
    is_admin()
    and exists (
      select 1
      from driver_vehicles dv
      join drivers d on d.id = dv.driver_id
      where dv.vehicle_id = vehicles.id
        and admin_can_access_city(d.city_id)
    )
  );

-- city_admin dashboard reads journeys via KPI paths.
drop policy if exists journeys_select_admin on journeys;
create policy journeys_select_admin
  on journeys for select to authenticated
  using (
    has_admin_role(array[
      'superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance', 'analyst', 'city_admin'
    ])
    and admin_can_access_city(city_id)
  );
