-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.operator_accounts
-- RLS enabled: true
-- RLS forced: false

create policy operator_accounts_no_client_write
  on operator_accounts for all to authenticated
  using (false)
  with check (false);

create policy operator_accounts_select_admin
  on operator_accounts for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND (has_admin_role(ARRAY['superadmin'::text]) OR (deployment_id = ( SELECT a.deployment_id
   FROM admin_users a
  WHERE ((a.id = auth.uid()) AND (a.disabled_at IS NULL))))));

create policy operator_accounts_select_operator_viewer
  on operator_accounts for select to authenticated
  using (id = admin_operator_account_id());
