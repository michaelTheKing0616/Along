-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.vehicle_seat_states
-- RLS enabled: true
-- RLS forced: false

create policy vehicle_seat_states_read
  on vehicle_seat_states for select to authenticated
  using (EXISTS ( SELECT 1
   FROM vehicle_layouts l
  WHERE ((l.id = vehicle_seat_states.layout_id) AND (l.is_active OR (l.driver_id = auth.uid()) OR is_admin()))));
