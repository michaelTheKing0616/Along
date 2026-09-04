-- doc 02 §2.1 / §16: select all authenticated; write superadmin/ops_lead + city scope.
create policy corridors_select_authenticated
  on corridors for select to authenticated using (true);

create policy corridors_write_admin
  on corridors for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(city_id));
