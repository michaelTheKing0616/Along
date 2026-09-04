-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.route_stages
-- RLS enabled: true
-- RLS forced: false

create policy route_stages_select_authenticated
  on route_stages for select to authenticated
  using (true);

create policy route_stages_write_admin
  on route_stages for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT r.city_id
   FROM routes r
  WHERE (r.id = route_stages.route_id))))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT r.city_id
   FROM routes r
  WHERE (r.id = route_stages.route_id))));
