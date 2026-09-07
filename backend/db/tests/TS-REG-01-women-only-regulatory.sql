-- pgTAP: TS-REG-01 — women_only_matching regulatory flag gates mixed vs women-only match (P10-A-01)
create extension if not exists pgtap;

begin;
select plan(4);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0c100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003001'),
  ('0c200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003002'),
  ('0c200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000003003'),
  ('0c200000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000003004')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('0c100000-0000-4000-8000-000000000001', 'REG Test Rider'),
  ('0c200000-0000-4000-8000-000000000001', 'REG Mixed Driver A'),
  ('0c200000-0000-4000-8000-000000000002', 'REG Women Driver'),
  ('0c200000-0000-4000-8000-000000000003', 'REG Mixed Driver B')
on conflict (id) do nothing;

insert into riders (id, home_city_id) values
  ('0c100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id, women_only_eligible) values
  ('0c200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'REGMIX1', '0a020000-0000-4000-8000-000000000001', false),
  ('0c200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'REGWO01', '0a020000-0000-4000-8000-000000000001', true),
  ('0c200000-0000-4000-8000-000000000003', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'REGMIX2', '0a020000-0000-4000-8000-000000000001', false)
on conflict (id) do update set women_only_eligible = excluded.women_only_eligible;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'car', 'TST-REG-M1', 4, '0c200000-0000-4000-8000-000000000001'),
  ('NG', 'car', 'TST-REG-WO', 4, '0c200000-0000-4000-8000-000000000002'),
  ('NG', 'car', 'TST-REG-M2', 4, '0c200000-0000-4000-8000-000000000003')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select d.id, v.id, true
from drivers d
join vehicles v on v.owner_profile_id = d.id
where d.id in (
  '0c200000-0000-4000-8000-000000000001',
  '0c200000-0000-4000-8000-000000000002',
  '0c200000-0000-4000-8000-000000000003'
)
on conflict do nothing;

insert into driver_presence (driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available, last_ping_at)
select
  d.id,
  v.id,
  'at_park',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  '0a020000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  3,
  now()
from drivers d
join vehicles v on v.owner_profile_id = d.id
where d.id in (
  '0c200000-0000-4000-8000-000000000001',
  '0c200000-0000-4000-8000-000000000003'
)
on conflict (driver_id) do update set
  status = excluded.status,
  nearest_stage_id = excluded.nearest_stage_id,
  last_ping_at = excluded.last_ping_at;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values
  (
    '0c500000-0000-4000-8000-000000000001',
    '0c100000-0000-4000-8000-000000000001',
    '0c200000-0000-4000-8000-000000000001',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
    now() + interval '10 minutes'
  ),
  (
    '0c500000-0000-4000-8000-000000000002',
    '0c100000-0000-4000-8000-000000000001',
    '0c200000-0000-4000-8000-000000000003',
    '0a030000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000005',
    'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900,
    now() + interval '10 minutes'
  );

-- flag=false first: mixed match allowed, women_only requests rejected
set local role postgres;
update countries
set regulatory_flags = '{"women_only_matching": false}'::jsonb
where code = 'NG';

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '0c100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"women_only": false}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '0c800000-0000-4000-8000-000000000001',
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
        'quote_id', '0c500000-0000-4000-8000-000000000001', 'unconfirmed', false
      ),
      'supply', jsonb_build_object(
        'kind', 'parked',
        'driver_id', '0c200000-0000-4000-8000-000000000001'
      )
    ))
  ))
);

select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select lives_ok(
  $$ select request_trip('0c800000-0000-4000-8000-000000000001', 0, false, gen_random_uuid()) $$,
  'TS-REG-01: flag=false allows mixed match (women_only=false)'
);

select throws_ok(
  $$ select request_trip('0c800000-0000-4000-8000-000000000001', 0, true, gen_random_uuid()) $$,
  'P0001',
  'STATE_INVALID',
  'TS-REG-01: flag=false rejects women_only requests'
);

reset role;
set local role postgres;

update countries
set regulatory_flags = '{"women_only_matching": true}'::jsonb
where code = 'NG';

insert into planner_queries (
  rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates
) values (
  '0c100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"women_only": false}'::jsonb, 1, 1,
  jsonb_build_array(jsonb_build_object(
    'candidate_id', '0c800000-0000-4000-8000-000000000002',
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
        'quote_id', '0c500000-0000-4000-8000-000000000002', 'unconfirmed', false
      ),
      'supply', jsonb_build_object(
        'kind', 'parked',
        'driver_id', '0c200000-0000-4000-8000-000000000003'
      )
    ))
  ))
);

select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select lives_ok(
  $$ select request_trip('0c800000-0000-4000-8000-000000000002', 0, false, gen_random_uuid()) $$,
  'TS-REG-01: flag=true allows mixed match (women_only=false) with non-eligible driver'
);

reset role;
set local role postgres;

update planner_queries
set filters = '{"women_only": true}'::jsonb,
    candidates = jsonb_build_array(jsonb_build_object(
      'candidate_id', '0c800000-0000-4000-8000-000000000003',
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
          'quote_id', '0c500000-0000-4000-8000-000000000001', 'unconfirmed', false
        ),
        'supply', jsonb_build_object(
          'kind', 'parked',
          'driver_id', '0c200000-0000-4000-8000-000000000001'
        )
      ))
    ))
where rider_id = '0c100000-0000-4000-8000-000000000001';

select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select request_trip('0c800000-0000-4000-8000-000000000003', 0, true, gen_random_uuid()) $$,
  'P0001',
  'DRIVER_NOT_MATCHABLE',
  'TS-REG-01: flag=true enforces women-only match (non-eligible driver rejected)'
);

select * from finish();
rollback;
