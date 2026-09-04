-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_extensions
-- RLS enabled: true
-- RLS forced: false

create policy trip_extensions_no_client_write
  on trip_extensions for all to authenticated
  using (false)
  with check (false);

create policy trip_extensions_select_admin
  on trip_extensions for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text]) AND admin_can_access_city(( SELECT j.city_id
   FROM (trips t
     JOIN journeys j ON ((j.id = t.journey_id)))
  WHERE (t.id = trip_extensions.trip_id))));

create policy trip_extensions_select_party
  on trip_extensions for select to authenticated
  using (EXISTS ( SELECT 1
   FROM trips t
  WHERE ((t.id = trip_extensions.trip_id) AND ((t.rider_id = auth.uid()) OR (t.driver_id = auth.uid())))));
