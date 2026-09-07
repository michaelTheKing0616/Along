-- pgTAP: TS-PLAN-07 request/hail enforcement — women_only eligibility + regulatory gating (P5-A-02)
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

-- Rider + ineligible parked driver (mirrors TS-PLAN-v2 TS-PLAN-07 setup)
insert into auth.users (id, aud, role, phone) values
  ('0b100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000002001'),
  ('0b200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000002002')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('0b100000-0000-4000-8000-000000000001', 'WO Test Rider'),
  ('0b200000-0000-4000-8000-000000000001', 'WO Ineligible Driver')
on conflict (id) do nothing;

insert into riders (id, home_city_id) values
  ('0b100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id, women_only_eligible) values
  ('0b200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'WOTST01', '0a020000-0000-4000-8000-000000000001', false)
on conflict (id) do update set women_only_eligible = false;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'car', 'TST-WO-07', 4, '0b200000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0b200000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-WO-07'
on conflict do nothing;

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available, last_ping_at
) values (
  '0b200000-0000-4000-8000-000000000001',
  (select id from vehicles where plate_number = 'TST-WO-07' limit 1),
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3,
  now()
) on conflict (driver_id) do update set
  status = excluded.status,
  nearest_stage_id = excluded.nearest_stage_id,
  last_ping_at = excluded.last_ping_at;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0b500000-0000-4000-8000-000000000001',
  '0b100000-0000-4000-8000-000000000001',
  '0b200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '0b100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"women_only": true}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '0b800000-0000-4000-8000-000000000001',
    'kind', 'direct', 'source', 'parked', 'viable_direct', true,
    'legs', jsonb_build_array(jsonb_build_object(
      'leg_index', 0,
      'mode', jsonb_build_object('code', 'car'),
      'board', jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000001'),
      'alight', jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005'),
      'route_id', '0a030000-0000-4000-8000-000000000001',
      'route_leg_ids', '[]'::jsonb,
      'fare', jsonb_build_object(
        'amount', 320, 'currency', 'NGN', 'tier', 2,
        'quote_id', '0b500000-0000-4000-8000-000000000001', 'unconfirmed', false
      ),
      'supply', jsonb_build_object(
        'kind', 'parked',
        'driver_id', '0b200000-0000-4000-8000-000000000001'
      )
    ))
  ))
);

select set_config('request.jwt.claim.sub', '0b100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select request_trip('0b800000-0000-4000-8000-000000000001', 0, true, gen_random_uuid()) $$,
  'P0001',
  'DRIVER_NOT_MATCHABLE',
  'TS-PLAN-07: request_trip rejects non-eligible parked driver when women_only=true'
);

reset role;

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
  'TS-PLAN-07: graph-only direct remains under women_only (planner layer)'
);

-- Regulatory flag disabled → women_only requests rejected
set local role postgres;

update countries
set regulatory_flags = '{}'::jsonb
where code = 'NG';

select set_config('request.jwt.claim.sub', '0b100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select request_trip('0b800000-0000-4000-8000-000000000001', 0, true, gen_random_uuid()) $$,
  'P0001',
  'STATE_INVALID',
  'TS-PLAN-07: request_trip rejects women_only when regulatory flag disabled'
);

-- Roaming hail path with ineligible driver
reset role;
set local role postgres;

update countries
set regulatory_flags = '{"women_only_matching": true}'::jsonb
where code = 'NG';

update driver_presence
set
  status = 'roaming_available',
  session_id = '0b810000-0000-4000-8000-000000000001',
  current_location = st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  nearest_stage_id = '0a041000-0000-4000-8000-000000000002',
  last_ping_at = now()
where driver_id = '0b200000-0000-4000-8000-000000000001';

select set_config('app.settings.candidate_token_hmac_key', 'along-test-candidate-hmac-do-not-commit', true);

select set_config(
  'test.wo07_roam_token',
  sign_candidate_token(
    '0b200000-0000-4000-8000-000000000001',
    '0b810000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001'
  ),
  true
);

select set_config('request.jwt.claim.sub', '0b100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  format(
    $$ select hail_roaming(%L, '{"lat":11.065,"lng":7.705}'::jsonb, true, gen_random_uuid()) $$,
    current_setting('test.wo07_roam_token')
  ),
  'P0001',
  'DRIVER_NOT_MATCHABLE',
  'TS-PLAN-07: hail_roaming rejects non-eligible driver when women_only=true'
);

reset role;
set local role postgres;

update countries
set regulatory_flags = '{}'::jsonb
where code = 'NG';

select set_config('request.jwt.claim.sub', '0b100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  format(
    $$ select hail_roaming(%L, '{"lat":11.065,"lng":7.705}'::jsonb, true, gen_random_uuid()) $$,
    current_setting('test.wo07_roam_token')
  ),
  'P0001',
  'STATE_INVALID',
  'TS-PLAN-07: hail_roaming rejects women_only when regulatory flag disabled'
);

select * from finish();
rollback;
