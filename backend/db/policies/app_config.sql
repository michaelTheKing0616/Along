-- doc 02 §2.3 / §16: select all authenticated; write superadmin/ops_lead only.
create policy app_config_select_authenticated
  on app_config for select to authenticated using (true);

create policy app_config_write_admin
  on app_config for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));
