-- doc 02 §4 / §16: select all authenticated; write admin in route city scope.
create policy route_stages_select_authenticated
  on route_stages for select to authenticated using (true);

create policy route_stages_write_admin
  on route_stages for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );
