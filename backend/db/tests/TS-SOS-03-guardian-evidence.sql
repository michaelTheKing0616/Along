-- pgTAP: TS-SOS-03 — guardian share controls + incident photo evidence (migration 103)
create extension if not exists pgtap;

begin;
select plan(14);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000006201'),
  ('0e200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000006202')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000011', '+2348000006201', 'Share Rider'),
  ('0e200000-0000-4000-8000-000000000011', '+2348000006202', 'Share Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'SHRDR1', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, color, owner_profile_id) values
  ('0e300000-0000-4000-8000-000000000011', 'NG', 'car', 'SHR-01', 4, 'blue', '0e200000-0000-4000-8000-000000000011')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0e200000-0000-4000-8000-000000000011', '0e300000-0000-4000-8000-000000000011', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0e400000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  '0e200000-0000-4000-8000-000000000011',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into journeys (
  id, rider_id, city_id, status, origin, destination, destination_label, plan_snapshot
) values (
  '0e500000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  '0a000000-0000-4000-8000-000000000001',
  'active',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  'Test Park Beta',
  jsonb_build_object('legs', jsonb_build_array(
    jsonb_build_object('leg_index', 0, 'mode', jsonb_build_object('code', 'car', 'label', 'Along taxi'))
  ))
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, started_at, id_signal_color, id_signal_shape
) values (
  '0e600000-0000-4000-8000-000000000011',
  '0e500000-0000-4000-8000-000000000011',
  '0e100000-0000-4000-8000-000000000011',
  '0e200000-0000-4000-8000-000000000011',
  '0e300000-0000-4000-8000-000000000011',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0e400000-0000-4000-8000-000000000011',
  320.00, 'NGN', 2, 0.05,
  'in_transit',
  now() + interval '10 minutes',
  now() - interval '5 minutes',
  now() - interval '3 minutes',
  'red', 'circle'
);

insert into driver_presence (
  driver_id, vehicle_id, session_id, status, current_location, nearest_stage_id, seats_available, last_ping_at
) values (
  '0e200000-0000-4000-8000-000000000011',
  '0e300000-0000-4000-8000-000000000011',
  '0e310000-0000-4000-8000-000000000011',
  'roaming_available',
  st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  '0a040000-0000-4000-8000-000000000001',
  2,
  now()
) on conflict (driver_id) do update set
  current_location = excluded.current_location,
  last_ping_at = excluded.last_ping_at;

update app_config
set value = '"https://along.ng"'
where key = 'public.origin' and scope_type = 'global' and scope_id = '*';


insert into storage.objects (bucket_id, name, owner) values
  ('incidents', '0e100000-0000-4000-8000-000000000011/a.jpg', '0e100000-0000-4000-8000-000000000011'),
  ('incidents', '0e100000-0000-4000-8000-000000000011/b.jpg', '0e100000-0000-4000-8000-000000000011'),
  ('incidents', '0e100000-0000-4000-8000-000000000011/loose.jpg', '0e100000-0000-4000-8000-000000000011');

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000011', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

-- Guardian share: plate hidden on request, rider-chosen expiry
select set_config('test.s3_share',
  create_trip_share('0e500000-0000-4000-8000-000000000011', 'Ada', '+2348000000001', false, 30)::text, true);
select set_config('test.s3_token',
  regexp_replace(current_setting('test.s3_share')::jsonb->>'url', '^.*/s/', ''), true);

select ok(
  (current_setting('test.s3_share')::jsonb->>'share_plate')::boolean = false,
  'TS-SOS-03: create_trip_share echoes share_plate=false'
);
select ok(
  (current_setting('test.s3_share')::jsonb->>'expires_at')::timestamptz
    between now() + interval '29 minutes' and now() + interval '31 minutes',
  'TS-SOS-03: rider-chosen 30 min expiry is honoured'
);
select is(
  shared_trip_view(current_setting('test.s3_token'))->'vehicle'->>'plate', '',
  'TS-SOS-03: plate hidden when share_plate=false'
);
select is(
  shared_trip_view(current_setting('test.s3_token'))->'vehicle'->>'color', 'blue',
  'TS-SOS-03: colour still visible so the contact can spot the car'
);
select is(
  shared_trip_view(
    regexp_replace(create_trip_share('0e500000-0000-4000-8000-000000000011')->>'url', '^.*/s/', '')
  )->'vehicle'->>'plate', 'SHR-01',
  'TS-SOS-03: default share keeps the plate'
);
select throws_ok(
  $$ select create_trip_share('0e500000-0000-4000-8000-000000000011', null, null, true, 5) $$,
  'P0001', 'ttl out of range',
  'TS-SOS-03: expiry under 15 min rejected'
);
select throws_ok(
  $$ select create_trip_share('0e500000-0000-4000-8000-000000000011', null, null, true, 100000) $$,
  'P0001', 'ttl out of range',
  'TS-SOS-03: expiry over the city cap rejected'
);

-- Incident evidence
select set_config('test.s3_inc', report_incident(
  '0e600000-0000-4000-8000-000000000011', 'safety', 'driver took a strange road',
  array['incidents/0e100000-0000-4000-8000-000000000011/a.jpg',
        'incidents/0e100000-0000-4000-8000-000000000011/b.jpg'],
  '0e700000-0000-4000-8000-000000000011')::text, true);

select ok(
  (current_setting('test.s3_inc')::jsonb->>'replayed')::boolean = false,
  'TS-SOS-03: report with two uploaded photos accepted'
);
select is(
  report_incident('0e600000-0000-4000-8000-000000000011', 'safety', 'driver took a strange road',
    array['incidents/0e100000-0000-4000-8000-000000000011/a.jpg'],
    '0e700000-0000-4000-8000-000000000011')->>'incident_id',
  current_setting('test.s3_inc')::jsonb->>'incident_id',
  'TS-SOS-03: queue replay with same client_ref returns the same incident'
);
select is(
  (select count(*)::int from incidents where reported_by = '0e100000-0000-4000-8000-000000000011'),
  1,
  'TS-SOS-03: replay does not duplicate the incident'
);
select throws_ok(
  $$ select report_incident(null, 'safety', null,
       array['incidents/0e100000-0000-4000-8000-000000000011/missing.jpg']) $$,
  'P0001', 'photo not uploaded',
  'TS-SOS-03: path with no uploaded object rejected'
);
select throws_ok(
  $$ select report_incident(null, 'safety', null,
       array['incidents/0e100000-0000-4000-8000-000000000011/../x/a.jpg']) $$,
  'P0001', 'invalid attachment path',
  'TS-SOS-03: path traversal rejected'
);
select throws_ok(
  $$ select report_incident(null, 'safety', null, array[
       'incidents/0e100000-0000-4000-8000-000000000011/a.jpg',
       'incidents/0e100000-0000-4000-8000-000000000011/a.jpg',
       'incidents/0e100000-0000-4000-8000-000000000011/a.jpg',
       'incidents/0e100000-0000-4000-8000-000000000011/a.jpg',
       'incidents/0e100000-0000-4000-8000-000000000011/a.jpg']) $$,
  'P0001', 'too many photos',
  'TS-SOS-03: more than 4 photos rejected'
);

reset role;
select is(
  (select array_agg(p.policyname::text order by p.policyname)
   from pg_policies p
   where p.schemaname = 'storage' and p.tablename = 'objects'
     and p.policyname = 'incidents_objects_delete_own_unattached'),
  array['incidents_objects_delete_own_unattached'],
  'TS-SOS-03: reporter may discard only unattached photos (delete policy present)'
);

select * from finish();
rollback;
