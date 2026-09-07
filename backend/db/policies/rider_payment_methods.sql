-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.rider_payment_methods
-- RLS enabled: true
-- RLS forced: false

create policy rider_payment_methods_no_client_write
  on rider_payment_methods for all to authenticated
  using (false)
  with check (false);

create policy rider_payment_methods_select_own
  on rider_payment_methods for select to authenticated
  using (rider_id = auth.uid());
