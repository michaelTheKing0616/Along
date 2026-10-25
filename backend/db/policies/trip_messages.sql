-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_messages
-- RLS enabled: true
-- RLS forced: false

create policy trip_messages_party
  on trip_messages for select to authenticated
  using (is_admin() OR (EXISTS ( SELECT 1
   FROM trips t
  WHERE ((t.id = trip_messages.trip_id) AND ((t.rider_id = auth.uid()) OR (t.driver_id = auth.uid()))))));
