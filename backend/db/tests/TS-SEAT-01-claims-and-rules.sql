-- pgTAP: seat claims are compare-and-set, and ride rules are driver data.
create extension if not exists pgtap;

begin;
select plan(18);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select is(
  (private.seat_layout_stats((select layout_preset from mode_config where code = 'along'))->>'passenger_seats')::int,
  6,
  'TS-SEAT-01: along car preset has 6 passenger seats'
);

select is(
  (select review_seat_max::int from mode_config where code = 'car'),
  4,
  'TS-SEAT-01: car review cap stays 4'
);

select is(
  (select count(*)::int from ride_rule_presets),
  6, -- four from 0084 plus two day-rule presets from 0085
  'TS-SEAT-01: rule presets are seeded data'
);

insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007101'),
  ('0f100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000007102'),
  ('0f100000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000007103'),
  ('0f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007104')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000001', '+2348000007101', 'Seat Rider A'),
  ('0f100000-0000-4000-8000-000000000002', '+2348000007102', 'Seat Rider B'),
  ('0f100000-0000-4000-8000-000000000003', '+2348000007103', 'Seat Stranger'),
  ('0f200000-0000-4000-8000-000000000001', '+2348000007104', 'Seat Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'SEATD1', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f300000-0000-4000-8000-000000000001', 'NG', 'car', 'SEAT-01', 4, '0f200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000001', '0f300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ select save_vehicle_layout(
       '0f300000-0000-4000-8000-000000000001',
       'stolen',
       '{"version":1,"body":"cabin","rows":[{"id":"front","seats":[{"id":"fp","role":"passenger","label":"Front"},{"id":"drv","role":"driver","label":"Driver"}]}]}'::jsonb,
       true
     ) $$,
  'P0001',
  'FORBIDDEN',
  'TS-SEAT-01: a non-owner cannot save a layout'
);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
set local role authenticated;

select set_config(
  'test.layout',
  (
    save_vehicle_layout(
      '0f300000-0000-4000-8000-000000000001',
      'day',
      '{"version":1,"body":"cabin","rows":[{"id":"front","seats":[{"id":"fp","role":"passenger","label":"Front"},{"id":"drv","role":"driver","label":"Driver"}]},{"id":"back","seats":[{"id":"b1","role":"passenger","label":"Back left"},{"id":"b2","role":"passenger","label":"Back middle left"},{"id":"b3","role":"passenger","label":"Back middle right"},{"id":"b4","role":"passenger","label":"Back right"}]}]}'::jsonb,
      true
    )->>'id'
  ),
  true
);

select is(
  (select over_capacity from vehicle_layouts where id = current_setting('test.layout')::uuid),
  true,
  'TS-SEAT-01: over the review cap is saved and flagged'
);

select is(
  (select passenger_seats::int from vehicle_layouts where id = current_setting('test.layout')::uuid),
  5,
  'TS-SEAT-01: the saved layout keeps every passenger seat'
);

select is(
  (select count(*)::int from vehicle_seat_states where layout_id = current_setting('test.layout')::uuid and seat_id = 'drv'),
  0,
  'TS-SEAT-01: the driver seat has no claimable state'
);

select set_config(
  'test.ack',
  (
    save_ride_rule(
      '0f300000-0000-4000-8000-000000000001',
      'women_only_row',
      'Women only in front',
      'Please acknowledge before you sit in front.',
      '{}'::jsonb,
      'front',
      true,
      null
    )->>'id'
  ),
  true
);

select save_ride_rule(
  '0f300000-0000-4000-8000-000000000001',
  'max_front_passengers',
  'One in the back row',
  null,
  '{"max":1}'::jsonb,
  'back',
  true,
  null
);

select save_ride_rule(
  '0f300000-0000-4000-8000-000000000001',
  'seat_hold',
  'Hold',
  'Held seats expire on my timer.',
  '{"duration_minutes":7}'::jsonb,
  null,
  true,
  null
);

select save_ride_rule(
  '0f300000-0000-4000-8000-000000000001',
  null,
  'Quiet cabin',
  'No loud calls',
  '{}'::jsonb,
  null,
  true,
  null
);

select start_driver_day(
  '0f300000-0000-4000-8000-000000000001',
  current_setting('test.layout')::uuid,
  '0a000000-0000-4000-8000-000000000011',
  null
);

select set_seat_status(current_setting('test.layout')::uuid, 'b1', 'occupied');
select set_seat_status(current_setting('test.layout')::uuid, 'b3', 'held');

select ok(
  (
    select hold_until > now() + interval '6 minutes'
       and hold_until < now() + interval '8 minutes'
    from vehicle_seat_states
    where layout_id = current_setting('test.layout')::uuid
      and seat_id = 'b3'
  ),
  'TS-SEAT-01: hold_until uses the driver-set duration'
);

select ok(
  position('Quiet cabin' in seat_board(current_setting('test.layout')::uuid)::text) > 0,
  'TS-SEAT-01: a custom free-text rule is on the board'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  $$ select claim_seat(current_setting('test.layout')::uuid, 'b2', 1, '{}') $$,
  'P0001',
  'RULE_CAP',
  'TS-SEAT-01: a driver cap rejects another seat in that row'
);

select throws_ok(
  $$ select claim_seat(current_setting('test.layout')::uuid, 'fp', 1, '{}') $$,
  'P0001',
  'RULE_ACK',
  'TS-SEAT-01: an acknowledge rule blocks a claim until the rider accepts it'
);

select is(
  (claim_seat(
    current_setting('test.layout')::uuid,
    'fp',
    1,
    array[current_setting('test.ack')::uuid]
  )->>'status'),
  'occupied',
  'TS-SEAT-01: acknowledging the driver rule claims the seat'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000002', true);
set local role authenticated;

select throws_ok(
  $$ select claim_seat(
       current_setting('test.layout')::uuid,
       'fp',
       1,
       array[current_setting('test.ack')::uuid]
     ) $$,
  'P0001',
  'CONFLICT',
  'TS-SEAT-01: a second claim of the same seat is rejected'
);

select throws_ok(
  $$ select claim_seat(current_setting('test.layout')::uuid, 'b4', 99, '{}') $$,
  'P0001',
  'CONFLICT',
  'TS-SEAT-01: a stale version cannot claim a free seat'
);

select is(
  (select count(*)::int from vehicle_seat_states
    where layout_id = current_setting('test.layout')::uuid
      and seat_id = 'fp'
      and status = 'occupied'
      and holder_profile_id = '0f100000-0000-4000-8000-000000000001'),
  1,
  'TS-SEAT-01: the seat stays with the first rider'
);

reset role;

insert into driver_presence (
  driver_id, vehicle_id, status, current_location, seats_available
) values (
  '0f200000-0000-4000-8000-000000000001',
  '0f300000-0000-4000-8000-000000000001',
  'roaming_available',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  3
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000001', true);
set local role authenticated;

select is(
  jsonb_array_length(online_vehicle_cards(
    '0a000000-0000-4000-8000-000000000001',
    array['women_only_row'],
    'quiet'
  )->'cards'),
  1,
  'TS-SEAT-01: riders can filter cards by a preset and the driver''s words'
);

select is(
  jsonb_array_length(online_vehicle_cards(
    '0a000000-0000-4000-8000-000000000001',
    array['front_seat_offered'],
    null
  )->'cards'),
  0,
  'TS-SEAT-01: a preset the driver did not enable hides the card'
);

select set_config('request.jwt.claim.sub', '0f100000-0000-4000-8000-000000000003', true);
set local role authenticated;

select throws_ok(
  $$ select set_seat_status(current_setting('test.layout')::uuid, 'b4', 'occupied') $$,
  'P0001',
  'FORBIDDEN',
  'TS-SEAT-01: a stranger cannot mark seats'
);

select * from finish();
rollback;
