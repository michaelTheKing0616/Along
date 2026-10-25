-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_ride_rules
-- RLS enabled: true
-- RLS forced: false

create policy driver_ride_rules_read
  on driver_ride_rules for select to authenticated
  using (enabled OR (driver_id = auth.uid()) OR is_admin());
