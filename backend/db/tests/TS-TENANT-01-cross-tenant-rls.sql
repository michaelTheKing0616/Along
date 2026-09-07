-- pgTAP: TS-TENANT-01 — cross-tenant SELECT returns 0 (P10-A-01)
create extension if not exists pgtap;

begin;
select plan(8);

-- Tenant A (Along NG seed ids when present; fixture ids otherwise)
-- Tenant B: fictional second deployment — tests only
insert into deployments (id, tenant_name)
values ('e0000000-0000-4000-8000-000000000002', 'along-tenant-b')
on conflict (id) do nothing;

insert into countries (
  code, name, currency_code, currency_minor_units, currency_symbol,
  phone_prefix, timezone, deployment_id, verification_schema, regulatory_flags, active
) values (
  'TB',
  'Tenant B Country',
  'GHS',
  2,
  E'₵',
  '+233',
  'Africa/Accra',
  'e0000000-0000-4000-8000-000000000002',
  '[{"type":"nin","label":"Ghana Card","pattern":"^.{5,}$","provider":"verifyme"}]'::jsonb,
  '{"women_only_matching": false}'::jsonb,
  true
) on conflict (code) do update set deployment_id = excluded.deployment_id;

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'e0000000-0000-4000-8000-000000000003',
  'TB',
  'Tenant B City',
  'tenant-b-city',
  st_setsrid(st_makepoint(-0.187, 5.603), 4326)::geography,
  'live'
) on conflict (id) do nothing;

insert into app_config (key, scope_type, scope_id, value)
values (
  'test.tenant_b.secret',
  'city',
  'e0000000-0000-4000-8000-000000000003',
  '"tenant-b-only"'
) on conflict (key, scope_type, scope_id) do nothing;

-- Tenant A rider in deployment A (self-contained; uses Along NG when seeded)
insert into deployments (id, tenant_name)
values ('e0000000-0000-4000-8000-000000000001', 'along-tenant-a-fixture')
on conflict (id) do nothing;

insert into countries (
  code, name, currency_code, currency_minor_units, currency_symbol,
  phone_prefix, timezone, deployment_id, active
) values (
  'TA',
  'Tenant A Country',
  'NGN',
  2,
  E'₦',
  '+234',
  'Africa/Lagos',
  'e0000000-0000-4000-8000-000000000001',
  true
) on conflict (code) do update set deployment_id = excluded.deployment_id;

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'e0000000-0000-4000-8000-000000000001',
  'TA',
  'Tenant A City',
  'tenant-a-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
) on conflict (id) do nothing;

insert into auth.users (id, aud, role, phone) values
  ('e1000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009001')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('e1000000-0000-4000-8000-000000000001', 'Tenant A Rider')
on conflict (id) do nothing;

insert into riders (id, home_city_id)
values ('e1000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001')
on conflict (id) do update set home_city_id = excluded.home_city_id;

-- Tenant B rider (owns journey below; not visible to tenant A)
insert into auth.users (id, aud, role, phone) values
  ('e3000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2338000009002')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('e3000000-0000-4000-8000-000000000001', 'Tenant B Rider')
on conflict (id) do nothing;

insert into riders (id, home_city_id) values
  ('e3000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000003')
on conflict (id) do nothing;

-- Tenant B driver (cross-tenant driver row)
insert into auth.users (id, aud, role, phone) values
  ('e2000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2338000009001')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('e2000000-0000-4000-8000-000000000001', 'Tenant B Driver')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code)
values (
  'e2000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000003',
  'verified',
  'good_standing',
  'TNTB0001'
) on conflict (id) do nothing;

-- Tenant B admin-scoped row (journey in tenant B city — no graph FK required)
insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot, women_only
) values (
  'e4000000-0000-4000-8000-000000000001',
  'e3000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000003',
  'completed',
  st_setsrid(st_makepoint(-0.187, 5.603), 4326)::geography,
  st_setsrid(st_makepoint(-0.190, 5.610), 4326)::geography,
  '{}'::jsonb,
  false
) on conflict (id) do nothing;

-- Tenant A admin scoped to Along NG deployment
insert into auth.users (id, aud, role, phone) values
  ('e6000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009002')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('e6000000-0000-4000-8000-000000000001', 'Tenant A Admin')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id)
values (
  'e6000000-0000-4000-8000-000000000001',
  'ops_lead',
  'e0000000-0000-4000-8000-000000000001'
)
on conflict (id) do update set deployment_id = excluded.deployment_id;

select set_config('request.jwt.claim.sub', 'e1000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from cities where id = 'e0000000-0000-4000-8000-000000000003'::uuid),
  0,
  'TS-TENANT-01: tenant A rider cannot SELECT tenant B city'
);

select is(
  (select count(*)::int from countries where code = 'TB'),
  0,
  'TS-TENANT-01: tenant A rider cannot SELECT tenant B country'
);

select is(
  (select count(*)::int from deployments where id = 'e0000000-0000-4000-8000-000000000002'::uuid),
  0,
  'TS-TENANT-01: tenant A rider cannot SELECT tenant B deployment'
);

select is(
  (select count(*)::int
   from app_config
   where key = 'test.tenant_b.secret'
     and scope_type = 'city'
     and scope_id = 'e0000000-0000-4000-8000-000000000003'),
  0,
  'TS-TENANT-01: tenant A rider cannot SELECT tenant B scoped app_config'
);

select is(
  (select count(*)::int from drivers where id = 'e2000000-0000-4000-8000-000000000001'::uuid),
  0,
  'TS-TENANT-01: tenant A rider cannot SELECT tenant B driver'
);

select is(
  (select count(*)::int from journeys where id = 'e4000000-0000-4000-8000-000000000001'::uuid),
  0,
  'TS-TENANT-01: tenant A rider cannot SELECT tenant B journey/trip data'
);

reset role;

select set_config('request.jwt.claim.sub', 'e6000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from drivers where city_id = 'e0000000-0000-4000-8000-000000000003'::uuid),
  0,
  'TS-TENANT-01: tenant A admin cannot SELECT tenant B drivers via city scope'
);

select is(
  (select count(*)::int from journeys where city_id = 'e0000000-0000-4000-8000-000000000003'::uuid),
  0,
  'TS-TENANT-01: tenant A admin cannot SELECT tenant B journeys/trips'
);

select * from finish();
rollback;
