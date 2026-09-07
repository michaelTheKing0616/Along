-- pgTAP: P9-A-01 — city_admin scoped via admin_users.city_scope + admin_can_access_city
create extension if not exists pgtap;

begin;
select plan(4);

insert into deployments (id, tenant_name)
values ('f9000000-0000-4000-8000-000000000001', 'City Admin Scope Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values
  ('NG', 'Nigeria', 'NGN', E'₦', '+234', 'Africa/Lagos', 'f9000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values
  (
    'f9100000-0000-4000-8000-000000000001',
    'NG',
    'Scope City Alpha',
    'scope-alpha',
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    'live'
  ),
  (
    'f9100000-0000-4000-8000-000000000002',
    'NG',
    'Scope City Beta',
    'scope-beta',
    st_setsrid(st_makepoint(7.70, 9.15), 4326)::geography,
    'live'
  );

insert into auth.users (id, aud, role, phone) values
  ('f9200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009001'),
  ('f9200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000009002'),
  ('f9200000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000009003');

insert into profiles (id, phone_e164, display_name) values
  ('f9200000-0000-4000-8000-000000000002', '+2348000009002', 'Alpha Driver'),
  ('f9200000-0000-4000-8000-000000000003', '+2348000009003', 'Beta Driver'),
  ('f9200000-0000-4000-8000-000000000010', '+2348000009010', 'Alpha Rider'),
  ('f9200000-0000-4000-8000-000000000011', '+2348000009011', 'Beta Rider');

insert into riders (id) values
  ('f9200000-0000-4000-8000-000000000010'),
  ('f9200000-0000-4000-8000-000000000011');

insert into admin_users (id, role, city_scope)
values (
  'f9200000-0000-4000-8000-000000000001',
  'city_admin',
  array['f9100000-0000-4000-8000-000000000001']::uuid[]
);

insert into drivers (id, city_id) values
  ('f9200000-0000-4000-8000-000000000002', 'f9100000-0000-4000-8000-000000000001'),
  ('f9200000-0000-4000-8000-000000000003', 'f9100000-0000-4000-8000-000000000002');

insert into journeys (id, rider_id, city_id, status, origin, destination, plan_snapshot)
values
  (
    'f9300000-0000-4000-8000-000000000001',
    'f9200000-0000-4000-8000-000000000010',
    'f9100000-0000-4000-8000-000000000001',
    'planning',
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    st_setsrid(st_makepoint(7.41, 9.06), 4326)::geography,
    '{"kind":"direct"}'::jsonb
  ),
  (
    'f9300000-0000-4000-8000-000000000002',
    'f9200000-0000-4000-8000-000000000011',
    'f9100000-0000-4000-8000-000000000002',
    'planning',
    st_setsrid(st_makepoint(7.70, 9.15), 4326)::geography,
    st_setsrid(st_makepoint(7.71, 9.16), 4326)::geography,
    '{"kind":"direct"}'::jsonb
  );

select set_config('request.jwt.claim.sub', 'f9200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::int from drivers where city_id = 'f9100000-0000-4000-8000-000000000001'),
  1,
  'city_admin can read drivers in scoped city'
);

select is(
  (select count(*)::int from drivers where city_id = 'f9100000-0000-4000-8000-000000000002'),
  0,
  'city_admin cannot read drivers in another city'
);

select is(
  (select count(*)::int from journeys where city_id = 'f9100000-0000-4000-8000-000000000001'),
  1,
  'city_admin can read journeys in scoped city'
);

select is(
  (select count(*)::int from journeys where city_id = 'f9100000-0000-4000-8000-000000000002'),
  0,
  'city_admin cannot read journeys in another city'
);

select * from finish();
rollback;
