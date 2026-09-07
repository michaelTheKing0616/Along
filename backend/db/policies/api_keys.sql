-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.api_keys
-- RLS enabled: true
-- RLS forced: false

create policy api_keys_no_client_write
  on api_keys for all to authenticated
  using (false)
  with check (false);

create policy api_keys_select_admin
  on api_keys for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'finance'::text, 'ops_lead'::text, 'analyst'::text]));
