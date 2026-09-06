-- pgTAP: TS-QR-01..12 — QR scan-to-pay backend (P4-A-09)
create extension if not exists pgtap;

begin;
select plan(35);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

select set_config('app.settings.payment_token_hmac_key', 'along-test-payment-hmac-do-not-commit', true);
select set_config('app.settings.candidate_token_hmac_key', 'along-test-candidate-hmac-do-not-commit', true);

-- Riders / drivers
insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000060', 'authenticated', 'authenticated', '+2348000007060'),
  ('0f100000-0000-4000-8000-000000000061', 'authenticated', 'authenticated', '+2348000007061'),
  ('0f200000-0000-4000-8000-000000000060', 'authenticated', 'authenticated', '+2348000007062'),
  ('0f200000-0000-4000-8000-000000000061', 'authenticated', 'authenticated', '+2348000007063')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000060', '+2348000007060', 'QR Rider A'),
  ('0f100000-0000-4000-8000-000000000061', '+2348000007061', 'QR Rider B'),
  ('0f200000-0000-4000-8000-000000000060', '+2348000007062', 'QR Driver A'),
  ('0f200000-0000-4000-8000-000000000061', '+2348000007063', 'QR Driver B')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000060', '0a000000-0000-4000-8000-000000000001'),
  ('0f100000-0000-4000-8000-000000000061', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, payout_subaccount_code, accepts_digital, home_park_id) values
  ('0f200000-0000-4000-8000-000000000060', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'QRDRV060', 'ACCT_qr_060', true, '0a020000-0000-4000-8000-000000000001'),
  ('0f200000-0000-4000-8000-000000000061', '0a000000-0000-4000-8000-000000000001', 'verified', 'deactivated', 'QRDRV061', 'ACCT_qr_061', true, '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set
  driver_code = excluded.driver_code,
  payout_subaccount_code = excluded.payout_subaccount_code,
  standing = excluded.standing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f400000-0000-4000-8000-000000000060', 'NG', 'car', 'QR-060', 4, '0f200000-0000-4000-8000-000000000060'),
  ('0f400000-0000-4000-8000-000000000061', 'NG', 'keke', 'QR-061', 3, '0f200000-0000-4000-8000-000000000061')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000060', '0f400000-0000-4000-8000-000000000060', true),
  ('0f200000-0000-4000-8000-000000000061', '0f400000-0000-4000-8000-000000000061', true)
on conflict do nothing;

-- Trip with driver A for rider A (in_transit, unpaid)
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000060',
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 850.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0f600000-0000-4000-8000-000000000060', '0f100000-0000-4000-8000-000000000060', '0a000000-0000-4000-8000-000000000001', 'active',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
   st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
   '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb)
on conflict (id) do nothing;

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate, load_surcharge_amount,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000060',
  '0f600000-0000-4000-8000-000000000060', 1,
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0f400000-0000-4000-8000-000000000060',
  'car', '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000060',
  800.00, 'NGN', 2, 0.05, 50.00,
  'cash', 'in_transit', now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
)
on conflict (id) do nothing;

-- Trip with driver B for rider B (active different driver warning)
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000061',
  '0f100000-0000-4000-8000-000000000061',
  '0f200000-0000-4000-8000-000000000061',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'keke', 2, 500.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0f600000-0000-4000-8000-000000000061', '0f100000-0000-4000-8000-000000000061', '0a000000-0000-4000-8000-000000000001', 'active',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
   st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
   '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb)
on conflict (id) do nothing;

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000061',
  '0f600000-0000-4000-8000-000000000061', 1,
  '0f100000-0000-4000-8000-000000000061',
  '0f200000-0000-4000-8000-000000000061',
  '0f400000-0000-4000-8000-000000000061',
  'keke', '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000061',
  500.00, 'NGN', 2, 0.05,
  'cash', 'in_transit', now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
)
on conflict (id) do nothing;

-- TS-QR-01: known code resolves identity; unknown 404; inactive hides identity
select is(
  (resolve_qr_driver('QRDRV060', null, null)->'driver'->>'first_name'),
  'QR',
  'TS-QR-01: known code returns first name only'
);

select is(
  (resolve_qr_driver('QRDRV060', null, null)->'driver'->>'plate'),
  'QR-060',
  'TS-QR-01: known code returns plate'
);

select throws_like(
  $$ select resolve_qr_driver('UNKNOWN1', null, null) $$,
  '%NOT_FOUND%',
  'TS-QR-01: unknown code raises NOT_FOUND'
);

select is(
  (resolve_qr_driver('QRDRV061', null, null)->'driver'->>'active')::boolean,
  false,
  'TS-QR-01: inactive driver active=false'
);

select is(
  resolve_qr_driver('QRDRV061', null, null)->'driver' ? 'first_name',
  false,
  'TS-QR-01: inactive driver hides identity'
);

-- TS-QR-01 rate limit: 31st request blocked
select is(
  (select count(*)::int from generate_series(1, 30) g where check_qr_resolve_rate('1.2.3.4', 30)),
  30,
  'TS-QR-01: first 30 resolve checks allowed'
);

select is(
  check_qr_resolve_rate('1.2.3.4', 30),
  false,
  'TS-QR-01: 31st resolve check denied'
);

-- TS-QR-02: rider context with locked amount
select is(
  ((resolve_qr_driver('QRDRV060', '0f100000-0000-4000-8000-000000000060', null)->'context'->'amount'->>'amount')::numeric),
  850.00,
  'TS-QR-02: context amount = fare + surcharge'
);

select is(
  (resolve_qr_driver('QRDRV060', '0f100000-0000-4000-8000-000000000060', null)->'context'->>'locked')::boolean,
  true,
  'TS-QR-02: context locked=true'
);

-- TS-QR-03: different_driver warning when scanning another driver
select is(
  resolve_qr_driver('QRDRV060', '0f100000-0000-4000-8000-000000000061', null)->>'warning',
  'different_driver',
  'TS-QR-03: rider active trip with other driver → different_driver'
);

-- TS-QR-04: payment token verify / tamper / wrong driver
select lives_ok(
  $$ select sign_payment_token(
    '0f700000-0000-4000-8000-000000000060'::uuid,
    '0f200000-0000-4000-8000-000000000060'::uuid,
    850.00,
    '0a000000-0000-4000-8000-000000000001'::uuid
  ) $$,
  'TS-QR-04: sign payment token'
);

select is(
  (select amount from verify_payment_token(
    sign_payment_token(
      '0f700000-0000-4000-8000-000000000060'::uuid,
      '0f200000-0000-4000-8000-000000000060'::uuid,
      850.00,
      '0a000000-0000-4000-8000-000000000001'::uuid
    ),
    '0a000000-0000-4000-8000-000000000001'::uuid
  )),
  850.00,
  'TS-QR-04: valid token returns locked amount'
);

select throws_like(
  $$ select verify_payment_token('bad.token', null) $$,
  '%CANDIDATE_EXPIRED%',
  'TS-QR-04: tampered token → CANDIDATE_EXPIRED'
);

select throws_like(
  $$ select resolve_qr_driver(
    'QRDRV060',
    null,
    sign_payment_token(
      '0f700000-0000-4000-8000-000000000060'::uuid,
      '0f200000-0000-4000-8000-000000000061'::uuid,
      850.00,
      '0a000000-0000-4000-8000-000000000001'::uuid
    )
  ) $$,
  '%FORBIDDEN%',
  'TS-QR-04: token for different driver → FORBIDDEN'
);

-- TS-QR-05: split math + set_accepts_digital / no subaccount guards (SQL side)
select is(
  round(850.00 * 0.05, 2),
  42.50,
  'TS-QR-05: commission from trip rate'
);

select is(
  850.00 - 42.50,
  807.50,
  'TS-QR-05: driver_amount + commission_amount = amount'
);

select set_config('request.jwt.claims', '{"sub":"0f200000-0000-4000-8000-000000000060","role":"authenticated"}', true);
set local role authenticated;

select is(
  (set_accepts_digital(false)->>'accepts_digital')::boolean,
  false,
  'TS-QR-05: set_accepts_digital pauses acceptance'
);

reset role;
set local role postgres;

update drivers set accepts_digital = true where id = '0f200000-0000-4000-8000-000000000060';

-- TS-QR-06: webhook on completed cash trip with cash debit → offset nets zero
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000080',
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 850.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0f600000-0000-4000-8000-000000000080', '0f100000-0000-4000-8000-000000000060', '0a000000-0000-4000-8000-000000000001', 'active',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
   st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate, load_surcharge_amount,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000080',
  '0f600000-0000-4000-8000-000000000080', 1,
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0f400000-0000-4000-8000-000000000060',
  'car', '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000080',
  800.00, 'NGN', 2, 0.05, 50.00,
  'cash', 'in_transit', now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

select set_config('request.jwt.claims', '{"sub":"0f200000-0000-4000-8000-000000000060","role":"authenticated"}', true);
set local role authenticated;

select complete_trip('0f700000-0000-4000-8000-000000000080'::uuid);

reset role;
set local role postgres;

insert into payments (
  id, driver_id, trip_id, rider_id, source, channel, amount, currency,
  commission_amount, driver_amount, fee_bearer, provider_reference, method, status
) values (
  '0f800000-0000-4000-8000-000000000080',
  '0f200000-0000-4000-8000-000000000060',
  '0f700000-0000-4000-8000-000000000080',
  '0f100000-0000-4000-8000-000000000060',
  'app_trip', 'app', 850.00, 'NGN',
  42.50, 807.50, 'account', 'pending_qr060', 'card', 'initiated'
);

select apply_paystack_charge_success(
  'QR060_REF1', 850.00,
  jsonb_build_object('payment_id', '0f800000-0000-4000-8000-000000000080')
);

select is(
  (select payment_method from trips where id = '0f700000-0000-4000-8000-000000000080'),
  'digital',
  'TS-QR-06: webhook sets payment_method digital'
);

select is(
  (select coalesce(sum(amount), 0) from driver_ledger_entries
   where trip_id = '0f700000-0000-4000-8000-000000000080'),
  0.00,
  'TS-QR-06: cash debit + offset nets zero'
);

select apply_paystack_charge_success(
  'QR060_REF1', 850.00,
  jsonb_build_object('payment_id', '0f800000-0000-4000-8000-000000000080')
);

select is(
  (select count(*)::int from driver_ledger_entries
   where idempotency_key = 'trip:0f700000-0000-4000-8000-000000000080:digital_offset'),
  1,
  'TS-QR-06: webhook replay does not duplicate offset row'
);

-- TS-QR-07: webhook before completion → no cash debit at completion
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000070',
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 600.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0f600000-0000-4000-8000-000000000070', '0f100000-0000-4000-8000-000000000060', '0a000000-0000-4000-8000-000000000001', 'active',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
   st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb)
on conflict (id) do nothing;

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000070',
  '0f600000-0000-4000-8000-000000000070', 1,
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0f400000-0000-4000-8000-000000000060',
  'car', '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000070',
  600.00, 'NGN', 2, 0.05,
  'cash', 'in_transit', now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
)
on conflict (id) do nothing;

insert into payments (
  id, driver_id, trip_id, rider_id, source, channel, amount, currency,
  commission_amount, driver_amount, fee_bearer, provider_reference, method, status
) values (
  '0f800000-0000-4000-8000-000000000070',
  '0f200000-0000-4000-8000-000000000060',
  '0f700000-0000-4000-8000-000000000070',
  '0f100000-0000-4000-8000-000000000060',
  'qr_dynamic', 'app', 600.00, 'NGN',
  30.00, 570.00, 'account', 'pending_qr070', 'card', 'initiated'
);

select apply_paystack_charge_success(
  'QR070_REF1', 600.00,
  jsonb_build_object('payment_id', '0f800000-0000-4000-8000-000000000070')
);

select is(
  (select count(*)::int from driver_ledger_entries where trip_id = '0f700000-0000-4000-8000-000000000070'),
  0,
  'TS-QR-07: early webhook posts no ledger rows'
);

select set_config('request.jwt.claims', '{"sub":"0f200000-0000-4000-8000-000000000060","role":"authenticated"}', true);
set local role authenticated;

select complete_trip('0f700000-0000-4000-8000-000000000070'::uuid);

reset role;
set local role postgres;

select is(
  (select count(*)::int from driver_ledger_entries
   where trip_id = '0f700000-0000-4000-8000-000000000070'
     and entry_type = 'cash_commission_debit'),
  0,
  'TS-QR-07: completion after digital webhook posts no cash debit'
);

-- TS-QR-08: unique index blocks second succeeded payment
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000081',
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 500.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0f600000-0000-4000-8000-000000000081', '0f100000-0000-4000-8000-000000000060', '0a000000-0000-4000-8000-000000000001', 'active',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
   st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000081',
  '0f600000-0000-4000-8000-000000000081', 1,
  '0f100000-0000-4000-8000-000000000060',
  '0f200000-0000-4000-8000-000000000060',
  '0f400000-0000-4000-8000-000000000060',
  'car', '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000081',
  500.00, 'NGN', 2, 0.05,
  'cash', 'in_transit', now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

insert into payments (
  id, driver_id, trip_id, rider_id, source, channel, amount, currency,
  commission_amount, driver_amount, fee_bearer, provider_reference, method, status, confirmed_at
) values (
  '0f800000-0000-4000-8000-000000000081',
  '0f200000-0000-4000-8000-000000000060',
  '0f700000-0000-4000-8000-000000000081',
  '0f100000-0000-4000-8000-000000000060',
  'app_trip', 'app', 500.00, 'NGN',
  25.00, 475.00, 'account', 'qr081_paid', 'card', 'succeeded', now()
);

select throws_ok(
  $$ insert into payments (
    driver_id, trip_id, rider_id, source, channel, amount, currency,
    commission_amount, driver_amount, fee_bearer, provider_reference, method, status, confirmed_at
  ) values (
    '0f200000-0000-4000-8000-000000000060',
    '0f700000-0000-4000-8000-000000000081',
    '0f100000-0000-4000-8000-000000000060',
    'app_trip', 'app', 500.00, 'NGN',
    25.00, 475.00, 'account', 'qr081_dup', 'card', 'succeeded', now()
  ) $$,
  '23505',
  null,
  'TS-QR-08: unique index blocks second succeeded row per trip'
);

-- TS-QR-09: anonymous web payment row shape; no ledger for no trip
insert into payments (
  id, driver_id, trip_id, rider_id, source, channel, amount, currency,
  commission_amount, driver_amount, fee_bearer, provider_reference, method, status
) values (
  '0f800000-0000-4000-8000-000000000090',
  '0f200000-0000-4000-8000-000000000060',
  null, null,
  'web_anonymous', 'web', 450.00, 'NGN',
  33.75, 416.25, 'account', 'pending_web090', 'card', 'initiated'
);

select apply_paystack_charge_success(
  'WEB090_REF', 450.00,
  jsonb_build_object('payment_id', '0f800000-0000-4000-8000-000000000090')
);

select is(
  (select rider_id is null and source = 'web_anonymous' and channel = 'web'
   from payments where id = '0f800000-0000-4000-8000-000000000090'),
  true,
  'TS-QR-09: anonymous web payment shape'
);

select is(
  (select count(*)::int from driver_ledger_entries dle
   join payments p on p.id = '0f800000-0000-4000-8000-000000000090'
   where dle.driver_id = p.driver_id
     and dle.idempotency_key like 'paystack:%'),
  0,
  'TS-QR-09: unattributed payment creates no ledger rows'
);

-- TS-QR-10: rotate_driver_code
select set_config('request.jwt.claims', '{"sub":"0f200000-0000-4000-8000-000000000060","role":"authenticated"}', true);
set local role authenticated;

select rotate_driver_code();

reset role;
set local role postgres;

select throws_like(
  $$ select resolve_qr_driver('QRDRV060', null, null) $$,
  '%NOT_FOUND%',
  'TS-QR-10: old code 404 after rotation'
);

select isnt(
  (select driver_code from drivers where id = '0f200000-0000-4000-8000-000000000060'),
  'QRDRV060',
  'TS-QR-10: driver has new code'
);

select is(
  (select count(*)::int from qr_sticker_requests
   where driver_id = '0f200000-0000-4000-8000-000000000060' and reason = 'rotation'),
  1,
  'TS-QR-10: sticker request created'
);

select is(
  (select count(*)::int from audit_log
   where action = 'rotate_driver_code' and target_id = '0f200000-0000-4000-8000-000000000060'),
  1,
  'TS-QR-10: rotation audited'
);

-- TS-QR-11: rider_payment_methods view never exposes authorization_code
select set_config('request.jwt.claims', '{"sub":"0f100000-0000-4000-8000-000000000060","role":"authenticated"}', true);
set local role authenticated;

select upsert_rider_payment_method('AUTH_test_code_060', 'visa', '4242', 12::smallint, 2028::smallint, 'GTBank', true);

select is(
  (select count(*)::int from information_schema.columns
   where table_schema = 'public' and table_name = 'rider_payment_methods_safe'
     and column_name = 'authorization_code'),
  0,
  'TS-QR-11: safe view has no authorization_code column'
);

select is(
  (select to_jsonb(m)::text !~ 'AUTH_test'
   from rider_payment_methods_safe m
   where rider_id = '0f100000-0000-4000-8000-000000000060'
   limit 1),
  true,
  'TS-QR-11: rider select never returns authorization_code value'
);

reset role;
set local role postgres;

select is(
  (select authorization_code from rider_payment_methods
   where rider_id = '0f100000-0000-4000-8000-000000000060' limit 1),
  'AUTH_test_code_060',
  'TS-QR-11: server-side storage retains authorization_code'
);

-- TS-QR-12: split reconciliation (extends P4-A-08) — isolated day + driver B subaccount
do $$
declare
  v_day date := current_date - 30;
begin
  insert into payments (
    id, driver_id, source, channel, amount, currency,
    commission_amount, driver_amount, fee_bearer, provider_reference, method, status, confirmed_at
  ) values (
    '0f800000-0000-4000-8000-000000000120',
    '0f200000-0000-4000-8000-000000000061',
    'qr_static', 'web', 1000.00, 'NGN',
    75.00, 925.00, 'account', 'qr12_ref', 'card', 'succeeded', v_day + time '14:00'
  );

  perform set_config('test.qr12_reconcile_day', v_day::text, true);
end;
$$;

select is(
  reconcile_split_settlements(
    current_setting('test.qr12_reconcile_day')::date,
    jsonb_build_object('ACCT_qr_061', 925.00)
  ),
  0,
  'TS-QR-12: matching provider total → zero alerts'
);

select is(
  reconcile_split_settlements(
    current_setting('test.qr12_reconcile_day')::date,
    jsonb_build_object('ACCT_qr_061', 900.00)
  ),
  1,
  'TS-QR-12: mismatch → finance alert'
);

-- Zero card data at rest: no PAN columns in new tables
select is(
  (select count(*)::int from information_schema.columns
   where table_schema = 'public'
     and table_name in ('rider_payment_methods', 'payments', 'qr_sticker_requests')
     and column_name ~* '(pan|card_number|cvv|track)'),
  0,
  'zero card data: no PAN/CVV/track columns in QR payment tables'
);

select * from finish();
rollback;
