-- pgTAP: cash trip completion creates no settlement rows (zero payment path)
create extension if not exists pgtap;

begin;
select plan(1);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000020', 'authenticated', 'authenticated', '+2348000007201'),
  ('0f200000-0000-4000-8000-000000000020', 'authenticated', 'authenticated', '+2348000007202')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000020', '+2348000007201', 'Cash Gate Rider'),
  ('0f200000-0000-4000-8000-000000000020', '+2348000007202', 'Cash Gate Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000020', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000020', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'CSH01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f400000-0000-4000-8000-000000000020', 'NG', 'car', 'CSH-01', 4, '0f200000-0000-4000-8000-000000000020')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000020', '0f400000-0000-4000-8000-000000000020', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f500000-0000-4000-8000-000000000020',
  '0f100000-0000-4000-8000-000000000020',
  '0f200000-0000-4000-8000-000000000020',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 800.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0f600000-0000-4000-8000-000000000020',
  '0f100000-0000-4000-8000-000000000020',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0f600000-0000-4000-8000-000000000099","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f700000-0000-4000-8000-000000000020',
  '0f600000-0000-4000-8000-000000000020',
  1,
  '0f100000-0000-4000-8000-000000000020',
  '0f200000-0000-4000-8000-000000000020',
  '0f400000-0000-4000-8000-000000000020',
  'car',
  '0f500000-0000-4000-8000-000000000020',
  800.00, 'NGN', 2, 0.05,
  'cash',
  'in_transit',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000020', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select complete_trip('0f700000-0000-4000-8000-000000000020'::uuid);

select is(
  (select count(*)::int from settlements where driver_id = '0f200000-0000-4000-8000-000000000020'),
  0,
  'cash-trip gate: complete_trip creates zero settlement rows'
);

select * from finish();
rollback;
