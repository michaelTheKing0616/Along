-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.matched_traces
-- RLS enabled: true
-- RLS forced: false

create policy matched_traces_no_client_write
  on matched_traces for all to authenticated
  using (false)
  with check (false);

create policy matched_traces_select_admin
  on matched_traces for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND (EXISTS ( SELECT 1
   FROM (trips t
     JOIN journeys j ON ((j.id = t.journey_id)))
  WHERE ((t.id = matched_traces.trip_id) AND admin_can_access_city(j.city_id)))));
