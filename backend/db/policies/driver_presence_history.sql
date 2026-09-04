-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_presence_history
-- RLS enabled: true
-- RLS forced: false

create policy driver_presence_history_select_admin
  on driver_presence_history for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]));
