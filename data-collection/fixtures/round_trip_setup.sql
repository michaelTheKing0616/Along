-- Round-trip test fixtures (P0-E-03). Idempotent setup.
insert into deployments (id, tenant_name)
values ('f0000000-0000-4000-8000-000000000001', 'Round Trip Tenant')
on conflict (id) do nothing;

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XR', 'Round Trip Country', 'NGN', E'₦', '+998', 'UTC', 'f0000000-0000-4000-8000-000000000001', true)
on conflict (code) do nothing;

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'f0000000-0000-4000-8000-000000000002',
  'XR',
  'Round Trip City',
  'round-trip-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
) on conflict (id) do nothing;

insert into corridors (id, city_id, name, slug, status)
values (
  'f0000000-0000-4000-8000-000000000100',
  'f0000000-0000-4000-8000-000000000002',
  'East Axis Test',
  'east-axis-test',
  'live'
) on conflict (id) do nothing;

insert into auth.users (id, aud, role, phone) values
  ('f0000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000000100'),
  ('f0000000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000000101')
on conflict (id) do nothing;

insert into field_agents (id, city_id) values
  ('f0000000-0000-4000-8000-000000000010', 'f0000000-0000-4000-8000-000000000002'),
  ('f0000000-0000-4000-8000-000000000011', 'f0000000-0000-4000-8000-000000000002')
on conflict (id) do nothing;
