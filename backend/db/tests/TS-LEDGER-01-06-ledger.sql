-- pgTAP: TS-LEDGER-01/02/05/06 — ledger invariant, cash commission, immutability, threshold block (P4-A-01)
create extension if not exists pgtap;

begin;
select plan(15);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006101'),
  ('0e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006102'),
  ('0e200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000006103'),
  ('0e200000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000006104'),
  ('0e300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006201')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000001', '+2348000006101', 'Ledger Rider'),
  ('0e200000-0000-4000-8000-000000000001', '+2348000006102', 'Ledger Driver A'),
  ('0e200000-0000-4000-8000-000000000002', '+2348000006103', 'Ledger Driver B'),
  ('0e200000-0000-4000-8000-000000000003', '+2348000006104', 'Ledger Blocked'),
  ('0e300000-0000-4000-8000-000000000001', '+2348000006201', 'Ledger Roam Rider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001'),
  ('0e300000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'LEDG01', '0a020000-0000-4000-8000-000000000001'),
  ('0e200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'LEDG02', '0a020000-0000-4000-8000-000000000001'),
  ('0e200000-0000-4000-8000-000000000003', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'LEDG03', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status, standing = excluded.standing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0e400000-0000-4000-8000-000000000001', 'NG', 'car', 'LEDG-01', 4, '0e200000-0000-4000-8000-000000000001'),
  ('0e400000-0000-4000-8000-000000000002', 'NG', 'car', 'LEDG-02', 4, '0e200000-0000-4000-8000-000000000002'),
  ('0e400000-0000-4000-8000-000000000003', 'NG', 'keke', 'LEDG-03', 3, '0e200000-0000-4000-8000-000000000003')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0e200000-0000-4000-8000-000000000001', '0e400000-0000-4000-8000-000000000001', true),
  ('0e200000-0000-4000-8000-000000000002', '0e400000-0000-4000-8000-000000000002', true),
  ('0e200000-0000-4000-8000-000000000003', '0e400000-0000-4000-8000-000000000003', true)
on conflict do nothing;

-- Seed ledger rows for TS-LEDGER-01 invariant check
select ledger_post(
  '0e200000-0000-4000-8000-000000000001',
  'manual_adjustment',
  -100.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-01:a:1',
  'system',
  null,
  'TS-LEDGER-01 setup'
);

select ledger_post(
  '0e200000-0000-4000-8000-000000000001',
  'manual_adjustment',
  -50.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-01:a:2',
  'system',
  null,
  'TS-LEDGER-01 setup'
);

select ledger_post(
  '0e200000-0000-4000-8000-000000000002',
  'onboarding_deposit',
  200.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-01:b:1',
  'system',
  null,
  null
);

-- TS-LEDGER-01: sum(amount) = latest balance_after for every driver
select ok(
  not exists (
    select 1
    from (
      select
        dle.driver_id,
        sum(dle.amount) as sum_amount,
        (
          select dle2.balance_after
          from driver_ledger_entries dle2
          where dle2.driver_id = dle.driver_id
          order by dle2.id desc
          limit 1
        ) as latest_balance
      from driver_ledger_entries dle
      group by dle.driver_id
    ) x
    where x.sum_amount is distinct from x.latest_balance
  ),
  'TS-LEDGER-01: sum(amount) equals latest balance_after for every driver'
);

select ok(
  (
    select sum(amount) = (
      select balance_after
      from driver_ledger_entries
      where driver_id = '0e200000-0000-4000-8000-000000000001'
      order by id desc
      limit 1
    )
    from driver_ledger_entries
    where driver_id = '0e200000-0000-4000-8000-000000000001'
  ),
  'TS-LEDGER-01: driver_balances view agrees with running total'
);

-- TS-LEDGER-02: cash completion posts exactly one cash_commission_debit
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0e500000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 1000.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0e600000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0e600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0e700000-0000-4000-8000-000000000001',
  '0e600000-0000-4000-8000-000000000001',
  1,
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0e400000-0000-4000-8000-000000000001',
  'car',
  '0e500000-0000-4000-8000-000000000001',
  1000.00, 'NGN', 2, 0.05,
  'in_transit',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

select set_config('request.jwt.claim.sub', '0e200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select complete_trip('0e700000-0000-4000-8000-000000000001'::uuid);

select is(
  (select count(*)::int from driver_ledger_entries
   where trip_id = '0e700000-0000-4000-8000-000000000001'
     and entry_type = 'cash_commission_debit'),
  1,
  'TS-LEDGER-02: cash completion posts exactly one cash_commission_debit'
);

select is(
  (select amount from driver_ledger_entries
   where idempotency_key = 'trip:0e700000-0000-4000-8000-000000000001:commission'),
  -50.00::numeric,
  'TS-LEDGER-02: debit equals round(fare × rate) = round(1000 × 0.05) = -50'
);

set local role postgres;

select is(
  (select id from ledger_post(
    '0e200000-0000-4000-8000-000000000001',
    'cash_commission_debit',
    -50.00,
    'NGN',
    jsonb_build_object('trip_id', '0e700000-0000-4000-8000-000000000001'),
    'trip:0e700000-0000-4000-8000-000000000001:commission',
    'system',
    null,
    null
  )),
  (select id from driver_ledger_entries
   where idempotency_key = 'trip:0e700000-0000-4000-8000-000000000001:commission'),
  'TS-LEDGER-02: replay with same idempotency key returns same row'
);

-- TS-LEDGER-05: update/delete on ledger rejected for all roles
select throws_ok(
  $$ update driver_ledger_entries set amount = 0 where idempotency_key = 'ts-ledger-01:a:1' $$,
  '42501',
  null,
  'TS-LEDGER-05: update rejected for postgres role'
);

select throws_ok(
  $$ delete from driver_ledger_entries where idempotency_key = 'ts-ledger-01:a:1' $$,
  '42501',
  null,
  'TS-LEDGER-05: delete rejected for postgres role'
);

select set_config('request.jwt.claim.sub', '0e200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ update driver_ledger_entries set amount = 0 where driver_id = auth.uid() $$,
  '42501',
  null,
  'TS-LEDGER-05: update rejected for authenticated driver'
);

select throws_ok(
  $$ delete from driver_ledger_entries where driver_id = auth.uid() $$,
  '42501',
  null,
  'TS-LEDGER-05: delete rejected for authenticated driver'
);

-- TS-LEDGER-06: balance −5200 → not matchable; matching paths exclude driver
set local role postgres;

select ledger_post(
  '0e200000-0000-4000-8000-000000000003',
  'manual_adjustment',
  -5200.00,
  'NGN',
  '{}'::jsonb,
  'ts-ledger-06:blocked',
  'system',
  null,
  'TS-LEDGER-06 setup'
);

select ok(
  not driver_is_matchable('0e200000-0000-4000-8000-000000000003'),
  'TS-LEDGER-06: balance -5200 makes driver_is_matchable false'
);

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available, last_ping_at
) values (
  '0e200000-0000-4000-8000-000000000003',
  '0e400000-0000-4000-8000-000000000003',
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3,
  now()
) on conflict (driver_id) do update set
  status = excluded.status,
  nearest_stage_id = excluded.nearest_stage_id,
  last_ping_at = excluded.last_ping_at;

select ok(
  not exists (
    select 1
    from planner_direct_candidates_latlng(
      11.060, 7.700,
      11.065, 7.705,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' = 'parked'
  ),
  'TS-LEDGER-06: planner parked supply excludes ledger-blocked driver'
);

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0e500000-0000-4000-8000-000000000002',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000003',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '0e100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '0e800000-0000-4000-8000-000000000001',
    'kind', 'direct', 'source', 'parked', 'viable_direct', true,
    'legs', jsonb_build_array(jsonb_build_object(
      'leg_index', 0,
      'mode', jsonb_build_object('code', 'car'),
      'board', jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000001'),
      'alight', jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005'),
      'route_id', '0a030000-0000-4000-8000-000000000001',
      'route_leg_ids', '[]'::jsonb,
      'fare', jsonb_build_object('amount', 320, 'currency', 'NGN', 'tier', 2, 'quote_id', '0e500000-0000-4000-8000-000000000002', 'unconfirmed', false),
      'supply', jsonb_build_object('kind', 'parked', 'driver_id', '0e200000-0000-4000-8000-000000000003')
    ))
  ))
);

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select request_trip('0e800000-0000-4000-8000-000000000001', 0, false, gen_random_uuid()) $$,
  'P0001',
  'DRIVER_NOT_MATCHABLE',
  'TS-LEDGER-06: request_trip rejects ledger-blocked parked driver'
);

select set_config('request.jwt.claim.sub', '0e200000-0000-4000-8000-000000000003', true);
set local role authenticated;

select throws_ok(
  $$ select set_presence('roaming_available', '{"lat": 11.061, "lng": 7.701}'::jsonb, 2::smallint, 45::smallint) $$,
  'P0001',
  'LEDGER_BLOCKED',
  'TS-LEDGER-06: set_presence rejects ledger-blocked driver'
);

-- Roaming hail path
select set_config('app.settings.candidate_token_hmac_key', 'along-test-candidate-hmac-do-not-commit', true);

set local role postgres;

update driver_presence
set
  status = 'roaming_available',
  session_id = '0e810000-0000-4000-8000-000000000001',
  current_location = st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  nearest_stage_id = '0a041000-0000-4000-8000-000000000002',
  last_ping_at = now()
where driver_id = '0e200000-0000-4000-8000-000000000003';

select set_config(
  'test.ledger06_roam_token',
  sign_candidate_token(
    '0e200000-0000-4000-8000-000000000003',
    '0e810000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001'
  ),
  true
);

select set_config('request.jwt.claim.sub', '0e300000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  format(
    $$ select hail_roaming(%L, '{"lat":11.065,"lng":7.705}'::jsonb, false, gen_random_uuid()) $$,
    current_setting('test.ledger06_roam_token')
  ),
  'P0001',
  'DRIVER_NOT_MATCHABLE',
  'TS-LEDGER-06: roaming hail excludes ledger-blocked driver'
);

select ok(
  not exists (
    select 1
    from planner_direct_candidates_latlng(
      11.061, 7.701,
      11.065, 7.705,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' = 'roaming'
  ),
  'TS-LEDGER-06: planner roaming supply excludes ledger-blocked driver'
);

select * from finish();
rollback;
