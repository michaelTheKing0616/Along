-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.routes
-- RLS enabled: true
-- RLS forced: false

create policy routes_select_authenticated
  on routes for select to authenticated
  using (true);

create policy routes_write_admin
  on routes for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id));
