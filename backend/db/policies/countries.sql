-- doc 02 §2.1 / §16: select all authenticated; write superadmin/ops_lead only.
create policy countries_select_authenticated
  on countries for select to authenticated using (true);

create policy countries_write_admin
  on countries for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));
