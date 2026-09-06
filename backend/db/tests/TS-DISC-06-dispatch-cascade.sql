-- pgTAP: TS-DISC-06 — dispatch cascade hides declining driver identity (P2-A-03)
create extension if not exists pgtap;

begin;
select plan(7);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select set_config('app.settings.candidate_token_hmac_key', 'along-test-candidate-hmac-do-not-commit', true);

insert into auth.users (id, aud, role, phone) values
  ('0f400000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006101'),
  ('0f500000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006102'),
  ('0f600000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006103')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f400000-0000-4000-8000-000000000001', '+2348000006101', 'Cascade Rider'),
  ('0f500000-0000-4000-8000-000000000001', '+2348000006102', 'Declining Driver Alpha'),
  ('0f600000-0000-4000-8000-000000000001', '+2348000006103', 'Next Driver Beta')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f400000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f500000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'DISC06A', '0a020000-0000-4000-8000-000000000001'),
  ('0f600000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'DISC06B', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f700000-0000-4000-8000-000000000001', 'NG', 'keke', 'DISC-06-A', 3, '0f500000-0000-4000-8000-000000000001'),
  ('0f800000-0000-4000-8000-000000000001', 'NG', 'keke', 'DISC-06-B', 3, '0f600000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f500000-0000-4000-8000-000000000001', '0f700000-0000-4000-8000-000000000001', true),
  ('0f600000-0000-4000-8000-000000000001', '0f800000-0000-4000-8000-000000000001', true)
on conflict do nothing;

-- Same geohash cell, both roaming keke
insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values
  (
    '0f500000-0000-4000-8000-000000000001',
    '0f700000-0000-4000-8000-000000000001',
    '0f510000-0000-4000-8000-000000000001',
    'roaming_available',
    st_setsrid(st_makepoint(7.7010, 11.0610), 4326)::geography,
    '0a041000-0000-4000-8000-000000000002',
    2,
    now()
  ),
  (
    '0f600000-0000-4000-8000-000000000001',
    '0f800000-0000-4000-8000-000000000001',
    '0f610000-0000-4000-8000-000000000001',
    'roaming_available',
    st_setsrid(st_makepoint(7.7012, 11.0612), 4326)::geography,
    '0a041000-0000-4000-8000-000000000002',
    2,
    now()
  )
on conflict (driver_id) do update set
  session_id = excluded.session_id,
  status = excluded.status,
  current_location = excluded.current_location,
  last_ping_at = excluded.last_ping_at;

select set_config(
  'test.disc06_token',
  sign_candidate_token(
    '0f500000-0000-4000-8000-000000000001',
    '0f510000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001'
  ),
  true
);

select set_config('request.jwt.claim.sub', '0f400000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  hail_roaming(
    current_setting('test.disc06_token'),
    jsonb_build_object('lat', 11.065, 'lng', 7.705),
    false,
    gen_random_uuid()
  ) is not null,
  'TS-DISC-06: roaming hail created for cascade scenario'
);

select set_config('test.disc06_trip_id', (
  select id::text from trips where rider_id = '0f400000-0000-4000-8000-000000000001' limit 1
), true);

select ok(
  (build_trip_view(current_setting('test.disc06_trip_id')::uuid, '0f400000-0000-4000-8000-000000000001'::uuid)
    -> 'finding_vehicle')::boolean,
  'TS-DISC-06: rider TripView marks finding_vehicle before accept'
);

select ok(
  (build_trip_view(current_setting('test.disc06_trip_id')::uuid, '0f400000-0000-4000-8000-000000000001'::uuid)
    -> 'driver' ->> 'display_name') = '',
  'TS-DISC-06: rider TripView hides driver display_name while requested'
);

select ok(
  (build_trip_view(current_setting('test.disc06_trip_id')::uuid, '0f400000-0000-4000-8000-000000000001'::uuid)
    -> 'vehicle' ->> 'plate_number') = '',
  'TS-DISC-06: rider TripView hides vehicle plate while requested'
);

-- Driver Alpha declines → cascade retargets (sync; no Edge URL configured in tests)
select set_config('request.jwt.claim.sub', '0f500000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  (respond_to_trip(current_setting('test.disc06_trip_id')::uuid, 'decline', 'too_far') ->> 'declined')::boolean,
  'TS-DISC-06: declining driver receives decline acknowledgement'
);

select set_config('request.jwt.claim.sub', '0f400000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  not (
    rider_trip_broadcast_payload(
      current_setting('test.disc06_trip_id')::uuid,
      'dispatch_retarget'
    )::text ~* 'Declining Driver Alpha|DISC-06-A|0f500000-0000-4000-8000-000000000001'
  ),
  'TS-DISC-06: dispatch_retarget event payload omits declining driver identity'
);

select is(
  (select driver_id from trips where id = current_setting('test.disc06_trip_id')::uuid),
  '0f600000-0000-4000-8000-000000000001'::uuid,
  'TS-DISC-06: cascade retargets trip to next driver in cell'
);

select * from finish();
rollback;
