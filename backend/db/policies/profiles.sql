-- profiles: owner select/update; admins select in scope.
create policy profiles_select_own
  on profiles for select to authenticated
  using (id = auth.uid());
create policy profiles_update_own
  on profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
create policy profiles_select_admin
  on profiles for select to authenticated
  using (is_admin());
