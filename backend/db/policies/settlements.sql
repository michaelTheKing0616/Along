-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.settlements
-- RLS enabled: true
-- RLS forced: false

create policy settlements_no_client_write
  on settlements for all to authenticated
  using (false)
  with check (false);

create policy settlements_select_admin
  on settlements for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = settlements.driver_id))));

create policy settlements_select_agent
  on settlements for select to authenticated
  using ((agent_id IS NOT NULL) AND (agent_id IN ( SELECT sa.id
   FROM settlement_agents sa
  WHERE ((sa.profile_id = auth.uid()) AND sa.active))));

create policy settlements_select_own
  on settlements for select to authenticated
  using (driver_id = auth.uid());
