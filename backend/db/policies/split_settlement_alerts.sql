-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.split_settlement_alerts
-- RLS enabled: true
-- RLS forced: false

create policy split_settlement_alerts_no_client_write
  on split_settlement_alerts for all to authenticated
  using (false)
  with check (false);

create policy split_settlement_alerts_select_finance
  on split_settlement_alerts for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]));
