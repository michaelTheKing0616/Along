-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_pins
-- RLS enabled: true
-- RLS forced: false

create policy trip_pins_no_client_write
  on trip_pins for all to authenticated
  using (false)
  with check (false);

create policy trip_pins_select_rider
  on trip_pins for select to authenticated
  using (EXISTS ( SELECT 1
   FROM trips t
  WHERE ((t.id = trip_pins.trip_id) AND (t.rider_id = ( SELECT auth.uid() AS uid)))));
