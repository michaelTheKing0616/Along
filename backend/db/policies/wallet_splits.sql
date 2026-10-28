-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.wallet_splits
-- RLS enabled: true
-- RLS forced: false

create policy wallet_splits_select_party
  on wallet_splits for select to authenticated
  using ((requester_id = auth.uid()) OR (payer_id = auth.uid()) OR is_admin());
