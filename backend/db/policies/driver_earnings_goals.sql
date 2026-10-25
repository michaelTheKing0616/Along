-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_earnings_goals
-- RLS enabled: true
-- RLS forced: false

create policy driver_earnings_goals_owner
  on driver_earnings_goals for select to authenticated
  using ((driver_id = auth.uid()) OR is_admin());
