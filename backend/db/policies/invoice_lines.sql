-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.invoice_lines
-- RLS enabled: true
-- RLS forced: false

create policy invoice_lines_no_client_write
  on invoice_lines for all to authenticated
  using (false)
  with check (false);

create policy invoice_lines_select_admin
  on invoice_lines for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text]) AND (EXISTS ( SELECT 1
   FROM ((corporate_invoices ci
     JOIN corporate_accounts ca ON ((ca.id = ci.corporate_account_id)))
     JOIN admin_users au ON (((au.id = auth.uid()) AND (au.disabled_at IS NULL))))
  WHERE ((ci.id = invoice_lines.invoice_id) AND (ca.deployment_id = au.deployment_id)))));

create policy invoice_lines_select_corporate_admin
  on invoice_lines for select to authenticated
  using (EXISTS ( SELECT 1
   FROM corporate_invoices ci
  WHERE ((ci.id = invoice_lines.invoice_id) AND (ci.corporate_account_id = admin_corporate_account_id()))));
