-- pgTAP: TS-PRES-01/02/03/04 — presence RPCs and stale job (P1-A-04)
create extension if not exists pgtap;

begin;
select plan(11);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000001001'),
  ('0a100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000001002'),
  ('0a100000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000001003'),
  ('0a100000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '+2348000001004'),
  ('0a200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000002001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0a100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TSTDRV01', '0a020000-0000-4000-8000-000000000001'),
  ('0a100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'matching_paused', 'TSTDRV03', '0a020000-0000-4000-8000-000000000001'),
  ('0a100000-0000-4000-8000-000000000004', '0a000000-0000-4000-8000-000000000001', 'unverified', 'good_standing', 'TSTDRV04', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set
  verified_status = excluded.verified_status,
  standing = excluded.standing;

insert into riders (id, home_city_id) values
  ('0a200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'keke', 'TST-PRES-01', 3, '0a100000-0000-4000-8000-000000000001'),
  ('NG', 'car', 'TST-PRES-02', 4, '0a100000-0000-4000-8000-000000000002'),
  ('NG', 'car', 'TST-PRES-04', 4, '0a100000-0000-4000-8000-000000000004')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-PRES-01'
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000002', v.id, true
from vehicles v where v.plate_number = 'TST-PRES-02'
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000004', v.id, true
from vehicles v where v.plate_number = 'TST-PRES-04'
on conflict do nothing;

-- TS-PRES-01: online driver visible in ambient; offline deletes row and drops count
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_presence(
  'roaming_available',
  '{"lat": 11.061, "lng": 7.701}'::jsonb,
  2::smallint,
  45::smallint
);

select set_config('request.jwt.claim.sub', '0a200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  jsonb_array_length((ambient_vehicles(11.061, 7.701, 2000)->'cells')) >= 1,
  'TS-PRES-01: ambient includes online driver'
);

select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select set_presence(
  'offline',
  '{"lat": 11.061, "lng": 7.701}'::jsonb,
  0::smallint
);

select ok(
  (select count(*) from driver_presence where driver_id = '0a100000-0000-4000-8000-000000000001') = 0,
  'TS-PRES-01: offline deletes driver_presence row'
);

select set_config('request.jwt.claim.sub', '0a200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  jsonb_array_length((ambient_vehicles(11.061, 7.701, 2000)->'cells')) = 0,
  'TS-PRES-01: ambient count drops immediately after offline'
);

-- TS-PRES-02: stale excluded from ambient; offline job deletes row
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select set_presence(
  'roaming_available',
  '{"lat": 11.062, "lng": 7.702}'::jsonb,
  2::smallint,
  90::smallint
);

set local role postgres;

update driver_presence
set last_ping_at = now() - interval '50 seconds'
where driver_id = '0a100000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub', '0a200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  jsonb_array_length((ambient_vehicles(11.062, 7.702, 2000)->'cells')) = 0,
  'TS-PRES-02: stale > stale_after_s excluded from ambient'
);

set local role postgres;

update driver_presence
set last_ping_at = now() - interval '200 seconds'
where driver_id = '0a100000-0000-4000-8000-000000000001';

select presence_stale();

select ok(
  (select count(*) from driver_presence where driver_id = '0a100000-0000-4000-8000-000000000001') = 0,
  'TS-PRES-02: offline_after_s job deletes presence row'
);

-- TS-PRES-03: unverified / blocked drivers cannot go online
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000004', true);
set local role authenticated;

select throws_ok(
  $$ select set_presence('roaming_available', '{"lat": 11.061, "lng": 7.701}'::jsonb, 2::smallint) $$,
  'P0001',
  'LEDGER_BLOCKED',
  'TS-PRES-03: unverified driver cannot go online'
);

select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000002', true);
set local role authenticated;

select throws_ok(
  $$ select set_presence('roaming_available', '{"lat": 11.061, "lng": 7.701}'::jsonb, 2::smallint) $$,
  'P0001',
  'LEDGER_BLOCKED',
  'TS-PRES-03: matching_paused driver cannot go online'
);

-- TS-PRES-04: rapid ping dropped; accepted ping appends history
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
set local role authenticated;

create temp table pres04_ctx as
select (set_presence(
  'roaming_available',
  '{"lat": 11.061, "lng": 7.701}'::jsonb,
  2::smallint,
  45::smallint
)->>'session_id')::uuid as session_id;

set local role postgres;

update driver_presence
set last_ping_at = now() - interval '3 seconds'
where driver_id = '0a100000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (select (presence_ping('{"lat": 11.0611, "lng": 7.7011}'::jsonb, 45::smallint, 5::numeric, 10::numeric)->>'accepted')::boolean),
  'TS-PRES-04: first ping accepted'
);

set local role postgres;

select ok(
  (select count(*) from driver_presence_history h
   join pres04_ctx c on c.session_id = h.session_id) = 2,
  'TS-PRES-04: accepted ping appends history'
);

select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  not (select (presence_ping('{"lat": 11.0612, "lng": 7.7012}'::jsonb, 45::smallint, 5::numeric, 10::numeric)->>'accepted')::boolean),
  'TS-PRES-04: ping < min interval dropped silently'
);

set local role postgres;

select is(
  (select count(*)::int from driver_presence_history h
   join pres04_ctx c on c.session_id = h.session_id),
  2,
  'TS-PRES-04: dropped ping does not append history'
);

select * from finish();
rollback;
