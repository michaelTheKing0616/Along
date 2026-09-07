-- pgTAP: FM39 — sponsored placements keyed to aggregate context only; no rider identity path (P8-A-03)
create extension if not exists pgtap;

begin;
select plan(11);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select ok(
  not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'sponsored_placements'
      and c.column_name = any (array[
        'rider_id', 'profile_id', 'journey_id', 'trip_id', 'phone', 'phone_e164'
      ])
  ),
  'TS-FM39: sponsored_placements has no rider identity columns'
);

select ok(
  not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'placement_counters'
      and c.column_name = any (array['rider_id', 'profile_id', 'trip_id'])
  ),
  'TS-FM39: placement_counters is aggregate-only (no identity columns)'
);

select ok(
  pg_get_functiondef('resolve_sponsored_placements(placement_context_type, uuid, uuid)'::regprocedure)
    !~* '\mrider(s|_id)\M'
    and pg_get_functiondef('resolve_sponsored_placements(placement_context_type, uuid, uuid)'::regprocedure)
      !~* '\mjourneys?\M'
    and pg_get_functiondef('resolve_sponsored_placements(placement_context_type, uuid, uuid)'::regprocedure)
      !~* '\mtrips?\M'
    and pg_get_functiondef('resolve_sponsored_placements(placement_context_type, uuid, uuid)'::regprocedure)
      !~* '\mprofiles?\M',
  'TS-FM39: resolve_sponsored_placements SQL references no rider/trip history tables'
);

insert into deployments (id, tenant_name) values
  ('0f500000-0000-4000-8000-000000000001', 'FM39 Test Deployment')
on conflict (id) do nothing;

insert into auth.users (id, aud, role, phone) values
  ('0f540000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003900')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id) values
  ('0f540000-0000-4000-8000-000000000001', 'superadmin', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', '0f540000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

insert into sponsored_placements (
  id, deployment_id, context_type, target_reference, advertiser, content, active_from, active_to
) values (
  '0f510000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000001',
  'park',
  '0a020000-0000-4000-8000-000000000001',
  'Fixture Advertiser',
  '{"headline":"Visit Test Park Alpha","label":"Sponsored"}'::jsonb,
  now() - interval '1 hour',
  now() + interval '7 days'
);

select admin_set_config(
  'placements.enabled',
  'global'::config_scope,
  '*',
  'true'::jsonb,
  'TS-FM39 enable placements'
);

select is(
  jsonb_array_length(
    resolve_sponsored_placements(
      'park'::placement_context_type,
      '0a020000-0000-4000-8000-000000000001',
      '0f500000-0000-4000-8000-000000000001'
    )
  ),
  1,
  'TS-FM39: park-context placement resolves by target_reference only'
);

select is(
  resolve_sponsored_placements(
    'park'::placement_context_type,
    '0a020000-0000-4000-8000-000000000002',
    '0f500000-0000-4000-8000-000000000001'
  ),
  '[]'::jsonb,
  'TS-FM39: different park target returns empty (no cross-context leakage)'
);

select record_placement_counter('0f510000-0000-4000-8000-000000000001', 'impression');
select record_placement_counter('0f510000-0000-4000-8000-000000000001', 'tap');

select is(
  (select impressions from placement_counters
   where placement_id = '0f510000-0000-4000-8000-000000000001'
     and day = current_date),
  1,
  'TS-FM39: placement_counters records aggregate impressions'
);

select is(
  (select taps from placement_counters
   where placement_id = '0f510000-0000-4000-8000-000000000001'
     and day = current_date),
  1,
  'TS-FM39: placement_counters records aggregate taps'
);

-- RLS: operator_viewer scoped to own operator account
insert into operator_accounts (
  id, deployment_id, type, name, subscription_tier, billing_status
) values
  ('0f520000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'park', 'FM39 Operator A', 'basic', 'active'),
  ('0f520000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'park', 'FM39 Operator B', 'basic', 'active');

insert into auth.users (id, aud, role, phone) values
  ('0f530000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003901')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f530000-0000-4000-8000-000000000001', '+2348000003901', 'Operator Viewer')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id, operator_account_id) values
  ('0f530000-0000-4000-8000-000000000001', 'operator_viewer', 'a0000000-0000-4000-8000-000000000001', '0f520000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, operator_account_id = excluded.operator_account_id;

select set_config('request.jwt.claim.sub', '0f530000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  admin_operator_account_id(),
  '0f520000-0000-4000-8000-000000000001'::uuid,
  'TS-FM39: operator_viewer resolves scoped operator account id'
);

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'operator_accounts'
      and policyname = 'operator_accounts_select_operator_viewer'
  ),
  'TS-FM39: operator_accounts has operator_viewer RLS policy'
);

select ok(
  exists (select 1 from audit_log where target_type = 'sponsored_placements'),
  'TS-FM39: audit_admin_write logs sponsored_placements admin inserts'
);

select ok(
  to_regclass('public.operator_members') is not null
  and to_regclass('public.placement_counters') is not null,
  'TS-FM39: operator_members and placement_counters tables exist with RLS'
);

select * from finish();
rollback;
