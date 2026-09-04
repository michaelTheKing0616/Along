-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.app_config
-- RLS enabled: true
-- RLS forced: false

create policy app_config_select_authenticated
  on app_config for select to authenticated
  using (true);

create policy app_config_write_admin
  on app_config for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]));
