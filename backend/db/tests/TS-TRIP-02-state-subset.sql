-- pgTAP: TS-TRIP-02 (subset) — illegal trip transitions raise STATE_INVALID (P1-A-05)
create extension if not exists pgtap;

begin;
select plan(4);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0b100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003001'),
  ('0b200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003002')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0b100000-0000-4000-8000-000000000001', '+2348000003001', 'Trip Rider'),
  ('0b200000-0000-4000-8000-000000000001', '+2348000003002', 'Trip Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0b100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0b200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TSTTRP01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, color, make_model, owner_profile_id) values
  ('0b300000-0000-4000-8000-000000000001', 'NG', 'car', 'TST-TRP-01', 4, 'White', 'Toyota Corolla', '0b200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0b200000-0000-4000-8000-000000000001', '0b300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0b400000-0000-4000-8000-000000000001',
  '0b100000-0000-4000-8000-000000000001',
  '0b200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0b500000-0000-4000-8000-000000000001',
  '0b100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'planning',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0b600000-0000-4000-8000-000000000001","source":"parked","kind":"direct"}'::jsonb
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape
) values (
  '0b700000-0000-4000-8000-000000000001',
  '0b500000-0000-4000-8000-000000000001',
  '0b100000-0000-4000-8000-000000000001',
  '0b200000-0000-4000-8000-000000000001',
  '0b300000-0000-4000-8000-000000000001',
  'car',
  '0b400000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'completed',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond'
);

-- completed → boarded
select throws_ok(
  $$ select trip_transition(
       '0b700000-0000-4000-8000-000000000001'::uuid,
       'boarded'::trip_status,
       'driver'::actor_type,
       '0b200000-0000-4000-8000-000000000001'::uuid
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-TRIP-02: completed→boarded raises STATE_INVALID'
);

update trips set ended_at = null where id = '0b700000-0000-4000-8000-000000000001';
select set_config('along.in_transition', 'on', true);
update trips set status = 'requested' where id = '0b700000-0000-4000-8000-000000000001';
select set_config('along.in_transition', '', true);

-- requested → in_transit
select throws_ok(
  $$ select trip_transition(
       '0b700000-0000-4000-8000-000000000001'::uuid,
       'in_transit'::trip_status,
       'driver'::actor_type,
       '0b200000-0000-4000-8000-000000000001'::uuid
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-TRIP-02: requested→in_transit raises STATE_INVALID'
);

-- requested → accepted by wrong driver
select throws_ok(
  $$ select trip_transition(
       '0b700000-0000-4000-8000-000000000001'::uuid,
       'accepted'::trip_status,
       'driver'::actor_type,
       '0b100000-0000-4000-8000-000000000001'::uuid
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-TRIP-02: requested→accepted by non-driver raises STATE_INVALID'
);

-- accepted → accepted (no-op transition)
select trip_transition(
  '0b700000-0000-4000-8000-000000000001'::uuid,
  'accepted'::trip_status,
  'driver'::actor_type,
  '0b200000-0000-4000-8000-000000000001'::uuid
);

select throws_ok(
  $$ select trip_transition(
       '0b700000-0000-4000-8000-000000000001'::uuid,
       'accepted'::trip_status,
       'driver'::actor_type,
       '0b200000-0000-4000-8000-000000000001'::uuid
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-TRIP-02: accepted→accepted raises STATE_INVALID'
);

select * from finish();
rollback;
