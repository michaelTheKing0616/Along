-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.data_sources
-- RLS enabled: true
-- RLS forced: false

create policy data_sources_select_authenticated
  on data_sources for select to authenticated
  using (true);

create policy data_sources_write_admin
  on data_sources for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]));
