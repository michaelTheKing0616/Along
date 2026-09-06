-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.pending_ledger_adjustments
-- RLS enabled: true
-- RLS forced: false

create policy pending_ledger_adjustments_no_client_write
  on pending_ledger_adjustments for all to authenticated
  using (false)
  with check (false);

create policy pending_ledger_adjustments_select_admin
  on pending_ledger_adjustments for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = pending_ledger_adjustments.driver_id))));
