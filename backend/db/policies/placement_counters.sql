-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.placement_counters
-- RLS enabled: true
-- RLS forced: false

create policy placement_counters_no_client_write
  on placement_counters for all to authenticated
  using (false)
  with check (false);

create policy placement_counters_select_admin
  on placement_counters for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text, 'analyst'::text]) AND (EXISTS ( SELECT 1
   FROM (sponsored_placements sp
     JOIN admin_users au ON (((au.id = auth.uid()) AND (au.disabled_at IS NULL))))
  WHERE ((sp.id = placement_counters.placement_id) AND (sp.deployment_id = au.deployment_id)))));
