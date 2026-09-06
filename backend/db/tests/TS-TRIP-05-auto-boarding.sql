-- pgTAP: TS-TRIP-05 + false-trigger gate — auto-boarding co-location (P3-A-01)
create extension if not exists pgtap;

begin;
select plan(6);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

-- Shared coords (co-located) and far-away driver coords
-- Zaria test city ~ 11.06, 7.70

insert into auth.users (id, aud, role, phone) values
  ('0c100000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000004101'),
  ('0c100000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000004102'),
  ('0c200000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000004103'),
  ('0c200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000004104')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0c100000-0000-4000-8000-000000000010', '+2348000004101', 'Auto Rider'),
  ('0c100000-0000-4000-8000-000000000011', '+2348000004102', 'Other Rider'),
  ('0c200000-0000-4000-8000-000000000010', '+2348000004103', 'Auto Driver'),
  ('0c200000-0000-4000-8000-000000000011', '+2348000004104', 'Stranger Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0c100000-0000-4000-8000-000000000010', '0a000000-0000-4000-8000-000000000001'),
  ('0c100000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0c200000-0000-4000-8000-000000000010', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'AUTOD01', '0a020000-0000-4000-8000-000000000001'),
  ('0c200000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'AUTOD02', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0c300000-0000-4000-8000-000000000010', 'NG', 'car', 'AUT-01', 4, '0c200000-0000-4000-8000-000000000010'),
  ('0c300000-0000-4000-8000-000000000011', 'NG', 'car', 'AUT-02', 4, '0c200000-0000-4000-8000-000000000011')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0c200000-0000-4000-8000-000000000010', '0c300000-0000-4000-8000-000000000010', true),
  ('0c200000-0000-4000-8000-000000000011', '0c300000-0000-4000-8000-000000000011', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values
  (
    '0c400000-0000-4000-8000-000000000010',
    '0c100000-0000-4000-8000-000000000010',
    '0c200000-0000-4000-8000-000000000010',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
    now() + interval '10 minutes'
  ),
  (
    '0c400000-0000-4000-8000-000000000011',
    '0c100000-0000-4000-8000-000000000011',
    '0c200000-0000-4000-8000-000000000011',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
    now() + interval '10 minutes'
  );

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  (
    '0c500000-0000-4000-8000-000000000010',
    '0c100000-0000-4000-8000-000000000010',
    '0a000000-0000-4000-8000-000000000001',
    'active',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '{"source":"parked"}'::jsonb
  ),
  (
    '0c500000-0000-4000-8000-000000000011',
    '0c100000-0000-4000-8000-000000000011',
    '0a000000-0000-4000-8000-000000000001',
    'active',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '{"source":"parked"}'::jsonb
  );

-- Trip T1: Auto Rider + Auto Driver (accepted)
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0c700000-0000-4000-8000-000000000010',
  '0c500000-0000-4000-8000-000000000010',
  '0c100000-0000-4000-8000-000000000010',
  '0c200000-0000-4000-8000-000000000010',
  '0c300000-0000-4000-8000-000000000010',
  'car',
  '0c400000-0000-4000-8000-000000000010',
  320.00, 'NGN', 2, 0.05,
  'accepted',
  now() + interval '25 seconds',
  now() - interval '1 minute',
  'color.naMe.green', 'diamond'
);

-- Trip T2: Other Rider + Stranger Driver (accepted) — for false-trigger gate
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0c700000-0000-4000-8000-000000000011',
  '0c500000-0000-4000-8000-000000000011',
  '0c100000-0000-4000-8000-000000000011',
  '0c200000-0000-4000-8000-000000000011',
  '0c300000-0000-4000-8000-000000000011',
  'car',
  '0c400000-0000-4000-8000-000000000011',
  320.00, 'NGN', 2, 0.05,
  'accepted',
  now() + interval '25 seconds',
  now() - interval '1 minute',
  'color.naMe.blue', 'circle'
);

-- TS-TRIP-05: co-located 20s with movement → boarded (auto_colocation)
select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000010', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0601, 'lng', 7.7001, 'accuracy_m', 10, 'speed_mps', 2.0)
  )
);

select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000010', true);

select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0601, 'lng', 7.7001, 'accuracy_m', 10, 'speed_mps', 2.0)
  )
);

-- Simulate 21s of sustained co-location (fresh samples within max_age window)
update trips
set meta = jsonb_build_object('colocated_since', (now() - interval '21 seconds')::text)
where id = '0c700000-0000-4000-8000-000000000010';

select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0601, 'lng', 7.7001, 'accuracy_m', 10, 'speed_mps', 2.5)
  )
);

select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0601, 'lng', 7.7001, 'accuracy_m', 10, 'speed_mps', 2.5)
  )
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000010'),
  'boarded',
  'TS-TRIP-05: co-located 20s with movement → boarded'
);

select is(
  (select boarded_via from trips where id = '0c700000-0000-4000-8000-000000000010'),
  'auto_colocation',
  'TS-TRIP-05: auto_colocation boarded_via'
);

-- Reset trip T-stationary for stationary test
select set_config('along.in_transition', 'on', true);
update trips set status = 'accepted', boarded_at = null, boarded_via = null, meta = '{}'::jsonb
where id = '0c700000-0000-4000-8000-000000000010';
select set_config('along.in_transition', '', true);
delete from trip_location_samples where trip_id = '0c700000-0000-4000-8000-000000000010';

-- TS-TRIP-05: co-located but both stationary → no transition
select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0602, 'lng', 7.7002, 'accuracy_m', 10, 'speed_mps', 0)
  )
);

update trips
set meta = jsonb_build_object('colocated_since', (now() - interval '21 seconds')::text)
where id = '0c700000-0000-4000-8000-000000000010';

select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0602, 'lng', 7.7002, 'accuracy_m', 10, 'speed_mps', 0)
  )
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000010'),
  'accepted',
  'TS-TRIP-05: co-located stationary → no transition'
);

-- TS-TRIP-05: rider without samples → no auto
delete from trip_location_samples where trip_id = '0c700000-0000-4000-8000-000000000010';
update trips set meta = '{}'::jsonb where id = '0c700000-0000-4000-8000-000000000010';

select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0603, 'lng', 7.7003, 'accuracy_m', 10, 'speed_mps', 3.0, 'ts', now()::text)
  )
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000010'),
  'accepted',
  'TS-TRIP-05: rider without samples → no auto-board'
);

-- False-trigger gate: rider co-located with stranger driver (different trip) → no auto on either trip
-- Auto Rider on T1 matched to Auto Driver; Stranger Driver D2 co-located with rider but on T2 with Other Rider
delete from trip_location_samples where trip_id in (
  '0c700000-0000-4000-8000-000000000010',
  '0c700000-0000-4000-8000-000000000011'
);
update trips set status = 'accepted', boarded_at = null, boarded_via = null, meta = '{}'::jsonb
where id in ('0c700000-0000-4000-8000-000000000010', '0c700000-0000-4000-8000-000000000011');

-- Rider on T1 samples at pickup; matched driver D1 is far away
select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0604, 'lng', 7.7004, 'accuracy_m', 10, 'speed_mps', 2.0)
  )
);

-- Stranger driver D2 co-located with rider (same coords) but samples on T2, not T1
select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000011', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000011'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0604, 'lng', 7.7004, 'accuracy_m', 10, 'speed_mps', 2.0)
  )
);

update trips
set meta = jsonb_build_object('colocated_since', (now() - interval '21 seconds')::text)
where id = '0c700000-0000-4000-8000-000000000011';

-- Matched driver D1 far from rider — samples on T1
select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000010', true);
select trip_location_sample(
  '0c700000-0000-4000-8000-000000000010'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0800, 'lng', 7.7200, 'accuracy_m', 10, 'speed_mps', 2.0)
  )
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000010'),
  'accepted',
  'false-trigger gate: co-located without match on same trip → no auto-board on T1'
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000011'),
  'accepted',
  'false-trigger gate: stranger co-location on different trip → no auto-board on T2'
);

select * from finish();
rollback;
