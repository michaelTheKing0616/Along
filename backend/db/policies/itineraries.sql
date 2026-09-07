-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.itineraries
-- RLS enabled: true
-- RLS forced: false

create policy itineraries_no_client_write
  on itineraries for all to authenticated
  using (false)
  with check (false);

create policy itineraries_select_own
  on itineraries for select to authenticated
  using (rider_id = auth.uid());
