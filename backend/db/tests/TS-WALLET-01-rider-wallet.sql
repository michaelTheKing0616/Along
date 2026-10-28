-- pgTAP: TS-WALLET-01 — rider wallet double-entry ledger, RLS, idempotent RPCs (PR #27)
-- Tables: wallet_accounts, wallet_transactions, wallet_entries, wallet_splits
create extension if not exists pgtap;

begin;
select plan(30);

insert into auth.users (id, aud, role, phone) values
  ('3a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000027001'),
  ('3a100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000027002'),
  ('3a100000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000027003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('3a100000-0000-4000-8000-000000000001', '+2348000027001', 'Wallet Ada'),
  ('3a100000-0000-4000-8000-000000000002', '+2348000027002', 'Wallet Bayo'),
  ('3a100000-0000-4000-8000-000000000003', '+2348000027003', 'Wallet Chi')
on conflict (id) do update set display_name = excluded.display_name, phone_e164 = excluded.phone_e164;

-- Structure
select has_table('public', 'wallet_accounts', 'wallet_accounts exists');
select has_table('public', 'wallet_entries', 'wallet_entries exists');
select ok((select relrowsecurity from pg_class where oid = 'public.wallet_entries'::regclass), 'wallet_entries has RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.wallet_splits'::regclass), 'wallet_splits has RLS');
select ok(not has_table_privilege('authenticated', 'public.wallet_entries', 'INSERT'), 'authenticated cannot insert entries');
select ok(not has_table_privilege('authenticated', 'public.wallet_accounts', 'UPDATE'), 'authenticated cannot update balances');

-- Ada tops up (stub provider), idempotently.
select set_config('request.jwt.claim.sub', '3a100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is((wallet_top_up(5000, 'ts-wallet-topup-1')->>'balance')::numeric, 5000.00, 'top-up credits the rider');
select is((wallet_top_up(5000, 'ts-wallet-topup-1')->>'replayed')::boolean, true, 'same key replays');
select is((get_wallet()->>'balance')::numeric, 5000.00, 'replay does not double-credit');
select throws_ok($$ select wallet_top_up(50, 'ts-wallet-topup-2') $$, 'P0001', 'VALIDATION', 'top-up below minimum rejected');
select throws_ok($$ select wallet_top_up(60000, 'ts-wallet-topup-3') $$, 'P0001', 'VALIDATION', 'top-up above maximum rejected');
select throws_ok($$ select wallet_top_up(500, 'short') $$, 'P0001', 'VALIDATION', 'short idempotency key rejected');

-- Send to Bayo
select is((wallet_send('+2348000027002', 1200, 'ts-wallet-send-1')->>'balance')::numeric, 3800.00, 'send debits sender');
select throws_ok($$ select wallet_send('+2348000027002', 9000, 'ts-wallet-send-2') $$, 'P0001', 'INSUFFICIENT_FUNDS', 'no negative balance');
select throws_ok($$ select wallet_send('+2348000027999', 100, 'ts-wallet-send-3') $$, 'P0001', 'NOT_FOUND', 'unknown recipient');
select throws_ok($$ select wallet_send('+2348000027001', 100, 'ts-wallet-send-4') $$, 'P0001', 'VALIDATION', 'cannot send to self');

-- Pass
select is((wallet_buy_pass('ts-wallet-pass-1')->>'balance')::numeric, 1800.00, 'pass costs 2000');

-- Split with Bayo and Chi
select is(jsonb_array_length(wallet_request_split(array['+2348000027002', '+2348000027003'], 700, null, 'ts-wallet-split-1')->'split_ids'), 2, 'split request creates one row per co-rider');
select is((wallet_request_split(array['+2348000027002', '+2348000027003'], 700, null, 'ts-wallet-split-1')->>'replayed')::boolean, true, 'split request replays');
select is((select count(*)::int from wallet_splits), 2, 'requester sees both splits');

-- RLS: Ada never sees system or other riders' rows
select is((select count(*)::int from wallet_accounts), 1, 'rider sees only own account');
select throws_ok($$ insert into wallet_entries (transaction_id, account_id, amount)
  select id, id, 1 from wallet_transactions limit 1 $$, '42501', null, 'direct ledger insert denied');

-- Bayo pays his share
select set_config('request.jwt.claim.sub', '3a100000-0000-4000-8000-000000000002', true);
select is(jsonb_array_length(get_wallet()->'splits_owed'), 1, 'payer sees owed split');
select is((wallet_settle_split((select id from wallet_splits where payer_id = auth.uid()), true, 'ts-wallet-settle-1')->>'balance')::numeric,
  500.00, 'paying split debits payer');
select is((wallet_settle_split((select id from wallet_splits where payer_id = auth.uid()), true, 'ts-wallet-settle-1')->>'replayed')::boolean,
  true, 'settle replays');

-- Chi cannot settle Bayo's split, and declines her own with no funds moved
select set_config('request.jwt.claim.sub', '3a100000-0000-4000-8000-000000000003', true);
select throws_ok(format($$ select wallet_settle_split(%L, true, 'ts-wallet-settle-x') $$,
  (select s.id from wallet_splits s where s.payer_id = '3a100000-0000-4000-8000-000000000002')),
  'P0001', 'NOT_FOUND', 'other payer split invisible/forbidden');
select is((wallet_settle_split((select id from wallet_splits where payer_id = auth.uid()), false, 'ts-wallet-settle-2')->>'status'),
  'declined', 'decline works');
reset role;

-- Integrity: entries balance, cached balances match, append-only
select set_config('request.jwt.claim.sub', '', true);
select is((select count(*)::int from wallet_ledger_check()), 0, 'ledger check is clean');
select throws_ok($$ update wallet_entries set amount = amount + 1 $$, 'P0001', 'IMMUTABLE', 'entries are append-only');
set constraints wallet_entries_balanced immediate;
select throws_ok($$ insert into wallet_entries (transaction_id, account_id, amount)
  select t.id, a.id, 1 from wallet_transactions t, wallet_accounts a where a.kind = 'fares' limit 1 $$,
  'P0001', 'UNBALANCED', 'one-legged entry rejected');

select * from finish();
rollback;
