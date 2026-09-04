-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.field_submissions
-- RLS enabled: true
-- RLS forced: false

create policy field_submissions_insert_agent
  on field_submissions for insert to authenticated
  with check ((scout_profile_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM field_agents fa
  WHERE ((fa.id = auth.uid()) AND (fa.city_id = field_submissions.city_id) AND fa.active))));

create policy field_submissions_select_admin
  on field_submissions for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id));

create policy field_submissions_select_agent
  on field_submissions for select to authenticated
  using (scout_profile_id = auth.uid());

create policy field_submissions_update_admin
  on field_submissions for update to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(city_id));
