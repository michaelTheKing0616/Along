-- doc 02 §7 / §16: rider/driver select own; insert only via resolve_fare (SECURITY DEFINER); admin select.
create policy fare_quotes_select_rider
  on fare_quotes for select to authenticated
  using (rider_id = auth.uid());

create policy fare_quotes_select_driver
  on fare_quotes for select to authenticated
  using (driver_id = auth.uid());

create policy fare_quotes_select_admin
  on fare_quotes for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'finance', 'analyst']));

create policy fare_quotes_no_client_insert
  on fare_quotes for insert to authenticated
  with check (false);

create policy fare_quotes_no_client_update
  on fare_quotes for update to authenticated
  using (false);

create policy fare_quotes_no_client_delete
  on fare_quotes for delete to authenticated
  using (false);
