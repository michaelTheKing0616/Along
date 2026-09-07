-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.corridors
-- RLS enabled: true
-- RLS forced: false

create policy corridors_select_authenticated
  on corridors for select to authenticated
  using (city_in_user_deployment(city_id));

create policy corridors_write_admin
  on corridors for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]) AND admin_can_access_city(city_id))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]) AND admin_can_access_city(city_id));
