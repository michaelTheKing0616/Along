-- pgTAP: TS-SOS-01 — incidents RLS restricted to reporter + safety roles (P5-A-01 gate)
create extension if not exists pgtap;

begin;
select plan(9);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006101'),
  ('0e100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000006102'),
  ('0e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006103'),
  ('0e900000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009101'),
  ('0e900000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000009102'),
  ('0e900000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000009103')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000001', '+2348000006101', 'SOS Rider A'),
  ('0e100000-0000-4000-8000-000000000002', '+2348000006102', 'SOS Rider B'),
  ('0e200000-0000-4000-8000-000000000001', '+2348000006103', 'SOS Driver A'),
  ('0e900000-0000-4000-8000-000000000001', '+2348000009101', 'Safety Admin'),
  ('0e900000-0000-4000-8000-000000000002', '+2348000009102', 'Ops Agent'),
  ('0e900000-0000-4000-8000-000000000003', '+2348000009103', 'Finance Admin')
on conflict (id) do update set display_name = excluded.display_name;

insert into admin_users (id, role, deployment_id) values
  ('0e900000-0000-4000-8000-000000000001', 'safety', 'a0000000-0000-4000-8000-000000000001'),
  ('0e900000-0000-4000-8000-000000000002', 'ops_agent', 'a0000000-0000-4000-8000-000000000001'),
  ('0e900000-0000-4000-8000-000000000003', 'finance', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001'),
  ('0e100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'SOSDR1', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0e300000-0000-4000-8000-000000000001', 'NG', 'car', 'SOS-01', 4, '0e200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0e200000-0000-4000-8000-000000000001', '0e300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0e400000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0e500000-0000-4000-8000-000000000001', '0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'active', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb)
on conflict (id) do nothing;

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0e600000-0000-4000-8000-000000000001',
  '0e500000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0e300000-0000-4000-8000-000000000001',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0e400000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'in_transit',
  now() + interval '10 minutes',
  now() - interval '5 minutes',
  'red', 'circle'
) on conflict (id) do nothing;

insert into storage.objects (bucket_id, name, owner)
values ('incidents', '0e100000-0000-4000-8000-000000000001/test.jpg', '0e100000-0000-4000-8000-000000000001');

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (report_incident(
    '0e600000-0000-4000-8000-000000000001',
    'safety',
    'felt unsafe during trip',
    array['incidents/0e100000-0000-4000-8000-000000000001/test.jpg']
  )->>'incident_id') is not null,
  'TS-SOS-01: reporter can create incident via RPC'
);

select is(
  (select count(*)::int from incidents where reported_by = '0e100000-0000-4000-8000-000000000001'),
  1,
  'TS-SOS-01: reporter sees own incident via RLS'
);

select set_config('request.jwt.claim.sub', '0e900000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  (select count(*)::int from incidents),
  1,
  'TS-SOS-01: safety admin sees incidents in scope'
);

select set_config('request.jwt.claim.sub', '0e900000-0000-4000-8000-000000000002', true);
set local role authenticated;

select is(
  (select count(*)::int from incidents),
  1,
  'TS-SOS-01: ops_agent admin sees incidents in scope'
);

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000002', true);
set local role authenticated;

select is(
  (select count(*)::int from incidents),
  0,
  'TS-SOS-01: non-reporter rider cannot select others incidents'
);

select set_config('request.jwt.claim.sub', '0e900000-0000-4000-8000-000000000003', true);
set local role authenticated;

select is(
  (select count(*)::int from incidents),
  0,
  'TS-SOS-01: finance admin cannot select incidents'
);

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  $$ insert into incidents (trip_id, type, reported_by, reported_role, description)
     values ('0e600000-0000-4000-8000-000000000001', 'other', auth.uid(), 'rider', 'direct write') $$,
  '42501',
  null,
  'TS-SOS-01: direct client INSERT on incidents blocked by RLS'
);

select ok(
  octet_length(
    raise_sos(
      '0e600000-0000-4000-8000-000000000001',
      null,
      jsonb_build_object('lat', 11.061, 'lng', 7.701),
      12.5
    )::text
  ) <= 300,
  'TS-SOS-01: raise_sos response payload <= 300 B'
);

select ok(
  octet_length(
    jsonb_build_object(
      'p_trip_id', '0e600000-0000-4000-8000-000000000001',
      'p_location', jsonb_build_object('lat', 11.061, 'lng', 7.701),
      'p_accuracy_m', 12.5
    )::text
  ) <= 300,
  'TS-SOS-01: typical raise_sos request payload <= 300 B'
);

select * from finish();
rollback;
