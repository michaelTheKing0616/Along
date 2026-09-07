-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.incidents
-- RLS enabled: true
-- RLS forced: false

create policy incidents_no_client_write
  on incidents for all to authenticated
  using (false)
  with check (false);

create policy incidents_select_admin
  on incidents for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text]) AND ((trip_id IS NULL) OR admin_can_access_city(( SELECT j.city_id
   FROM (trips t
     JOIN journeys j ON ((j.id = t.journey_id)))
  WHERE (t.id = incidents.trip_id)))));

create policy incidents_select_reporter
  on incidents for select to authenticated
  using (reported_by = auth.uid());
