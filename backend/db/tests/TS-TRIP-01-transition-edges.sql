-- Contract for trip_transition (migration 53) and the Dart mirror
-- shared/flutter/along_data/lib/src/trips/trip_transition.dart.
-- Run with the database tests when Postgres is available.
--
-- Legal edges (actor must be that party; accepted requires a matchable driver):
--   requested -> accepted            driver
--   requested -> declined            driver
--   requested -> expired             system
--   requested -> cancelled_by_rider  rider
--   accepted  -> cancelled_by_rider  rider
--   accepted  -> cancelled_by_driver driver
--   accepted  -> no_show             driver
--   accepted  -> released_before_arrival driver
--   accepted  -> boarded             system | rider | driver
--   boarded   -> in_transit          system | driver
--   boarded   -> cancelled_by_driver driver
--   boarded   -> cancelled_by_rider  rider
--   in_transit -> completed          driver
--   in_transit -> cancelled_by_driver driver
--   in_transit -> cancelled_by_rider rider
--
-- Every other pair, including a repeated status, raises STATE_INVALID.

create extension if not exists pgtap;

begin;
select plan(28);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0e100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007001'),
  ('0e200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007002')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e100000-0000-4000-8000-000000000001', '+2348000007001', 'Legal Rider'),
  ('0e200000-0000-4000-8000-000000000001', '+2348000007002', 'Legal Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0e100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0e200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'EDGTRP01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0e300000-0000-4000-8000-000000000001', 'NG', 'car', 'EDG-01', 4, '0e200000-0000-4000-8000-000000000001')
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
  'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0e500000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'planning',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0e600000-0000-4000-8000-000000000001","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0e700000-0000-4000-8000-000000000001',
  '0e500000-0000-4000-8000-000000000001',
  '0e100000-0000-4000-8000-000000000001',
  '0e200000-0000-4000-8000-000000000001',
  '0e300000-0000-4000-8000-000000000001',
  'car',
  '0e400000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.05,
  'requested',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0e700000-0000-4000-8000-000000000001', null, 'requested', 'rider', '0e100000-0000-4000-8000-000000000001');


-- Puts the fixture trip in p_from, attempts one edge, then rolls the attempt
-- back by raising, so every edge starts from the same row. Returns EDGE_OK when
-- trip_transition accepted the edge, otherwise the error message it raised.
create function pg_temp.try_edge(p_from trip_status, p_to trip_status, p_actor actor_type)
returns text
language plpgsql
as $$
declare
  v_trip constant uuid := '0e700000-0000-4000-8000-000000000001';
  v_actor_id uuid := case p_actor
    when 'rider' then '0e100000-0000-4000-8000-000000000001'::uuid
    when 'driver' then '0e200000-0000-4000-8000-000000000001'::uuid
    else null end;
begin
  begin
    perform set_config('along.in_transition', 'on', true);
    update trips set status = p_from where id = v_trip;
    perform set_config('along.in_transition', '', true);
    perform trip_transition(v_trip, p_to, p_actor, v_actor_id);
    raise exception 'EDGE_OK';
  exception when others then
    perform set_config('along.in_transition', '', true);
    return sqlerrm;
  end;
end;
$$;

select is(pg_temp.try_edge('requested', 'accepted', 'driver'), 'EDGE_OK', 'legal: requested -> accepted by driver');
select is(pg_temp.try_edge('requested', 'declined', 'driver'), 'EDGE_OK', 'legal: requested -> declined by driver');
select is(pg_temp.try_edge('requested', 'expired', 'system'), 'EDGE_OK', 'legal: requested -> expired by system');
select is(pg_temp.try_edge('requested', 'cancelled_by_rider', 'rider'), 'EDGE_OK', 'legal: requested -> cancelled_by_rider by rider');
select is(pg_temp.try_edge('accepted', 'cancelled_by_rider', 'rider'), 'EDGE_OK', 'legal: accepted -> cancelled_by_rider by rider');
select is(pg_temp.try_edge('accepted', 'cancelled_by_driver', 'driver'), 'EDGE_OK', 'legal: accepted -> cancelled_by_driver by driver');
select is(pg_temp.try_edge('accepted', 'no_show', 'driver'), 'EDGE_OK', 'legal: accepted -> no_show by driver');
select is(pg_temp.try_edge('accepted', 'released_before_arrival', 'driver'), 'EDGE_OK', 'legal: accepted -> released_before_arrival by driver');
select is(pg_temp.try_edge('accepted', 'boarded', 'system'), 'EDGE_OK', 'legal: accepted -> boarded by system');
select is(pg_temp.try_edge('accepted', 'boarded', 'rider'), 'EDGE_OK', 'legal: accepted -> boarded by rider');
select is(pg_temp.try_edge('accepted', 'boarded', 'driver'), 'EDGE_OK', 'legal: accepted -> boarded by driver');
select is(pg_temp.try_edge('boarded', 'in_transit', 'system'), 'EDGE_OK', 'legal: boarded -> in_transit by system');
select is(pg_temp.try_edge('boarded', 'in_transit', 'driver'), 'EDGE_OK', 'legal: boarded -> in_transit by driver');
select is(pg_temp.try_edge('boarded', 'cancelled_by_driver', 'driver'), 'EDGE_OK', 'legal: boarded -> cancelled_by_driver by driver');
select is(pg_temp.try_edge('boarded', 'cancelled_by_rider', 'rider'), 'EDGE_OK', 'legal: boarded -> cancelled_by_rider by rider');
select is(pg_temp.try_edge('in_transit', 'completed', 'driver'), 'EDGE_OK', 'legal: in_transit -> completed by driver');
select is(pg_temp.try_edge('in_transit', 'cancelled_by_driver', 'driver'), 'EDGE_OK', 'legal: in_transit -> cancelled_by_driver by driver');
select is(pg_temp.try_edge('in_transit', 'cancelled_by_rider', 'rider'), 'EDGE_OK', 'legal: in_transit -> cancelled_by_rider by rider');
select is(pg_temp.try_edge('requested', 'boarded', 'driver'), 'STATE_INVALID', 'illegal: requested -> boarded by driver');
select is(pg_temp.try_edge('requested', 'completed', 'driver'), 'STATE_INVALID', 'illegal: requested -> completed by driver');
select is(pg_temp.try_edge('requested', 'accepted', 'rider'), 'STATE_INVALID', 'illegal: requested -> accepted by rider');
select is(pg_temp.try_edge('accepted', 'accepted', 'driver'), 'STATE_INVALID', 'illegal: accepted -> accepted by driver');
select is(pg_temp.try_edge('accepted', 'completed', 'driver'), 'STATE_INVALID', 'illegal: accepted -> completed by driver');
select is(pg_temp.try_edge('boarded', 'accepted', 'driver'), 'STATE_INVALID', 'illegal: boarded -> accepted by driver');
select is(pg_temp.try_edge('in_transit', 'boarded', 'driver'), 'STATE_INVALID', 'illegal: in_transit -> boarded by driver');
select is(pg_temp.try_edge('in_transit', 'completed', 'rider'), 'STATE_INVALID', 'illegal: in_transit -> completed by rider');
select is(pg_temp.try_edge('completed', 'cancelled_by_rider', 'rider'), 'STATE_INVALID', 'illegal: completed -> cancelled_by_rider by rider');
select is(pg_temp.try_edge('declined', 'accepted', 'driver'), 'STATE_INVALID', 'illegal: declined -> accepted by driver');

select * from finish();
rollback;
