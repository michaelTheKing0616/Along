-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_handshakes
-- RLS enabled: true
-- RLS forced: false

create policy trip_handshakes_select_party
  on trip_handshakes for select to authenticated
  using (EXISTS ( SELECT 1
   FROM trips t
  WHERE ((t.id = trip_handshakes.trip_id) AND (t.status = ANY (ARRAY['accepted'::trip_status, 'boarded'::trip_status])) AND ((t.rider_id = ( SELECT auth.uid() AS uid)) OR (t.driver_id = ( SELECT auth.uid() AS uid))))));
