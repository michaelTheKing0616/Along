-- Abuja pilot: city + corridors (doc 13 §5, doc 02 §17).
-- Requires seed_core.sql (NG deployment + country) applied first.

insert into cities (id, country_code, name, slug, state_region, centroid, status)
values (
  'b1000000-0000-4000-8000-000000000001',
  'NG',
  'Abuja',
  'abuja',
  'FCT',
  st_setsrid(st_makepoint(7.495, 9.057), 4326)::geography,
  'live'
);

insert into corridors (id, city_id, name, slug, status) values
  (
    'b1000000-0000-4000-8000-000000000011',
    'b1000000-0000-4000-8000-000000000001',
    'Nyanya / Mararaba ↔ CBD',
    'nyanya-cbd',
    'live'
  ),
  (
    'b1000000-0000-4000-8000-000000000012',
    'b1000000-0000-4000-8000-000000000001',
    'Lugbe ↔ Area 1 / Berger',
    'lugbe-area1',
    'live'
  ),
  (
    'b1000000-0000-4000-8000-000000000013',
    'b1000000-0000-4000-8000-000000000001',
    'Kubwa ↔ Wuse / Berger',
    'kubwa-wuse',
    'live'
  );
