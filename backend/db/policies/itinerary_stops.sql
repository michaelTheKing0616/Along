-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.itinerary_stops
-- RLS enabled: true
-- RLS forced: false

create policy itinerary_stops_no_client_write
  on itinerary_stops for all to authenticated
  using (false)
  with check (false);

create policy itinerary_stops_select_own
  on itinerary_stops for select to authenticated
  using (EXISTS ( SELECT 1
   FROM itineraries i
  WHERE ((i.id = itinerary_stops.itinerary_id) AND (i.rider_id = auth.uid()))));
