-- pgTAP: TS-EXPORT-01 — k-anonymised OD export (P8-A-02, doc 12 §1 T9, FM39/40)
create extension if not exists pgtap;

begin;
select plan(8);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select is(
  cfg_num('export.k', '0a000000-0000-4000-8000-000000000001')::int,
  10,
  'TS-EXPORT-01: export.k resolves from config defaults'
);

select is(
  cfg_num('export.geohash_precision', '0a000000-0000-4000-8000-000000000001')::int,
  5,
  'TS-EXPORT-01: export.geohash_precision resolves from config defaults'
);

select ok(
  not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'anonymized_od_cells'
      and c.column_name = any (array[
        'rider_id', 'driver_id', 'phone', 'phone_e164', 'plate_number',
        'vehicle_id', 'origin', 'destination', 'boarding_location', 'alighting_location'
      ])
  ),
  'TS-EXPORT-01: anonymized_od_cells exposes no PII columns'
);

insert into auth.users (id, aud, role, phone) values
  ('0a300000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003001'),
  ('0a300000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000003002')
on conflict (id) do nothing;

insert into riders (id, home_city_id) values
  ('0a300000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code) values
  ('0a300000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'EXP001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into fare_quotes (id, mode_code, tier, amount, currency, components, confidence) values
  ('0a310000-0000-4000-8000-000000000001', 'car', 2, 500.00, 'NGN', '[{"kind":"leg","amount":500}]'::jsonb, 0.900)
on conflict (id) do nothing;

create temp table export_fixture_trips (
  seq int primary key,
  journey_id uuid not null,
  trip_id uuid not null,
  origin geography(Point, 4326) not null,
  destination geography(Point, 4326) not null
) on commit drop;

insert into export_fixture_trips (seq, journey_id, trip_id, origin, destination) values
  (1, '0a320000-0000-4000-8000-000000000001', '0a330000-0000-4000-8000-000000000001', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (2, '0a320000-0000-4000-8000-000000000002', '0a330000-0000-4000-8000-000000000002', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (3, '0a320000-0000-4000-8000-000000000003', '0a330000-0000-4000-8000-000000000003', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (4, '0a320000-0000-4000-8000-000000000004', '0a330000-0000-4000-8000-000000000004', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (5, '0a320000-0000-4000-8000-000000000005', '0a330000-0000-4000-8000-000000000005', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (6, '0a320000-0000-4000-8000-000000000006', '0a330000-0000-4000-8000-000000000006', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (7, '0a320000-0000-4000-8000-000000000007', '0a330000-0000-4000-8000-000000000007', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (8, '0a320000-0000-4000-8000-000000000008', '0a330000-0000-4000-8000-000000000008', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (9, '0a320000-0000-4000-8000-000000000009', '0a330000-0000-4000-8000-000000000009', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (10, '0a320000-0000-4000-8000-000000000010', '0a330000-0000-4000-8000-000000000010', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (11, '0a320000-0000-4000-8000-000000000011', '0a330000-0000-4000-8000-000000000011', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (12, '0a320000-0000-4000-8000-000000000012', '0a330000-0000-4000-8000-000000000012', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography),
  (13, '0a320000-0000-4000-8000-000000000013', '0a330000-0000-4000-8000-000000000013', st_setsrid(st_makepoint(7.710, 11.070), 4326)::geography, st_setsrid(st_makepoint(7.715, 11.075), 4326)::geography),
  (14, '0a320000-0000-4000-8000-000000000014', '0a330000-0000-4000-8000-000000000014', st_setsrid(st_makepoint(7.720, 11.080), 4326)::geography, st_setsrid(st_makepoint(7.725, 11.085), 4326)::geography);

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot)
select
  f.journey_id,
  '0a300000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'completed',
  f.origin,
  f.destination,
  '{"kind":"direct"}'::jsonb
from export_fixture_trips f;

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
  status,
  requested_at,
  ended_at,
  expires_at,
  id_signal_color,
  id_signal_shape
)
select
  f.trip_id,
  f.journey_id,
  '0a300000-0000-4000-8000-000000000001',
  '0a300000-0000-4000-8000-000000000002',
  'car',
  '0a310000-0000-4000-8000-000000000001',
  500.00,
  'NGN',
  2,
  0.0750,
  'completed',
  timestamptz '2026-09-01 10:00:00+00' + (f.seq || ' minutes')::interval,
  timestamptz '2026-09-01 10:30:00+00' + (f.seq || ' minutes')::interval,
  timestamptz '2026-09-01 11:00:00+00' + (f.seq || ' minutes')::interval,
  'color.naMe.green',
  'circle'
from export_fixture_trips f;

select set_config('role', 'service_role', true);

select is(
  (
    select count(*)::int
    from private.aggregate_anonymized_od_cells(
      '0a000000-0000-4000-8000-000000000001'::uuid,
      timestamptz '2026-09-01',
      timestamptz '2026-09-02',
      10,
      5::smallint
    )
  ),
  1,
  'TS-EXPORT-01: aggregate emits one k-anonymous cell for 12 identical OD trips'
);

select ok(
  not exists (
    select 1
    from private.aggregate_anonymized_od_cells(
      '0a000000-0000-4000-8000-000000000001'::uuid,
      timestamptz '2026-09-01',
      timestamptz '2026-09-02',
      10,
      5::smallint
    )
    where trip_count < 10
  ),
  'TS-EXPORT-01: no emitted cell has count below k'
);

select is(
  private.count_suppressed_od_cells(
    '0a000000-0000-4000-8000-000000000001'::uuid,
    timestamptz '2026-09-01',
    timestamptz '2026-09-02',
    10,
    5::smallint
  )::int,
  2,
  'TS-EXPORT-01: singleton and sub-k cells are suppressed'
);

select is(
  (
    select trip_count::int
    from private.aggregate_anonymized_od_cells(
      '0a000000-0000-4000-8000-000000000001'::uuid,
      timestamptz '2026-09-01',
      timestamptz '2026-09-02',
      10,
      5::smallint
    )
    limit 1
  ),
  12,
  'TS-EXPORT-01: emitted aggregate cell preserves exact trip count'
);

reset role;

insert into job_runs (id, job_name, status, finished_at)
values ('0a340000-0000-4000-8000-000000000001', 'anonymized-export', 'succeeded', now());

insert into anonymized_od_exports (
  id,
  job_run_id,
  city_id,
  period_start,
  period_end,
  k_threshold,
  geohash_precision,
  trips_examined,
  cells_emitted,
  cells_suppressed
) values (
  '0a350000-0000-4000-8000-000000000001',
  '0a340000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  timestamptz '2026-09-01',
  timestamptz '2026-09-02',
  10,
  5,
  14,
  1,
  2
);

select throws_ok(
  $$
    insert into anonymized_od_cells (
      export_id,
      city_id,
      origin_geohash,
      destination_geohash,
      mode_code,
      dow_bucket,
      hour_bucket,
      trip_count
    ) values (
      '0a350000-0000-4000-8000-000000000001',
      '0a000000-0000-4000-8000-000000000001',
      's1t7d',
      's1t7e',
      'car',
      0,
      10,
      3
    )
  $$,
  'P0001',
  'ALONG:EXPORT_K_ANONYMITY_VIOLATION',
  'TS-EXPORT-01: trigger blocks sub-k cell inserts'
);

select * from finish();
rollback;
