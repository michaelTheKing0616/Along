-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_verifications
-- RLS enabled: true
-- RLS forced: false

create policy driver_verifications_select_admin
  on driver_verifications for select to authenticated
  using (has_admin_role(ARRAY['verifier'::text, 'ops_lead'::text, 'ops_agent'::text, 'superadmin'::text]));

create policy driver_verifications_select_own
  on driver_verifications for select to authenticated
  using (driver_id = auth.uid());
