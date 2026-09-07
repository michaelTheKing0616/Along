-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.cities
-- RLS enabled: true
-- RLS forced: false

create policy cities_select_authenticated
  on cities for select to authenticated
  using (city_in_user_deployment(id));

create policy cities_write_admin
  on cities for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]) AND admin_can_access_city(id))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]) AND admin_can_access_city(id));
