-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.anonymized_od_exports
-- RLS enabled: true
-- RLS forced: false

create policy anonymized_od_exports_no_client_write
  on anonymized_od_exports for all to authenticated
  using (false)
  with check (false);

create policy anonymized_od_exports_select_admin
  on anonymized_od_exports for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text, 'analyst'::text]) AND admin_can_access_city(city_id));
