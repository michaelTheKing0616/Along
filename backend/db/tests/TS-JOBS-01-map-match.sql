-- pgTAP: TS-JOBS-01 — map-match tables + FM27 guard (P7-A-02)
create extension if not exists pgtap;

begin;
select plan(7);

select ok(
  to_regclass('public.job_runs') is not null,
  'job_runs table exists'
);

select ok(
  to_regclass('public.matched_traces') is not null,
  'matched_traces table exists'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.job_runs'::regclass),
  'job_runs has RLS enabled'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.matched_traces'::regclass),
  'matched_traces has RLS enabled'
);

select is(
  cfg_num('jobs.map_match_min_samples'),
  10::numeric,
  'jobs.map_match_min_samples default is 10'
);

select is(
  cfg_num('jobs.map_match_min_confidence'),
  0.6::numeric,
  'jobs.map_match_min_confidence default is 0.6'
);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007301'),
  ('0f310000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007302')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f300000-0000-4000-8000-000000000001', '+2348000007301', 'FM27 Rider'),
  ('0f310000-0000-4000-8000-000000000001', '+2348000007302', 'FM27 Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f300000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f310000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'FM2701', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0f320000-0000-4000-8000-000000000001',
  '0f300000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'completed',
  st_setsrid(st_makepoint(7.40, 9.00), 4326)::geography,
  st_setsrid(st_makepoint(7.42, 9.02), 4326)::geography,
  '{"legs":[]}'::jsonb
) on conflict (id) do nothing;

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f330000-0000-4000-8000-000000000001',
  '0f300000-0000-4000-8000-000000000001',
  '0f310000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 500.00, 'NGN', '[]'::jsonb, 0.900, now() + interval '10 minutes'
) on conflict (id) do nothing;

insert into trips (
  id, journey_id, journey_sequence, rider_id, driver_id, mode_code, route_id,
  boarding_stage_id, alighting_stage_id,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  id_signal_color, id_signal_shape, status, ended_at
) values (
  '0f340000-0000-4000-8000-000000000001',
  '0f320000-0000-4000-8000-000000000001',
  1,
  '0f300000-0000-4000-8000-000000000001',
  '0f310000-0000-4000-8000-000000000001',
  'car',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  '0f330000-0000-4000-8000-000000000001',
  500.00,
  'NGN',
  2,
  0.075,
  'green',
  'diamond',
  'completed',
  now()
) on conflict (id) do nothing;

insert into trip_location_samples (trip_id, actor_type, ts, location, accuracy_m)
select
  '0f340000-0000-4000-8000-000000000001',
  'driver',
  now() - make_interval(secs => (12 - g.i) * 5),
  st_setsrid(st_makepoint(7.40 + g.i * 0.001, 9.00 + g.i * 0.001), 4326)::geography,
  20
from generate_series(1, 12) as g(i);

select is(
  private.propose_from_traces(
    '0f340000-0000-4000-8000-000000000001'::uuid,
    'driver'::actor_type
  ),
  '[]'::jsonb,
  'FM27: raw trip with samples but no matched_traces yields zero proposals'
);

select * from finish();
rollback;
