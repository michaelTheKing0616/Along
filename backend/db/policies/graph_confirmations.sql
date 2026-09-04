-- doc 02 §4 / §16: insert via RPC only; select admin/analyst.
create policy graph_confirmations_select_admin
  on graph_confirmations for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'analyst']));
