-- pgTAP: TS-LEDGER-07 — threshold policy job + flags never transition standing (P4-A-02)
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007102'),
  ('0f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007101')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f200000-0000-4000-8000-000000000001', '+2348000007102', 'Policy Rider'),
  ('0f100000-0000-4000-8000-000000000001', '+2348000007101', 'Policy Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'POLY01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status, standing = excluded.standing;

-- TS-LEDGER-07 step 1: balance −3,100 → warned (+ notification)
select ledger_post(
  '0f100000-0000-4000-8000-000000000001',
  'manual_adjustment',
  -3100.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-07:warn',
  'system',
  null,
  'TS-LEDGER-07 setup'
);

select apply_threshold_policy();

select is(
  (select standing from drivers where id = '0f100000-0000-4000-8000-000000000001'),
  'warned'::driver_standing,
  'TS-LEDGER-07: balance -3100 triggers warned standing'
);

select ok(
  exists (
    select 1
    from notifications n
    where n.profile_id = '0f100000-0000-4000-8000-000000000001'
      and n.type = 'standing_changed'
      and n.payload->>'to_standing' = 'warned'
      and n.payload->>'reason' = 'balance_below_warn_threshold'
      and n.payload ? 'grace_deadline'
      and n.payload ? 'settle_cta'
  ),
  'TS-LEDGER-07: warned transition inserts standing_changed notification with grace deadline'
);

-- TS-LEDGER-07 step 2: settle to −2,000 → good_standing
select ledger_post(
  '0f100000-0000-4000-8000-000000000001',
  'digital_settlement_credit',
  1100.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-07:settle',
  'system',
  null,
  null
);

select apply_threshold_policy();

select is(
  (select standing from drivers where id = '0f100000-0000-4000-8000-000000000001'),
  'good_standing'::driver_standing,
  'TS-LEDGER-07: settle to -2000 restores good_standing'
);

select ok(
  exists (
    select 1
    from driver_standing_transitions dst
    where dst.driver_id = '0f100000-0000-4000-8000-000000000001'
      and dst.to_standing = 'good_standing'
      and dst.reason = 'balance_restored'
  ),
  'TS-LEDGER-07: balance restoration logged with balance_restored reason'
);

-- TS-LEDGER-07 step 3: balance −5,200 → matching_paused
select ledger_post(
  '0f100000-0000-4000-8000-000000000001',
  'manual_adjustment',
  -3200.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-07:block',
  'system',
  null,
  'TS-LEDGER-07 setup block'
);

select apply_threshold_policy();

select is(
  (select standing from drivers where id = '0f100000-0000-4000-8000-000000000001'),
  'matching_paused'::driver_standing,
  'TS-LEDGER-07: balance -5200 triggers matching_paused'
);

-- TS-LEDGER-07 step 4: flags never transition standing (FM13)
select is(
  (select count(*)::int from driver_standing_transitions
   where driver_id = '0f100000-0000-4000-8000-000000000001'),
  3,
  'TS-LEDGER-07: three threshold transitions before flag insert'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0f600000-0000-4000-8000-000000000001',
  '0f200000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'completed',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb
);

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
)
select
  format('0f500000-0000-4000-8000-%12s', lpad(g.i::text, 12, '0'))::uuid,
  '0f200000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 500.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
from generate_series(1, 10) g(i);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape
)
select
  format('0f700000-0000-4000-8000-%12s', lpad(g.i::text, 12, '0'))::uuid,
  '0f600000-0000-4000-8000-000000000001',
  g.i,
  '0f200000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  'car',
  format('0f500000-0000-4000-8000-%12s', lpad(g.i::text, 12, '0'))::uuid,
  500.00,
  'NGN',
  2,
  0.05,
  'cancelled_by_driver',
  now() + interval '25 seconds',
  'color.naMe.green',
  'diamond'
from generate_series(1, 10) g(i);

insert into trip_reconciliation_flags (
  trip_id, driver_id, flag_type, score, evidence, rider_trace_quality
)
select
  format('0f700000-0000-4000-8000-%12s', lpad(g.i::text, 12, '0'))::uuid,
  '0f100000-0000-4000-8000-000000000001',
  'premature_conversion',
  0.7500,
  jsonb_build_object('driver_trace', jsonb_build_object('quality', 'good')),
  'partial'
from generate_series(1, 10) g(i);

select apply_threshold_policy();

select is(
  (select standing from drivers where id = '0f100000-0000-4000-8000-000000000001'),
  'matching_paused'::driver_standing,
  'TS-LEDGER-07: inserting 10 reconciliation flags does not change standing'
);

select is(
  (select count(*)::int from driver_standing_transitions
   where driver_id = '0f100000-0000-4000-8000-000000000001'),
  3,
  'TS-LEDGER-07: flag inserts produce zero new standing transitions'
);

select is(
  (select count(*)::int from trip_reconciliation_flags
   where driver_id = '0f100000-0000-4000-8000-000000000001'),
  10,
  'TS-LEDGER-07: ten reconciliation flags were inserted'
);

select * from finish();
rollback;
