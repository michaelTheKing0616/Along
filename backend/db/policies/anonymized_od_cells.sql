-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.anonymized_od_cells
-- RLS enabled: true
-- RLS forced: false

create policy anonymized_od_cells_no_client_write
  on anonymized_od_cells for all to authenticated
  using (false)
  with check (false);

create policy anonymized_od_cells_select_admin
  on anonymized_od_cells for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
