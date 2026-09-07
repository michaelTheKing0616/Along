-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.job_runs
-- RLS enabled: true
-- RLS forced: false

create policy job_runs_no_client_write
  on job_runs for all to authenticated
  using (false)
  with check (false);

create policy job_runs_select_admin
  on job_runs for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]));
