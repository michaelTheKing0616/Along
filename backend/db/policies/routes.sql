-- doc 02 §4 / §16: select all authenticated; write admin in city scope.
create policy routes_select_authenticated
  on routes for select to authenticated using (true);

create policy routes_write_admin
  on routes for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));
