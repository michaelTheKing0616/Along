-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.fare_observations
-- RLS enabled: true
-- RLS forced: false

create policy fare_observations_owner
  on fare_observations for select to authenticated
  using ((rider_id = auth.uid()) OR is_admin());
