-- driver_vehicles: driver owns rows linked to their profile id.
create policy driver_vehicles_select_own
  on driver_vehicles for select to authenticated
  using (driver_id = auth.uid());
create policy driver_vehicles_write_own
  on driver_vehicles for all to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());
