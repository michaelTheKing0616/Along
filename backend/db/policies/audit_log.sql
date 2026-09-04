-- doc 02 §15 / §16: append-only; ops_lead/finance select; superadmin all; inserts via audit_admin_write() only.
create policy audit_log_select_ops_lead
  on audit_log for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']));

create policy audit_log_select_finance
  on audit_log for select to authenticated
  using (has_admin_role(array['finance']));

create policy audit_log_all_superadmin
  on audit_log for all to authenticated
  using (has_admin_role(array['superadmin']))
  with check (has_admin_role(array['superadmin']));
