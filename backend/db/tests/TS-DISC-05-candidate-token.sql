-- pgTAP: TS-DISC-05 — candidate_token tampered/expired → CANDIDATE_EXPIRED (P2-A-03)
create extension if not exists pgtap;

begin;
select plan(4);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select set_config('app.settings.candidate_token_hmac_key', 'along-test-candidate-hmac-do-not-commit', true);

insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005101'),
  ('0f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000005102')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000001', '+2348000005101', 'Disc05 Rider'),
  ('0f200000-0000-4000-8000-000000000001', '+2348000005102', 'Disc05 Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'DISC05', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f300000-0000-4000-8000-000000000001', 'NG', 'keke', 'DISC-05-A', 3, '0f200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000001', '0f300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values (
  '0f200000-0000-4000-8000-000000000001',
  '0f300000-0000-4000-8000-000000000001',
  '0f310000-0000-4000-8000-000000000001',
  'roaming_available',
  st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  '0a041000-0000-4000-8000-000000000002',
  2,
  now()
) on conflict (driver_id) do update set
  session_id = excluded.session_id,
  status = excluded.status,
  last_ping_at = excluded.last_ping_at;

select set_config(
  'test.disc05_valid_token',
  sign_candidate_token(
    '0f200000-0000-4000-8000-000000000001',
    '0f310000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001'
  ),
  true
);

select set_config(
  'test.disc05_expired_token',
  encode(
    convert_to(
      '0f200000-0000-4000-8000-000000000001.0f310000-0000-4000-8000-000000000001.1',
      'UTF8'
    ),
    'base64'
  ) || '.' || encode(
    extensions.hmac(
      convert_to(
        '0f200000-0000-4000-8000-000000000001.0f310000-0000-4000-8000-000000000001.1',
        'UTF8'
      ),
      convert_to(current_setting('app.settings.candidate_token_hmac_key'), 'UTF8'),
      'sha256'
    ),
    'base64'
  ),
  true
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  hail_roaming(
    current_setting('test.disc05_valid_token'),
    jsonb_build_object('lat', 11.065, 'lng', 7.705),
    false,
    gen_random_uuid()
  ) is not null,
  'TS-DISC-05: valid candidate_token creates roaming hail'
);

select throws_ok(
  $$ select hail_roaming(
    left(current_setting('test.disc05_valid_token'), length(current_setting('test.disc05_valid_token')) - 3) || 'XXX',
    jsonb_build_object('lat', 11.065, 'lng', 7.705),
    false,
    gen_random_uuid()
  ) $$,
  'P0001',
  'CANDIDATE_EXPIRED',
  'TS-DISC-05: tampered candidate_token raises CANDIDATE_EXPIRED'
);

select throws_ok(
  $$ select hail_roaming(
    current_setting('test.disc05_expired_token'),
    jsonb_build_object('lat', 11.065, 'lng', 7.705),
    false,
    gen_random_uuid()
  ) $$,
  'P0001',
  'CANDIDATE_EXPIRED',
  'TS-DISC-05: expired candidate_token raises CANDIDATE_EXPIRED'
);

select throws_ok(
  $$ select verify_candidate_token('not-a-token', '0a000000-0000-4000-8000-000000000001') $$,
  'P0001',
  'CANDIDATE_EXPIRED',
  'TS-DISC-05: malformed candidate_token raises CANDIDATE_EXPIRED'
);

select * from finish();
rollback;
