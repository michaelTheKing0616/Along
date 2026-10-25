-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_rests
-- RLS enabled: true
-- RLS forced: false

create policy driver_rests_read
  on driver_rests for select to authenticated
  using ((driver_id = auth.uid()) OR is_admin());
