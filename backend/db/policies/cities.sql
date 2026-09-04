-- doc 02 §2.1 / §16: select all authenticated; write superadmin/ops_lead + city scope.
create policy cities_select_authenticated
  on cities for select to authenticated using (true);

create policy cities_write_admin
  on cities for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(id))
  with check (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(id));
