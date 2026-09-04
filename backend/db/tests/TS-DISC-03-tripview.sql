-- pgTAP: TS-DISC-03 — TripView for non-party caller returns FORBIDDEN (P1-A-05)
create extension if not exists pgtap;

begin;
select plan(2);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0d100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005001'),
  ('0d200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005002'),
  ('0d300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0d100000-0000-4000-8000-000000000001', '+2348000005001', 'Party Rider'),
  ('0d200000-0000-4000-8000-000000000001', '+2348000005002', 'Party Driver'),
  ('0d300000-0000-4000-8000-000000000001', '+2348000005003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0d200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'DISC03', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0d400000-0000-4000-8000-000000000001', 'NG', 'car', 'DISC-03', 4, '0d200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0d200000-0000-4000-8000-000000000001', '0d400000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0d500000-0000-4000-8000-000000000001',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available
) values (
  '0d200000-0000-4000-8000-000000000001',
  '0d400000-0000-4000-8000-000000000001',
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3
) on conflict (driver_id) do update set status = excluded.status;

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '0d100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '0d600000-0000-4000-8000-000000000001',
    'kind', 'direct', 'source', 'parked', 'viable_direct', true,
    'legs', jsonb_build_array(jsonb_build_object(
      'leg_index', 0,
      'mode', jsonb_build_object('code', 'car'),
      'board', jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000001', 'name', 'Test Park Alpha',
        'location', jsonb_build_object('lat', 11.060, 'lng', 7.700), 'walk_m', 0, 'walk_s', 0, 'wayfinding_available', true),
      'alight', jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005', 'name', 'Test Park Beta',
        'location', jsonb_build_object('lat', 11.065, 'lng', 7.705)),
      'route_id', '0a030000-0000-4000-8000-000000000001',
      'route_leg_ids', '[]'::jsonb,
      'fare', jsonb_build_object('amount', 320, 'currency', 'NGN', 'tier', 2, 'quote_id', '0d500000-0000-4000-8000-000000000001', 'unconfirmed', false),
      'supply', jsonb_build_object('kind', 'parked', 'driver_id', '0d200000-0000-4000-8000-000000000001')
    ))
  ))
);

select set_config('request.jwt.claim.sub', '0d100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  request_trip('0d600000-0000-4000-8000-000000000001', 0, false, gen_random_uuid()) is not null,
  'request_trip succeeds for party rider'
);

select set_config('test.disc03_trip_id', (
  select id::text from trips where rider_id = '0d100000-0000-4000-8000-000000000001' limit 1
), true);

select set_config('request.jwt.claim.sub', '0d300000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  format(
    $$ select trip_snapshot(%L::uuid) $$,
    current_setting('test.disc03_trip_id')
  ),
  'P0001',
  'FORBIDDEN',
  'TS-DISC-03: non-party trip_snapshot raises FORBIDDEN'
);

select * from finish();
rollback;
