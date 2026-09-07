-- pgTAP: doc 02 §15 — audit_admin_write attached to all admin-modifiable tables (P6-A-01)
create extension if not exists pgtap;

begin;
select plan(6);

-- Every table in doc 02 §15 attach list that exists must have audit_admin_write trigger
with required as (
  select unnest(array[
    'app_config',
    'mode_config',
    'cities',
    'corridors',
    'parks',
    'routes',
    'route_stages',
    'route_legs',
    'route_through_fares',
    'drivers',
    'driver_verifications',
    'fare_corrections',
    'trip_reconciliation_flags',
    'incidents',
    'sos_alerts',
    'settlements',
    'driver_ledger_entries',
    'admin_users',
    'deployments',
    'countries',
    'corporate_accounts',
    'corporate_members',
    'corporate_trip_policies',
    'sponsored_placements',
    'api_keys'
  ]) as tbl
),
existing as (
  select r.tbl
  from required r
  where to_regclass('public.' || r.tbl) is not null
),
covered as (
  select e.tbl
  from existing e
  where exists (
    select 1
    from pg_trigger tg
    join pg_class c on c.oid = tg.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_proc p on p.oid = tg.tgfoid
    where n.nspname = 'public'
      and c.relname = e.tbl
      and not tg.tgisinternal
      and p.proname = 'audit_admin_write'
  )
),
missing as (
  select e.tbl
  from existing e
  where e.tbl not in (select tbl from covered)
)
select is(
  (select count(*) from missing),
  0::bigint,
  'doc 02 §15: every existing attach-list table has audit_admin_write trigger'
);

-- Phase 8 tables not yet migrated — confirm deferred, not forgotten
select ok(
  to_regclass('public.sponsored_placements') is null
  and to_regclass('public.api_keys') is null,
  'sponsored_placements and api_keys deferred to Phase 8 (P8-A-03)'
);

-- Conditional triggers: drivers.standing
select ok(
  exists (
    select 1
    from pg_trigger tg
    join pg_class c on c.oid = tg.tgrelid
    join pg_proc p on p.oid = tg.tgfoid
    where c.relname = 'drivers'
      and p.proname = 'audit_admin_write'
      and pg_get_triggerdef(tg.oid) ilike '%standing%'
  ),
  'drivers audit trigger includes standing columns'
);

-- Conditional triggers: driver_ledger_entries(manual)
select ok(
  exists (
    select 1
    from pg_trigger tg
    join pg_class c on c.oid = tg.tgrelid
    join pg_proc p on p.oid = tg.tgfoid
    where c.relname = 'driver_ledger_entries'
      and p.proname = 'audit_admin_write'
      and pg_get_triggerdef(tg.oid) ilike '%manual_adjustment%'
  ),
  'driver_ledger_entries audit trigger limited to manual_adjustment'
);

-- Conditional triggers: guarantors.last_notified_at
select ok(
  exists (
    select 1
    from pg_trigger tg
    join pg_class c on c.oid = tg.tgrelid
    join pg_proc p on p.oid = tg.tgfoid
    where c.relname = 'guarantors'
      and p.proname = 'audit_admin_write'
      and pg_get_triggerdef(tg.oid) ilike '%last_notified_at%'
  ),
  'guarantors audit trigger limited to last_notified_at'
);

-- admin_set_config rejects read-only keys (payments.digital_enabled)
insert into auth.users (id, aud, role, phone) values
  ('f0000000-0000-4000-8000-000000000099', 'authenticated', 'authenticated', '+2348000000099')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id) values
  ('f0000000-0000-4000-8000-000000000099', 'superadmin', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', 'f0000000-0000-4000-8000-000000000099', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$ select admin_set_config(
    'payments.digital_enabled',
    'global'::config_scope,
    '*',
    'true'::jsonb,
    'test attempt'
  ) $$,
  'P0001',
  null,
  'admin_set_config rejects read-only payments.digital_enabled'
);

select * from finish();
rollback;
