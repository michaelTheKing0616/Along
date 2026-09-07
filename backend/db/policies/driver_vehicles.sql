-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_vehicles
-- RLS enabled: true
-- RLS forced: false

create policy driver_vehicles_select_admin
  on driver_vehicles for select to authenticated
  using (is_admin() AND (EXISTS ( SELECT 1
   FROM drivers d
  WHERE ((d.id = driver_vehicles.driver_id) AND admin_can_access_city(d.city_id)))));

create policy driver_vehicles_select_own
  on driver_vehicles for select to authenticated
  using (driver_id = auth.uid());

create policy driver_vehicles_write_own
  on driver_vehicles for all to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());
