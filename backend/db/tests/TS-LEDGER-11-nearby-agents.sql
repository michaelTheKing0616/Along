-- pgTAP: TS-LEDGER-11 — nearby_settlement_agents is city-bound and distance-ordered
create extension if not exists pgtap;

begin;
select plan(4);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f200000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000007110'),
  ('0f200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000007111'),
  ('0f300000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000007120')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f200000-0000-4000-8000-000000000010', '+2348000007110', 'Agent Driver'),
  ('0f200000-0000-4000-8000-000000000011', '+2348000007111', 'Zaria Agent'),
  ('0f300000-0000-4000-8000-000000000010', '+2348000007120', 'Other City Agent')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000010', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'AGD01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into deployments (id, tenant_name) values
  ('c0000000-0000-4000-8000-000000000099', 'Agent Test Tenant')
on conflict (id) do nothing;

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('NG', 'Nigeria', 'NGN', E'₦', '+234', 'Africa/Lagos', 'c0000000-0000-4000-8000-000000000099', true)
on conflict (code) do nothing;

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'c0000000-0000-4000-8000-000000000001',
  'NG',
  'Agent Other City',
  'agent-other-city',
  st_setsrid(st_makepoint(7.4, 9.0), 4326)::geography,
  'live'
) on conflict (id) do nothing;

insert into settlement_agents (id, profile_id, city_id, business_name, location, active) values
  (
    '0f800000-0000-4000-8000-000000000001',
    '0f200000-0000-4000-8000-000000000011',
    '0a000000-0000-4000-8000-000000000001',
    'Zaria POS',
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    true
  ),
  (
    '0f800000-0000-4000-8000-000000000002',
    '0f300000-0000-4000-8000-000000000010',
    'c0000000-0000-4000-8000-000000000001',
    'Other POS',
    st_setsrid(st_makepoint(7.401, 9.001), 4326)::geography,
    true
  ),
  (
    '0f800000-0000-4000-8000-000000000003',
    '0f200000-0000-4000-8000-000000000011',
    '0a000000-0000-4000-8000-000000000001',
    'Zaria Far POS',
    st_setsrid(st_makepoint(7.800, 11.100), 4326)::geography,
    true
  )
on conflict (id) do update set
  business_name = excluded.business_name,
  location = excluded.location,
  active = excluded.active;

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000010', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config(
  'test.agents',
  nearby_settlement_agents('{"lat": 11.060, "lng": 7.700}')::text,
  true
);

select is(
  jsonb_array_length(current_setting('test.agents')::jsonb),
  2,
  'TS-LEDGER-11: returns only active agents in driver city'
);

select ok(
  not exists (
    select 1
    from jsonb_array_elements(current_setting('test.agents')::jsonb) elem
    where elem->>'business_name' = 'Other POS'
  ),
  'TS-LEDGER-11: excludes agents from other cities'
);

select is(
  (current_setting('test.agents')::jsonb->0->>'business_name'),
  'Zaria POS',
  'TS-LEDGER-11: nearest agent first'
);

select ok(
  (current_setting('test.agents')::jsonb->0 ? 'id')
  and (current_setting('test.agents')::jsonb->0 ? 'business_name')
  and (current_setting('test.agents')::jsonb->0 ? 'distance_m')
  and not (current_setting('test.agents')::jsonb->0 ? 'profile_id')
  and not (current_setting('test.agents')::jsonb->0 ? 'phone'),
  'TS-LEDGER-11: response exposes id, business_name, distance_m only'
);

select * from finish();
rollback;
