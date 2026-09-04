-- doc 02 §2.2 / §16: select all authenticated; write superadmin/ops_lead only.
create policy mode_config_select_authenticated
  on mode_config for select to authenticated using (true);

create policy mode_config_write_admin
  on mode_config for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));
