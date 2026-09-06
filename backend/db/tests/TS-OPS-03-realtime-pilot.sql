-- pgTAP: TS-OPS-03 pilot — authz + payload size + polling fallback (local scale; full 5k deferred P3-E-01)
create extension if not exists pgtap;

begin;
select plan(7);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007001'),
  ('0f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007002'),
  ('0f300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007003'),
  ('0f400000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007004')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000001', '+2348000007001', 'Pilot Rider'),
  ('0f200000-0000-4000-8000-000000000001', '+2348000007002', 'Pilot Driver'),
  ('0f300000-0000-4000-8000-000000000001', '+2348000007003', 'Pilot Outsider'),
  ('0f400000-0000-4000-8000-000000000001', '+2348000007004', 'Pilot Ops')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001'),
  ('0f300000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'OPS03', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into admin_users (id, role, deployment_id) values
  ('0f400000-0000-4000-8000-000000000001', 'ops_agent', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f500000-0000-4000-8000-000000000001', 'NG', 'car', 'OPS-03', 4, '0f200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000001', '0f500000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available, last_ping_at
) values (
  '0f200000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000001',
  'at_park',
  st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3,
  now()
) on conflict (driver_id) do update set last_ping_at = excluded.last_ping_at;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f600000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  '0f200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '0f100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '0f700000-0000-4000-8000-000000000001',
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
      'fare', jsonb_build_object('amount', 320, 'currency', 'NGN', 'tier', 2, 'quote_id', '0f600000-0000-4000-8000-000000000001', 'unconfirmed', false),
      'supply', jsonb_build_object('kind', 'parked', 'driver_id', '0f200000-0000-4000-8000-000000000001')
    ))
  ))
);

-- Create trip and accept for active tracking state
select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;
select request_trip('0f700000-0000-4000-8000-000000000001', 0, false, gen_random_uuid());

select set_config('test.ops03_trip_id', (
  select id::text from trips where rider_id = '0f100000-0000-4000-8000-000000000001' limit 1
), true);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select respond_to_trip(current_setting('test.ops03_trip_id')::uuid, 'accept', null);

-- Payload size guard rejects oversize loc broadcast; valid loc passes (service_role)
reset role;
set local role service_role;
select throws_ok(
  $$ select private.realtime_send_bounded(
       jsonb_build_object('type','loc','actor','driver','lat',1,'lng',2,'padding', repeat('x', 600)),
       'loc', 'trip:test', true) $$,
  'P0001',
  'VALIDATION',
  'TS-OPS-03 pilot: oversize loc payload rejected by max_payload_bytes'
);

select lives_ok(
  $$ select private.broadcast_trip_location(
       '00000000-0000-4000-8000-000000000001'::uuid,
       'driver'::text, 11.061::double precision, 7.701::double precision,
       90::smallint, 4.5::numeric, now()) $$,
  'TS-OPS-03 pilot: valid loc payload passes size guard'
);

-- Admin fanout returns precise coordinates (not cell centroids)
select set_config('request.jwt.claim.sub', '0f400000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (admin_presence_snapshot('0a000000-0000-4000-8000-000000000001'::uuid)->'vehicles'->0->>'lat') is not null,
  'TS-OPS-03 pilot: admin snapshot includes precise lat'
);

select cmp_ok(
  (admin_presence_snapshot('0a000000-0000-4000-8000-000000000001'::uuid)->'vehicles'->0->>'lat')::numeric,
  '>',
  11.0,
  'TS-OPS-03 pilot: admin snapshot lat is precise (not geohash centroid)'
);

-- Rider cannot subscribe to admin:{city}
select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('realtime.topic', 'admin:zaria-test', true);
set local role authenticated;

select is(
  realtime_admin_city('admin:zaria-test', '0f100000-0000-4000-8000-000000000001'::uuid),
  false,
  'TS-OPS-03 pilot: rider blocked from admin channel authz'
);

-- Ops admin passes admin channel authz
select set_config('request.jwt.claim.sub', '0f400000-0000-4000-8000-000000000001', true);
select is(
  realtime_admin_city('admin:zaria-test', '0f400000-0000-4000-8000-000000000001'::uuid),
  true,
  'TS-OPS-03 pilot: ops admin passes admin channel authz'
);

-- trip_snapshot polling fallback includes live driver position after sample
select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
set local role authenticated;
select trip_location_sample(
  current_setting('test.ops03_trip_id')::uuid,
  jsonb_build_array(jsonb_build_object(
    'lat', 11.061, 'lng', 7.701, 'accuracy_m', 10, 'speed_mps', 4.5, 'heading', 90,
    'ts', to_jsonb(now())
  ))
);

select ok(
  (trip_snapshot(current_setting('test.ops03_trip_id')::uuid)->'live'->'driver'->>'lat')::numeric > 11.0,
  'TS-OPS-03 pilot: trip_snapshot polling fallback returns live driver position'
);

select * from finish();
rollback;
