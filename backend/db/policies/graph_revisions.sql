-- doc 02 §4 / §16: append-only; select admin/analyst; no client insert/update/delete.
create policy graph_revisions_select_admin
  on graph_revisions for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'analyst']));
