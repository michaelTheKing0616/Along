-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.field_reconciliations
-- RLS enabled: true
-- RLS forced: false

create policy field_reconciliations_select_admin
  on field_reconciliations for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT fs.city_id
   FROM field_submissions fs
  WHERE (fs.id = field_reconciliations.submission_a))));

create policy field_reconciliations_update_admin
  on field_reconciliations for update to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT fs.city_id
   FROM field_submissions fs
  WHERE (fs.id = field_reconciliations.submission_a))))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text]) AND admin_can_access_city(( SELECT fs.city_id
   FROM field_submissions fs
  WHERE (fs.id = field_reconciliations.submission_a))));
