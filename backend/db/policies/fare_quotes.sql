-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.fare_quotes
-- RLS enabled: true
-- RLS forced: false

create policy fare_quotes_no_client_delete
  on fare_quotes for delete to authenticated
  using (false);

create policy fare_quotes_no_client_insert
  on fare_quotes for insert to authenticated
  with check (false);

create policy fare_quotes_no_client_update
  on fare_quotes for update to authenticated
  using (false);

create policy fare_quotes_select_admin
  on fare_quotes for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text, 'analyst'::text]));

create policy fare_quotes_select_driver
  on fare_quotes for select to authenticated
  using (driver_id = auth.uid());

create policy fare_quotes_select_rider
  on fare_quotes for select to authenticated
  using (rider_id = auth.uid());
