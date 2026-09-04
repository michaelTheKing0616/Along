-- doc 02 §2.1 / §16: select all authenticated; write superadmin/ops_lead only.
create policy deployments_select_authenticated
  on deployments for select to authenticated using (true);

create policy deployments_write_admin
  on deployments for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));
