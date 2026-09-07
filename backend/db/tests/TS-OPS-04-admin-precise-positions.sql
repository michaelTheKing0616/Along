-- pgTAP: TS-OPS-04 — admin-only precise positions (P6-D-02 / FM21 extension)
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0b100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003001'),
  ('0b200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003002'),
  ('0b300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0b100000-0000-4000-8000-000000000001', '+2348000003001', 'Ops Driver'),
  ('0b200000-0000-4000-8000-000000000001', '+2348000003002', 'Ops Rider'),
  ('0b300000-0000-4000-8000-000000000001', '+2348000003003', 'Ops Agent Admin')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0b200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0b100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'OPSPOS01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into admin_users (id, role, deployment_id) values
  ('0b300000-0000-4000-8000-000000000001', 'ops_agent', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0b400000-0000-4000-8000-000000000001', 'NG', 'car', 'OPS-PREC-1', 4, '0b100000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0b100000-0000-4000-8000-000000000001', '0b400000-0000-4000-8000-000000000001', true)
on conflict do nothing;

select set_config('request.jwt.claim.sub', '0b100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_presence(
  'roaming_available',
  '{"lat": 11.062, "lng": 7.702}'::jsonb,
  2::smallint,
  45::smallint
);

-- TS-DISC-02 (extended): rider cannot read driver_presence
select set_config('request.jwt.claim.sub', '0b200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  (select count(*)::int from driver_presence),
  0,
  'TS-OPS-04: rider sees zero driver_presence rows via RLS'
);

select throws_ok(
  $$ select admin_presence_snapshot('0a000000-0000-4000-8000-000000000001'::uuid) $$,
  'P0001',
  'FORBIDDEN',
  'TS-OPS-04: rider blocked from admin_presence_snapshot RPC'
);

-- Unauthenticated (no JWT sub) cannot read driver_presence or admin snapshot
reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from driver_presence),
  0,
  'TS-OPS-04: unauthenticated sees zero driver_presence rows'
);

select throws_ok(
  $$ select admin_presence_snapshot('0a000000-0000-4000-8000-000000000001'::uuid) $$,
  'P0001',
  'UNAUTHENTICATED',
  'TS-OPS-04: unauthenticated blocked from admin_presence_snapshot RPC'
);

-- Admin ops_agent receives precise positions and plate
select set_config('request.jwt.claim.sub', '0b300000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  admin_presence_snapshot('0a000000-0000-4000-8000-000000000001'::uuid)->'vehicles'->0->>'plate',
  'OPS-PREC-1',
  'TS-OPS-04: admin snapshot includes vehicle plate'
);

select cmp_ok(
  (admin_presence_snapshot('0a000000-0000-4000-8000-000000000001'::uuid)->'vehicles'->0->>'lat')::numeric,
  '>',
  11.0,
  'TS-OPS-04: admin snapshot includes precise lat'
);

select is(
  (select plate_number from driver_presence dp
   join vehicles v on v.id = dp.vehicle_id
   where dp.driver_id = '0b100000-0000-4000-8000-000000000001'),
  'OPS-PREC-1',
  'TS-OPS-04: admin direct select on driver_presence includes plate'
);

select ok(
  admin_active_trips_map('0a000000-0000-4000-8000-000000000001'::uuid) = '[]'::jsonb,
  'TS-OPS-04: admin_active_trips_map returns empty array when no active trips'
);

select set_config('request.jwt.claim.sub', '0b200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  $$ select admin_active_trips_map('0a000000-0000-4000-8000-000000000001'::uuid) $$,
  'P0001',
  'FORBIDDEN',
  'TS-OPS-04: rider blocked from admin_active_trips_map'
);

select * from finish();
rollback;
