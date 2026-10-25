-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.live_segment_observations
-- RLS enabled: true
-- RLS forced: false

create policy live_segment_observations_no_client_write
  on live_segment_observations for all to authenticated
  using (false)
  with check (false);

create policy live_segment_observations_select_admin
  on live_segment_observations for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
