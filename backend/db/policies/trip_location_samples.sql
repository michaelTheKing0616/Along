-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_location_samples
-- RLS enabled: true
-- RLS forced: false

create policy trip_location_samples_no_client_select
  on trip_location_samples for select to authenticated
  using (false);

create policy trip_location_samples_no_client_write
  on trip_location_samples for all to authenticated
  using (false)
  with check (false);

create policy trip_location_samples_select_admin
  on trip_location_samples for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT j.city_id
   FROM (trips t
     JOIN journeys j ON ((j.id = t.journey_id)))
  WHERE (t.id = trip_location_samples.trip_id))));
