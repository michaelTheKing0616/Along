-- doc 02 §14 / §16: field agents — self read; admin read/write in city scope.
create policy field_agents_select_admin
  on field_agents for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy field_agents_select_self
  on field_agents for select to authenticated
  using (id = auth.uid());

create policy field_agents_write_admin
  on field_agents for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));
