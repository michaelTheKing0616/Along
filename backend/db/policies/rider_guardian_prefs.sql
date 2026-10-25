-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.rider_guardian_prefs
-- RLS enabled: true
-- RLS forced: false

create policy rider_guardian_prefs_owner
  on rider_guardian_prefs for select to authenticated
  using ((profile_id = auth.uid()) OR is_admin());
