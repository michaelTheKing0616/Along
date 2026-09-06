-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_ledger_entries
-- RLS enabled: true
-- RLS forced: false

create policy driver_ledger_entries_no_client_write
  on driver_ledger_entries for all to authenticated
  using (false)
  with check (false);

create policy driver_ledger_entries_select_admin
  on driver_ledger_entries for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = driver_ledger_entries.driver_id))));

create policy driver_ledger_entries_select_own
  on driver_ledger_entries for select to authenticated
  using (driver_id = auth.uid());
