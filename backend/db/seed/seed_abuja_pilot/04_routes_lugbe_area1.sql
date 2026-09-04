-- Corridor 2: Lugbe ↔ Area 1 / Berger (south-west axis) — car + keke feeder (doc 13 §5.2).

insert into routes (id, city_id, corridor_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score) values
  ('b1400000-0000-4000-8000-000000000021', 'b1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000012', 'b1100000-0000-4000-8000-000000000007', 'b1100000-0000-4000-8000-000000000006', 'car', 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950),
  ('b1400000-0000-4000-8000-000000000022', 'b1000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000012', 'b1100000-0000-4000-8000-000000000007', 'b1100000-0000-4000-8000-000000000008', 'keke', 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950);

insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score, independent_confirmation_count) values
  ('b1430000-0000-4000-8000-000000000021', 'b1400000-0000-4000-8000-000000000021', 1, 'b1100000-0000-4000-8000-000000000007', 'Lugbe Park', st_setsrid(st_makepoint(7.365, 8.987), 4326)::geography, true, 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2),
  ('b1430000-0000-4000-8000-000000000022', 'b1400000-0000-4000-8000-000000000021', 2, 'b1100000-0000-4000-8000-000000000008', 'Area 1 Park', st_setsrid(st_makepoint(7.495, 9.048), 4326)::geography, true, 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2),
  ('b1430000-0000-4000-8000-000000000023', 'b1400000-0000-4000-8000-000000000021', 3, 'b1100000-0000-4000-8000-000000000006', 'Berger Junction', st_setsrid(st_makepoint(7.433, 9.067), 4326)::geography, true, 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2);

insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score, independent_confirmation_count) values
  ('b1440000-0000-4000-8000-000000000021', 'b1400000-0000-4000-8000-000000000022', 1, 'b1100000-0000-4000-8000-000000000007', 'Lugbe Park', st_setsrid(st_makepoint(7.365, 8.987), 4326)::geography, true, 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2),
  ('b1440000-0000-4000-8000-000000000022', 'b1400000-0000-4000-8000-000000000022', 2, 'b1100000-0000-4000-8000-000000000008', 'Area 1 Park', st_setsrid(st_makepoint(7.495, 9.048), 4326)::geography, true, 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2);

insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, independent_confirmation_count, in_vehicle_time_estimate_s, avg_wait_time_estimate_s) values
  ('b1400000-0000-4000-8000-000000000021', 'b1430000-0000-4000-8000-000000000021', 'b1430000-0000-4000-8000-000000000022', 'car', 350.00, 'NGN', 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2, 1200, 240),
  ('b1400000-0000-4000-8000-000000000021', 'b1430000-0000-4000-8000-000000000022', 'b1430000-0000-4000-8000-000000000023', 'car', 200.00, 'NGN', 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2, 720, 180),
  ('b1400000-0000-4000-8000-000000000022', 'b1440000-0000-4000-8000-000000000021', 'b1440000-0000-4000-8000-000000000022', 'keke', 150.00, 'NGN', 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2, 900, 300);

insert into route_through_fares (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, independent_confirmation_count) values
  ('b1400000-0000-4000-8000-000000000021', 'b1430000-0000-4000-8000-000000000021', 'b1430000-0000-4000-8000-000000000023', 'car', 550.00, 'NGN', 'b1300000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2);
