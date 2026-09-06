-- pgTAP: TS-TRIP-08 — extension propose/accept/decline + completion commission (P4-A-05)
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

-- Through-fare for extension delta: stage 3 → stage 5 = 150 NGN (tier 1)
insert into route_through_fares (
  route_id, from_stage_id, to_stage_id, mode_code,
  fare_amount, fare_currency, source_id, verification_status, confidence_score
) values (
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000003',
  '0a040000-0000-4000-8000-000000000005',
  'car',
  150.00,
  'NGN',
  '0a010000-0000-4000-8000-000000000001',
  'crowd_verified',
  0.800
);

insert into auth.users (id, aud, role, phone) values
  ('0f800000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008001'),
  ('0f810000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008002')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f800000-0000-4000-8000-000000000001', '+2348000008001', 'Extension Rider'),
  ('0f810000-0000-4000-8000-000000000001', '+2348000008002', 'Extension Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f800000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f810000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'EXT01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f820000-0000-4000-8000-000000000001', 'NG', 'car', 'EXT-01', 4, '0f810000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f810000-0000-4000-8000-000000000001', '0f820000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f830000-0000-4000-8000-000000000001',
  '0f800000-0000-4000-8000-000000000001',
  '0f810000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000003',
  'car', 2, 320.00, 'NGN', '[{"kind":"leg","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
),
(
  '0f830000-0000-4000-8000-000000000002',
  '0f800000-0000-4000-8000-000000000001',
  '0f810000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000003',
  'car', 2, 320.00, 'NGN', '[{"kind":"leg","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values
  (
    '0f840000-0000-4000-8000-000000000001',
    '0f800000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001',
    'active',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography,
    '{"candidate_id":"0f850000-0000-4000-8000-000000000001","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
  ),
  (
    '0f840000-0000-4000-8000-000000000002',
    '0f800000-0000-4000-8000-000000000001',
    '0a000000-0000-4000-8000-000000000001',
    'active',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography,
    '{"candidate_id":"0f850000-0000-4000-8000-000000000002","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
  );

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, vehicle_id, mode_code, route_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id,
  boarding_location, alighting_location,
  started_at
) values
  (
    '0f860000-0000-4000-8000-000000000001',
    '0f840000-0000-4000-8000-000000000001',
    1,
    '0f800000-0000-4000-8000-000000000001',
    '0f810000-0000-4000-8000-000000000001',
    '0f820000-0000-4000-8000-000000000001',
    'car',
    '0a030000-0000-4000-8000-000000000001',
    '0f830000-0000-4000-8000-000000000001',
    320.00, 'NGN', 2, 0.05,
    'in_transit',
    now() + interval '25 seconds',
    'color.naMe.green', 'diamond',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000003',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography,
    now() - interval '6 minutes'
  ),
  (
    '0f860000-0000-4000-8000-000000000002',
    '0f840000-0000-4000-8000-000000000002',
    1,
    '0f800000-0000-4000-8000-000000000001',
    '0f810000-0000-4000-8000-000000000001',
    '0f820000-0000-4000-8000-000000000001',
    'car',
    '0a030000-0000-4000-8000-000000000001',
    '0f830000-0000-4000-8000-000000000002',
    320.00, 'NGN', 2, 0.05,
    'in_transit',
    now() + interval '25 seconds',
    'color.naMe.blue', 'circle',
    '0a040000-0000-4000-8000-000000000001',
    '0a040000-0000-4000-8000-000000000003',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography,
    now() - interval '6 minutes'
  );

-- Accept path: rider proposes +150 → driver accepts → alighting updated
select set_config('request.jwt.claim.sub', '0f800000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (propose_extension(
    '0f860000-0000-4000-8000-000000000001'::uuid,
    jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005')
  )->>'fare_delta')::numeric,
  150.00::numeric,
  'TS-TRIP-08: propose extension fare_delta = +150'
);

select set_config('request.jwt.claim.sub', '0f810000-0000-4000-8000-000000000001', true);
select respond_extension(
  (
    select id from trip_extensions
    where trip_id = '0f860000-0000-4000-8000-000000000001'
    order by proposed_at desc
    limit 1
  ),
  'accept'
);

select is(
  (select alighting_stage_id from trips where id = '0f860000-0000-4000-8000-000000000001'),
  '0a040000-0000-4000-8000-000000000005'::uuid,
  'TS-TRIP-08: accept updates trips.alighting_stage_id'
);

select is(
  (select status from trip_extensions where trip_id = '0f860000-0000-4000-8000-000000000001'),
  'accepted',
  'TS-TRIP-08: extension status accepted'
);

select complete_trip('0f860000-0000-4000-8000-000000000001'::uuid);

select is(
  (select count(*)::int from driver_ledger_entries
   where trip_id = '0f860000-0000-4000-8000-000000000001'
     and entry_type = 'cash_commission_debit'),
  2,
  'TS-TRIP-08: completion posts base + extension commission (two rows)'
);

select is(
  (select amount from driver_ledger_entries
   where idempotency_key = 'trip:0f860000-0000-4000-8000-000000000001:commission'),
  -16.00::numeric,
  'TS-TRIP-08: base commission = round(320 × 0.05) = -16'
);

select is(
  (select amount from driver_ledger_entries dle
   join trip_extensions te on te.id = dle.trip_extension_id
   where te.trip_id = '0f860000-0000-4000-8000-000000000001'),
  -7.50::numeric,
  'TS-TRIP-08: extension commission = round(150 × 0.05) = -7.50'
);

-- Declined path: propose → decline → completion posts base only
select set_config('request.jwt.claim.sub', '0f800000-0000-4000-8000-000000000001', true);
select propose_extension(
  '0f860000-0000-4000-8000-000000000002'::uuid,
  jsonb_build_object('stage_id', '0a040000-0000-4000-8000-000000000005')
);

select set_config('request.jwt.claim.sub', '0f810000-0000-4000-8000-000000000001', true);
select respond_extension(
  (
    select id from trip_extensions
    where trip_id = '0f860000-0000-4000-8000-000000000002'
      and status = 'proposed'
    limit 1
  ),
  'decline'
);

select is(
  (select status from trip_extensions
   where trip_id = '0f860000-0000-4000-8000-000000000002'
   order by proposed_at desc
   limit 1),
  'declined',
  'TS-TRIP-08: declined extension status'
);

select complete_trip('0f860000-0000-4000-8000-000000000002'::uuid);

select is(
  (select count(*)::int from driver_ledger_entries
   where trip_id = '0f860000-0000-4000-8000-000000000002'
     and entry_type = 'cash_commission_debit'),
  1,
  'TS-TRIP-08: declined extension bills nothing (base commission only)'
);

select ok(
  not exists (
    select 1 from driver_ledger_entries dle
    join trip_extensions te on te.id = dle.trip_extension_id
    where te.trip_id = '0f860000-0000-4000-8000-000000000002'
  ),
  'TS-TRIP-08: no extension ledger row for declined extension'
);

select * from finish();
rollback;
