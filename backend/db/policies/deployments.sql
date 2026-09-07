-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.deployments
-- RLS enabled: true
-- RLS forced: false

create policy deployments_select_authenticated
  on deployments for select to authenticated
  using ((auth_user_deployment_id() IS NULL) OR (id = auth_user_deployment_id()));

create policy deployments_write_admin
  on deployments for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]));
