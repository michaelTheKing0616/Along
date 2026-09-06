-- pgTAP: TS-INTEG-01..05 — cash-integrity reconciliation (P4-A-06)
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

-- Drivers: D1=INTEG-01/05, D2=INTEG-02, D3=INTEG-03, D4=INTEG-04+peers

insert into auth.users (id, aud, role, phone) values
  ('0d100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008101'),
  ('0d100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000008102'),
  ('0d100000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000008103'),
  ('0d100000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '+2348000008104'),
  ('0d200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008105'),
  ('0d200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000008106'),
  ('0d200000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000008107'),
  ('0d200000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '+2348000008108')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0d100000-0000-4000-8000-000000000001', '+2348000008101', 'Integr Rider 1'),
  ('0d100000-0000-4000-8000-000000000002', '+2348000008102', 'Integr Peer 1'),
  ('0d100000-0000-4000-8000-000000000003', '+2348000008103', 'Integr Peer 2'),
  ('0d100000-0000-4000-8000-000000000004', '+2348000008104', 'Integr Ext Rider'),
  ('0d200000-0000-4000-8000-000000000001', '+2348000008105', 'Integr Driver 1'),
  ('0d200000-0000-4000-8000-000000000002', '+2348000008106', 'Integr Driver 2'),
  ('0d200000-0000-4000-8000-000000000003', '+2348000008107', 'Integr Driver 3'),
  ('0d200000-0000-4000-8000-000000000004', '+2348000008108', 'Integr Driver 4')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001'),
  ('0d100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001'),
  ('0d100000-0000-4000-8000-000000000003', '0a000000-0000-4000-8000-000000000001'),
  ('0d100000-0000-4000-8000-000000000004', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0d200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'INTDR01', '0a020000-0000-4000-8000-000000000001'),
  ('0d200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'INTDR02', '0a020000-0000-4000-8000-000000000001'),
  ('0d200000-0000-4000-8000-000000000003', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'INTDR03', '0a020000-0000-4000-8000-000000000001'),
  ('0d200000-0000-4000-8000-000000000004', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'INTDR04', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0d300000-0000-4000-8000-000000000001', 'NG', 'car', 'INT-01', 4, '0d200000-0000-4000-8000-000000000001'),
  ('0d300000-0000-4000-8000-000000000002', 'NG', 'car', 'INT-02', 4, '0d200000-0000-4000-8000-000000000002'),
  ('0d300000-0000-4000-8000-000000000003', 'NG', 'car', 'INT-03', 4, '0d200000-0000-4000-8000-000000000003'),
  ('0d300000-0000-4000-8000-000000000004', 'NG', 'car', 'INT-04', 4, '0d200000-0000-4000-8000-000000000004')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0d200000-0000-4000-8000-000000000001', '0d300000-0000-4000-8000-000000000001', true),
  ('0d200000-0000-4000-8000-000000000002', '0d300000-0000-4000-8000-000000000002', true),
  ('0d200000-0000-4000-8000-000000000003', '0d300000-0000-4000-8000-000000000003', true),
  ('0d200000-0000-4000-8000-000000000004', '0d300000-0000-4000-8000-000000000004', true)
on conflict do nothing;

-- Shared fare quotes
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values
  ('0d400000-0000-4000-8000-000000000001', '0d100000-0000-4000-8000-000000000001', '0d200000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000002', '0d100000-0000-4000-8000-000000000002', '0d200000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000003', '0d100000-0000-4000-8000-000000000003', '0d200000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000004', '0d100000-0000-4000-8000-000000000004', '0d200000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000011', '0d100000-0000-4000-8000-000000000001', '0d200000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000012', '0d100000-0000-4000-8000-000000000001', '0d200000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000013', '0d100000-0000-4000-8000-000000000001', '0d200000-0000-4000-8000-000000000004', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000014', '0d100000-0000-4000-8000-000000000002', '0d200000-0000-4000-8000-000000000004', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'),
  ('0d400000-0000-4000-8000-000000000015', '0d100000-0000-4000-8000-000000000003', '0d200000-0000-4000-8000-000000000004', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes');

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0d500000-0000-4000-8000-000000000001', '0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb),
  ('0d500000-0000-4000-8000-000000000002', '0d100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb),
  ('0d500000-0000-4000-8000-000000000003', '0d100000-0000-4000-8000-000000000003', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb),
  ('0d500000-0000-4000-8000-000000000004', '0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb),
  ('0d500000-0000-4000-8000-000000000005', '0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb),
  ('0d500000-0000-4000-8000-000000000006', '0d100000-0000-4000-8000-000000000004', '0a000000-0000-4000-8000-000000000001', 'completed', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb),
  ('0d500000-0000-4000-8000-000000000007', '0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb);

-- Helper: insert route-following driver samples + optional rider samples
create temp table if not exists _integr_seed_ts as
select now() - interval '30 minutes' as base_ts;

-- TS-INTEG-01: both reach destination → score ≥ 0.8
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at, cancelled_at,
  id_signal_color, id_signal_shape
) values (
  '0d700000-0000-4000-8000-000000000001',
  '0d500000-0000-4000-8000-000000000001',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000001',
  '0d300000-0000-4000-8000-000000000001',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0d400000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'cancelled_by_driver',
  now() + interval '25 seconds',
  (select base_ts - interval '20 minutes' from _integr_seed_ts),
  (select base_ts - interval '18 minutes' from _integr_seed_ts),
  (select base_ts - interval '15 minutes' from _integr_seed_ts),
  (select base_ts - interval '5 minutes' from _integr_seed_ts),
  'color.naMe.green', 'diamond'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0d700000-0000-4000-8000-000000000001', 'in_transit', 'cancelled_by_driver', 'driver', '0d200000-0000-4000-8000-000000000001');

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000001', 'driver', base_ts - interval '14 minutes' + (g * interval '2 minutes'),
  st_setsrid(st_makepoint(7.700 + g * 0.001, 11.060 + g * 0.001), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 4) g;

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000001', 'driver', base_ts - interval '4 minutes' + (g * interval '30 seconds'),
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000001', 'rider', base_ts - interval '6 minutes' + (g * interval '30 seconds'),
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

-- TS-INTEG-02: driver reaches, no rider trace → capped 0.5
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at, cancelled_at,
  id_signal_color, id_signal_shape
) values (
  '0d700000-0000-4000-8000-000000000002',
  '0d500000-0000-4000-8000-000000000004',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000002',
  '0d300000-0000-4000-8000-000000000002',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0d400000-0000-4000-8000-000000000011',
  320.00, 'NGN', 2, 0.05,
  'cancelled_by_driver',
  now() + interval '25 seconds',
  (select base_ts - interval '20 minutes' from _integr_seed_ts),
  (select base_ts - interval '18 minutes' from _integr_seed_ts),
  (select base_ts - interval '15 minutes' from _integr_seed_ts),
  (select base_ts - interval '5 minutes' from _integr_seed_ts),
  'color.naMe.blue', 'circle'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0d700000-0000-4000-8000-000000000002', 'in_transit', 'cancelled_by_driver', 'driver', '0d200000-0000-4000-8000-000000000002');

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000002', 'driver', base_ts - interval '14 minutes' + (g * interval '2 minutes'),
  st_setsrid(st_makepoint(7.700 + g * 0.001, 11.060 + g * 0.001), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 4) g;

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000002', 'driver', base_ts - interval '4 minutes' + (g * interval '30 seconds'),
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

-- TS-INTEG-03: driver diverts elsewhere → no flag
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at, cancelled_at,
  id_signal_color, id_signal_shape
) values (
  '0d700000-0000-4000-8000-000000000003',
  '0d500000-0000-4000-8000-000000000005',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000003',
  '0d300000-0000-4000-8000-000000000003',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0d400000-0000-4000-8000-000000000012',
  320.00, 'NGN', 2, 0.05,
  'cancelled_by_driver',
  now() + interval '25 seconds',
  (select base_ts - interval '20 minutes' from _integr_seed_ts),
  (select base_ts - interval '18 minutes' from _integr_seed_ts),
  (select base_ts - interval '15 minutes' from _integr_seed_ts),
  (select base_ts - interval '5 minutes' from _integr_seed_ts),
  'color.naMe.red', 'square'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0d700000-0000-4000-8000-000000000003', 'in_transit', 'cancelled_by_driver', 'driver', '0d200000-0000-4000-8000-000000000003');

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000003', 'driver', base_ts - interval '4 minutes' + (g * interval '30 seconds'),
  st_setsrid(st_makepoint(7.690, 11.050), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

-- TS-INTEG-04: two peer riders corroborate (main trip: rider 1, no rider trace)
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at, cancelled_at,
  id_signal_color, id_signal_shape
) values (
  '0d700000-0000-4000-8000-000000000004',
  '0d500000-0000-4000-8000-000000000007',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000004',
  '0d300000-0000-4000-8000-000000000004',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0d400000-0000-4000-8000-000000000013',
  320.00, 'NGN', 2, 0.05,
  'cancelled_by_driver',
  now() + interval '25 seconds',
  (select base_ts - interval '20 minutes' from _integr_seed_ts),
  (select base_ts - interval '18 minutes' from _integr_seed_ts),
  (select base_ts - interval '15 minutes' from _integr_seed_ts),
  (select base_ts - interval '5 minutes' from _integr_seed_ts),
  'color.naMe.yellow', 'triangle'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0d700000-0000-4000-8000-000000000004', 'in_transit', 'cancelled_by_driver', 'driver', '0d200000-0000-4000-8000-000000000004');

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000004', 'driver', base_ts - interval '14 minutes' + (g * interval '2 minutes'),
  st_setsrid(st_makepoint(7.700 + g * 0.001, 11.060 + g * 0.001), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 4) g;

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000004', 'driver', base_ts - interval '4 minutes' + (g * interval '30 seconds'),
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

-- Peer trips (overlapping window, riders at dest)
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at, cancelled_at,
  id_signal_color, id_signal_shape
) values
  (
    '0d700000-0000-4000-8000-000000000041',
    '0d500000-0000-4000-8000-000000000002',
    '0d100000-0000-4000-8000-000000000002',
    '0d200000-0000-4000-8000-000000000004',
    '0d300000-0000-4000-8000-000000000004',
    'car',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    '0d400000-0000-4000-8000-000000000014',
    320.00, 'NGN', 2, 0.05,
    'cancelled_by_rider',
    now() + interval '25 seconds',
    (select base_ts - interval '19 minutes' from _integr_seed_ts),
    (select base_ts - interval '17 minutes' from _integr_seed_ts),
    (select base_ts - interval '14 minutes' from _integr_seed_ts),
    (select base_ts - interval '6 minutes' from _integr_seed_ts),
    'color.naMe.yellow', 'triangle'
  ),
  (
    '0d700000-0000-4000-8000-000000000042',
    '0d500000-0000-4000-8000-000000000003',
    '0d100000-0000-4000-8000-000000000003',
    '0d200000-0000-4000-8000-000000000004',
    '0d300000-0000-4000-8000-000000000004',
    'car',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    '0d400000-0000-4000-8000-000000000015',
    320.00, 'NGN', 2, 0.05,
    'cancelled_by_rider',
    now() + interval '25 seconds',
    (select base_ts - interval '19 minutes' from _integr_seed_ts),
    (select base_ts - interval '17 minutes' from _integr_seed_ts),
    (select base_ts - interval '14 minutes' from _integr_seed_ts),
    (select base_ts - interval '6 minutes' from _integr_seed_ts),
    'color.naMe.orange', 'star'
  );

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id) values
  ('0d700000-0000-4000-8000-000000000041', 'in_transit', 'cancelled_by_rider', 'rider', '0d100000-0000-4000-8000-000000000002'),
  ('0d700000-0000-4000-8000-000000000042', 'in_transit', 'cancelled_by_rider', 'rider', '0d100000-0000-4000-8000-000000000003');

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select trip_id, 'rider', base_ts - interval '8 minutes' + (g * interval '20 seconds'),
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, 10
from _integr_seed_ts,
     (values
       ('0d700000-0000-4000-8000-000000000041'::uuid),
       ('0d700000-0000-4000-8000-000000000042'::uuid)
     ) peers(trip_id),
     generate_series(0, 2) g;

-- TS-INTEG-05: undeclared extension 600 m beyond alight
insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  payment_method, status, expires_at, accepted_at, boarded_at, started_at, ended_at,
  id_signal_color, id_signal_shape
) values (
  '0d700000-0000-4000-8000-000000000005',
  '0d500000-0000-4000-8000-000000000006',
  '0d100000-0000-4000-8000-000000000004',
  '0d200000-0000-4000-8000-000000000001',
  '0d300000-0000-4000-8000-000000000001',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0d400000-0000-4000-8000-000000000004',
  320.00, 'NGN', 2, 0.05,
  'cash',
  'completed',
  now() + interval '25 seconds',
  (select base_ts - interval '20 minutes' from _integr_seed_ts),
  (select base_ts - interval '18 minutes' from _integr_seed_ts),
  (select base_ts - interval '15 minutes' from _integr_seed_ts),
  (select base_ts - interval '2 minutes' from _integr_seed_ts),
  'color.naMe.purple', 'hexagon'
);

-- ~600 m north of alight (7.705, 11.065) → lat +0.0054
insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000005', 'driver', base_ts - interval '1 minute' + (g * interval '15 seconds'),
  st_setsrid(st_makepoint(7.705, 11.0704), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select '0d700000-0000-4000-8000-000000000005', 'rider', base_ts - interval '1 minute' + (g * interval '15 seconds'),
  st_setsrid(st_makepoint(7.705, 11.0704), 4326)::geography, 10
from _integr_seed_ts, generate_series(0, 2) g;

select reconcile_cancelled_trips();
select compute_risk_scores();

-- TS-INTEG-01
select ok(
  (select score >= 0.8 from trip_reconciliation_flags
   where trip_id = '0d700000-0000-4000-8000-000000000001' and flag_type = 'premature_conversion'),
  'TS-INTEG-01: driver + rider both reach dest → score ≥ 0.8'
);

-- TS-INTEG-02
select is(
  (select score from trip_reconciliation_flags
   where trip_id = '0d700000-0000-4000-8000-000000000002' and flag_type = 'premature_conversion'),
  0.5000::numeric,
  'TS-INTEG-02: no rider trace → score capped at 0.5'
);

select is(
  (select rider_trace_quality::text from trip_reconciliation_flags
   where trip_id = '0d700000-0000-4000-8000-000000000002' and flag_type = 'premature_conversion'),
  'none',
  'TS-INTEG-02: rider_trace_quality=none (inconclusive band)'
);

-- TS-INTEG-03
select ok(
  not exists (
    select 1 from trip_reconciliation_flags
    where trip_id = '0d700000-0000-4000-8000-000000000003'
  ),
  'TS-INTEG-03: driver diverts elsewhere → no flag'
);

-- TS-INTEG-04
select is(
  (select corroborating_rider_count from trip_reconciliation_flags
   where trip_id = '0d700000-0000-4000-8000-000000000004' and flag_type = 'premature_conversion'),
  2::smallint,
  'TS-INTEG-04: corroborating_rider_count=2'
);

select ok(
  (select (evidence->'score_components'->>'corroboration')::numeric > 0
   from trip_reconciliation_flags
   where trip_id = '0d700000-0000-4000-8000-000000000004' and flag_type = 'premature_conversion'),
  'TS-INTEG-04: score includes corroboration term'
);

-- TS-INTEG-05
select ok(
  exists (
    select 1 from trip_reconciliation_flags
    where trip_id = '0d700000-0000-4000-8000-000000000005'
      and flag_type = 'undeclared_extension'
      and (evidence->>'distance_beyond_alighting_m')::numeric >= 400
  ),
  'TS-INTEG-05: undeclared extension flag when trace continues ≥400 m beyond alight with co-located rider'
);

-- FM13: flags never transition standing
select is(
  (select standing from drivers where id = '0d200000-0000-4000-8000-000000000001'),
  'good_standing'::driver_standing,
  'FM13: reconcile job does not change driver standing'
);

-- driver_risk_scores populated for review UI
select ok(
  exists (
    select 1 from driver_risk_scores
    where driver_id = '0d200000-0000-4000-8000-000000000001'
      and open_flags >= 1
  ),
  'compute_risk_scores aggregates open flags for driver review UI'
);

select * from finish();
rollback;
