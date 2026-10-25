-- pgTAP: TS-TRIP-16 — rider handoff (PIN + driver phone) and driver earnings context (PR #16)
create extension if not exists pgtap;

begin;
select plan(13);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('1d100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000016001'),
  ('1d200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000016002'),
  ('1d300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000016003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('1d100000-0000-4000-8000-000000000001', '+2348000016001', 'Party Rider'),
  ('1d200000-0000-4000-8000-000000000001', '+2348000016002', 'Party Driver'),
  ('1d300000-0000-4000-8000-000000000001', '+2348000016003', 'Outsider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('1d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('1d200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TRIP16', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('1d400000-0000-4000-8000-000000000001', 'NG', 'car', 'TRIP-16', 4, '1d200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('1d200000-0000-4000-8000-000000000001', '1d400000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '1d500000-0000-4000-8000-000000000001',
  '1d100000-0000-4000-8000-000000000001',
  '1d200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available
) values (
  '1d200000-0000-4000-8000-000000000001',
  '1d400000-0000-4000-8000-000000000001',
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3
) on conflict (driver_id) do update set status = excluded.status;

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '1d100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '1d600000-0000-4000-8000-000000000001',
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
      'fare', jsonb_build_object('amount', 320, 'currency', 'NGN', 'tier', 2, 'quote_id', '1d500000-0000-4000-8000-000000000001', 'unconfirmed', false),
      'supply', jsonb_build_object('kind', 'parked', 'driver_id', '1d200000-0000-4000-8000-000000000001')
    ))
  ))
);

select set_config('request.jwt.claim.sub', '1d100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  request_trip('1d600000-0000-4000-8000-000000000001', 0, false, gen_random_uuid()) is not null,
  'request_trip succeeds for party rider'
);


select set_config('test.trip_id', (
  select id::text from trips where rider_id = '1d100000-0000-4000-8000-000000000001' limit 1
), true);

select set_config('request.jwt.claim.sub', '1d200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select respond_to_trip(current_setting('test.trip_id')::uuid, 'accept', null);
reset role;

select ok(
  (select pin ~ '^[0-9]{4}$' from trip_pins where trip_id = current_setting('test.trip_id')::uuid),
  'accepting a trip mints a 4-digit PIN'
);

-- Rider view
select set_config('request.jwt.claim.sub', '1d100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  build_trip_view(current_setting('test.trip_id')::uuid)->'handoff'->>'pin',
  (select pin::text from trip_pins where trip_id = current_setting('test.trip_id')::uuid),
  'rider sees the trip PIN while the driver is arriving'
);
select is(
  build_trip_view(current_setting('test.trip_id')::uuid)->'handoff'->>'driver_phone',
  '+2348000016002',
  'rider gets the driver phone for Call/Message'
);
select is(
  (select count(*)::int from trip_pins where trip_id = current_setting('test.trip_id')::uuid),
  1,
  'RLS: rider can read own trip PIN'
);

-- Driver view
select set_config('request.jwt.claim.sub', '1d200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  build_trip_view(current_setting('test.trip_id')::uuid)->'handoff' = 'null'::jsonb,
  'driver view carries no handoff (PIN is rider-only)'
);
select is(
  (select count(*)::int from trip_pins where trip_id = current_setting('test.trip_id')::uuid),
  0,
  'RLS: driver cannot read the trip PIN'
);

-- Outsider
select set_config('request.jwt.claim.sub', '1d300000-0000-4000-8000-000000000001', true);
set local role authenticated;
select is(
  (select count(*)::int from trip_pins where trip_id = current_setting('test.trip_id')::uuid),
  0,
  'RLS: outsider cannot read the trip PIN'
);

-- In transit: phone stays, PIN goes
reset role;
select trip_transition(current_setting('test.trip_id')::uuid, 'boarded'::trip_status,
  'driver'::actor_type, '1d200000-0000-4000-8000-000000000001'::uuid);
select trip_transition(current_setting('test.trip_id')::uuid, 'in_transit'::trip_status,
  'driver'::actor_type, '1d200000-0000-4000-8000-000000000001'::uuid);
select set_config('request.jwt.claim.sub', '1d100000-0000-4000-8000-000000000001', true);
set local role authenticated;
select ok(
  build_trip_view(current_setting('test.trip_id')::uuid)->'handoff'->>'pin' is null
    and build_trip_view(current_setting('test.trip_id')::uuid)->'handoff'->>'driver_phone' is not null,
  'in transit: no PIN, driver phone kept'
);

select throws_ok(
  $$ select driver_earnings_context(7) $$,
  'P0001',
  'FORBIDDEN',
  'driver_earnings_context rejects non-drivers'
);

-- Driver earnings context
reset role;
insert into driver_presence_history (driver_id, session_id, ts, location, status) values
  ('1d200000-0000-4000-8000-000000000001', '1d700000-0000-4000-8000-000000000001',
   now() - interval '2 hours', st_setsrid(st_makepoint(7.7, 11.06), 4326)::geography, 'at_park'),
  ('1d200000-0000-4000-8000-000000000001', '1d700000-0000-4000-8000-000000000001',
   now() - interval '1 hour', st_setsrid(st_makepoint(7.7, 11.06), 4326)::geography, 'roaming_available');
insert into admin_users (id, role) values ('1d300000-0000-4000-8000-000000000001', 'finance')
on conflict (id) do nothing;
insert into driver_payouts (driver_id, amount, currency, status, provider_reference, recipient_subaccount_code, initiated_by, confirmed_at)
values ('1d200000-0000-4000-8000-000000000001', 9600, 'NGN', 'confirmed', 'trip16-payout', 'ACCT_abc4821',
        '1d300000-0000-4000-8000-000000000001', now());

select set_config('request.jwt.claim.sub', '1d200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  (select sum(value::int) from jsonb_each_text(driver_earnings_context(7)->'online_seconds_by_day')) between 3500 and 3700,
  'online time derives from presence sessions'
);
select is(
  driver_earnings_context(7)->'latest_payout'->>'account_label',
  'Paystack ••4821',
  'latest payout carries the account label'
);
select is(
  driver_earnings_context(7)->'latest_payout'->>'status',
  'confirmed',
  'latest payout status'
);

select * from finish();
rollback;
