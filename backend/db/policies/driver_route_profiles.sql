-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_route_profiles
-- RLS enabled: true
-- RLS forced: false

create policy driver_route_profiles_delete_own
  on driver_route_profiles for delete to authenticated
  using (driver_id = auth.uid());

create policy driver_route_profiles_insert_own
  on driver_route_profiles for insert to authenticated
  with check (driver_id = auth.uid());

create policy driver_route_profiles_select_admin
  on driver_route_profiles for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = driver_route_profiles.driver_id))));

create policy driver_route_profiles_select_own
  on driver_route_profiles for select to authenticated
  using (driver_id = auth.uid());

create policy driver_route_profiles_update_own
  on driver_route_profiles for update to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());
