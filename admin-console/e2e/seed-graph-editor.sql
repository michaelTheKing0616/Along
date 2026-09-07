-- E2E graph editor fixture (P6-D-03): minimal Abuja park for graph edit + audit tests.

insert into data_sources (id, source_type, notes)
values (
  'b1300000-0000-4000-8000-0000000000e2',
  'import',
  'e2e graph editor seed'
)
on conflict (id) do nothing;

insert into parks (
  id,
  city_id,
  name,
  name_aliases,
  location,
  source_id,
  verification_status,
  confidence_score
) values (
  'b1100000-0000-4000-8000-000000000001',
  'b1000000-0000-4000-8000-000000000001',
  'Nyanya Park',
  array['Nyanya'],
  st_setsrid(st_makepoint(7.595, 9.012), 4326)::geography,
  'b1300000-0000-4000-8000-0000000000e2',
  'field_verified',
  0.950
)
on conflict (id) do update
  set name = excluded.name,
      location = excluded.location;
