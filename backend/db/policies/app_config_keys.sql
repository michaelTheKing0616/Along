-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.app_config_keys
-- RLS enabled: true
-- RLS forced: false

create policy app_config_keys_select_authenticated
  on app_config_keys for select to authenticated
  using (true);

create policy app_config_keys_write_superadmin
  on app_config_keys for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text]))
  with check (has_admin_role(ARRAY['superadmin'::text]));
