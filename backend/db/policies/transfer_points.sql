-- doc 02 §4 / §16: select all authenticated; write admin in route city scope.
create policy transfer_points_select_authenticated
  on transfer_points for select to authenticated using (true);

create policy transfer_points_write_admin
  on transfer_points for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );
