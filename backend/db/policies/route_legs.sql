-- doc 02 §4 / §16: select all authenticated; write admin in route city scope.
create policy route_legs_select_authenticated
  on route_legs for select to authenticated using (true);

create policy route_legs_write_admin
  on route_legs for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );
