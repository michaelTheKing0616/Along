-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.wallet_transactions
-- RLS enabled: true
-- RLS forced: false

create policy wallet_transactions_select_party
  on wallet_transactions for select to authenticated
  using ((initiator_id = auth.uid()) OR is_admin() OR (EXISTS ( SELECT 1
   FROM (wallet_entries e
     JOIN wallet_accounts a ON ((a.id = e.account_id)))
  WHERE ((e.transaction_id = wallet_transactions.id) AND (a.owner_id = auth.uid())))));
