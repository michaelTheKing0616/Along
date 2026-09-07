-- P11-A-01: Authorization matrix drift fixes — private RLS coverage, city-scoped admin reads.

-- ---------------------------------------------------------------------------
-- Helper: admin may read a profile when tied to an in-scope city (driver, rider,
-- journey, field agent, fellow admin in deployment, or own row).
-- ---------------------------------------------------------------------------
create or replace function admin_can_access_profile(p_profile uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_profile = auth.uid()
    or exists (
      select 1
      from drivers d
      where d.id = p_profile
        and admin_can_access_city(d.city_id)
    )
    or exists (
      select 1
      from riders r
      where r.id = p_profile
        and r.home_city_id is not null
        and admin_can_access_city(r.home_city_id)
    )
    or exists (
      select 1
      from journeys j
      where j.rider_id = p_profile
        and admin_can_access_city(j.city_id)
    )
    or exists (
      select 1
      from field_agents fa
      where fa.id = p_profile
        and fa.active
        and admin_can_access_city(fa.city_id)
    )
    or exists (
      select 1
      from admin_users target
      join admin_users actor on actor.id = auth.uid()
      where target.id = p_profile
        and target.disabled_at is null
        and actor.disabled_at is null
        and (
          actor.role = 'superadmin'
          or (
            actor.role <> 'city_admin'
            and actor.deployment_id = target.deployment_id
          )
        )
    )
$$;

revoke all on function admin_can_access_profile(uuid) from public;
grant execute on function admin_can_access_profile(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- private.* service-only tables must still have RLS enabled (doc 02 §16).
-- ---------------------------------------------------------------------------
alter table private.guarantor_ack_tokens enable row level security;
alter table private.payment_webhook_raw enable row level security;
alter table private.qr_resolve_rate_buckets enable row level security;

-- ---------------------------------------------------------------------------
-- City-scoped admin reads (P9-A-01 gap: profiles/riders/verifications/fare_quotes;
-- city_admin on trips).
-- ---------------------------------------------------------------------------
drop policy if exists profiles_select_admin on profiles;
create policy profiles_select_admin
  on profiles for select to authenticated
  using (is_admin() and admin_can_access_profile(id));

drop policy if exists riders_select_admin on riders;
create policy riders_select_admin
  on riders for select to authenticated
  using (
    is_admin()
    and (
      (home_city_id is not null and admin_can_access_city(home_city_id))
      or exists (
        select 1
        from journeys j
        where j.rider_id = riders.id
          and admin_can_access_city(j.city_id)
      )
    )
  );

drop policy if exists driver_verifications_select_admin on driver_verifications;
create policy driver_verifications_select_admin
  on driver_verifications for select to authenticated
  using (
    has_admin_role(array['verifier', 'ops_lead', 'ops_agent', 'superadmin'])
    and exists (
      select 1
      from drivers d
      where d.id = driver_verifications.driver_id
        and admin_can_access_city(d.city_id)
    )
  );

drop policy if exists driver_verifications_update_admin on driver_verifications;
create policy driver_verifications_update_admin
  on driver_verifications for update to authenticated
  using (
    has_admin_role(array['verifier', 'ops_lead', 'superadmin'])
    and exists (
      select 1
      from drivers d
      where d.id = driver_verifications.driver_id
        and admin_can_access_city(d.city_id)
    )
  )
  with check (
    has_admin_role(array['verifier', 'ops_lead', 'superadmin'])
    and exists (
      select 1
      from drivers d
      where d.id = driver_verifications.driver_id
        and admin_can_access_city(d.city_id)
    )
  );

drop policy if exists fare_quotes_select_admin on fare_quotes;
create policy fare_quotes_select_admin
  on fare_quotes for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'finance', 'analyst'])
    and (
      (
        driver_id is not null
        and exists (
          select 1
          from drivers d
          where d.id = fare_quotes.driver_id
            and admin_can_access_city(d.city_id)
        )
      )
      or (
        rider_id is not null
        and exists (
          select 1
          from journeys j
          where j.rider_id = fare_quotes.rider_id
            and admin_can_access_city(j.city_id)
        )
      )
    )
  );

drop policy if exists trips_select_admin on trips;
create policy trips_select_admin
  on trips for select to authenticated
  using (
    has_admin_role(array[
      'superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance', 'analyst', 'city_admin'
    ])
    and admin_can_access_city((
      select j.city_id
      from journeys j
      where j.id = trips.journey_id
    ))
  );
