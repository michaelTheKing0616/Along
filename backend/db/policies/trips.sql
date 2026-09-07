-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trips
-- RLS enabled: true
-- RLS forced: false

create policy trips_no_client_write
  on trips for all to authenticated
  using (false)
  with check (false);

create policy trips_select_admin
  on trips for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text, 'analyst'::text, 'city_admin'::text]) AND admin_can_access_city(( SELECT j.city_id
   FROM journeys j
  WHERE (j.id = trips.journey_id))));

create policy trips_select_driver
  on trips for select to authenticated
  using (driver_id = auth.uid());

create policy trips_select_rider
  on trips for select to authenticated
  using (rider_id = auth.uid());
