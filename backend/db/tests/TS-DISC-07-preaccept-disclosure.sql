-- pgTAP: TS-DISC-07 — pre-accept TripView / trip_request has approach_band only (FM42)
create extension if not exists pgtap;

begin;
select plan(6);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

select set_config('app.settings.candidate_token_hmac_key', 'along-test-candidate-hmac-do-not-commit', true);
select set_config('along.test.osrm_foot_duration_s', '90', true);

insert into auth.users (id, aud, role, phone) values
  ('0fa00000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007101'),
  ('0fb00000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007102')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0fa00000-0000-4000-8000-000000000001', '+2348000007101', 'Disc07 Rider'),
  ('0fb00000-0000-4000-8000-000000000001', '+2348000007102', 'Disc07 Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0fa00000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0fb00000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'DISC07D', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0fc00000-0000-4000-8000-000000000001', 'NG', 'keke', 'DISC-07', 3, '0fb00000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0fb00000-0000-4000-8000-000000000001', '0fc00000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values (
  '0fb00000-0000-4000-8000-000000000001',
  '0fc00000-0000-4000-8000-000000000001',
  '0fb10000-0000-4000-8000-000000000001',
  'roaming_available',
  st_setsrid(st_makepoint(7.7010, 11.0610), 4326)::geography,
  '0a041000-0000-4000-8000-000000000002',
  2,
  now()
)
on conflict (driver_id) do update set
  current_location = excluded.current_location,
  last_ping_at = excluded.last_ping_at;

select set_config(
  'test.disc07_token',
  sign_candidate_token(
    '0fb00000-0000-4000-8000-000000000001',
    '0fb10000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001'
  ),
  true
);

select set_config('request.jwt.claim.sub', '0fa00000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  hail_roaming(
    current_setting('test.disc07_token'),
    jsonb_build_object('lat', 11.065, 'lng', 7.705),
    false,
    gen_random_uuid()
  ) is not null,
  'TS-DISC-07: roaming hail created'
);

select set_config('test.disc07_trip_id', (
  select id::text from trips where rider_id = '0fa00000-0000-4000-8000-000000000001' limit 1
), true);

select set_config('request.jwt.claim.sub', '0fb00000-0000-4000-8000-000000000001', true);
set local role authenticated;

select set_config('test.disc07_driver_view', build_trip_view(
  current_setting('test.disc07_trip_id')::uuid,
  '0fb00000-0000-4000-8000-000000000001'::uuid
)::text, true);

select ok(
  (current_setting('test.disc07_driver_view')::jsonb->>'approach_band') = 'under_2',
  'TS-DISC-07: pre-accept driver TripView includes approach_band under_2'
);

select ok(
  array_length(tripview_disclosure_violations(current_setting('test.disc07_driver_view')::jsonb), 1) is null,
  'TS-DISC-07: pre-accept driver TripView has no lat/lng, walk_eta_s, or polyline'
);

-- trip_request broadcast payload shape (same TripView embedded)
select ok(
  array_length(
    tripview_disclosure_violations(
      jsonb_build_object(
        'type', 'trip_request',
        'trip', current_setting('test.disc07_driver_view')::jsonb,
        'expires_at', now()
      )
    ),
    1
  ) is null,
  'TS-DISC-07: trip_request envelope grep-clean of coordinates and walk_eta_s'
);

select ok(
  (current_setting('test.disc07_driver_view')::jsonb->'board' ? 'name'),
  'TS-DISC-07: pre-accept driver TripView includes pickup label'
);

select ok(
  not (current_setting('test.disc07_driver_view')::jsonb->'board' ? 'location'),
  'TS-DISC-07: pre-accept driver TripView omits board.location'
);

select * from finish();
rollback;
