-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_shares
-- RLS enabled: true
-- RLS forced: false

create policy trip_shares_no_client_write
  on trip_shares for all to authenticated
  using (false)
  with check (false);

create policy trip_shares_select_own
  on trip_shares for select to authenticated
  using (rider_id = auth.uid());
