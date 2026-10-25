-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.vehicle_layouts
-- RLS enabled: true
-- RLS forced: false

create policy vehicle_layouts_read
  on vehicle_layouts for select to authenticated
  using (is_active OR (driver_id = auth.uid()) OR is_admin());
