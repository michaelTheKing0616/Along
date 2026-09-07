-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.operator_members
-- RLS enabled: true
-- RLS forced: false

create policy operator_members_no_client_write
  on operator_members for all to authenticated
  using (false)
  with check (false);

create policy operator_members_select_admin
  on operator_members for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND (EXISTS ( SELECT 1
   FROM (operator_accounts oa
     JOIN admin_users au ON (((au.id = auth.uid()) AND (au.disabled_at IS NULL))))
  WHERE ((oa.id = operator_members.operator_account_id) AND (oa.deployment_id = au.deployment_id)))));

create policy operator_members_select_operator_viewer
  on operator_members for select to authenticated
  using (operator_account_id = admin_operator_account_id());
