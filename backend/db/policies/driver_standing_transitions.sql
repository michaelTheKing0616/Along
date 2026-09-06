-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_standing_transitions
-- RLS enabled: true
-- RLS forced: false

create policy driver_standing_transitions_no_client_write
  on driver_standing_transitions for all to authenticated
  using (false)
  with check (false);

create policy driver_standing_transitions_select_admin
  on driver_standing_transitions for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = driver_standing_transitions.driver_id))));

create policy driver_standing_transitions_select_own
  on driver_standing_transitions for select to authenticated
  using (driver_id = auth.uid());
