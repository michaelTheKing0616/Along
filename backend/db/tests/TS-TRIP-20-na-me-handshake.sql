-- pgTAP: TS-TRIP-20 — Na Me handshake: unique pairing, secret, confirm_na_me_match
create extension if not exists pgtap;

begin;
select plan(19);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('1f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000020001'),
  ('1f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000020002'),
  ('1f300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000020003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('1f100000-0000-4000-8000-000000000001', '+2348000020001', 'Party Rider'),
  ('1f200000-0000-4000-8000-000000000001', '+2348000020002', 'Party Driver'),
  ('1f300000-0000-4000-8000-000000000001', '+2348000020003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('1f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('1f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TRIP20', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('1f400000-0000-4000-8000-000000000001', 'NG', 'car', 'TRIP-20', 4, '1f200000-0000-4000-8000-000000000001')
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

reset role;
insert into riders (id, home_city_id) values
  ('1f300000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;
-- A second live trip at the same stage already holds the pairing this trip would get.
insert into trips
select (jsonb_populate_record(null::trips, to_jsonb(t) || jsonb_build_object(
  'id', '1f700000-0000-4000-8000-000000000001',
  'rider_id', '1f300000-0000-4000-8000-000000000001',
  'journey_sequence', 99))).*
from trips t where t.id = current_setting('test.trip_id')::uuid;

select set_config('request.jwt.claim.sub', '1f200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select respond_to_trip(current_setting('test.trip_id')::uuid, 'accept', null);
reset role;

select isnt(
  (select id_signal_color || ':' || id_signal_shape from trips where id = current_setting('test.trip_id')::uuid),
  (select id_signal_color || ':' || id_signal_shape from trips where id = '1f700000-0000-4000-8000-000000000001'),
  'accept re-picks a pairing no other live trip at the stage holds'
);
select is((select count(*)::int from trip_handshakes where trip_id = current_setting('test.trip_id')::uuid), 1,
  'accept creates the handshake secret');
select set_config('test.real', (select id_signal_color || ':' || id_signal_shape from trips where id = current_setting('test.trip_id')::uuid), true);
select set_config('test.decoy', (select id_signal_color || ':' || id_signal_shape from trips where id = '1f700000-0000-4000-8000-000000000001'), true);

-- Secret visibility.
select set_config('request.jwt.claim.sub', '1f100000-0000-4000-8000-000000000001', true);
set local role authenticated;
select is((select count(*)::int from trip_handshakes), 1, 'rider reads the secret');
select throws_ok(
  format('select confirm_na_me_match(%L::uuid, %L::jsonb)', current_setting('test.trip_id'), '{"method":"tap"}'),
  'P0001', 'FORBIDDEN', 'rider cannot confirm'
);
select set_config('request.jwt.claim.sub', '1f300000-0000-4000-8000-000000000001', true);
select is((select count(*)::int from trip_handshakes), 0, 'outsider reads no secret (RLS)');
select throws_ok('update trip_handshakes set attempts = 0', '42501', null, 'no direct writes');

-- Tap options for the driver.
select set_config('request.jwt.claim.sub', '1f200000-0000-4000-8000-000000000001', true);
select is(jsonb_array_length(na_me_tap_options(current_setting('test.trip_id')::uuid)->'options'), 4, 'four tap choices');
select is(
  (select count(*)::int from jsonb_array_elements(na_me_tap_options(current_setting('test.trip_id')::uuid)->'options') o
   where o->>'color_token' || ':' || (o->>'shape') = current_setting('test.real')), 1,
  'the real pairing appears exactly once'
);
select is(
  (select count(*)::int from jsonb_array_elements(na_me_tap_options(current_setting('test.trip_id')::uuid)->'options') o
   where o->>'color_token' || ':' || (o->>'shape') = current_setting('test.decoy')), 0,
  'another live trip''s real pairing is never a decoy'
);
select is(
  na_me_tap_options(current_setting('test.trip_id')::uuid),
  na_me_tap_options(current_setting('test.trip_id')::uuid),
  'choices are stable, so refetching reveals nothing'
);

-- Wrong tap: neutral, counts, locks tap-match.
select is(
  confirm_na_me_match(current_setting('test.trip_id')::uuid,
    jsonb_build_object('method', 'tap', 'color_token', split_part(current_setting('test.decoy'), ':', 1), 'shape', split_part(current_setting('test.decoy'), ':', 2))),
  '{"locked": false, "matched": false, "tap_locked": true, "attempts_left": 2}'::jsonb,
  'wrong tap is neutral, counts toward the cap and locks tap-match'
);
select ok(
  (confirm_na_me_match(current_setting('test.trip_id')::uuid, '{"method":"optical","code":1,"step":1}')->>'rate_limited')::boolean,
  'attempts are rate-limited'
);
reset role;
update trip_handshakes set last_attempt_at = now() - interval '5 seconds' where trip_id = current_setting('test.trip_id')::uuid;
set local role authenticated;
select is(
  (confirm_na_me_match(current_setting('test.trip_id')::uuid,
    jsonb_build_object('method', 'tap', 'color_token', split_part(current_setting('test.real'), ':', 1), 'shape', split_part(current_setting('test.real'), ':', 2)))->>'matched')::boolean,
  false, 'a locked tap-match refuses even the right pairing'
);

-- Optical: a stale proof fails; one inside the skew window boards the rider.
reset role;
update trip_handshakes set last_attempt_at = null where trip_id = current_setting('test.trip_id')::uuid;
select set_config('test.step', (floor(extract(epoch from now()) / 10)::bigint)::text, true);
select set_config('test.stale', _na_me_optical_code(secret, current_setting('test.step')::bigint - 61)::text, true),
       set_config('test.ahead', _na_me_optical_code(secret, current_setting('test.step')::bigint + 2)::text, true)
from trip_handshakes where trip_id = current_setting('test.trip_id')::uuid;
set local role authenticated;
select is(
  (confirm_na_me_match(current_setting('test.trip_id')::uuid, jsonb_build_object('method', 'optical',
    'step', current_setting('test.step')::bigint - 61, 'code', current_setting('test.stale')::int))->>'attempts_left')::int,
  1, 'a proof older than 10 minutes fails and counts'
);
reset role;
update trip_handshakes set last_attempt_at = null where trip_id = current_setting('test.trip_id')::uuid;
set local role authenticated;
select is(
  confirm_na_me_match(current_setting('test.trip_id')::uuid, jsonb_build_object('method', 'optical',
    'step', current_setting('test.step')::bigint + 2, 'code', current_setting('test.ahead')::int)),
  '{"matched": true, "attempts_left": 1}'::jsonb,
  'an optical proof 20 s ahead (clock skew) matches'
);
reset role;
select is((select status::text from trips where id = current_setting('test.trip_id')::uuid), 'boarded', 'a match boards the rider');
select ok(
  not exists (select 1 from trip_pins where trip_id = current_setting('test.trip_id')::uuid and verified_at is null),
  'a match clears the PIN gate'
);
select is(
  (select after->>'method' from audit_log where action = 'na_me_match' and target_id = current_setting('test.trip_id')),
  'optical', 'a match writes an audit event'
);

select * from finish();
rollback;
