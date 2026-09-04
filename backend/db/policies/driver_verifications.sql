-- driver_verifications: driver select own; insert/update via RPC; verifier/ops select.
create policy driver_verifications_select_own
  on driver_verifications for select to authenticated
  using (driver_id = auth.uid());
create policy driver_verifications_select_admin
  on driver_verifications for select to authenticated
  using (has_admin_role(array['verifier', 'ops_lead', 'ops_agent', 'superadmin']));
