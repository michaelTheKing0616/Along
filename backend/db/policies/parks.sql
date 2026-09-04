-- doc 02 §4 / §16: select all authenticated; write admin in city scope.
create policy parks_select_authenticated
  on parks for select to authenticated using (true);

create policy parks_write_admin
  on parks for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));
