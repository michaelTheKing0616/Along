-- pgTAP: TS-UI-04 server-side — cash trip, confirm_fare, rate_trip (P4-A-04)
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000040', 'authenticated', 'authenticated', '+2348000007401'),
  ('0f200000-0000-4000-8000-000000000040', 'authenticated', 'authenticated', '+2348000007402')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000040', '+2348000007401', 'UI04 Rider'),
  ('0f200000-0000-4000-8000-000000000040', '+2348000007402', 'UI04 Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000040', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000040', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'UI0401', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f400000-0000-4000-8000-000000000040', 'NG', 'car', 'UI4-01', 4, '0f200000-0000-4000-8000-000000000040')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000040', '0f400000-0000-4000-8000-000000000040', true)
on conflict do nothing;

-- Tier 2 cash trip (no fare_correction on as_shown)
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000040',
  '0f100000-0000-4000-8000-000000000040',
  '0f200000-0000-4000-8000-000000000040',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 800.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0f600000-0000-4000-8000-000000000040',
  '0f100000-0000-4000-8000-000000000040',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000040',
  '0f600000-0000-4000-8000-000000000040',
  1,
  '0f100000-0000-4000-8000-000000000040',
  '0f200000-0000-4000-8000-000000000040',
  '0f400000-0000-4000-8000-000000000040',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000040',
  800.00, 'NGN', 2, 0.05,
  'cash',
  'in_transit',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

-- Tier 3 completed trip for FM33
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000041',
  '0f100000-0000-4000-8000-000000000040',
  '0f200000-0000-4000-8000-000000000040',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 3, 950.00, 'NGN', '[]'::jsonb, 0.300,
  now() + interval '10 minutes'
);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  route_id, fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id, ended_at
) values (
  '0f700000-0000-4000-8000-000000000041',
  '0f600000-0000-4000-8000-000000000040',
  2,
  '0f100000-0000-4000-8000-000000000040',
  '0f200000-0000-4000-8000-000000000040',
  '0f400000-0000-4000-8000-000000000040',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000041',
  950.00, 'NGN', 3, 0.05,
  'cash',
  'completed',
  now() + interval '25 seconds',
  'color.naMe.blue', 'circle',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  now()
);

-- Cash complete_trip: zero payments rows
select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000040', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select complete_trip('0f700000-0000-4000-8000-000000000040'::uuid);

select is(
  (select count(*)::int from payments),
  0,
  'TS-UI-04: cash complete_trip creates zero payments rows'
);

-- confirm_fare Tier 3 as_shown → fare_corrections row (FM33)
select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000040', true);

select confirm_fare('0f700000-0000-4000-8000-000000000041'::uuid, 'as_shown', 950.00);

select ok(
  exists (
    select 1 from fare_corrections
    where trip_id = '0f700000-0000-4000-8000-000000000041'
      and submitter_role = 'rider'
  ),
  'TS-UI-04: confirm_fare as_shown on Tier 3 creates fare_corrections row (FM33)'
);

-- confirm_fare different → fare_corrections row
select confirm_fare('0f700000-0000-4000-8000-000000000040'::uuid, 'different', 900.00);

select ok(
  exists (
    select 1 from fare_corrections
    where trip_id = '0f700000-0000-4000-8000-000000000040'
      and proposed_fare = 900.00
  ),
  'TS-UI-04: confirm_fare different creates fare_corrections row'
);

-- rate_trip writes ratings
select rate_trip(
  '0f700000-0000-4000-8000-000000000040'::uuid,
  5::smallint,
  array['safe_driving', 'polite'],
  'Great trip'
);

select is(
  (select count(*)::int from ratings where trip_id = '0f700000-0000-4000-8000-000000000040'),
  1,
  'TS-UI-04: rate_trip writes ratings row'
);

select is(
  (select score from ratings where trip_id = '0f700000-0000-4000-8000-000000000040'),
  5::smallint,
  'TS-UI-04: rate_trip stores score'
);

select * from finish();
rollback;
