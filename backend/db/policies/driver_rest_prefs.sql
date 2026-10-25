-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_rest_prefs
-- RLS enabled: true
-- RLS forced: false

create policy driver_rest_prefs_owner
  on driver_rest_prefs for select to authenticated
  using ((driver_id = auth.uid()) OR is_admin());
