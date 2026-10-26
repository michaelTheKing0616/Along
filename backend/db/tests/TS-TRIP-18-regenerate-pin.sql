-- pgTAP: TS-TRIP-18 — rider regenerates the pickup PIN (PR #17)
create extension if not exists pgtap;

begin;
select plan(10);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('1f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000018001'),
  ('1f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000018002'),
  ('1f300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000018003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('1f100000-0000-4000-8000-000000000001', '+2348000018001', 'Party Rider'),
  ('1f200000-0000-4000-8000-000000000001', '+2348000018002', 'Party Driver'),
  ('1f300000-0000-4000-8000-000000000001', '+2348000018003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('1f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('1f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TRIP18', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('1f400000-0000-4000-8000-000000000001', 'NG', 'car', 'TRIP-18', 4, '1f200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('1f200000-0000-4000-8000-000000000001', '1f400000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '1f500000-0000-4000-8000-000000000001',
  '1f100000-0000-4000-8000-000000000001',
  '1f200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available
) values (
  '1f200000-0000-4000-8000-000000000001',
  '1f400000-0000-4000-8000-000000000001',
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3
) on conflict (driver_id) do update set status = excluded.status;

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '1f100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '1f600000-0000-4000-8000-000000000001',
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
      'fare', jsonb_build_object('amount', 320, 'currency', 'NGN', 'tier', 2, 'quote_id', '1f500000-0000-4000-8000-000000000001', 'unconfirmed', false),
      'supply', jsonb_build_object('kind', 'parked', 'driver_id', '1f200000-0000-4000-8000-000000000001')
    ))
  ))
);

select set_config('request.jwt.claim.sub', '1f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  request_trip('1f600000-0000-4000-8000-000000000001', 0, false, gen_random_uuid()) is not null,
  'request_trip succeeds for party rider'
);


select set_config('test.trip_id', (
  select id::text from trips where rider_id = '1f100000-0000-4000-8000-000000000001' limit 1
), true);

select set_config('request.jwt.claim.sub', '1f200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select respond_to_trip(current_setting('test.trip_id')::uuid, 'accept', null);

-- Driver burns two attempts.
reset role;
update trip_pins set attempts = 2, last_attempt_at = now() - interval '5 seconds'
where trip_id = current_setting('test.trip_id')::uuid;
select set_config('test.old', (select pin::text from trip_pins where trip_id = current_setting('test.trip_id')::uuid), true);

-- Driver and outsider may not regenerate.
set local role authenticated;
select throws_ok(
  format('select regenerate_trip_pin(%L::uuid)', current_setting('test.trip_id')),
  'P0001', 'FORBIDDEN', 'driver cannot regenerate the PIN'
);
select set_config('request.jwt.claim.sub', '1f300000-0000-4000-8000-000000000001', true);
select throws_ok(
  format('select regenerate_trip_pin(%L::uuid)', current_setting('test.trip_id')),
  'P0001', 'FORBIDDEN', 'outsider cannot regenerate the PIN'
);

select set_config('request.jwt.claim.sub', '1f100000-0000-4000-8000-000000000001', true);
select set_config('test.r1', regenerate_trip_pin(current_setting('test.trip_id')::uuid)::text, true);
select ok((current_setting('test.r1')::jsonb->>'regenerated')::boolean, 'rider gets a new PIN');
select isnt(current_setting('test.r1')::jsonb->>'pin', current_setting('test.old'), 'new PIN differs');
reset role;
select is(
  (select attempts from trip_pins where trip_id = current_setting('test.trip_id')::uuid),
  0, 'driver attempt counter resets'
);
set local role authenticated;
select ok(
  (regenerate_trip_pin(current_setting('test.trip_id')::uuid)->>'rate_limited')::boolean,
  'second regeneration within 30 s is rate limited'
);
reset role;
update trip_pins set regenerations = 3, regenerated_at = now() - interval '1 minute'
where trip_id = current_setting('test.trip_id')::uuid;
set local role authenticated;
select ok(
  (regenerate_trip_pin(current_setting('test.trip_id')::uuid)->>'limit_reached')::boolean,
  'at most 3 new PINs per trip'
);

-- RLS: rider still reads only their own trip's PIN; no client writes.
select throws_ok(
  format('update trip_pins set pin = %L where trip_id = %L::uuid', '1111', current_setting('test.trip_id')),
  '42501', null, 'rider cannot write trip_pins directly'
);
reset role;

-- After boarding, no regeneration.
update trip_pins set regenerations = 0 where trip_id = current_setting('test.trip_id')::uuid;
select trip_transition(current_setting('test.trip_id')::uuid, 'boarded'::trip_status,
  'rider', '1f100000-0000-4000-8000-000000000001');
set local role authenticated;
select throws_ok(
  format('select regenerate_trip_pin(%L::uuid)', current_setting('test.trip_id')),
  'P0001', 'STATE_INVALID', 'no new PIN once boarded'
);

select * from finish();
rollback;
