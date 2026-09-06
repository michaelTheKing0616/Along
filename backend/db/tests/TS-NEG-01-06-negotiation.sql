-- pgTAP: TS-NEG-01..06 — Along Pricing negotiation (P2-A-02)
create extension if not exists pgtap;

begin;
select plan(26);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

-- Shared identities
insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007001'),
  ('0f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007002'),
  ('0f200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000007003')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000001', '+2348000007001', 'Neg Rider'),
  ('0f200000-0000-4000-8000-000000000001', '+2348000007002', 'Neg Driver Park'),
  ('0f200000-0000-4000-8000-000000000002', '+2348000007003', 'Neg Driver Roam')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'NEGP01', '0a020000-0000-4000-8000-000000000001'),
  ('0f200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'NEGR01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f300000-0000-4000-8000-000000000001', 'NG', 'car', 'NEG-P01', 4, '0f200000-0000-4000-8000-000000000001'),
  ('0f300000-0000-4000-8000-000000000002', 'NG', 'car', 'NEG-R01', 4, '0f200000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000001', '0f300000-0000-4000-8000-000000000001', true),
  ('0f200000-0000-4000-8000-000000000002', '0f300000-0000-4000-8000-000000000002', true)
on conflict do nothing;

-- Tier-3 candidate route (same pattern as TS-FARE-04)
insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score)
values (
  '0f030000-0000-4000-8000-000000000099',
  '0a000000-0000-4000-8000-000000000001',
  '0a020000-0000-4000-8000-000000000001',
  '0a020000-0000-4000-8000-000000000002',
  'car',
  '0a010000-0000-4000-8000-000000000001',
  'candidate',
  0.300
);

insert into route_stages (id, route_id, sequence, location, source_id, verification_status, confidence_score) values
  ('0f090000-0000-4000-8000-000000000001', '0f030000-0000-4000-8000-000000000099', 1, st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300),
  ('0f090000-0000-4000-8000-000000000002', '0f030000-0000-4000-8000-000000000099', 2, st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300),
  ('0f090000-0000-4000-8000-000000000003', '0f030000-0000-4000-8000-000000000099', 3, st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300),
  ('0f090000-0000-4000-8000-000000000004', '0f030000-0000-4000-8000-000000000099', 4, st_setsrid(st_makepoint(7.704, 11.064), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300);

insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, distance_m)
values (
  '0f030000-0000-4000-8000-000000000099',
  '0f090000-0000-4000-8000-000000000001',
  '0f090000-0000-4000-8000-000000000002',
  'car', 80.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 800
);

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available, speed_mps, last_ping_at
) values
  ('0f200000-0000-4000-8000-000000000001', '0f300000-0000-4000-8000-000000000001', 'at_park',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, '0a020000-0000-4000-8000-000000000001',
   '0a040000-0000-4000-8000-000000000001', 3, 0, now()),
  ('0f200000-0000-4000-8000-000000000002', '0f300000-0000-4000-8000-000000000002', 'roaming_available',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, null,
   '0a040000-0000-4000-8000-000000000001', 3, 0, now())
on conflict (driver_id) do update set
  status = excluded.status,
  current_location = excluded.current_location,
  speed_mps = excluded.speed_mps,
  declared_route_profile_id = excluded.declared_route_profile_id,
  last_ping_at = excluded.last_ping_at;

-- Helper for roaming ETA band tests (must exist before role switch)
create or replace function _ts_neg03_open_at_distance(p_dist_m double precision)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_rider geography := st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography;
  v_driver geography;
begin
  v_driver := st_project(v_rider::geometry, p_dist_m, radians(0))::geography;

  update driver_presence
  set current_location = v_driver,
      speed_mps = 0,
      status = 'roaming_available',
      declared_route_profile_id = null
  where driver_id = '0f200000-0000-4000-8000-000000000002';

  perform set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  return open_negotiation(
    'roaming'::negotiation_context,
    jsonb_build_object(
      'lat', st_y(v_rider::geometry),
      'lng', st_x(v_rider::geometry),
      'stage_id', '0f090000-0000-4000-8000-000000000002'
    ),
    jsonb_build_object('stage_id', '0f090000-0000-4000-8000-000000000004'),
    gen_random_uuid(),
    '0f200000-0000-4000-8000-000000000002'::uuid
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- TS-NEG-01: Tier 1/2 pair → open_negotiation raises STATE_INVALID
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select open_negotiation(
       'park'::negotiation_context,
       jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000001'),
       jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005'),
       gen_random_uuid(),
       '0f200000-0000-4000-8000-000000000001'::uuid
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-NEG-01: tier 2 pair rejects open_negotiation'
);

-- ---------------------------------------------------------------------------
-- TS-NEG-02: Park — 4 rounds, 5th rejected, split midpoint, accept → trip tier 3 + fare_corrections
-- ---------------------------------------------------------------------------
select set_config('test.neg02_id', (
  select open_negotiation(
    'park'::negotiation_context,
    jsonb_build_object('stage_id', '0f090000-0000-4000-8000-000000000002'),
    jsonb_build_object('stage_id', '0f090000-0000-4000-8000-000000000004'),
    gen_random_uuid(),
    '0f200000-0000-4000-8000-000000000001'::uuid
  )->>'negotiation_id'
), true);

select ok(
  (select round_cap from price_negotiations where id = current_setting('test.neg02_id')::uuid)
    = cfg_num('negotiation.park.round_cap', '0a000000-0000-4000-8000-000000000001')::int,
  'TS-NEG-02: park round_cap from config'
);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  negotiation_round(
    current_setting('test.neg02_id')::uuid,
    'counter',
    (select amount - 50 from price_negotiation_rounds where negotiation_id = current_setting('test.neg02_id')::uuid order by round_number desc limit 1)
  ) is not null,
  'TS-NEG-02: driver counter round 2'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  negotiation_round(
    current_setting('test.neg02_id')::uuid,
    'counter',
    (select amount + 50 from price_negotiation_rounds where negotiation_id = current_setting('test.neg02_id')::uuid order by round_number desc limit 1)
  ) is not null,
  'TS-NEG-02: rider counter round 3'
);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  negotiation_round(
    current_setting('test.neg02_id')::uuid,
    'counter',
    (select amount - 50 from price_negotiation_rounds where negotiation_id = current_setting('test.neg02_id')::uuid order by round_number desc limit 1)
  ) is not null,
  'TS-NEG-02: driver counter round 4'
);

select throws_ok(
  $$ select negotiation_round(
       current_setting('test.neg02_id')::uuid,
       'counter',
       (select amount + 50 from price_negotiation_rounds where negotiation_id = current_setting('test.neg02_id')::uuid order by round_number desc limit 1)
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-NEG-02: 5th counter rejected at round_cap'
);

select ok(
  negotiation_split(current_setting('test.neg02_id')::uuid) is not null,
  'TS-NEG-02: split at round_cap creates midpoint round'
);

select ok(
  exists (
    select 1 from price_negotiation_rounds
    where negotiation_id = current_setting('test.neg02_id')::uuid
      and proposed_by = 'system'
  ),
  'TS-NEG-02: system split round exists'
);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  (negotiation_round(current_setting('test.neg02_id')::uuid, 'accept')->>'status') = 'agreed',
  'TS-NEG-02: driver accept locks negotiation'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select ok(
  exists (
    select 1 from trips t
    join price_negotiations n on n.resulting_trip_id = t.id
    where n.id = current_setting('test.neg02_id')::uuid
      and t.fare_tier = 3
  ),
  'TS-NEG-02: resulting trip has fare_tier 3'
);

select ok(
  exists (
    select 1 from fare_corrections fc
    join price_negotiations n on n.resulting_trip_id = fc.trip_id
    where n.id = current_setting('test.neg02_id')::uuid
      and fc.status = 'pending'
      and fc.submitter_role = 'system'
  ),
  'TS-NEG-02: fare_corrections pending posted on accept'
);

-- ---------------------------------------------------------------------------
-- TS-NEG-03: Roaming ETA bands — 15s none, 45s single, 150s full
-- ---------------------------------------------------------------------------
select is(
  (_ts_neg03_open_at_distance(45)->>'eta_band'),
  'none',
  'TS-NEG-03: eta ~15s → none band'
);

select is(
  (_ts_neg03_open_at_distance(45)->>'round_cap')::int,
  0,
  'TS-NEG-03: none band round_cap 0'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select negotiation_round(
       (select id from price_negotiations where context = 'roaming' and eta_band = 'none' order by created_at desc limit 1),
       'counter',
       500
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-NEG-03: none band counter rejected'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (_ts_neg03_open_at_distance(135)->>'eta_band'),
  'single',
  'TS-NEG-03: eta ~45s → single band'
);

select is(
  (_ts_neg03_open_at_distance(135)->>'round_cap')::int,
  1,
  'TS-NEG-03: single band round_cap 1'
);

select is(
  (_ts_neg03_open_at_distance(450)->>'eta_band'),
  'full',
  'TS-NEG-03: eta ~150s → full band'
);

select is(
  (_ts_neg03_open_at_distance(450)->>'round_cap')::int,
  cfg_num('negotiation.roaming.round_cap', '0a000000-0000-4000-8000-000000000001')::int,
  'TS-NEG-03: full band uses config round_cap'
);

-- ---------------------------------------------------------------------------
-- TS-NEG-04: Roaming vehicle leaves pickup radius → lapsed mid-round
-- ---------------------------------------------------------------------------
select set_config('test.neg04_id', (_ts_neg03_open_at_distance(450)->>'negotiation_id'), true);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  negotiation_round(
    current_setting('test.neg04_id')::uuid,
    'counter',
    (select amount - 50 from price_negotiation_rounds where negotiation_id = current_setting('test.neg04_id')::uuid order by round_number desc limit 1)
  ) is not null,
  'TS-NEG-04: mid-round counter before lapse'
);

set local role none;

update price_negotiations
set status = 'lapsed', resolved_at = now()
where status = 'open'
  and id <> current_setting('test.neg04_id')::uuid;

update driver_presence
set current_location = st_project(
      st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography::geometry,
      500,
      radians(0)
    )::geography,
    speed_mps = 5
where driver_id = '0f200000-0000-4000-8000-000000000002';

select ok(
  (negotiation_clock_tick()->>'lapsed')::int >= 1,
  'TS-NEG-04: clock tick lapses out-of-range roaming negotiation'
);

select is(
  (select status::text from price_negotiations where id = current_setting('test.neg04_id')::uuid),
  'lapsed',
  'TS-NEG-04: negotiation status lapsed'
);

-- ---------------------------------------------------------------------------
-- TS-NEG-05: Timeout → lapsed; round rows immutable
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config('test.neg05_id', (
  select open_negotiation(
    'park'::negotiation_context,
    jsonb_build_object('stage_id', '0f090000-0000-4000-8000-000000000002'),
    jsonb_build_object('stage_id', '0f090000-0000-4000-8000-000000000004'),
    gen_random_uuid(),
    '0f200000-0000-4000-8000-000000000001'::uuid
  )->>'negotiation_id'
), true);

set local role none;

update price_negotiations
set expires_at = now() - interval '1 second'
where id = current_setting('test.neg05_id')::uuid;

select ok(
  (negotiation_clock_tick()->>'lapsed')::int >= 1,
  'TS-NEG-05: timeout lapses open negotiation'
);

select is(
  (select status::text from price_negotiations where id = current_setting('test.neg05_id')::uuid),
  'lapsed',
  'TS-NEG-05: status lapsed after timeout'
);

select throws_ok(
  $$ update price_negotiation_rounds set amount = 1 where negotiation_id = current_setting('test.neg05_id')::uuid $$,
  '42501',
  null,
  'TS-NEG-05: round rows reject update (append-only)'
);

select throws_ok(
  $$ delete from price_negotiation_rounds where negotiation_id = current_setting('test.neg05_id')::uuid $$,
  '42501',
  null,
  'TS-NEG-05: round rows reject delete (append-only)'
);

-- ---------------------------------------------------------------------------
-- TS-NEG-06: Roaming driver with declared profile covering pair → refused
-- ---------------------------------------------------------------------------
insert into driver_route_profiles (id, driver_id, route_id, mode_code, active)
values (
  '0f200000-0000-4000-8000-000000000010',
  '0f200000-0000-4000-8000-000000000002',
  '0a030000-0000-4000-8000-000000000001',
  'car',
  true
)
on conflict (id) do nothing;

insert into driver_route_stops (profile_id, sequence, route_stage_id, price_to_end, currency) values
  ('0f200000-0000-4000-8000-000000000010', 1, '0a040000-0000-4000-8000-000000000001', 400, 'NGN'),
  ('0f200000-0000-4000-8000-000000000010', 2, '0a040000-0000-4000-8000-000000000002', 300, 'NGN'),
  ('0f200000-0000-4000-8000-000000000010', 3, '0a040000-0000-4000-8000-000000000003', 150, 'NGN'),
  ('0f200000-0000-4000-8000-000000000010', 4, '0a040000-0000-4000-8000-000000000004', 50, 'NGN'),
  ('0f200000-0000-4000-8000-000000000010', 5, '0a040000-0000-4000-8000-000000000005', 0, 'NGN')
on conflict do nothing;

update driver_presence
set declared_route_profile_id = '0f200000-0000-4000-8000-000000000010',
    current_location = st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    speed_mps = 0
where driver_id = '0f200000-0000-4000-8000-000000000002';

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  $$ select open_negotiation(
       'roaming'::negotiation_context,
       jsonb_build_object('lat', 11.060, 'lng', 7.700),
       jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005'),
       gen_random_uuid(),
       '0f200000-0000-4000-8000-000000000002'::uuid
     ) $$,
  'P0001',
  'STATE_INVALID',
  'TS-NEG-06: roaming driver with profile covering pair refused'
);

select * from finish();
rollback;
