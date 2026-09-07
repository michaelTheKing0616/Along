-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.road_geometry_corrections
-- RLS enabled: true
-- RLS forced: false

create policy road_geometry_corrections_no_client_write
  on road_geometry_corrections for all to authenticated
  using (false)
  with check (false);

create policy road_geometry_corrections_select_admin
  on road_geometry_corrections for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
