-- pgTAP: TS-TRIP-19 — rider regenerates the pickup PIN (PR #17)
create extension if not exists pgtap;

begin;
select plan(12);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('1e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000019001'),
  ('1e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000019002'),
  ('1e300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000019003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('1e100000-0000-4000-8000-000000000001', '+2348000019001', 'Party Rider'),
  ('1e200000-0000-4000-8000-000000000001', '+2348000019002', 'Party Driver'),
  ('1e300000-0000-4000-8000-000000000001', '+2348000019003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('1e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('1e200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TRIP19', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('1e400000-0000-4000-8000-000000000001', 'NG', 'car', 'TRIP-19', 4, '1e200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('1e200000-0000-4000-8000-000000000001', '1e400000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '1e500000-0000-4000-8000-000000000001',
  '1e100000-0000-4000-8000-000000000001',
  '1e200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available
) values (
  '1e200000-0000-4000-8000-000000000001',
  '1e400000-0000-4000-8000-000000000001',
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3
) on conflict (driver_id) do update set status = excluded.status;

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '1e100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '1e600000-0000-4000-8000-000000000001',
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
      'fare', jsonb_build_object('amount', 320, 'currency', 'NGN', 'tier', 2, 'quote_id', '1e500000-0000-4000-8000-000000000001', 'unconfirmed', false),
      'supply', jsonb_build_object('kind', 'parked', 'driver_id', '1e200000-0000-4000-8000-000000000001')
    ))
  ))
);

select set_config('request.jwt.claim.sub', '1e100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  request_trip('1e600000-0000-4000-8000-000000000001', 0, false, gen_random_uuid()) is not null,
  'request_trip succeeds for party rider'
);


select set_config('test.trip_id', (
  select id::text from trips where rider_id = '1e100000-0000-4000-8000-000000000001' limit 1
), true);

select set_config('request.jwt.claim.sub', '1e200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select respond_to_trip(current_setting('test.trip_id')::uuid, 'accept', null);

-- Live (accepted): both parties may chat; outsider may not.
select is(
  post_trip_message(current_setting('test.trip_id')::uuid, 'Arriving in 2 min', 'drv-00000001')->>'author_role',
  'driver', 'driver posts while the trip is live'
);
select set_config('request.jwt.claim.sub', '1e100000-0000-4000-8000-000000000001', true);
select is(
  post_trip_message(current_setting('test.trip_id')::uuid, 'I''m at the pickup', 'rdr-00000001')->>'author_role',
  'rider', 'rider posts while the trip is live'
);
select ok(
  (post_trip_message(current_setting('test.trip_id')::uuid, 'I''m at the pickup', 'rdr-00000001')->>'replayed')::boolean,
  'retry with the same client_ref is idempotent'
);
select is(jsonb_array_length(list_trip_messages(current_setting('test.trip_id')::uuid)), 2, 'rider sees both messages');
select is(mark_trip_messages_read(current_setting('test.trip_id')::uuid), 1, 'rider marks the driver message read');
select ok(
  exists (select 1 from jsonb_array_elements(list_trip_messages(current_setting('test.trip_id')::uuid)) m
          where m->>'author_role' = 'driver' and m->>'read_at' is not null),
  'read receipt is visible'
);

select set_config('request.jwt.claim.sub', '1e300000-0000-4000-8000-000000000001', true);
select throws_ok(
  format('select post_trip_message(%L::uuid, %L, %L)', current_setting('test.trip_id'), 'hi', 'out-00000001'),
  'P0001', 'FORBIDDEN', 'outsider cannot post'
);
select is((select count(*)::int from trip_messages), 0, 'outsider reads no messages (RLS)');
select throws_ok(
  format('insert into trip_messages (trip_id, author_id, author_role, body, client_ref) values (%L::uuid, %L::uuid, %L, %L, %L)',
    current_setting('test.trip_id'), '1e300000-0000-4000-8000-000000000001', 'rider', 'x', 'out-00000002'),
  '42501', null, 'no direct inserts'
);

-- Rate limit: 6 per 10 s per sender.
select set_config('request.jwt.claim.sub', '1e100000-0000-4000-8000-000000000001', true);
select count(post_trip_message(current_setting('test.trip_id')::uuid, 'm' || g, 'rdr-burst-' || g)) from generate_series(1, 5) g;
select throws_ok(
  format('select post_trip_message(%L::uuid, %L, %L)', current_setting('test.trip_id'), 'one more', 'rdr-burst-99'),
  'P0001', 'RATE_LIMITED', 'seventh message in 10 s is rate limited'
);
select throws_ok(
  format('select post_trip_message(%L::uuid, %L, %L)', current_setting('test.trip_id'), repeat('a', 281), 'rdr-long-001'),
  'P0001', 'VALIDATION', 'bodies over 280 chars are rejected'
);

select * from finish();
rollback;
