-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.corporate_accounts
-- RLS enabled: true
-- RLS forced: false

create policy corporate_accounts_no_client_write
  on corporate_accounts for all to authenticated
  using (false)
  with check (false);

create policy corporate_accounts_select_admin
  on corporate_accounts for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text]) AND (has_admin_role(ARRAY['superadmin'::text]) OR (deployment_id = ( SELECT a.deployment_id
   FROM admin_users a
  WHERE ((a.id = auth.uid()) AND (a.disabled_at IS NULL))))));

create policy corporate_accounts_select_corporate_admin
  on corporate_accounts for select to authenticated
  using (id = admin_corporate_account_id());
