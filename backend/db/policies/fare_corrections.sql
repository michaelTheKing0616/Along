-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.fare_corrections
-- RLS enabled: true
-- RLS forced: false

create policy fare_corrections_select_admin
  on fare_corrections for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]));

create policy fare_corrections_select_own
  on fare_corrections for select to authenticated
  using (submitted_by = auth.uid());
