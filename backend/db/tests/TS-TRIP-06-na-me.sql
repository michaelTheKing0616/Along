-- pgTAP: TS-TRIP-06 — Na Me pairing unique per driver/rider concurrent trips (P1-A-05)
create extension if not exists pgtap;

begin;
select plan(4);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0c100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000004001'),
  ('0c100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000004002'),
  ('0c200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000004003'),
  ('0c200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000004004')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name, locale) values
  ('0c100000-0000-4000-8000-000000000001', '+2348000004001', 'Na Me Rider A', 'en-NG'),
  ('0c100000-0000-4000-8000-000000000002', '+2348000004002', 'Na Me Rider B', 'en-NG'),
  ('0c200000-0000-4000-8000-000000000001', '+2348000004003', 'Na Me Driver A', 'en-NG'),
  ('0c200000-0000-4000-8000-000000000002', '+2348000004004', 'Na Me Driver B', 'en-NG')
on conflict (id) do update set display_name = excluded.display_name, locale = excluded.locale;

insert into riders (id, home_city_id) values
  ('0c100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001'),
  ('0c100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0c200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'NMDRV01', '0a020000-0000-4000-8000-000000000001'),
  ('0c200000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'NMDRV02', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0c300000-0000-4000-8000-000000000001', 'NG', 'car', 'NA-ME-01', 4, '0c200000-0000-4000-8000-000000000001'),
  ('0c300000-0000-4000-8000-000000000002', 'NG', 'car', 'NA-ME-02', 4, '0c200000-0000-4000-8000-000000000002')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0c200000-0000-4000-8000-000000000001', '0c300000-0000-4000-8000-000000000001', true),
  ('0c200000-0000-4000-8000-000000000002', '0c300000-0000-4000-8000-000000000002', true)
on conflict do nothing;

-- Helper: seed planner query + request (presence seeded separately as superuser)
create or replace function _ts_trip06_request(
  p_rider uuid,
  p_driver uuid,
  p_candidate uuid,
  p_quote uuid
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into planner_queries (
    id, rider_id, city_id, origin, destination, filters,
    candidate_count, direct_count, candidates
  ) values (
    gen_random_uuid(), p_rider, '0a000000-0000-4000-8000-000000000001',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '{}'::jsonb, 1, 1,
    jsonb_build_array(jsonb_build_object(
      'candidate_id', p_candidate,
      'kind', 'direct',
      'source', 'parked',
      'viable_direct', true,
      'legs', jsonb_build_array(jsonb_build_object(
        'leg_index', 0,
        'mode', jsonb_build_object('code', 'car', 'label', 'Along taxi'),
        'board', jsonb_build_object(
          'stage_id', '0a040000-0000-4000-8000-000000000001',
          'name', 'Test Park Alpha',
          'location', jsonb_build_object('lat', 11.060, 'lng', 7.700),
          'walk_m', 0, 'walk_s', 0, 'wayfinding_available', true
        ),
        'alight', jsonb_build_object(
          'stage_id', '0a040000-0000-4000-8000-000000000005',
          'name', 'Test Park Beta',
          'location', jsonb_build_object('lat', 11.065, 'lng', 7.705)
        ),
        'route_id', '0a030000-0000-4000-8000-000000000001',
        'route_leg_ids', jsonb_build_array(),
        'in_vehicle_s', 600,
        'wait_s', 120,
        'fare', jsonb_build_object(
          'amount', 320, 'currency', 'NGN', 'tier', 2,
          'quote_id', p_quote, 'unconfirmed', false
        ),
        'supply', jsonb_build_object('kind', 'parked', 'driver_id', p_driver)
      ))
    ))
  );

  perform set_config('request.jwt.claim.sub', p_rider::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  return request_trip(p_candidate, 0, false, gen_random_uuid());
end;
$$;

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, park_id, nearest_stage_id, seats_available
) values
  ('0c200000-0000-4000-8000-000000000001', '0c300000-0000-4000-8000-000000000001', 'at_park',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, '0a020000-0000-4000-8000-000000000001',
   '0a040000-0000-4000-8000-000000000001', 3),
  ('0c200000-0000-4000-8000-000000000002', '0c300000-0000-4000-8000-000000000002', 'at_park',
   st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, '0a020000-0000-4000-8000-000000000001',
   '0a040000-0000-4000-8000-000000000001', 3)
on conflict (driver_id) do update set
  vehicle_id = excluded.vehicle_id,
  status = excluded.status,
  current_location = excluded.current_location,
  park_id = excluded.park_id,
  nearest_stage_id = excluded.nearest_stage_id;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values
  ('0c400000-0000-4000-8000-000000000001', '0c100000-0000-4000-8000-000000000001', '0c200000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320, 'NGN', '[]'::jsonb, 0.9, now() + interval '10 minutes'),
  ('0c400000-0000-4000-8000-000000000002', '0c100000-0000-4000-8000-000000000002', '0c200000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320, 'NGN', '[]'::jsonb, 0.9, now() + interval '10 minutes'),
  ('0c400000-0000-4000-8000-000000000003', '0c100000-0000-4000-8000-000000000001', '0c200000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 'car', 2, 320, 'NGN', '[]'::jsonb, 0.9, now() + interval '10 minutes');

set local role authenticated;

-- Trip 1: driver A + rider A
select _ts_trip06_request(
  '0c100000-0000-4000-8000-000000000001',
  '0c200000-0000-4000-8000-000000000001',
  '0c500000-0000-4000-8000-000000000001',
  '0c400000-0000-4000-8000-000000000001'
);

-- Accept trip 1 so it counts toward driver's in_use pairs
select set_config('request.jwt.claim.sub', '0c200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select respond_to_trip(
  (select id from trips where rider_id = '0c100000-0000-4000-8000-000000000001' and driver_id = '0c200000-0000-4000-8000-000000000001' limit 1),
  'accept'
);
select set_config('request.jwt.claim.sub', '0c100000-0000-4000-8000-000000000001', true);

-- Trip 2: same driver A, different rider B — must get different Na Me pair
select _ts_trip06_request(
  '0c100000-0000-4000-8000-000000000002',
  '0c200000-0000-4000-8000-000000000001',
  '0c500000-0000-4000-8000-000000000002',
  '0c400000-0000-4000-8000-000000000002'
);

reset role;

select is(
  (select count(distinct (id_signal_color || ':' || id_signal_shape))
   from trips
   where driver_id = '0c200000-0000-4000-8000-000000000001'),
  2::bigint,
  'TS-TRIP-06: driver concurrent trips have distinct Na Me pairs'
);

-- Trip 3: same rider A, different driver B
select _ts_trip06_request(
  '0c100000-0000-4000-8000-000000000001',
  '0c200000-0000-4000-8000-000000000002',
  '0c500000-0000-4000-8000-000000000003',
  '0c400000-0000-4000-8000-000000000003'
);

reset role;

select is(
  (select count(distinct (id_signal_color || ':' || id_signal_shape))
   from trips
   where rider_id = '0c100000-0000-4000-8000-000000000001'),
  2::bigint,
  'TS-TRIP-06: rider concurrent trips have distinct Na Me pairs'
);

select is(
  (select (trip_snapshot(
    (select id from trips where rider_id = '0c100000-0000-4000-8000-000000000001' order by created_at desc limit 1)
  )->'na_me'->>'label')),
  (select _na_me_label(id_signal_color, id_signal_shape)
   from trips
   where rider_id = '0c100000-0000-4000-8000-000000000001'
   order by created_at desc limit 1),
  'TS-TRIP-06: Na Me label matches localized token label'
);

select ok(
  (select trip_snapshot(
    (select id from trips where rider_id = '0c100000-0000-4000-8000-000000000001' order by created_at desc limit 1)
  )->'na_me' ? 'color_token'),
  'TS-TRIP-06: TripView includes na_me color_token'
);

select * from finish();
rollback;
