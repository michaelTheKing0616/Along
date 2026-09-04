-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.transfer_points
-- RLS enabled: true
-- RLS forced: false

create policy transfer_points_select_authenticated
  on transfer_points for select to authenticated
  using (true);

create policy transfer_points_write_admin
  on transfer_points for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT r.city_id
   FROM routes r
  WHERE (r.id = transfer_points.route_id))))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT r.city_id
   FROM routes r
  WHERE (r.id = transfer_points.route_id))));
