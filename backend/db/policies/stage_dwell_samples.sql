-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.stage_dwell_samples
-- RLS enabled: true
-- RLS forced: false

create policy stage_dwell_samples_no_client_write
  on stage_dwell_samples for all to authenticated
  using (false)
  with check (false);

create policy stage_dwell_samples_select_admin
  on stage_dwell_samples for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
