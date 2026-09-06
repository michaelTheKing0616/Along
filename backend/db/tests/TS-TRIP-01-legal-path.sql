-- pgTAP: TS-TRIP-01 — legal path requested→accepted→boarded→in_transit→completed (P3-A-01)
create extension if not exists pgtap;

begin;
select plan(8);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0c100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000004001'),
  ('0c200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000004002')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0c100000-0000-4000-8000-000000000001', '+2348000004001', 'Legal Rider'),
  ('0c200000-0000-4000-8000-000000000001', '+2348000004002', 'Legal Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0c100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0c200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'LGLTRP01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0c300000-0000-4000-8000-000000000001', 'NG', 'car', 'LGL-01', 4, '0c200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0c200000-0000-4000-8000-000000000001', '0c300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0c400000-0000-4000-8000-000000000001',
  '0c100000-0000-4000-8000-000000000001',
  '0c200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0c500000-0000-4000-8000-000000000001',
  '0c100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'planning',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0c600000-0000-4000-8000-000000000001","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0c700000-0000-4000-8000-000000000001',
  '0c500000-0000-4000-8000-000000000001',
  '0c100000-0000-4000-8000-000000000001',
  '0c200000-0000-4000-8000-000000000001',
  '0c300000-0000-4000-8000-000000000001',
  'car',
  '0c400000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'requested',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0c700000-0000-4000-8000-000000000001', null, 'requested', 'rider', '0c100000-0000-4000-8000-000000000001');

-- requested → accepted
select trip_transition(
  '0c700000-0000-4000-8000-000000000001'::uuid,
  'accepted'::trip_status,
  'driver'::actor_type,
  '0c200000-0000-4000-8000-000000000001'::uuid
);

select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- accepted → boarded (manual driver)
select mark_boarded('0c700000-0000-4000-8000-000000000001'::uuid);

-- boarded → in_transit
select start_trip('0c700000-0000-4000-8000-000000000001'::uuid);

-- in_transit → completed
select complete_trip('0c700000-0000-4000-8000-000000000001'::uuid);

select is(
  (select count(*)::int from trip_events
   where trip_id = '0c700000-0000-4000-8000-000000000001'
     and from_status is not null),
  4,
  'TS-TRIP-01: legal path writes 4 status transition trip_events'
);

select ok(
  (select accepted_at is not null from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'TS-TRIP-01: accepted_at set'
);

select ok(
  (select boarded_at is not null from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'TS-TRIP-01: boarded_at set'
);

select ok(
  (select started_at is not null from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'TS-TRIP-01: started_at set'
);

select ok(
  (select ended_at is not null from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'TS-TRIP-01: ended_at set'
);

select is(
  (select status::text from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'completed',
  'TS-TRIP-01: trip ends in completed'
);

select is(
  (select boarded_via from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'manual_driver',
  'TS-TRIP-01: manual driver boarding recorded'
);

select ok(
  (select commission_amount is not null from trips where id = '0c700000-0000-4000-8000-000000000001'),
  'TS-TRIP-01: commission_amount computed (ledger stub until P4)'
);

select * from finish();
rollback;
