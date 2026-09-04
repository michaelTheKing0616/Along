-- admin_users stub (0001): no client access; helpers use security definer.
create policy admin_users_no_client_access
  on admin_users for all to authenticated
  using (false)
  with check (false);
