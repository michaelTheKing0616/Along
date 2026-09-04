-- pgTAP: identity RLS (doc 02 §3) — rider/driver own-row, driver column protection, private schema
create extension if not exists pgtap;

begin;
select plan(16);

-- Fixture UUIDs
-- rider_a: c0000000-0000-4000-8000-000000000001
-- rider_b: c0000000-0000-4000-8000-000000000002
-- driver_a: c0000000-0000-4000-8000-000000000003
-- driver_b: c0000000-0000-4000-8000-000000000004
-- deploy:  d0000000-0000-4000-8000-000000000001
-- city:    d0000000-0000-4000-8000-000000000002

insert into deployments (id, tenant_name)
values ('d0000000-0000-4000-8000-000000000001', 'Identity RLS Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XT', 'Identity Test Country', 'XXX', 'X', '+997', 'UTC', 'd0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'd0000000-0000-4000-8000-000000000002',
  'XT',
  'Identity Test City',
  'identity-test-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into auth.users (id, aud, role, phone) values
  ('c0000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000000001'),
  ('c0000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000000002'),
  ('c0000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000000003'),
  ('c0000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '+2348000000004');

select ok(
  (select count(*) from profiles where id in (
    'c0000000-0000-4000-8000-000000000001'::uuid,
    'c0000000-0000-4000-8000-000000000003'::uuid
  )) = 2,
  'profiles auto-created from auth.users insert'
);

insert into riders (id) values
  ('c0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000002');

insert into drivers (id, city_id) values
  ('c0000000-0000-4000-8000-000000000003', 'd0000000-0000-4000-8000-000000000002'),
  ('c0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-000000000002');

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id)
values ('XT', 'car', 'ABC-123', 4, 'c0000000-0000-4000-8000-000000000003');

insert into driver_vehicles (driver_id, vehicle_id)
select 'c0000000-0000-4000-8000-000000000003'::uuid, id from vehicles where plate_number = 'ABC-123';

insert into driver_verifications (driver_id, country_code, document_type)
values ('c0000000-0000-4000-8000-000000000003', 'XT', 'nin');

insert into private.identity_hashes (document_type, id_hash, driver_id)
values ('nin', decode('deadbeef', 'hex'), 'c0000000-0000-4000-8000-000000000003');

insert into device_tokens (profile_id, platform, token, app)
values ('c0000000-0000-4000-8000-000000000001', 'android', 'token-rider-a', 'rider');

-- Rider own-row RLS
select set_config('request.jwt.claim.sub', 'c0000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from riders where id = 'c0000000-0000-4000-8000-000000000001'::uuid),
  1,
  'rider selects own riders row'
);

select is(
  (select count(*)::int from riders where id = 'c0000000-0000-4000-8000-000000000002'::uuid),
  0,
  'rider cannot select another riders row'
);

select is(
  (select count(*)::int from profiles where id = 'c0000000-0000-4000-8000-000000000001'::uuid),
  1,
  'rider selects own profiles row'
);

reset role;

-- Driver own-row RLS
select set_config('request.jwt.claim.sub', 'c0000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from drivers where id = 'c0000000-0000-4000-8000-000000000003'::uuid),
  1,
  'driver selects own drivers row'
);

select is(
  (select count(*)::int from drivers where id = 'c0000000-0000-4000-8000-000000000004'::uuid),
  0,
  'driver cannot select another drivers row'
);

select is(
  (select count(*)::int from vehicles where plate_number = 'ABC-123'),
  1,
  'driver selects vehicle linked via driver_vehicles'
);

select is(
  (select count(*)::int from driver_verifications where driver_id = 'c0000000-0000-4000-8000-000000000003'::uuid),
  1,
  'driver selects own driver_verifications row'
);

select is(
  (select count(*)::int from device_tokens where profile_id = 'c0000000-0000-4000-8000-000000000001'::uuid),
  0,
  'driver cannot select another user device_tokens row'
);

update drivers set accepts_digital = false where id = 'c0000000-0000-4000-8000-000000000003'::uuid;
select ok(
  (select accepts_digital from drivers where id = 'c0000000-0000-4000-8000-000000000003'::uuid) = false,
  'driver can update non-protected drivers column'
);

select throws_ok(
  $$ update drivers set verified_status = 'verified' where id = 'c0000000-0000-4000-8000-000000000003'::uuid $$,
  '42501',
  'cannot update verified_status',
  'driver cannot update verified_status'
);

select throws_ok(
  $$ update drivers set standing = 'warned' where id = 'c0000000-0000-4000-8000-000000000003'::uuid $$,
  '42501',
  'cannot update standing',
  'driver cannot update standing'
);

select throws_ok(
  $$ update drivers set rating = 4.50 where id = 'c0000000-0000-4000-8000-000000000003'::uuid $$,
  '42501',
  'cannot update rating',
  'driver cannot update rating'
);

reset role;

select ok(
  not has_schema_privilege('authenticated', 'private', 'USAGE'),
  'authenticated has no USAGE on private schema'
);

select ok(
  not has_table_privilege('authenticated', 'private.identity_hashes', 'SELECT'),
  'authenticated has no SELECT on private.identity_hashes'
);

select ok(
  not has_table_privilege('anon', 'private.identity_hashes', 'SELECT'),
  'anon has no SELECT on private.identity_hashes'
);

select * from finish();
rollback;
