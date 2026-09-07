-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.route_inference_candidates
-- RLS enabled: true
-- RLS forced: false

create policy route_inference_candidates_no_client_write
  on route_inference_candidates for all to authenticated
  using (false)
  with check (false);

create policy route_inference_candidates_select_admin
  on route_inference_candidates for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
