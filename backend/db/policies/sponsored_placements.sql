-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.sponsored_placements
-- RLS enabled: true
-- RLS forced: false

create policy sponsored_placements_no_client_write
  on sponsored_placements for all to authenticated
  using (false)
  with check (false);

create policy sponsored_placements_select_admin
  on sponsored_placements for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text, 'analyst'::text]) AND (has_admin_role(ARRAY['superadmin'::text]) OR (deployment_id = ( SELECT a.deployment_id
   FROM admin_users a
  WHERE ((a.id = auth.uid()) AND (a.disabled_at IS NULL))))));
