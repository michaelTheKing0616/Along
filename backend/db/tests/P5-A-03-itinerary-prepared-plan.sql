-- pgTAP: P5-A-03 — prepared_plan present before next stop completes (FM23: candidate set, not booked)
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000007101'),
  ('0f200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000007102')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000011', '+2348000007101', 'Itinerary Rider'),
  ('0f200000-0000-4000-8000-000000000011', '+2348000007102', 'Itinerary Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'ITN001', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f300000-0000-4000-8000-000000000011', 'NG', 'car', 'ITN-01', 4, '0f200000-0000-4000-8000-000000000011')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000011', '0f300000-0000-4000-8000-000000000011', true)
on conflict do nothing;

insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values (
  '0f200000-0000-4000-8000-000000000011',
  '0f300000-0000-4000-8000-000000000011',
  '0f310000-0000-4000-8000-000000000011',
  'roaming_available',
  st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  '0a040000-0000-4000-8000-000000000001',
  2,
  now()
) on conflict (driver_id) do update set
  current_location = excluded.current_location,
  last_ping_at = excluded.last_ping_at;

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000011', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config(
  'test.itin_create',
  create_itinerary(jsonb_build_array(
    jsonb_build_object(
      'sequence', 1,
      'destination_description', 'Test Park Alpha',
      'location', jsonb_build_object('lat', 11.060, 'lng', 7.700)
    ),
    jsonb_build_object(
      'sequence', 2,
      'destination_description', 'Test Park Beta',
      'location', jsonb_build_object('lat', 11.065, 'lng', 7.705)
    )
  ))::text,
  true
);

select ok(
  (current_setting('test.itin_create')::jsonb->>'not_booked')::boolean,
  'P5-A-03: create_itinerary state marks not_booked (FM23)'
);

reset role;

insert into journeys (
  id, rider_id, city_id, status, origin, destination, destination_label, plan_snapshot, itinerary_stop_id
) values (
  '0f500000-0000-4000-8000-000000000011',
  '0f100000-0000-4000-8000-000000000011',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.702, 11.062), 4326)::geography,
  'Test Park Alpha',
  jsonb_build_object('legs', jsonb_build_array(
    jsonb_build_object('leg_index', 0, 'in_vehicle_s', 120, 'mode', jsonb_build_object('code', 'car'))
  )),
  (
    select (s->>'id')::uuid
    from jsonb_array_elements(current_setting('test.itin_create')::jsonb->'stops') s
    where (s->>'sequence')::int = 1
  )
);

update itinerary_stops
set status = 'in_progress', linked_journey_id = '0f500000-0000-4000-8000-000000000011'
where itinerary_id = (current_setting('test.itin_create')::jsonb->>'itinerary_id')::uuid
  and sequence = 1;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f400000-0000-4000-8000-000000000011',
  '0f100000-0000-4000-8000-000000000011',
  '0f200000-0000-4000-8000-000000000011',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at,
  id_signal_color, id_signal_shape
) values (
  '0f600000-0000-4000-8000-000000000011',
  '0f500000-0000-4000-8000-000000000011',
  '0f100000-0000-4000-8000-000000000011',
  '0f200000-0000-4000-8000-000000000011',
  '0f300000-0000-4000-8000-000000000011',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0f400000-0000-4000-8000-000000000011',
  320.00, 'NGN', 2, 0.05,
  'in_transit',
  now() + interval '10 minutes',
  now() - interval '8 minutes',
  now() - interval '6 minutes',
  now() - interval '4 minutes',
  'red', 'circle'
);

reset role;

select ok(
  (itinerary_prepare_context('0f600000-0000-4000-8000-000000000011')->>'eligible')::boolean,
  'P5-A-03: itinerary_prepare_context eligible when in_transit within prepare ETA'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000011', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config(
  'test.itin_match',
  itinerary_match_next((current_setting('test.itin_create')::jsonb->>'itinerary_id')::uuid)::text,
  true
);

select ok(
  (
    select s.prepared_plan is not null
    from itinerary_stops s
    where s.itinerary_id = (current_setting('test.itin_create')::jsonb->>'itinerary_id')::uuid
      and s.sequence = 2
      and s.status = 'pending'
  ),
  'P5-A-03: next pending stop has prepared_plan before in_progress/completed'
);

select ok(
  (
    select (s.prepared_plan->>'candidate_set_only')::boolean
    from itinerary_stops s
    where s.itinerary_id = (current_setting('test.itin_create')::jsonb->>'itinerary_id')::uuid
      and s.sequence = 2
  ),
  'P5-A-03: prepared_plan is candidate_set_only (not booked, FM23)'
);

select ok(
  (current_setting('test.itin_match')::jsonb->>'match_action') = 'request_trip',
  'P5-A-03: itinerary_match_next response directs to request_trip not auto-book'
);

select * from finish();
rollback;
