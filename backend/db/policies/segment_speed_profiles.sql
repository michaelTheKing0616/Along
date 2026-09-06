-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.segment_speed_profiles
-- RLS enabled: true
-- RLS forced: false

create policy segment_speed_profiles_no_client_write
  on segment_speed_profiles for all to authenticated
  using (false)
  with check (false);

create policy segment_speed_profiles_select_admin
  on segment_speed_profiles for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
