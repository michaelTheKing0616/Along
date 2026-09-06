-- pgTAP: TS-PRES-02 — stale excluded from ambient; offline job deletes row (P3-A-02)
create extension if not exists pgtap;

begin;
select plan(3);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000001001'),
  ('0a200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000002001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0a100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TSTDRV01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into riders (id, home_city_id) values
  ('0a200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'keke', 'TST-PRES-02', 3, '0a100000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-PRES-02'
on conflict do nothing;

-- TS-PRES-02: stale > stale_after_s (45 s default) excluded from ambient
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_presence(
  'roaming_available',
  '{"lat": 11.062, "lng": 7.702}'::jsonb,
  2::smallint,
  90::smallint
);

set local role postgres;

update driver_presence
set last_ping_at = now() - make_interval(secs => (cfg_num('presence.stale_after_s', '0a000000-0000-4000-8000-000000000001')::int + 5))
where driver_id = '0a100000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub', '0a200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  jsonb_array_length((ambient_vehicles(11.062, 7.702, 2000)->'cells')) = 0,
  'TS-PRES-02: stale > stale_after_s excluded from ambient'
);

-- TS-PRES-02: offline_after_s (180 s default) job deletes presence row
set local role postgres;

update driver_presence
set last_ping_at = now() - make_interval(secs => (cfg_num('presence.offline_after_s', '0a000000-0000-4000-8000-000000000001')::int + 5))
where driver_id = '0a100000-0000-4000-8000-000000000001';

select presence_stale();

select ok(
  (select count(*) from driver_presence where driver_id = '0a100000-0000-4000-8000-000000000001') = 0,
  'TS-PRES-02: offline_after_s job deletes presence row'
);

select ok(
  exists (
    select 1
    from realtime.messages
    where extension = 'broadcast'
      and payload::text like '%presence_dropped%'
  ),
  'TS-PRES-02: presence_stale emits presence_dropped on driver channel'
);

select * from finish();
rollback;
