-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_presence
-- RLS enabled: true
-- RLS forced: false

create policy driver_presence_no_client_write
  on driver_presence for all to authenticated
  using (false)
  with check (false);

create policy driver_presence_select_admin
  on driver_presence for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = driver_presence.driver_id))));

create policy driver_presence_select_own
  on driver_presence for select to authenticated
  using (driver_id = auth.uid());
