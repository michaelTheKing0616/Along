-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.api_usage
-- RLS enabled: true
-- RLS forced: false

create policy api_usage_no_client_write
  on api_usage for all to authenticated
  using (false)
  with check (false);

create policy api_usage_select_admin
  on api_usage for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]));
