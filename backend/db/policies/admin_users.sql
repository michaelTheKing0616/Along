-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.admin_users
-- RLS enabled: true
-- RLS forced: false

create policy admin_users_no_client_access
  on admin_users for all to authenticated
  using (false)
  with check (false);
