-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.coverage_gap_reports
-- RLS enabled: true
-- RLS forced: false

create policy coverage_gap_reports_no_client_write
  on coverage_gap_reports for all to authenticated
  using (false)
  with check (false);

create policy coverage_gap_reports_select_admin
  on coverage_gap_reports for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]));
