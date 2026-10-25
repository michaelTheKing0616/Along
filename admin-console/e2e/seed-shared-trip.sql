-- W-01 E2E fixture: an in-transit keke trip with an active share token.
-- Mirrors backend/db/tests/TS-SOS-02-share-token-active.sql; the share link page
-- calls shared_trip_view server-side, so the browser cannot mock it.
\ir ../../backend/db/seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000006201'),
  ('0e200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000006202')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000011', '+2348000006201', 'Share Rider'),
  ('0e200000-0000-4000-8000-000000000011', '+2348000006202', 'Musa Bello')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'SHRDR1', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, color, owner_profile_id) values
  ('0e300000-0000-4000-8000-000000000011', 'NG', 'keke', 'SHR-01', 3, 'Yellow', '0e200000-0000-4000-8000-000000000011')
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
  'keke', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
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
  'Area 1',
  jsonb_build_object('legs', jsonb_build_array(
    jsonb_build_object('leg_index', 0, 'mode', jsonb_build_object('code', 'keke', 'label', 'Keke'))
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
  'keke',
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


update trips
set meta = coalesce(meta, '{}'::jsonb) || jsonb_build_object(
  'eta', jsonb_build_object(
    'status', 'ready',
    'pickup', null,
    'trip', jsonb_build_object('kind', 'single', 'low_s', 420, 'high_s', 420, 'label', '7 min'),
    'stops', '[]'::jsonb,
    'updated_at', now()
  )
)
where id = '0e600000-0000-4000-8000-000000000011';

insert into trip_shares (journey_id, rider_id, token_hash, expires_at)
values (
  '0e500000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  digest('e2e-share-token', 'sha256'),
  now() + interval '1 day'
);
