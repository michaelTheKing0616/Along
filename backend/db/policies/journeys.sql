-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.journeys
-- RLS enabled: true
-- RLS forced: false

create policy journeys_no_client_write
  on journeys for all to authenticated
  using (false)
  with check (false);

create policy journeys_select_admin
  on journeys for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text, 'analyst'::text, 'city_admin'::text]) AND admin_can_access_city(city_id));

create policy journeys_select_own
  on journeys for select to authenticated
  using (rider_id = auth.uid());
