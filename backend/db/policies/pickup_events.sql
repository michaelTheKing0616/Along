-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.pickup_events
-- RLS enabled: true
-- RLS forced: false

create policy pickup_events_read
  on pickup_events for select to authenticated
  using (true);
