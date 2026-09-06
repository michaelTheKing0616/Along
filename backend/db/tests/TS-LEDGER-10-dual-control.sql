-- pgTAP: TS-LEDGER-10 — manual adjustment dual control + payout_debit sign (P4-A-07)
create extension if not exists pgtap;

begin;
select plan(13);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f600000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007601'),
  ('0f600000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000007602'),
  ('0f100000-0000-4000-8000-000000000020', 'authenticated', 'authenticated', '+2348000007620')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f600000-0000-4000-8000-000000000001', '+2348000007601', 'Finance One'),
  ('0f600000-0000-4000-8000-000000000002', '+2348000007602', 'Finance Two'),
  ('0f100000-0000-4000-8000-000000000020', '+2348000007620', 'Payout Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into admin_users (id, role, deployment_id) values
  ('0f600000-0000-4000-8000-000000000001', 'finance', 'a0000000-0000-4000-8000-000000000001'),
  ('0f600000-0000-4000-8000-000000000002', 'finance', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, deployment_id = excluded.deployment_id;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id, payout_subaccount_code) values
  ('0f100000-0000-4000-8000-000000000020', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'PAY01', '0a020000-0000-4000-8000-000000000001', 'ACCT_test_subaccount')
on conflict (id) do update set
  payout_subaccount_code = excluded.payout_subaccount_code,
  verified_status = excluded.verified_status;

-- TS-LEDGER-10: above dual-control threshold → pending, no ledger row yet
select set_config('request.jwt.claim.sub', '0f600000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config(
  'test.pending_result',
  admin_manual_ledger_adjustment(
    '0f100000-0000-4000-8000-000000000020',
    25000.00,
    'Large goodwill credit — dual control'
  )::text,
  true
);

select set_config(
  'test.pending_req',
  (current_setting('test.pending_result')::jsonb->>'request_id'),
  true
);

select is(
  current_setting('test.pending_result')::jsonb->>'status',
  'pending',
  'TS-LEDGER-10: above-threshold adjustment returns pending'
);

set local role postgres;

select is(
  (select count(*)::int from driver_ledger_entries
   where driver_id = '0f100000-0000-4000-8000-000000000020'),
  0,
  'TS-LEDGER-10: above-threshold request creates no ledger entry before approval'
);

select is(
  (select status::text from pending_ledger_adjustments
   where id = current_setting('test.pending_req')::uuid),
  'pending',
  'TS-LEDGER-10: pending adjustment row exists'
);

select ok(
  exists (
    select 1 from audit_log
    where action = 'request_adjustment'
      and target_type = 'pending_ledger_adjustments'
      and target_id = current_setting('test.pending_req')
  ),
  'TS-LEDGER-10: request writes audit row'
);

-- Same user approve → rejected (SQL-enforced)
select set_config('request.jwt.claim.sub', '0f600000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  format(
    $$ select admin_approve_adjustment(%L) $$,
    current_setting('test.pending_req')
  ),
  'P0001',
  'cannot approve own adjustment request',
  'TS-LEDGER-10: same user approve is rejected'
);

-- Second finance user approves → ledger posted
select set_config('request.jwt.claim.sub', '0f600000-0000-4000-8000-000000000002', true);
set local role authenticated;

select ok(
  (admin_approve_adjustment(current_setting('test.pending_req')::uuid)->>'ledger_entry_id') is not null,
  'TS-LEDGER-10: second approver posts ledger entry'
);

set local role postgres;

select is(
  (select count(*)::int from driver_ledger_entries
   where driver_id = '0f100000-0000-4000-8000-000000000020'
     and entry_type = 'manual_adjustment'),
  1,
  'TS-LEDGER-10: exactly one manual_adjustment after approval'
);

select ok(
  exists (
    select 1 from audit_log
    where action = 'approve_adjustment'
      and target_id = current_setting('test.pending_req')
  ),
  'TS-LEDGER-10: approve writes audit row'
);

-- Below-threshold adjustment posts immediately
select set_config('request.jwt.claim.sub', '0f600000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  admin_manual_ledger_adjustment(
    '0f100000-0000-4000-8000-000000000020',
    5000.00,
    'Small top-up below threshold'
  )->>'status',
  'posted',
  'TS-LEDGER-10: below-threshold adjustment posts immediately'
);

set local role postgres;

select is(
  (select count(*)::int from driver_ledger_entries
   where driver_id = '0f100000-0000-4000-8000-000000000020'
     and entry_type = 'manual_adjustment'),
  2,
  'TS-LEDGER-10: below-threshold adds second manual_adjustment without pending row'
);

-- payout_debit is negative after transfer webhook confirmation
select set_config('request.jwt.claim.sub', '0f600000-0000-4000-8000-000000000001', true);
set local role authenticated;

select set_config(
  'test.payout',
  admin_payout_positive_balance('0f100000-0000-4000-8000-000000000020')::text,
  true
);

set local role postgres;

select is(
  (select balance from driver_balances where driver_id = '0f100000-0000-4000-8000-000000000020'),
  30000.00,
  'TS-LEDGER-10: driver has positive balance before payout'
);

select apply_paystack_transfer_success(
  (select provider_reference from driver_payouts
   where driver_id = '0f100000-0000-4000-8000-000000000020'
   order by created_at desc limit 1),
  30000.00,
  jsonb_build_object(
    'payout_id',
    (select id::text from driver_payouts
     where driver_id = '0f100000-0000-4000-8000-000000000020'
     order by created_at desc limit 1)
  )
);

select is(
  (select amount from driver_ledger_entries
   where driver_id = '0f100000-0000-4000-8000-000000000020'
     and entry_type = 'payout_debit'
   order by id desc limit 1),
  -30000.00,
  'TS-LEDGER-10: payout_debit amount is negative'
);

select is(
  (select balance from driver_balances where driver_id = '0f100000-0000-4000-8000-000000000020'),
  0.00,
  'TS-LEDGER-10: payout clears positive balance to zero'
);

select * from finish();
rollback;
