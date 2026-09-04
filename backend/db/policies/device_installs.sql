-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.device_installs
-- RLS enabled: true
-- RLS forced: false

create policy device_installs_select_admin
  on device_installs for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text, 'safety'::text, 'analyst'::text]));

create policy device_installs_select_own
  on device_installs for select to authenticated
  using (profile_id = auth.uid());

create policy device_installs_update_own
  on device_installs for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy device_installs_write_own
  on device_installs for insert to authenticated
  with check (profile_id = auth.uid());
