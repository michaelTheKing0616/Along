-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_day_plans
-- RLS enabled: true
-- RLS forced: false

create policy driver_day_plans_read
  on driver_day_plans for select to authenticated
  using ((driver_id = auth.uid()) OR is_admin());
