-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.ride_rule_presets
-- RLS enabled: true
-- RLS forced: false

create policy ride_rule_presets_read
  on ride_rule_presets for select to authenticated
  using (active OR is_admin());
