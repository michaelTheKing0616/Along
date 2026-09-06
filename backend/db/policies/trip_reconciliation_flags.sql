-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_reconciliation_flags
-- RLS enabled: true
-- RLS forced: false

create policy trip_reconciliation_flags_no_client_write
  on trip_reconciliation_flags for all to authenticated
  using (false)
  with check (false);

create policy trip_reconciliation_flags_select_admin
  on trip_reconciliation_flags for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = trip_reconciliation_flags.driver_id))));
