-- pgTAP: TS-WAIT-01..05 — wait-decision backend (P3-A-04)
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0aa10000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008101'),
  ('0aa20000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008102')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0aa10000-0000-4000-8000-000000000001', '+2348000008101', 'Wait Rider'),
  ('0aa20000-0000-4000-8000-000000000001', '+2348000008102', 'Wait Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id, account_trust_weight) values
  ('0aa10000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 0.350)
on conflict (id) do update set account_trust_weight = excluded.account_trust_weight;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0aa20000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'WAIT01D', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status, standing = excluded.standing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0aa30000-0000-4000-8000-000000000001', 'NG', 'car', 'WAIT-01', 4, '0aa20000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0aa20000-0000-4000-8000-000000000001', '0aa30000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0aa40000-0000-4000-8000-000000000001',
  '0aa10000-0000-4000-8000-000000000001',
  '0aa20000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values (
  '0aa50000-0000-4000-8000-000000000001',
  '0aa10000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.7000, 11.0600), 4326)::geography,
  st_setsrid(st_makepoint(7.7050, 11.0650), 4326)::geography,
  '{"source":"parked"}'::jsonb
);

-- ~80 m straight-line apart (FM41 fixture)
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0aa60000-0000-4000-8000-000000000001',
  '0aa50000-0000-4000-8000-000000000001',
  '0aa10000-0000-4000-8000-000000000001',
  '0aa20000-0000-4000-8000-000000000001',
  '0aa30000-0000-4000-8000-000000000001',
  'car',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0aa40000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'accepted',
  now() + interval '25 seconds',
  now() - interval '2 minutes',
  'color.naMe.green', 'diamond'
);

insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values (
  '0aa20000-0000-4000-8000-000000000001',
  '0aa30000-0000-4000-8000-000000000001',
  '0aa21000-0000-4000-8000-000000000001',
  'roaming_available',
  st_setsrid(st_makepoint(7.7000, 11.0600), 4326)::geography,
  '0a041000-0000-4000-8000-000000000002',
  2,
  now()
)
on conflict (driver_id) do update set current_location = excluded.current_location;

-- TS-WAIT-01: OSRM foot > 8 min, not haversine (~64 s at 80 m)
select set_config('along.test.osrm_foot_duration_s', '520', true);

select set_config('request.jwt.claim.sub', '0aa20000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select trip_location_sample(
  '0aa60000-0000-4000-8000-000000000001'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0607, 'lng', 7.7007, 'accuracy_m', 10)
  )
);

select set_config('request.jwt.claim.sub', '0aa10000-0000-4000-8000-000000000001', true);
select trip_location_sample(
  '0aa60000-0000-4000-8000-000000000001'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0600, 'lng', 7.7000, 'accuracy_m', 10)
  )
);

select ok(
  (refresh_wait('0aa60000-0000-4000-8000-000000000001'::uuid)->>'walk_eta_s')::int >= 480,
  'TS-WAIT-01: wait.walk_eta_s uses OSRM foot stub (>=480s), not haversine'
);

-- TS-WAIT-04: missing rider GPS in stalled window → unknown, never stalled
reset role;
insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0aa60000-0000-4000-8000-000000000004',
  '0aa50000-0000-4000-8000-000000000001', 2,
  '0aa10000-0000-4000-8000-000000000001',
  '0aa20000-0000-4000-8000-000000000001',
  '0aa30000-0000-4000-8000-000000000001',
  'car',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0aa40000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'accepted',
  now() + interval '25 seconds',
  now() - interval '1 minute',
  'color.naMe.yellow', 'triangle'
);

select set_config('request.jwt.claim.sub', '0aa20000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select trip_location_sample(
  '0aa60000-0000-4000-8000-000000000004'::uuid,
  jsonb_build_array(
    jsonb_build_object('lat', 11.0600, 'lng', 7.7000, 'accuracy_m', 10)
  )
);

select is(
  refresh_wait('0aa60000-0000-4000-8000-000000000004'::uuid)->>'approach',
  'unknown',
  'TS-WAIT-04: missing rider GPS in stalled window → approach unknown'
);

select isnt(
  refresh_wait('0aa60000-0000-4000-8000-000000000004'::uuid)->>'approach',
  'stalled',
  'TS-WAIT-04: missing rider GPS never surfaces as stalled'
);

-- TS-WAIT-02: release_match → released_before_arrival, no reconciliation flag
reset role;
insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0aa60000-0000-4000-8000-000000000002',
  '0aa50000-0000-4000-8000-000000000001', 3,
  '0aa10000-0000-4000-8000-000000000001',
  '0aa20000-0000-4000-8000-000000000001',
  '0aa30000-0000-4000-8000-000000000001',
  'car',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0aa40000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'accepted',
  now() + interval '25 seconds',
  now() - interval '1 minute',
  'color.naMe.blue', 'circle'
);

select set_config('request.jwt.claim.sub', '0aa20000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select release_match('0aa60000-0000-4000-8000-000000000002'::uuid);

select is(
  (select status::text from trips where id = '0aa60000-0000-4000-8000-000000000002'),
  'released_before_arrival',
  'TS-WAIT-02: release_match writes released_before_arrival'
);

reset role;
select reconcile_cancelled_trips();

select ok(
  not exists (
    select 1 from trip_reconciliation_flags
    where trip_id = '0aa60000-0000-4000-8000-000000000002'
  ),
  'TS-WAIT-02: reconcile_cancelled_trips produces no flag for released_before_arrival'
);

-- TS-WAIT-03: rider inside pickup radius → STATE_INVALID
reset role;
insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0aa60000-0000-4000-8000-000000000003',
  '0aa50000-0000-4000-8000-000000000001', 4,
  '0aa10000-0000-4000-8000-000000000001',
  '0aa20000-0000-4000-8000-000000000001',
  '0aa30000-0000-4000-8000-000000000001',
  'car',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0aa40000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'accepted',
  now() + interval '25 seconds',
  now() - interval '1 minute',
  'color.naMe.red', 'square'
);

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m) values
  (
    '0aa60000-0000-4000-8000-000000000003',
    'driver',
    now() - interval '5 seconds',
    st_setsrid(st_makepoint(7.7000, 11.0600), 4326)::geography,
    10
  ),
  (
    '0aa60000-0000-4000-8000-000000000003',
    'rider',
    now() - interval '4 seconds',
    st_setsrid(st_makepoint(7.70005, 11.06005), 4326)::geography,
    10
  );

select set_config('request.jwt.claim.sub', '0aa20000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select release_match('0aa60000-0000-4000-8000-000000000003'::uuid) $$,
  'P0001',
  'STATE_INVALID',
  'TS-WAIT-03: release_match blocked after rider entered pickup radius'
);

-- TS-WAIT-05: FM43 rider_no_show_pattern flag, no standing/trust auto-change
reset role;
select set_config('along.in_transition', 'on', true);

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, ended_at, id_signal_color, id_signal_shape
) values
  (
    '0aa70000-0000-4000-8000-000000000001',
    '0aa50000-0000-4000-8000-000000000001', 6,
    '0aa10000-0000-4000-8000-000000000001',
    '0aa20000-0000-4000-8000-000000000001',
    '0aa30000-0000-4000-8000-000000000001',
    'car',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    '0aa40000-0000-4000-8000-000000000001',
    320.00, 'NGN', 2, 0.05,
    'no_show', now() + interval '25 seconds', now() - interval '3 days', now() - interval '3 days',
    'color.naMe.green', 'diamond'
  ),
  (
    '0aa70000-0000-4000-8000-000000000002',
    '0aa50000-0000-4000-8000-000000000001', 7,
    '0aa10000-0000-4000-8000-000000000001',
    '0aa20000-0000-4000-8000-000000000001',
    '0aa30000-0000-4000-8000-000000000001',
    'car',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    '0aa40000-0000-4000-8000-000000000001',
    320.00, 'NGN', 2, 0.05,
    'released_before_arrival', now() + interval '25 seconds', now() - interval '2 days', now() - interval '2 days',
    'color.naMe.blue', 'circle'
  ),
  (
    '0aa70000-0000-4000-8000-000000000003',
    '0aa50000-0000-4000-8000-000000000001', 8,
    '0aa10000-0000-4000-8000-000000000001',
    '0aa20000-0000-4000-8000-000000000001',
    '0aa30000-0000-4000-8000-000000000001',
    'car',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    '0aa40000-0000-4000-8000-000000000001',
    320.00, 'NGN', 2, 0.05,
    'no_show', now() + interval '25 seconds', now() - interval '1 day', now() - interval '1 day',
    'color.naMe.red', 'square'
  );

select set_config('along.in_transition', '', true);

select set_config('test.wait05_trust_before', (
  select account_trust_weight::text from riders where id = '0aa10000-0000-4000-8000-000000000001'
), true);

select set_config('test.wait05_standing_before', (
  select standing::text from drivers where id = '0aa20000-0000-4000-8000-000000000001'
), true);

reset role;
select rider_no_show_review();

select is(
  (select count(*)::int from trip_reconciliation_flags
   where flag_type = 'rider_no_show_pattern'
     and evidence->>'rider_id' = '0aa10000-0000-4000-8000-000000000001'),
  1,
  'TS-WAIT-05: three qualifying trips → one rider_no_show_pattern flag'
);

select is(
  (select account_trust_weight::text from riders where id = '0aa10000-0000-4000-8000-000000000001'),
  current_setting('test.wait05_trust_before'),
  'TS-WAIT-05: rider trust weight unchanged after review job'
);

select is(
  (select standing::text from drivers where id = '0aa20000-0000-4000-8000-000000000001'),
  current_setting('test.wait05_standing_before'),
  'TS-WAIT-05: driver standing unchanged after review job'
);

select * from finish();
rollback;
