-- pgTAP: TS-TRIP-04 — expiry job flips requested past expires_at to expired (P3-A-01)
create extension if not exists pgtap;

begin;
select plan(3);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0c100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000004011'),
  ('0c200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000004012')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0c100000-0000-4000-8000-000000000002', '+2348000004011', 'Expiry Rider'),
  ('0c200000-0000-4000-8000-000000000002', '+2348000004012', 'Expiry Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0c100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0c200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'EXPTRP01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0c300000-0000-4000-8000-000000000002', 'NG', 'car', 'EXP-01', 4, '0c200000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0c200000-0000-4000-8000-000000000002', '0c300000-0000-4000-8000-000000000002', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0c400000-0000-4000-8000-000000000002',
  '0c100000-0000-4000-8000-000000000002',
  '0c200000-0000-4000-8000-000000000002',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0c500000-0000-4000-8000-000000000002',
  '0c100000-0000-4000-8000-000000000002',
  '0a000000-0000-4000-8000-000000000001',
  'planning',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0c600000-0000-4000-8000-000000000002","source":"parked","kind":"direct"}'::jsonb
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape
) values (
  '0c700000-0000-4000-8000-000000000002',
  '0c500000-0000-4000-8000-000000000002',
  '0c100000-0000-4000-8000-000000000002',
  '0c200000-0000-4000-8000-000000000002',
  '0c300000-0000-4000-8000-000000000002',
  'car',
  '0c400000-0000-4000-8000-000000000002',
  320.00, 'NGN', 2, 0.05,
  'requested',
  now() - interval '5 seconds',
  'color.naMe.blue', 'circle'
);

select is(
  expire_requests(),
  1,
  'TS-TRIP-04: expire_requests returns 1 expired trip'
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000002'),
  'expired',
  'TS-TRIP-04: requested past expires_at → expired'
);

select ok(
  exists (
    select 1 from trip_events
    where trip_id = '0c700000-0000-4000-8000-000000000002'
      and from_status = 'requested'
      and to_status = 'expired'
      and actor_type = 'system'
  ),
  'TS-TRIP-04: expiry recorded as system trip_event'
);

select * from finish();
rollback;
