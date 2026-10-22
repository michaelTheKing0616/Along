-- pgTAP: emergency contacts are owner-only, and a non-owner cannot raise SOS.
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006101'),
  ('0e100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000006102'),
  ('0e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006103')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000001', '+2348000006101', 'SOS Rider A'),
  ('0e100000-0000-4000-8000-000000000002', '+2348000006102', 'SOS Rider B'),
  ('0e200000-0000-4000-8000-000000000001', '+2348000006103', 'SOS Driver A')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001'),
  ('0e100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'SOSDR1', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0e300000-0000-4000-8000-000000000001', 'NG', 'car', 'SOS-03', 4, '0e200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0e200000-0000-4000-8000-000000000001', '0e300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0e400000-0000-4000-8000-000000000099',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0e500000-0000-4000-8000-000000000099', '0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'active', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb)
on conflict (id) do nothing;

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, id_signal_color, id_signal_shape
) values (
  '0e600000-0000-4000-8000-000000000099',
  '0e500000-0000-4000-8000-000000000099',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0e300000-0000-4000-8000-000000000001',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0e400000-0000-4000-8000-000000000099',
  320.00, 'NGN', 2, 0.05,
  'in_transit',
  now() + interval '10 minutes',
  now() - interval '5 minutes',
  'red', 'circle'
) on conflict (id) do nothing;

insert into emergency_contacts (id, profile_id, display_name, phone_e164) values
  ('0e800000-0000-4000-8000-000000000001', '0e100000-0000-4000-8000-000000000001', 'Ada', '+2348011111111');

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from emergency_contacts),
  0,
  'TS-SOS-03: non-owner cannot read emergency contacts'
);

select throws_ok(
  $$ insert into emergency_contacts (profile_id, display_name, phone_e164)
     values ('0e100000-0000-4000-8000-000000000001', 'Stolen', '+2348033333333') $$,
  '42501',
  null,
  'TS-SOS-03: cannot insert a contact for another profile'
);

select throws_ok(
  $$ select delete_emergency_contact('0e800000-0000-4000-8000-000000000001') $$,
  'P0001',
  'FORBIDDEN',
  'TS-SOS-03: non-owner cannot delete an emergency contact'
);

select throws_ok(
  $$ select raise_sos(
       '0e600000-0000-4000-8000-000000000099',
       null,
       jsonb_build_object('lat', 11.061, 'lng', 7.701),
       12
     ) $$,
  'P0001',
  'FORBIDDEN',
  'TS-SOS-03: non-owner cannot raise SOS on someone else''s trip'
);

select set_config('request.jwt.claim.sub', '0e100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  (list_emergency_contacts() -> 0 ->> 'phone_e164'),
  '+2348011111111',
  'TS-SOS-03: owner lists their own emergency contact'
);

select * from finish();
rollback;
