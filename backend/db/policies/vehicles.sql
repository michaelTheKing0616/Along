-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.vehicles
-- RLS enabled: true
-- RLS forced: false

create policy vehicles_select_admin
  on vehicles for select to authenticated
  using (is_admin());

create policy vehicles_select_linked_driver
  on vehicles for select to authenticated
  using (EXISTS ( SELECT 1
   FROM (driver_vehicles dv
     JOIN drivers d ON ((d.id = dv.driver_id)))
  WHERE ((dv.vehicle_id = vehicles.id) AND dv.active AND (d.id = auth.uid()))));

create policy vehicles_select_owner
  on vehicles for select to authenticated
  using (owner_profile_id = auth.uid());
