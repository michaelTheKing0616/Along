-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_route_stops
-- RLS enabled: true
-- RLS forced: false

create policy driver_route_stops_delete_own
  on driver_route_stops for delete to authenticated
  using (EXISTS ( SELECT 1
   FROM driver_route_profiles p
  WHERE ((p.id = driver_route_stops.profile_id) AND (p.driver_id = auth.uid()))));

create policy driver_route_stops_insert_own
  on driver_route_stops for insert to authenticated
  with check (EXISTS ( SELECT 1
   FROM driver_route_profiles p
  WHERE ((p.id = driver_route_stops.profile_id) AND (p.driver_id = auth.uid()))));

create policy driver_route_stops_select_admin
  on driver_route_stops for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM (driver_route_profiles p
     JOIN drivers d ON ((d.id = p.driver_id)))
  WHERE (p.id = driver_route_stops.profile_id))));

create policy driver_route_stops_select_own
  on driver_route_stops for select to authenticated
  using (EXISTS ( SELECT 1
   FROM driver_route_profiles p
  WHERE ((p.id = driver_route_stops.profile_id) AND (p.driver_id = auth.uid()))));

create policy driver_route_stops_update_own
  on driver_route_stops for update to authenticated
  using (EXISTS ( SELECT 1
   FROM driver_route_profiles p
  WHERE ((p.id = driver_route_stops.profile_id) AND (p.driver_id = auth.uid()))))
  with check (EXISTS ( SELECT 1
   FROM driver_route_profiles p
  WHERE ((p.id = driver_route_stops.profile_id) AND (p.driver_id = auth.uid()))));
