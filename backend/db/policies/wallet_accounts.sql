-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.wallet_accounts
-- RLS enabled: true
-- RLS forced: false

create policy wallet_accounts_select_own
  on wallet_accounts for select to authenticated
  using ((owner_id = auth.uid()) OR is_admin());
