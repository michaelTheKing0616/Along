-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.field_agents
-- RLS enabled: true
-- RLS forced: false

create policy field_agents_select_admin
  on field_agents for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id));

create policy field_agents_select_self
  on field_agents for select to authenticated
  using (id = auth.uid());

create policy field_agents_write_admin
  on field_agents for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id));
