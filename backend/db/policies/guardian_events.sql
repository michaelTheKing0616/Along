-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.guardian_events
-- RLS enabled: true
-- RLS forced: false

create policy guardian_events_read
  on guardian_events for select to authenticated
  using ((rider_id = auth.uid()) OR is_admin() OR (EXISTS ( SELECT 1
   FROM trips t
  WHERE ((t.id = guardian_events.trip_id) AND (t.driver_id = auth.uid())))));
