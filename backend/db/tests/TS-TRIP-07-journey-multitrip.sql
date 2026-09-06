-- pgTAP: TS-TRIP-07 — 2-leg journey → transfer after trip 1, completed after trip 2 (P2-A-04)
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0d100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005001'),
  ('0d200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005002'),
  ('0d200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000005003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0d100000-0000-4000-8000-000000000001', '+2348000005001', 'Journey Rider'),
  ('0d200000-0000-4000-8000-000000000001', '+2348000005002', 'Journey Driver 1'),
  ('0d200000-0000-4000-8000-000000000002', '+2348000005003', 'Journey Driver 2')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0d200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'JTRP01', '0a020000-0000-4000-8000-000000000001'),
  ('0d200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'JTRP02', '0a020000-0000-4000-8000-000000000002')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0d300000-0000-4000-8000-000000000001', 'NG', 'car', 'JTR-01', 4, '0d200000-0000-4000-8000-000000000001'),
  ('0d300000-0000-4000-8000-000000000002', 'NG', 'keke', 'JTR-02', 3, '0d200000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0d200000-0000-4000-8000-000000000001', '0d300000-0000-4000-8000-000000000001', true),
  ('0d200000-0000-4000-8000-000000000002', '0d300000-0000-4000-8000-000000000002', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values
  (
    '0d400000-0000-4000-8000-000000000001',
    '0d100000-0000-4000-8000-000000000001',
    '0d200000-0000-4000-8000-000000000001',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
    now() + interval '10 minutes'
  ),
  (
    '0d400000-0000-4000-8000-000000000002',
    '0d100000-0000-4000-8000-000000000001',
    '0d200000-0000-4000-8000-000000000002',
    '0a030000-0000-4000-8000-000000000002',
    '0a041000-0000-4000-8000-000000000005',
    '0a041000-0000-4000-8000-000000000004',
    'keke', 2, 80.00, 'NGN', '[{"kind":"through","amount":80}]'::jsonb, 0.900,
    now() + interval '10 minutes'
  );

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot, current_trip_sequence
) values (
  '0d500000-0000-4000-8000-000000000001',
  '0d100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.710, 11.070), 4326)::geography,
  jsonb_build_object(
    'candidate_id', '0d600000-0000-4000-8000-000000000001',
    'kind', 'multi_leg',
    'source', 'graph',
    'legs', jsonb_build_array(
      jsonb_build_object(
        'leg_index', 0,
        'mode', jsonb_build_object('code', 'car', 'label', 'Along taxi'),
        'board', jsonb_build_object(
          'stage_id', '0a040000-0000-4000-8000-000000000001',
          'name', 'Test Park Alpha',
          'location', jsonb_build_object('lat', 11.060, 'lng', 7.700)
        ),
        'alight', jsonb_build_object(
          'stage_id', '0a040000-0000-4000-8000-000000000005',
          'name', 'Test Park Beta',
          'location', jsonb_build_object('lat', 11.065, 'lng', 7.705)
        ),
        'in_vehicle_s', 600
      ),
      jsonb_build_object(
        'leg_index', 1,
        'mode', jsonb_build_object('code', 'keke', 'label', 'Keke'),
        'board', jsonb_build_object(
          'stage_id', '0a041000-0000-4000-8000-000000000005',
          'name', 'Test Park Beta',
          'location', jsonb_build_object('lat', 11.065, 'lng', 7.705)
        ),
        'alight', jsonb_build_object(
          'stage_id', '0a041000-0000-4000-8000-000000000004',
          'name', 'Test Junction Epsilon',
          'location', jsonb_build_object('lat', 11.064, 'lng', 7.704)
        ),
        'in_vehicle_s', 480
      )
    )
  ),
  1
);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id,
  boarding_location, alighting_location,
  started_at
) values
  (
    '0d700000-0000-4000-8000-000000000001',
    '0d500000-0000-4000-8000-000000000001',
    1,
    '0d100000-0000-4000-8000-000000000001',
    '0d200000-0000-4000-8000-000000000001',
    '0d300000-0000-4000-8000-000000000001',
    'car',
    '0d400000-0000-4000-8000-000000000001',
    320.00, 'NGN', 2, 0.05,
    'in_transit',
    now() + interval '25 seconds',
    'color.naMe.green', 'diamond',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    now() - interval '8 minutes'
  ),
  (
    '0d700000-0000-4000-8000-000000000002',
    '0d500000-0000-4000-8000-000000000001',
    2,
    '0d100000-0000-4000-8000-000000000001',
    '0d200000-0000-4000-8000-000000000002',
    '0d300000-0000-4000-8000-000000000002',
    'keke',
    '0d400000-0000-4000-8000-000000000002',
    80.00, 'NGN', 2, 0.05,
    'in_transit',
    now() + interval '25 seconds',
    'color.naMe.blue', 'circle',
    '0a041000-0000-4000-8000-000000000005',
    '0a041000-0000-4000-8000-000000000004',
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    st_setsrid(st_makepoint(7.704, 11.064), 4326)::geography,
    now() - interval '4 minutes'
  );

select is(
  _journey_planned_leg_count('0d500000-0000-4000-8000-000000000001'::uuid),
  2,
  'TS-TRIP-07: journey plan has 2 legs'
);

-- Complete trip 1 → journey transfer
select trip_transition(
  '0d700000-0000-4000-8000-000000000001'::uuid,
  'completed'::trip_status,
  'driver'::actor_type,
  '0d200000-0000-4000-8000-000000000001'::uuid
);

select is(
  (select status::text from journeys where id = '0d500000-0000-4000-8000-000000000001'),
  'transfer',
  'TS-TRIP-07: journey → transfer after trip 1 completed'
);

select is(
  (select current_trip_sequence from journeys where id = '0d500000-0000-4000-8000-000000000001'),
  2::smallint,
  'TS-TRIP-07: current_trip_sequence advances to 2'
);

-- Complete trip 2 → journey completed
select trip_transition(
  '0d700000-0000-4000-8000-000000000002'::uuid,
  'completed'::trip_status,
  'driver'::actor_type,
  '0d200000-0000-4000-8000-000000000002'::uuid
);

select is(
  (select status::text from journeys where id = '0d500000-0000-4000-8000-000000000001'),
  'completed',
  'TS-TRIP-07: journey → completed after trip 2 completed'
);

select ok(
  (select completed_at is not null from journeys where id = '0d500000-0000-4000-8000-000000000001'),
  'TS-TRIP-07: journey completed_at set'
);

select * from finish();
rollback;
