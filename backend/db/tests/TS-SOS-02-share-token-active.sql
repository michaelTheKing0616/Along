-- pgTAP: TS-SOS-02 — share token only while journey active and token valid (P5-A-01 gate)
create extension if not exists pgtap;

begin;
select plan(6);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000006201'),
  ('0e200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000006202')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000011', '+2348000006201', 'Share Rider'),
  ('0e200000-0000-4000-8000-000000000011', '+2348000006202', 'Share Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'SHRDR1', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, color, owner_profile_id) values
  ('0e300000-0000-4000-8000-000000000011', 'NG', 'car', 'SHR-01', 4, 'blue', '0e200000-0000-4000-8000-000000000011')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0e200000-0000-4000-8000-000000000011', '0e300000-0000-4000-8000-000000000011', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0e400000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  '0e200000-0000-4000-8000-000000000011',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into journeys (
  id, rider_id, city_id, status, origin, destination, destination_label, plan_snapshot
) values (
  '0e500000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  'Test Park Beta',
  jsonb_build_object('legs', jsonb_build_array(
    jsonb_build_object('leg_index', 0, 'mode', jsonb_build_object('code', 'car', 'label', 'Along taxi'))
  ))
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, started_at, id_signal_color, id_signal_shape
) values (
  '0e600000-0000-4000-8000-000000000011',
  '0e500000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  '0e200000-0000-4000-8000-000000000011',
  '0e300000-0000-4000-8000-000000000011',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0e400000-0000-4000-8000-000000000011',
  320.00, 'NGN', 2, 0.05,
  'in_transit',
  now() + interval '10 minutes',
  now() - interval '5 minutes',
  now() - interval '3 minutes',
  'red', 'circle'
);

insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values (
  '0e200000-0000-4000-8000-000000000011',
  '0e300000-0000-4000-8000-000000000011',
  '0e310000-0000-4000-8000-000000000011',
  'roaming_available',
  st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  '0a040000-0000-4000-8000-000000000001',
  2,
  now()
) on conflict (driver_id) do update set
  current_location = excluded.current_location,
  last_ping_at = excluded.last_ping_at;

update app_config
set value = '"https://along.ng"'
where key = 'public.origin' and scope_type = 'global' and scope_id = '*';

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000011', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config(
  'test.sos02_share',
  create_trip_share('0e500000-0000-4000-8000-000000000011')::text,
  true
);

select ok(
  (current_setting('test.sos02_share')::jsonb->>'url') like 'https://along.ng/s/%',
  'TS-SOS-02: create_trip_share returns origin-based share URL'
);

select set_config(
  'test.sos02_token',
  regexp_replace(current_setting('test.sos02_share')::jsonb->>'url', '^.*/s/', ''),
  true
);

reset role;

select ok(
  shared_trip_view(current_setting('test.sos02_token'))->>'rider_first_name' = 'Share',
  'TS-SOS-02: shared_trip_view works while journey active and token valid'
);

select ok(
  shared_trip_view(current_setting('test.sos02_token'))->'vehicle'->>'plate' = 'SHR-01',
  'TS-SOS-02: shared_trip_view exposes minimal vehicle plate only'
);

select set_config(
  'test.sos02_eta_default',
  shared_trip_view(current_setting('test.sos02_token'))->>'eta_s',
  true
);

update app_config
set value = '100'
where key = 'planner.baseline_speed_mps' and scope_type = 'global' and scope_id = '*';

select ok(
  (shared_trip_view(current_setting('test.sos02_token'))->>'eta_s')::int
    < (current_setting('test.sos02_eta_default')::int),
  'TS-SOS-02: shared_trip_view eta_s uses planner.baseline_speed_mps config'
);

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000011', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (revoke_trip_share((current_setting('test.sos02_share')::jsonb->>'share_id')::uuid)->>'share_id') is not null,
  'TS-SOS-02: rider can revoke own trip share'
);

reset role;

select throws_ok(
  $$ select shared_trip_view(current_setting('test.sos02_token')) $$,
  'P0001',
  'SHARE_INVALID',
  'TS-SOS-02: revoked share token raises SHARE_INVALID'
);

select * from finish();
rollback;
