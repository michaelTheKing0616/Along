-- pgTAP: TS-DISC-01/02 — ambient disclosure and driver_presence RLS (P1-A-04)
create extension if not exists pgtap;

begin;
select plan(4);

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
  ('NG', 'keke', 'TST-DISC-01', 3, '0a100000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-DISC-01'
on conflict do nothing;

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

-- TS-DISC-02: rider cannot read driver_presence
select is(
  (select count(*)::int from driver_presence),
  0,
  'TS-DISC-02: rider sees zero driver_presence rows via RLS'
);

-- TS-DISC-01: ambient payload has no ids/plates and centroids match geohash grid
select ok(
  not exists (
    select 1
    from jsonb_array_elements(ambient_vehicles(11.061, 7.701, 2000)->'cells') c
    cross join lateral (
      select
        c->>'cell' as cell,
        (c->'centroid'->>'lat')::double precision as lat,
        (c->'centroid'->>'lng')::double precision as lng,
        cfg_num('presence.ambient_cell_precision', '0a000000-0000-4000-8000-000000000001')::int as precision
    ) x
    where c::text ~* '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
       or c::text ~* 'TST-DISC'
       or abs(x.lat - st_y(geohash_centroid(x.cell, x.precision)::geometry)) > 0.000001
       or abs(x.lng - st_x(geohash_centroid(x.cell, x.precision)::geometry)) > 0.000001
  ),
  'TS-DISC-01: ambient cells expose only geohash centroids without ids/plates'
);

select ok(
  jsonb_array_length(ambient_vehicles(11.061, 7.701, 2000)->'cells') >= 1,
  'TS-DISC-01: ambient returns at least one cell for seeded driver'
);

select ok(
  ambient_vehicles(11.061, 7.701, 2000)->'cells'->0 ? 'count_bucket',
  'TS-DISC-01: ambient cell shape includes count_bucket'
);

select * from finish();
rollback;
