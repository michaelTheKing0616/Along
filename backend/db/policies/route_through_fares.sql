-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.route_through_fares
-- RLS enabled: true
-- RLS forced: false

create policy route_through_fares_select_authenticated
  on route_through_fares for select to authenticated
  using (true);

create policy route_through_fares_write_admin
  on route_through_fares for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT r.city_id
   FROM routes r
  WHERE (r.id = route_through_fares.route_id))))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT r.city_id
   FROM routes r
  WHERE (r.id = route_through_fares.route_id))));
