-- doc 02 §4 / §16: own-row select; insert via RPC; admin select in scope.
create policy fare_corrections_select_own
  on fare_corrections for select to authenticated
  using (submitted_by = auth.uid());

create policy fare_corrections_select_admin
  on fare_corrections for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']));
