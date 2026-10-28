-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.wallet_entries
-- RLS enabled: true
-- RLS forced: false

create policy wallet_entries_select_own
  on wallet_entries for select to authenticated
  using (is_admin() OR (EXISTS ( SELECT 1
   FROM wallet_accounts a
  WHERE ((a.id = wallet_entries.account_id) AND (a.owner_id = auth.uid())))));
