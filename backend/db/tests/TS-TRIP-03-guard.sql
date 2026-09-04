-- pgTAP: P1-A-01 — append-only tables, TS-TRIP-03 status guard, ensure_partitions
create extension if not exists pgtap;

begin;
select plan(11);

insert into deployments (id, tenant_name)
values ('a1000000-0000-4000-8000-000000000001', 'Trip Guard Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('TG', 'Trip Guard Country', 'NGN', E'₦', '+996', 'UTC', 'a1000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'a1000000-0000-4000-8000-000000000002',
  'TG',
  'Trip Guard City',
  'trip-guard-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into auth.users (id, aud, role, phone) values
  ('a1000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000000100'),
  ('a1000000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000000101'),
  ('a1000000-0000-4000-8000-000000000099', 'authenticated', 'authenticated', '+2348000000199');

insert into riders (id) values ('a1000000-0000-4000-8000-000000000010');
insert into drivers (id, city_id) values ('a1000000-0000-4000-8000-000000000011', 'a1000000-0000-4000-8000-000000000002');

insert into admin_users (id, role, deployment_id)
values ('a1000000-0000-4000-8000-000000000099', 'superadmin', 'a1000000-0000-4000-8000-000000000001');

insert into fare_quotes (
  id, mode_code, tier, amount, currency, components, confidence
) values (
  'a1000000-0000-4000-8000-000000000020',
  'car',
  2,
  500.00,
  'NGN',
  '[{"kind":"leg","amount":500}]'::jsonb,
  0.900
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  'a1000000-0000-4000-8000-000000000030',
  'a1000000-0000-4000-8000-000000000010',
  'a1000000-0000-4000-8000-000000000002',
  'planning',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  st_setsrid(st_makepoint(7.50, 9.15), 4326)::geography,
  '{"kind":"direct"}'::jsonb
);

insert into trips (
  id,
  journey_id,
  rider_id,
  driver_id,
  mode_code,
  fare_quote_id,
  fare_shown,
  fare_currency,
  fare_tier,
  commission_rate,
  expires_at,
  id_signal_color,
  id_signal_shape
) values (
  'a1000000-0000-4000-8000-000000000040',
  'a1000000-0000-4000-8000-000000000030',
  'a1000000-0000-4000-8000-000000000010',
  'a1000000-0000-4000-8000-000000000011',
  'car',
  'a1000000-0000-4000-8000-000000000020',
  500.00,
  'NGN',
  2,
  0.0750,
  now() + interval '25 seconds',
  'color.naMe.green',
  'circle'
);

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values (
  'a1000000-0000-4000-8000-000000000040',
  null,
  'requested',
  'system',
  null
);

insert into price_negotiations (
  id,
  rider_id,
  driver_id,
  context,
  candidate_ref,
  anchor_amount,
  currency,
  round_cap,
  round_timeout_s,
  expires_at
) values (
  'a1000000-0000-4000-8000-000000000050',
  'a1000000-0000-4000-8000-000000000010',
  'a1000000-0000-4000-8000-000000000011',
  'park',
  '{"route_id":"00000000-0000-0000-0000-000000000001"}'::jsonb,
  500.00,
  'NGN',
  4,
  20,
  now() + interval '5 minutes'
);

insert into price_negotiation_rounds (negotiation_id, round_number, proposed_by, amount)
values ('a1000000-0000-4000-8000-000000000050', 1, 'rider', 450.00);

insert into trip_extensions (
  trip_id,
  proposed_by,
  fare_delta,
  currency,
  expires_at
) values (
  'a1000000-0000-4000-8000-000000000040',
  'rider',
  150.00,
  'NGN',
  now() + interval '10 minutes'
);

-- TS-TRIP-03: direct status write rejected even as superadmin
select throws_ok(
  $$ update trips set status = 'accepted' where id = 'a1000000-0000-4000-8000-000000000040'::uuid $$,
  '42501',
  null,
  'TS-TRIP-03: direct trips.status update rejected by guard trigger'
);

select set_config('request.jwt.claim.sub', 'a1000000-0000-4000-8000-000000000099', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select throws_ok(
  $$ update trips set status = 'accepted' where id = 'a1000000-0000-4000-8000-000000000040'::uuid $$,
  '42501',
  null,
  'TS-TRIP-03: direct trips.status update rejected for superadmin JWT role too'
);

reset role;

-- Allowed path: along.in_transition=on permits status change
select set_config('along.in_transition', 'on', true);
update trips set status = 'accepted' where id = 'a1000000-0000-4000-8000-000000000040'::uuid;
select set_config('along.in_transition', '', true);

select is(
  (select status::text from trips where id = 'a1000000-0000-4000-8000-000000000040'::uuid),
  'accepted',
  'trips.status update allowed when along.in_transition=on'
);

-- Append-only: trip_events
select throws_ok(
  $$ update trip_events set reason = 'tampered' where trip_id = 'a1000000-0000-4000-8000-000000000040'::uuid $$,
  '42501',
  null,
  'trip_events rejects update (append-only)'
);

select throws_ok(
  $$ delete from trip_events where trip_id = 'a1000000-0000-4000-8000-000000000040'::uuid $$,
  '42501',
  null,
  'trip_events rejects delete (append-only)'
);

-- Append-only: price_negotiation_rounds
select throws_ok(
  $$ update price_negotiation_rounds set amount = 1 where negotiation_id = 'a1000000-0000-4000-8000-000000000050'::uuid $$,
  '42501',
  null,
  'price_negotiation_rounds rejects update (append-only)'
);

select throws_ok(
  $$ delete from price_negotiation_rounds where negotiation_id = 'a1000000-0000-4000-8000-000000000050'::uuid $$,
  '42501',
  null,
  'price_negotiation_rounds rejects delete (append-only)'
);

-- Append-only: trip_extensions delete; update blocked outside RPC
select throws_ok(
  $$ delete from trip_extensions where trip_id = 'a1000000-0000-4000-8000-000000000040'::uuid $$,
  '42501',
  null,
  'trip_extensions rejects delete (append-only)'
);

select throws_ok(
  $$ update trip_extensions set status = 'accepted' where trip_id = 'a1000000-0000-4000-8000-000000000040'::uuid $$,
  '42501',
  null,
  'trip_extensions rejects update outside RPC'
);

-- Partitions created for current month + next two months
select ok(
  (
    select count(*) >= 3
    from pg_class c
    join pg_inherits i on i.inhrelid = c.oid
    join pg_class p on p.oid = i.inhparent
    where p.relname = 'driver_presence_history'
  ),
  'driver_presence_history has at least 3 monthly partitions'
);

select ok(
  (
    select count(*) >= 3
    from pg_class c
    join pg_inherits i on i.inhrelid = c.oid
    join pg_class p on p.oid = i.inhparent
    where p.relname = 'trip_location_samples'
  ),
  'trip_location_samples has at least 3 monthly partitions'
);

select * from finish();
rollback;
