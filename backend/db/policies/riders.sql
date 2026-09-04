-- riders: owner select/insert/update; admins select in scope.
create policy riders_select_own
  on riders for select to authenticated
  using (id = auth.uid());
create policy riders_insert_own
  on riders for insert to authenticated
  with check (id = auth.uid());
create policy riders_update_own
  on riders for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
create policy riders_select_admin
  on riders for select to authenticated
  using (is_admin());
