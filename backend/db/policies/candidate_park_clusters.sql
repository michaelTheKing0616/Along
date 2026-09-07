-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.candidate_park_clusters
-- RLS enabled: true
-- RLS forced: false

create policy candidate_park_clusters_no_client_write
  on candidate_park_clusters for all to authenticated
  using (false)
  with check (false);

create policy candidate_park_clusters_select_admin
  on candidate_park_clusters for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
