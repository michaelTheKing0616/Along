-- pgTAP: P6-D-01 — admin_corridor_analytics bounded/paginated; conversion diagnostic (FM13)
create extension if not exists pgtap;

begin;
select plan(11);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f400000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000007010'),
  ('0f400000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000007011'),
  ('0f100000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000007012')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f400000-0000-4000-8000-000000000010', '+2348000007010', 'Analytics Analyst'),
  ('0f400000-0000-4000-8000-000000000011', '+2348000007011', 'Analytics Outsider'),
  ('0f100000-0000-4000-8000-000000000010', '+2348000007012', 'Analytics Rider')
on conflict (id) do update set display_name = excluded.display_name;

insert into admin_users (id, role, deployment_id) values
  ('0f400000-0000-4000-8000-000000000010', 'analyst', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000010', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into planner_queries (
  id, rider_id, city_id, origin, destination, filters, candidate_count, direct_count, candidates, created_at, chosen_candidate_id
) values
  (
    '0f700000-0000-4000-8000-000000000001',
    '0f100000-0000-4000-8000-000000000010',
    '0a000000-0000-4000-8000-000000000001',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '{}'::jsonb, 2, 1, '[]'::jsonb,
    now() - interval '2 hours',
    '0f800000-0000-4000-8000-000000000001'::uuid
  ),
  (
    '0f700000-0000-4000-8000-000000000002',
    '0f100000-0000-4000-8000-000000000010',
    '0a000000-0000-4000-8000-000000000001',
    st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '{}'::jsonb, 1, 1, '[]'::jsonb,
    now() - interval '90 minutes',
    null
  ),
  (
    '0f700000-0000-4000-8000-000000000003',
    '0f100000-0000-4000-8000-000000000010',
    '0a000000-0000-4000-8000-000000000001',
    st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '{}'::jsonb, 0, 0, '[]'::jsonb,
    now() - interval '30 minutes',
    null
  );

insert into coverage_gap_reports (
  id, rider_id, city_id, searched_location, searched_at, nearest_known_stage_id, nearest_known_stage_distance_m, ambient_vehicle_count
) values (
  '0f710000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000010',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.7005, 11.0605), 4326)::geography,
  now() - interval '45 minutes',
  '0a040000-0000-4000-8000-000000000001',
  120,
  2
);

select set_config('request.jwt.claim.sub', '0f400000-0000-4000-8000-000000000010', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '24 hours',
    now(),
    null,
    2
  )->'meta'->>'page_size')::int = 2,
  'admin_corridor_analytics respects bounded page_size'
);

select ok(
  jsonb_array_length(
    admin_corridor_analytics(
      '0a000000-0000-4000-8000-000000000011'::uuid,
      now() - interval '24 hours',
      now(),
      null,
      2
    )->'series'
  ) <= 2,
  'admin_corridor_analytics series page is capped'
);

select ok(
  jsonb_array_length(
    admin_corridor_analytics(
      '0a000000-0000-4000-8000-000000000011'::uuid,
      now() - interval '24 hours',
      now(),
      null,
      2
    )->'coverage_gaps'
  ) <= 2,
  'admin_corridor_analytics coverage_gaps list is capped'
);

select is(
  (admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '24 hours',
    now()
  )->'summary'->>'searches')::int,
  3,
  'admin_corridor_analytics counts corridor searches'
);

select is(
  (admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '24 hours',
    now()
  )->'summary'->>'ambient_views')::int,
  2,
  'admin_corridor_analytics counts ambient views (candidate_count > 0)'
);

select is(
  (admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '24 hours',
    now()
  )->'summary'->>'commits')::int,
  1,
  'admin_corridor_analytics counts commits'
);

select ok(
  (admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '24 hours',
    now()
  )->'summary'->'ambient_to_commit_rate') is not null,
  'ambient_to_commit_rate conversion metric is present'
);

select is(
  (admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '24 hours',
    now()
  )->'summary'->>'ambient_to_commit_diagnostic')::boolean,
  true,
  'conversion flagged diagnostic-only in payload'
);

select throws_ok(
  $$select admin_corridor_analytics(
    '0a000000-0000-4000-8000-000000000011'::uuid,
    now() - interval '90 days',
    now()
  )$$,
  'P0001',
  'time window exceeds analytics.max_window_days',
  'admin_corridor_analytics rejects unbounded window'
);

-- FM13: read-only — no standing / flag side effects
select is(
  (select count(*)::int from driver_standing_transitions),
  0,
  'admin_corridor_analytics does not write standing transitions'
);

select is(
  (select count(*)::int from trip_reconciliation_flags),
  0,
  'admin_corridor_analytics does not write integrity flags'
);

select * from finish();
rollback;
