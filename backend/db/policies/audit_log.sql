-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.audit_log
-- RLS enabled: true
-- RLS forced: false

create policy audit_log_all_superadmin
  on audit_log for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text]))
  with check (has_admin_role(ARRAY['superadmin'::text]));

create policy audit_log_select_finance
  on audit_log for select to authenticated
  using (has_admin_role(ARRAY['finance'::text]));

create policy audit_log_select_ops_lead
  on audit_log for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]));
