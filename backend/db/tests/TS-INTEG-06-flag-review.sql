-- pgTAP: TS-INTEG-06 — flag review clear/action requires standing transition id (P4-D-01)
create extension if not exists pgtap;

begin;
select plan(6);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0d900000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009101'),
  ('0d900000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000009102'),
  ('0d100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008101'),
  ('0d200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000008105')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0d900000-0000-4000-8000-000000000001', '+2348000009101', 'Safety Reviewer'),
  ('0d900000-0000-4000-8000-000000000002', '+2348000009102', 'Ops Lead'),
  ('0d100000-0000-4000-8000-000000000001', '+2348000008101', 'Integr Rider 1'),
  ('0d200000-0000-4000-8000-000000000001', '+2348000008105', 'Integr Driver 1')
on conflict (id) do update set display_name = excluded.display_name;

insert into admin_users (id, role, deployment_id) values
  ('0d900000-0000-4000-8000-000000000001', 'safety', 'a0000000-0000-4000-8000-000000000001'),
  ('0d900000-0000-4000-8000-000000000002', 'ops_lead', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role;

insert into riders (id, home_city_id) values
  ('0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0d200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'matching_paused', 'INTDR01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set standing = excluded.standing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0d300000-0000-4000-8000-000000000001', 'NG', 'car', 'INT-01', 4, '0d200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0d200000-0000-4000-8000-000000000001', '0d300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0d400000-0000-4000-8000-000000000099',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot) values
  ('0d500000-0000-4000-8000-000000000099', '0d100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'abandoned', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '{}'::jsonb)
on conflict (id) do nothing;

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, accepted_at, boarded_at, started_at, cancelled_at,
  id_signal_color, id_signal_shape
) values (
  '0d700000-0000-4000-8000-000000000099',
  '0d500000-0000-4000-8000-000000000099',
  '0d100000-0000-4000-8000-000000000001',
  '0d200000-0000-4000-8000-000000000001',
  '0d300000-0000-4000-8000-000000000001',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0d400000-0000-4000-8000-000000000099',
  320.00, 'NGN', 2, 0.05,
  'cancelled_by_driver',
  now() + interval '25 seconds',
  now() - interval '20 minutes',
  now() - interval '18 minutes',
  now() - interval '15 minutes',
  now() - interval '5 minutes',
  'color.naMe.green', 'diamond'
) on conflict (id) do nothing;

insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id)
values ('0d700000-0000-4000-8000-000000000099', 'in_transit', 'cancelled_by_driver', 'driver', '0d200000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into trip_reconciliation_flags (
  id, trip_id, driver_id, flag_type, score, evidence, rider_trace_quality, corroborating_rider_count, status
) values (
  '0d800000-0000-4000-8000-000000000099',
  '0d700000-0000-4000-8000-000000000099',
  '0d200000-0000-4000-8000-000000000001',
  'premature_conversion',
  0.8500,
  '{"driver_trace":{"quality":"good","reached_dest_m":45},"rider_trace":{"quality":"good"}}'::jsonb,
  'good',
  1,
  'open'
) on conflict (trip_id, flag_type) do update
  set status = 'open', standing_transition_id = null, reviewed_by = null, reviewed_at = null;

insert into trip_reconciliation_flags (
  id, trip_id, driver_id, flag_type, score, evidence, rider_trace_quality, status
) values (
  '0d800000-0000-4000-8000-000000000098',
  '0d700000-0000-4000-8000-000000000099',
  '0d200000-0000-4000-8000-000000000001',
  'route_deviation',
  0.7000,
  '{"note":"action path test"}'::jsonb,
  'partial',
  'open'
) on conflict (trip_id, flag_type) do update
  set status = 'open', standing_transition_id = null, reviewed_by = null, reviewed_at = null;

select set_config('request.jwt.claim.sub', '0d900000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  admin_review_flag('0d800000-0000-4000-8000-000000000099', 'clear', 'False positive')::jsonb->>'status',
  'cleared',
  'TS-INTEG-06: clear updates status'
);

set local role postgres;

select is(
  (select status::text from trip_reconciliation_flags where id = '0d800000-0000-4000-8000-000000000099'),
  'cleared',
  'TS-INTEG-06: clear persisted on flag row'
);

select set_config('request.jwt.claim.sub', '0d900000-0000-4000-8000-000000000001', true);
set local role authenticated;

select throws_ok(
  $$ select admin_review_flag('0d800000-0000-4000-8000-000000000098', 'action', 'Integrity action') $$,
  'P0001',
  'standing transition id is required for action',
  'TS-INTEG-06: action without transition id rejected'
);

select set_config('request.jwt.claim.sub', '0d900000-0000-4000-8000-000000000002', true);
set local role authenticated;

select set_config(
  'test.transition',
  admin_transition_standing(
    '0d200000-0000-4000-8000-000000000001',
    'guarantor_referred',
    'Integrity review — route deviation pattern'
  )::text,
  true
);

select set_config('request.jwt.claim.sub', '0d900000-0000-4000-8000-000000000001', true);

select is(
  admin_review_flag(
    '0d800000-0000-4000-8000-000000000098',
    'action',
    'Standing applied',
    (current_setting('test.transition')::jsonb->>'transition_id')::bigint
  )::jsonb->>'status',
  'actioned',
  'TS-INTEG-06: action with transition id sets actioned'
);

set local role postgres;

select is(
  (select status::text from trip_reconciliation_flags where id = '0d800000-0000-4000-8000-000000000098'),
  'actioned',
  'TS-INTEG-06: actioned status persisted with transition link'
);

select ok(
  (select standing_transition_id is not null
   from trip_reconciliation_flags
   where id = '0d800000-0000-4000-8000-000000000098'),
  'TS-INTEG-06: standing_transition_id stored on actioned flag'
);

select * from finish();
rollback;
