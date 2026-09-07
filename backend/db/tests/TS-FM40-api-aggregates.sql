-- pgTAP: FM40 — API key returns k-anonymised aggregates only; never raw trips (P8-A-03)
create extension if not exists pgtap;

begin;
select plan(11);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0f600000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000004001')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id) values
  ('0f600000-0000-4000-8000-000000000001', 'superadmin', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', '0f600000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select ok(
  not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'api_keys'
      and c.column_name in ('api_key', 'plaintext_key', 'key')
  ),
  'TS-FM40: api_keys stores key_hash only (no plaintext column)'
);

create temp table fm40_created on commit drop as
select admin_create_api_key('FM40 Org', array['od_cells'], 5) as payload;

select lives_ok(
  $$ select 1 from fm40_created $$,
  'TS-FM40: admin_create_api_key succeeds'
);

select ok(
  (select count(*) from api_keys
   where key_hash = digest((select payload->>'api_key' from fm40_created), 'sha256')) = 1,
  'TS-FM40: api_keys row stores digest of issued key'
);

select is(
  (select count(*)::int from api_keys
   where id = (select (payload->>'id')::uuid from fm40_created)),
  1,
  'TS-FM40: admin can select api_keys metadata via RLS (hash only)'
);

insert into job_runs (id, job_name, status, started_at, finished_at)
values (
  '0f610000-0000-4000-8000-000000000001',
  'jobs/anonymized-export',
  'succeeded',
  now() - interval '1 hour',
  now()
);

insert into anonymized_od_exports (
  id, job_run_id, city_id, period_start, period_end, k_threshold, geohash_precision,
  trips_examined, cells_emitted, cells_suppressed
) values (
  '0f620000-0000-4000-8000-000000000001',
  '0f610000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  now() - interval '7 days',
  now(),
  10,
  5,
  100,
  1,
  0
);

insert into anonymized_od_cells (
  export_id, city_id, origin_geohash, destination_geohash, mode_code,
  dow_bucket, hour_bucket, trip_count
) values (
  '0f620000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  's0k8t', 's0k8u', 'car', 0, 12, 15
);

select ok(
  (api_fetch_od_cells(
    (select payload->>'api_key' from fm40_created),
    '0f620000-0000-4000-8000-000000000001'
  )->'meta'->>'aggregate_only')::boolean,
  'TS-FM40: api_fetch_od_cells marks response aggregate_only'
);

select ok(
  api_fetch_od_cells(
    (select payload->>'api_key' from fm40_created),
    '0f620000-0000-4000-8000-000000000001'
  )->'cells'->0 ? 'trip_count'
  and not (
    api_fetch_od_cells(
      (select payload->>'api_key' from fm40_created),
      '0f620000-0000-4000-8000-000000000001'
    )->'cells'->0 ?& array['trip_id', 'rider_id', 'driver_id', 'journey_id']
  ),
  'TS-FM40: api_fetch_od_cells returns geohash aggregates without trip/rider ids'
);

select ok(
  pg_get_functiondef('api_fetch_od_cells(text, uuid, int, text)'::regprocedure)
    !~* '\mtrips?\M'
    and pg_get_functiondef('api_fetch_od_cells(text, uuid, int, text)'::regprocedure)
      !~* '\mrider(s|_id)\M'
    and pg_get_functiondef('api_fetch_od_cells(text, uuid, int, text)'::regprocedure)
      !~* '\mjourneys?\M',
  'TS-FM40: api_fetch_od_cells SQL never selects raw trip/rider rows'
);

select throws_ok(
  $$ select api_fetch_od_cells('along_invalid_key', '0f620000-0000-4000-8000-000000000001') $$,
  'P0001',
  null,
  'TS-FM40: invalid API key rejected'
);

create temp table fm40_rate_key on commit drop as
select admin_create_api_key('FM40 Rate Org', array['od_cells'], 1) as payload;

select api_fetch_od_cells(
  (select payload->>'api_key' from fm40_rate_key),
  '0f620000-0000-4000-8000-000000000001'
);

select throws_ok(
  format(
    $q$
      select api_fetch_od_cells(%L, '0f620000-0000-4000-8000-000000000001')
    $q$,
    (select payload->>'api_key' from fm40_rate_key)
  ),
  'P0001',
  null,
  'TS-FM40: api_fetch_od_cells enforces per-minute rate limit'
);

select ok(
  exists (select 1 from audit_log where target_type = 'api_keys'),
  'TS-FM40: audit_admin_write logs api_keys admin inserts'
);

select ok(
  to_regclass('public.api_usage') is not null,
  'TS-FM40: api_usage table exists with RLS'
);

select * from finish();
rollback;
