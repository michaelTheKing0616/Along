-- pgTAP: admin safety RPCs (P5-D-01) — role restriction + ack side effects
create extension if not exists pgtap;

begin;
select plan(8);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006101'),
  ('0e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006103'),
  ('0e900000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009101'),
  ('0e900000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000009102'),
  ('0e900000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000009103')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000001', '+2348000006101', 'SOS Rider A'),
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
  ('0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
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

insert into sos_alerts (
  id, trip_id, journey_id, raised_by, raised_role, location, status, created_at
) values (
  '0e700000-0000-4000-8000-000000000001',
  '0e600000-0000-4000-8000-000000000001',
  '0e500000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  'rider',
  st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
  'open',
  now()
) on conflict (id) do nothing;

insert into incidents (
  id, trip_id, type, severity, status, reported_by, reported_role, description
) values (
  '0e800000-0000-4000-8000-000000000001',
  '0e600000-0000-4000-8000-000000000001',
  'safety',
  2,
  'open',
  '0e100000-0000-4000-8000-000000000001',
  'rider',
  'needs triage'
) on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', '0e900000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select admin_ack_sos('0e700000-0000-4000-8000-000000000001') $$,
  'P0001',
  'FORBIDDEN',
  'finance admin cannot admin_ack_sos'
);

select set_config('request.jwt.claim.sub', '0e900000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  admin_ack_sos('0e700000-0000-4000-8000-000000000001')->>'status',
  'acknowledged',
  'safety admin can acknowledge open SOS'
);

select is(
  (select status::text from sos_alerts where id = '0e700000-0000-4000-8000-000000000001'),
  'acknowledged',
  'admin_ack_sos updates sos_alerts row'
);

select is(
  (select acknowledged_by from sos_alerts where id = '0e700000-0000-4000-8000-000000000001'),
  '0e900000-0000-4000-8000-000000000001'::uuid,
  'admin_ack_sos records acknowledging admin'
);

select throws_ok(
  $$ select admin_ack_sos('0e700000-0000-4000-8000-000000000001') $$,
  'P0001',
  'SOS is not open',
  'admin_ack_sos rejects non-open SOS'
);

select is(
  admin_resolve_sos(
    '0e700000-0000-4000-8000-000000000001',
    'resolved',
    'contacted raiser'
  )->>'status',
  'resolved',
  'safety admin can resolve acknowledged SOS'
);

select set_config('request.jwt.claim.sub', '0e900000-0000-4000-8000-000000000002', true);
set local role authenticated;

select is(
  admin_triage_incident(
    '0e800000-0000-4000-8000-000000000001'::uuid,
    'triaged',
    '0e900000-0000-4000-8000-000000000001'::uuid,
    3::smallint
  )->>'status',
  'triaged',
  'ops_agent can triage incident'
);

select is(
  cfg_num('sos.ack_sla_s', '0a000000-0000-4000-8000-000000000001'::uuid),
  60::numeric,
  'sos.ack_sla_s default is 60'
);

select * from finish();
rollback;
