-- vehicles: owner or linked driver select; insert via RPC only (no client write policies).
create policy vehicles_select_owner
  on vehicles for select to authenticated
  using (owner_profile_id = auth.uid());
create policy vehicles_select_linked_driver
  on vehicles for select to authenticated
  using (
    exists (
      select 1 from driver_vehicles dv
      join drivers d on d.id = dv.driver_id
      where dv.vehicle_id = vehicles.id
        and dv.active
        and d.id = auth.uid()
    )
  );
create policy vehicles_select_admin
  on vehicles for select to authenticated
  using (is_admin());
