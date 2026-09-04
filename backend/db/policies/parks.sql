-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.parks
-- RLS enabled: true
-- RLS forced: false

create policy parks_select_authenticated
  on parks for select to authenticated
  using (true);

create policy parks_write_admin
  on parks for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id));
