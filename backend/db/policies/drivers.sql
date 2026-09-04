-- drivers: owner select/insert/update (protected cols via protect_driver_columns()); admins select in city scope.
create policy drivers_select_own
  on drivers for select to authenticated
  using (id = auth.uid());
create policy drivers_insert_own
  on drivers for insert to authenticated
  with check (id = auth.uid());
create policy drivers_update_own
  on drivers for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
create policy drivers_select_admin
  on drivers for select to authenticated
  using (is_admin() and admin_can_access_city(city_id));
