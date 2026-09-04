-- pgTAP: TS-PLAN-01 (direct only), TS-PLAN-06 coverage gap (P1-A-06)
create extension if not exists pgtap;

begin;
select plan(6);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000001001'),
  ('0a200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000002001')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('0a100000-0000-4000-8000-000000000001', 'Test Driver'),
  ('0a200000-0000-4000-8000-000000000001', 'Test Rider')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0a100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TSTDRV01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into riders (id, home_city_id) values
  ('0a200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'car', 'TST-PLAN-01', 4, '0a100000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-PLAN-01'
on conflict do nothing;

-- Parked driver at Test Park Alpha (stage 1)
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_presence(
  'at_park',
  '{"lat": 11.060, "lng": 7.700}'::jsonb,
  3::smallint,
  null::smallint,
  '0a020000-0000-4000-8000-000000000001'::uuid
);

-- TS-PLAN-01 (direct only): parked direct candidate Alpha → Beta exists
select ok(
  exists (
    select 1
    from planner_direct_candidates_latlng(
      11.060, 7.700,
      11.065, 7.705,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' = 'parked'
      and c->>'board_stage_id' = '0a040000-0000-4000-8000-000000000001'
      and c->>'alight_stage_id' = '0a040000-0000-4000-8000-000000000005'
  ),
  'TS-PLAN-01: direct parked candidate from Alpha to Beta'
);

select ok(
  exists (
    select 1
    from planner_direct_candidates_latlng(
      11.060, 7.700,
      11.065, 7.705,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' = 'graph'
  ),
  'TS-PLAN-01: graph direct candidate also returned'
);

-- TS-PLAN-06: coverage gap outside graph with report row
select ok(
  (
    select count(*) = 0
    from planner_direct_candidates_latlng(
      10.000, 3.000,
      10.001, 3.001,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{}'::jsonb
    )
  ),
  'TS-PLAN-06: zero candidates in uncovered area'
);

select set_config('request.jwt.claim.sub', '0a200000-0000-4000-8000-000000000001', true);
set local role authenticated;

create temp table gap_result as
select record_coverage_gap_latlng(
  '0a200000-0000-4000-8000-000000000001'::uuid,
  10.000, 3.000,
  10.001, 3.001,
  '0a000000-0000-4000-8000-000000000001'::uuid
) as gap;

select ok(
  (select gap ? 'report_id' from gap_result),
  'TS-PLAN-06: coverage_gap payload includes report_id'
);

select ok(
  (select gap->'nearest_stage' ? 'stage_id' from gap_result),
  'TS-PLAN-06: coverage_gap includes nearest_stage'
);

select ok(
  exists (
    select 1 from coverage_gap_reports cgr
    where cgr.id = ((select gap->>'report_id' from gap_result))::uuid
  ),
  'TS-PLAN-06: coverage_gap_reports row inserted'
);

select * from finish();
rollback;
