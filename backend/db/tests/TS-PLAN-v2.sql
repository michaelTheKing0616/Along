-- pgTAP: P2-A-01 plan-trip v2 scenarios TS-PLAN-01/02/07/09 (SQL layer)
-- Engineered 3-park graph: direct A→G (slow) + multi-leg A→B→G (fast)
create extension if not exists pgtap;

begin;
select plan(8);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

-- Park Gamma + routes for engineered direct vs multi-leg
insert into parks (id, city_id, name, location, source_id, verification_status, confidence_score)
values (
  '0a020000-0000-4000-8000-000000000003',
  '0a000000-0000-4000-8000-000000000001',
  'Test Park Gamma',
  st_setsrid(st_makepoint(7.708, 11.068), 4326)::geography,
  '0a010000-0000-4000-8000-000000000001',
  'crowd_verified',
  0.800
);

-- Direct A→G (slow — 90 min in-vehicle for TS-PLAN-02)
insert into routes (id, city_id, corridor_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score)
values (
  '0a030000-0000-4000-8000-000000000003',
  '0a000000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000011',
  '0a020000-0000-4000-8000-000000000001',
  '0a020000-0000-4000-8000-000000000003',
  'car',
  '0a010000-0000-4000-8000-000000000001',
  'crowd_verified',
  0.800
);

insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score) values
  ('0a042000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000003', 1, '0a020000-0000-4000-8000-000000000001', 'Test Park Alpha', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a042000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000003', 2, null, 'Test Mid Hop', st_setsrid(st_makepoint(7.704, 11.064), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a042000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000003', 3, '0a020000-0000-4000-8000-000000000003', 'Test Park Gamma', st_setsrid(st_makepoint(7.708, 11.068), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800);

insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, in_vehicle_time_estimate_s, avg_wait_time_estimate_s) values
  ('0a030000-0000-4000-8000-000000000003', '0a042000-0000-4000-8000-000000000001', '0a042000-0000-4000-8000-000000000002', 'car', 500.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 2700, 60),
  ('0a030000-0000-4000-8000-000000000003', '0a042000-0000-4000-8000-000000000002', '0a042000-0000-4000-8000-000000000003', 'car', 500.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 2700, 60);

-- Fast leg B→G (20 min total multi-leg path)
insert into routes (id, city_id, corridor_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score)
values (
  '0a030000-0000-4000-8000-000000000004',
  '0a000000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000011',
  '0a020000-0000-4000-8000-000000000002',
  '0a020000-0000-4000-8000-000000000003',
  'keke',
  '0a010000-0000-4000-8000-000000000001',
  'crowd_verified',
  0.800
);

insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score) values
  ('0a043000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000004', 1, '0a020000-0000-4000-8000-000000000002', 'Test Park Beta', st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a043000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000004', 2, '0a020000-0000-4000-8000-000000000003', 'Test Park Gamma', st_setsrid(st_makepoint(7.708, 11.068), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800);

insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, in_vehicle_time_estimate_s, avg_wait_time_estimate_s) values
  ('0a030000-0000-4000-8000-000000000004', '0a043000-0000-4000-8000-000000000001', '0a043000-0000-4000-8000-000000000002', 'keke', 80.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 600, 60);

-- Transfer hubs (skip rows already seeded at Alpha/Beta)
insert into transfer_points (park_id, route_id, stage_id, walk_distance_m, transfer_time_s) values
  ('0a020000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000003', '0a042000-0000-4000-8000-000000000001', 0, 60),
  ('0a020000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000004', '0a043000-0000-4000-8000-000000000001', 0, 60),
  ('0a020000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000003', '0a042000-0000-4000-8000-000000000003', 0, 60),
  ('0a020000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000004', '0a043000-0000-4000-8000-000000000002', 0, 60)
on conflict do nothing;

-- Slow direct A→G on existing car route (patch first leg time for TS-PLAN-02 baseline)
update route_legs
set in_vehicle_time_estimate_s = 300
where route_id = '0a030000-0000-4000-8000-000000000001'
  and from_stage_id = '0a040000-0000-4000-8000-000000000001';

-- TS-PLAN-01: direct candidate A→G exists
select ok(
  exists (
    select 1
    from planner_direct_candidates_latlng(
      11.060, 7.700,
      11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' in ('parked', 'graph', 'driver_profile')
      and c->>'route_id' = '0a030000-0000-4000-8000-000000000003'
  ),
  'TS-PLAN-01: direct candidate A→G returned'
);

-- TS-PLAN-01: multi-leg candidate A→B→G exists
select ok(
  exists (
    select 1
    from planner_decompose_latlng(
      11.060, 7.700,
      11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    ) itin
    where jsonb_array_length(itin->'legs') >= 2
      and jsonb_array_length(itin->'transfers') >= 1
  ),
  'TS-PLAN-01: multi-leg candidate with transfer returned'
);

-- TS-PLAN-02: direct in_vehicle ~90 min vs multi-leg ~20 min on engineered graph
select ok(
  (
    select coalesce(sum((l->>'in_vehicle_time_estimate_s')::int), 0)
    from planner_direct_candidates_latlng(
      11.060, 7.700, 11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{}'::jsonb
    ) c
    cross join lateral jsonb_array_elements(
      case when c->>'route_id' = '0a030000-0000-4000-8000-000000000003'
        then jsonb_build_array(jsonb_build_object('in_vehicle_time_estimate_s', c->'in_vehicle_time_estimate_s'))
        else '[]'::jsonb end
    ) l
    where c->>'route_id' = '0a030000-0000-4000-8000-000000000003'
  ) >= 5000,
  'TS-PLAN-02: direct A→G in_vehicle ≥ 5000s (slow)'
);

select ok(
  (
    select min(
      (
        select coalesce(sum((leg->>'in_vehicle_time_estimate_s')::int), 0)
        from jsonb_array_elements(itin->'legs') leg
      )
    )
    from planner_decompose_latlng(
      11.060, 7.700, 11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{}'::jsonb
    ) itin
    where jsonb_array_length(itin->'transfers') >= 1
  ) <= 2000,
  'TS-PLAN-02: multi-leg in_vehicle ≤ 2000s (fast)'
);

-- Gate: multiple genuinely different candidates from decompose
select ok(
  (
    select count(*) >= 2
    from (
      select distinct string_agg(l->>'route_id', ',' order by ord)
      from planner_decompose_latlng(
        11.060, 7.700, 11.068, 7.708,
        '0a000000-0000-4000-8000-000000000001'::uuid,
        '{}'::jsonb
      ) itin
      cross join lateral jsonb_array_elements(itin->'legs') with ordinality as t(l, ord)
      group by itin
    ) sigs
  ),
  'gate: planner_decompose_latlng returns ≥2 distinct route sequences'
);

-- TS-PLAN-07 setup: women-only ineligible driver + eligible graph
insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000001001')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('0a100000-0000-4000-8000-000000000001', 'Test Driver')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id, women_only_eligible) values
  ('0a100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'TSTDRV01', '0a020000-0000-4000-8000-000000000001', false)
on conflict (id) do update set women_only_eligible = false;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'car', 'TST-PLAN-07', 4, '0a100000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0a100000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-PLAN-07'
on conflict do nothing;

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

reset role;

select ok(
  not exists (
    select 1
    from planner_direct_candidates_latlng(
      11.060, 7.700, 11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": true, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' = 'parked'
  ),
  'TS-PLAN-07: women_only removes non-eligible parked direct'
);

select ok(
  exists (
    select 1
    from planner_direct_candidates_latlng(
      11.060, 7.700, 11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": true, "load": {"flagged": false}}'::jsonb
    ) c
    where c->>'source' = 'graph'
  ),
  'TS-PLAN-07: graph-only direct remains under women_only'
);

-- TS-PLAN-09: candidate limit respected by decompose_latlng
select ok(
  (
    select count(*) <= cfg_num('planner.max_candidates', '0a000000-0000-4000-8000-000000000001')::int
    from planner_decompose_latlng(
      11.060, 7.700, 11.068, 7.708,
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{}'::jsonb
    )
  ),
  'TS-PLAN-09: decompose_latlng respects cfg.planner.max_candidates'
);

select * from finish();
rollback;
