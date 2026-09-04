-- Zaria-Test fictional city (doc 13 §6, doc 02 §17). Never deployed to prod.
-- Real coordinates near Zaria; fictional park names. Requires seed_core.sql first.

insert into cities (id, country_code, name, slug, state_region, centroid, status)
values (
  '0a000000-0000-4000-8000-000000000001',
  'NG',
  'Zaria-Test',
  'zaria-test',
  'Kaduna (test fixture)',
  st_setsrid(st_makepoint(7.702, 11.066), 4326)::geography,
  'live'
);

insert into corridors (id, city_id, name, slug, status)
values (
  '0a000000-0000-4000-8000-000000000011',
  '0a000000-0000-4000-8000-000000000001',
  'Test Corridor Alpha',
  'test-corridor-alpha',
  'live'
);

-- Deliberately different from global defaults (FM5 / TS-CFG-01)
insert into app_config (key, scope_type, scope_id, value) values
  ('commission.rate', 'city', '0a000000-0000-4000-8000-000000000001', '0.05'),
  ('graph.snap_radius_m', 'city', '0a000000-0000-4000-8000-000000000001', '40')
on conflict (key, scope_type, scope_id) do update set value = excluded.value;

insert into data_sources (id, source_type, notes)
values ('0a010000-0000-4000-8000-000000000001', 'import', 'Zaria-Test CI fixture — not field data')
on conflict (id) do nothing;

insert into parks (id, city_id, name, location, source_id, verification_status, confidence_score) values
  ('0a020000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'Test Park Alpha', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a020000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'Test Park Beta', st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800);

insert into routes (id, city_id, corridor_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score) values
  ('0a030000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000011', '0a020000-0000-4000-8000-000000000001', '0a020000-0000-4000-8000-000000000002', 'car', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a030000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000011', '0a020000-0000-4000-8000-000000000001', '0a020000-0000-4000-8000-000000000002', 'keke', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800);

-- 5 stages per car route (keke shares stage geometry)
insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score) values
  ('0a040000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', 1, '0a020000-0000-4000-8000-000000000001', 'Test Park Alpha', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a040000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000001', 2, null, 'Test Junction Gamma', st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a040000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000001', 3, null, 'Test Junction Delta', st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a040000-0000-4000-8000-000000000004', '0a030000-0000-4000-8000-000000000001', 4, null, 'Test Junction Epsilon', st_setsrid(st_makepoint(7.704, 11.064), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a040000-0000-4000-8000-000000000005', '0a030000-0000-4000-8000-000000000001', 5, '0a020000-0000-4000-8000-000000000002', 'Test Park Beta', st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800);

insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score) values
  ('0a041000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000002', 1, '0a020000-0000-4000-8000-000000000001', 'Test Park Alpha', st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a041000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000002', 2, null, 'Test Junction Gamma', st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a041000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000002', 3, null, 'Test Junction Delta', st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a041000-0000-4000-8000-000000000004', '0a030000-0000-4000-8000-000000000002', 4, null, 'Test Junction Epsilon', st_setsrid(st_makepoint(7.704, 11.064), 4326)::geography, false, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800),
  ('0a041000-0000-4000-8000-000000000005', '0a030000-0000-4000-8000-000000000002', 5, '0a020000-0000-4000-8000-000000000002', 'Test Park Beta', st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography, true, '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800);

insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, in_vehicle_time_estimate_s, avg_wait_time_estimate_s) values
  ('0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000002', 'car', 80.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 300, 120),
  ('0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000002', '0a040000-0000-4000-8000-000000000003', 'car', 80.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 300, 120),
  ('0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000003', '0a040000-0000-4000-8000-000000000004', 'car', 80.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 300, 120),
  ('0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000004', '0a040000-0000-4000-8000-000000000005', 'car', 80.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 300, 120),
  ('0a030000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000001', '0a041000-0000-4000-8000-000000000002', 'keke', 50.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 360, 180),
  ('0a030000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000003', 'keke', 50.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 360, 180),
  ('0a030000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000003', '0a041000-0000-4000-8000-000000000004', 'keke', 50.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 360, 180),
  ('0a030000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000004', '0a041000-0000-4000-8000-000000000005', 'keke', 50.00, 'NGN', '0a010000-0000-4000-8000-000000000001', 'crowd_verified', 0.800, 360, 180);

-- One through-fare (S1→S4) for Tier 1 tests
insert into route_through_fares (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score)
values (
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000004',
  'car',
  280.00,
  'NGN',
  '0a010000-0000-4000-8000-000000000001',
  'crowd_verified',
  0.800
);

insert into transfer_points (park_id, route_id, stage_id, walk_distance_m, transfer_time_s) values
  ('0a020000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000001', 0, 120),
  ('0a020000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000001', 0, 120),
  ('0a020000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000001', '0a040000-0000-4000-8000-000000000005', 0, 120),
  ('0a020000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000002', '0a041000-0000-4000-8000-000000000005', 0, 120);
