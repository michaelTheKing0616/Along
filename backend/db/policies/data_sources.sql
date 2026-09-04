-- doc 02 §4 / §16: select all authenticated; write superadmin/ops_lead/ops_agent.
create policy data_sources_select_authenticated
  on data_sources for select to authenticated using (true);

create policy data_sources_write_admin
  on data_sources for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']));
