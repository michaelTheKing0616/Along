-- pgTAP: P4-A-08 — payout bank persist, re-auth, split settlement reconciliation
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f200000-0000-4000-8000-000000000050', 'authenticated', 'authenticated', '+2348000007050')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f200000-0000-4000-8000-000000000050', '+2348000007050', 'Payout Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, home_park_id) values
  ('0f200000-0000-4000-8000-000000000050', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

select set_config('request.jwt.claims', '{"sub":"0f200000-0000-4000-8000-000000000050","role":"authenticated"}', true);
set local role authenticated;

update profiles set phone_reauth_at = null where id = '0f200000-0000-4000-8000-000000000050';

select throws_like(
  $$ select persist_driver_payout_bank('ACCT_test', '6789') $$,
  '%REAUTH_REQUIRED%',
  'persist without recent reauth raises REAUTH_REQUIRED'
);

update profiles set phone_reauth_at = now() where id = '0f200000-0000-4000-8000-000000000050';

select lives_ok(
  $$ select persist_driver_payout_bank('ACCT_test_sub_050', '6789') $$,
  'persist succeeds with fresh reauth'
);

select is(
  (select payout_subaccount_code from drivers where id = '0f200000-0000-4000-8000-000000000050'),
  'ACCT_test_sub_050',
  'subaccount code stored'
);

select is(
  (select payout_bank_last4 from drivers where id = '0f200000-0000-4000-8000-000000000050'),
  '6789',
  'bank last4 stored'
);

select is(
  (select driver_code is not null from drivers where id = '0f200000-0000-4000-8000-000000000050'),
  true,
  'driver_code assigned when absent'
);

select is(
  (select to_jsonb(d)::text !~ '0123456789'
   from drivers d where d.id = '0f200000-0000-4000-8000-000000000050'),
  true,
  'full account number not persisted anywhere on drivers row'
);

reset role;
set local role postgres;

insert into payments (
  id, driver_id, source, channel, amount, currency,
  commission_amount, driver_amount, fee_bearer, provider_reference, method, status, confirmed_at
) values (
  '0f800000-0000-4000-8000-000000000050',
  '0f200000-0000-4000-8000-000000000050',
  'app_trip', 'app', 1000.00, 'NGN',
  75.00, 925.00, 'account', 'pay_split_test_050', 'card', 'succeeded', current_date + time '12:00'
);

select is(
  reconcile_split_settlements(current_date, jsonb_build_object('ACCT_test_sub_050', 925.00)),
  0,
  'matching provider total creates zero alerts'
);

select is(
  reconcile_split_settlements(current_date, jsonb_build_object('ACCT_test_sub_050', 900.00)),
  1,
  'mismatch creates one finance alert'
);

select is(
  (select count(*)::int from split_settlement_alerts where subaccount_code = 'ACCT_test_sub_050'),
  1,
  'alert row visible for finance reconciliation'
);

select * from finish();
rollback;
