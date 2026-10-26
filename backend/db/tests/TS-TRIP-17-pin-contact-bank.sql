-- pgTAP: TS-TRIP-17 — driver PIN check, start gate, contact target, bank name (PR #17)
create extension if not exists pgtap;

begin;
select plan(13);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('1e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000017001'),
  ('1e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000017002'),
  ('1e300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000017003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('1e100000-0000-4000-8000-000000000001', '+2348000017001', 'Party Rider'),
  ('1e200000-0000-4000-8000-000000000001', '+2348000017002', 'Party Driver'),
  ('1e300000-0000-4000-8000-000000000001', '+2348000017003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('1e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('1e200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TRIP17', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('1e400000-0000-4000-8000-000000000001', 'NG', 'car', 'TRIP-17', 4, '1e200000-0000-4000-8000-000000000001')
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
reset role;


-- Contact target (service role path used by trip-contact)
select is(
  trip_contact_target(current_setting('test.trip_id')::uuid, '1e100000-0000-4000-8000-000000000001')->>'target_phone',
  '+2348000017002',
  'rider on a live trip resolves the driver as contact target'
);
select throws_ok(
  format('select trip_contact_target(%L::uuid, %L::uuid)', current_setting('test.trip_id'), '1e300000-0000-4000-8000-000000000001'),
  'P0001', 'FORBIDDEN', 'contact: caller not on the trip is denied'
);

select set_config('request.jwt.claim.sub', '1e100000-0000-4000-8000-000000000001', true);
set local role authenticated;
select throws_ok(
  format('select trip_contact_target(%L::uuid, %L::uuid)', current_setting('test.trip_id'), '1e100000-0000-4000-8000-000000000001'),
  '42501', null, 'contact target is not callable by clients'
);
reset role;

-- PIN verification
select set_config('request.jwt.claim.sub', '1e100000-0000-4000-8000-000000000001', true);
set local role authenticated;
select throws_ok(
  format('select verify_trip_pin(%L::uuid, %L)', current_setting('test.trip_id'), '0000'),
  'P0001', 'FORBIDDEN', 'rider cannot verify the PIN'
);
reset role;

select set_config('test.wrong', (
  select case when pin = '0000' then '1111' else '0000' end from trip_pins
  where trip_id = current_setting('test.trip_id')::uuid
), true);

select set_config('request.jwt.claim.sub', '1e200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select is(
  (verify_trip_pin(current_setting('test.trip_id')::uuid, current_setting('test.wrong'))->>'attempts_left')::int,
  4,
  'wrong PIN costs one attempt'
);
select is(
  (verify_trip_pin(current_setting('test.trip_id')::uuid, current_setting('test.wrong'))->>'rate_limited')::boolean,
  true,
  'a second try within a second is rate limited'
);
reset role;
update trip_pins set attempts = 5, last_attempt_at = now() - interval '5 seconds'
where trip_id = current_setting('test.trip_id')::uuid;
set local role authenticated;
select is(
  (verify_trip_pin(current_setting('test.trip_id')::uuid,
    (select '0000'))->>'locked')::boolean,
  true,
  'after 5 wrong tries the PIN is locked'
);
reset role;
update trip_pins set attempts = 0, last_attempt_at = now() - interval '5 seconds'
where trip_id = current_setting('test.trip_id')::uuid;
select set_config('test.pin', (
  select pin::text from trip_pins where trip_id = current_setting('test.trip_id')::uuid
), true);
-- boarded without PIN (system path), start is gated
select trip_transition(current_setting('test.trip_id')::uuid, 'boarded'::trip_status,
  'system'::actor_type);
set local role authenticated;
select throws_ok(
  format('select start_trip(%L::uuid)', current_setting('test.trip_id')),
  'P0001', 'PIN_REQUIRED', 'start_trip is refused until the PIN is cleared'
);
select is(
  (verify_trip_pin(current_setting('test.trip_id')::uuid, current_setting('test.pin'))->>'verified')::boolean,
  true,
  'the right PIN verifies'
);
select lives_ok(
  format('select start_trip(%L::uuid)', current_setting('test.trip_id')),
  'start_trip works once the PIN is cleared'
);
select throws_ok(
  format('select verify_trip_pin(%L::uuid, %L)', current_setting('test.trip_id'), '0000'),
  'P0001', 'STATE_INVALID', 'PIN check is closed once the trip is in transit'
);
reset role;

select set_config('request.jwt.claim.sub', '1e200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select throws_ok(
  $$ update drivers set payout_bank_name = 'Fake Bank' where id = '1e200000-0000-4000-8000-000000000001' $$,
  '42501', null, 'drivers cannot set their own bank name directly'
);

select * from finish();
rollback;
