-- pgTAP: city_for_point() boundary match + centroid fallback
begin;
select plan(5);

create extension if not exists pgtap;

insert into deployments (id, tenant_name) values
  ('e0000000-0000-4000-8000-000000000001', 'Geo Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XG', 'Geo Test Country', 'XXX', 'X', '+998', 'UTC', 'e0000000-0000-4000-8000-000000000001', true);

-- City A: has boundary polygon around (9.05, 7.40)
insert into cities (id, country_code, name, slug, centroid, boundary, status)
values (
  'f0000000-0000-4000-8000-000000000001',
  'XG',
  'Boundary City',
  'boundary-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  st_geomfromtext(
    'MULTIPOLYGON(((7.395 9.045, 7.405 9.045, 7.405 9.055, 7.395 9.055, 7.395 9.045)))',
    4326
  )::geography,
  'live'
);

-- City B: centroid only, farther north-east
insert into cities (id, country_code, name, slug, centroid, status)
values (
  'f0000000-0000-4000-8000-000000000002',
  'XG',
  'Centroid City',
  'centroid-city',
  st_setsrid(st_makepoint(7.55, 9.20), 4326)::geography,
  'live'
);

-- City C: paused — must never match
insert into cities (id, country_code, name, slug, centroid, status)
values (
  'f0000000-0000-4000-8000-000000000003',
  'XG',
  'Paused City',
  'paused-city',
  st_setsrid(st_makepoint(7.41, 9.06), 4326)::geography,
  'paused'
);

select is(
  city_for_point(st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography),
  'f0000000-0000-4000-8000-000000000001'::uuid,
  'point inside boundary polygon resolves to boundary city'
);

select is(
  city_for_point(st_setsrid(st_makepoint(7.52, 9.18), 4326)::geography),
  'f0000000-0000-4000-8000-000000000002'::uuid,
  'point outside boundaries falls back to nearest centroid within 60 km'
);

select is(
  city_for_point(st_setsrid(st_makepoint(7.41, 9.06), 4326)::geography),
  'f0000000-0000-4000-8000-000000000001'::uuid,
  'paused city is excluded from resolution'
);

select is(
  city_for_point(st_setsrid(st_makepoint(0.0, 0.0), 4326)::geography),
  null::uuid,
  'point beyond 60 km from all active cities returns null'
);

-- Boundary beats nearer centroid when point is inside boundary city
select is(
  city_for_point(st_setsrid(st_makepoint(7.401, 9.051), 4326)::geography),
  'f0000000-0000-4000-8000-000000000001'::uuid,
  'boundary match takes priority over distance ordering'
);

select * from finish();
rollback;
