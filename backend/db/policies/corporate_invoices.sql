-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.corporate_invoices
-- RLS enabled: true
-- RLS forced: false

create policy corporate_invoices_no_client_write
  on corporate_invoices for all to authenticated
  using (false)
  with check (false);

create policy corporate_invoices_select_admin
  on corporate_invoices for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text]) AND (EXISTS ( SELECT 1
   FROM (corporate_accounts ca
     JOIN admin_users au ON (((au.id = auth.uid()) AND (au.disabled_at IS NULL))))
  WHERE ((ca.id = corporate_invoices.corporate_account_id) AND (ca.deployment_id = au.deployment_id)))));

create policy corporate_invoices_select_corporate_admin
  on corporate_invoices for select to authenticated
  using (corporate_account_id = admin_corporate_account_id());
