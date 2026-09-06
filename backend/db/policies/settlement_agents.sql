-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.settlement_agents
-- RLS enabled: true
-- RLS forced: false

create policy settlement_agents_no_client_write
  on settlement_agents for all to authenticated
  using (false)
  with check (false);

create policy settlement_agents_select_admin
  on settlement_agents for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(city_id));

create policy settlement_agents_select_own
  on settlement_agents for select to authenticated
  using (profile_id = auth.uid());
