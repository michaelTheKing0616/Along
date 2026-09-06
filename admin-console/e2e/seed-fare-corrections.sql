-- E2E fare corrections queue seed (P2-D-01).
-- Requires: seed_core, seed_abuja_pilot/00_city_and_corridors, seed-e2e-admins.

insert into data_sources (id, source_type, notes) values
  ('c2600000-0000-4000-8000-000000000001', 'field_agent', 'E2E fare corrections seed')
on conflict (id) do nothing;

insert into parks (id, city_id, name, location, source_id, verification_status, confidence_score) values
  (
    'c2200000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000001',
    'E2E FC Origin',
    st_setsrid(st_makepoint(7.50, 9.05), 4326)::geography,
    'c2600000-0000-4000-8000-000000000001',
    'field_verified',
    0.950
  ),
  (
    'c2200000-0000-4000-8000-000000000002',
    'b1000000-0000-4000-8000-000000000001',
    'E2E FC Mid',
    st_setsrid(st_makepoint(7.48, 9.06), 4326)::geography,
    'c2600000-0000-4000-8000-000000000001',
    'field_verified',
    0.950
  ),
  (
    'c2200000-0000-4000-8000-000000000003',
    'b1000000-0000-4000-8000-000000000001',
    'E2E FC Destination',
    st_setsrid(st_makepoint(7.46, 9.07), 4326)::geography,
    'c2600000-0000-4000-8000-000000000001',
    'field_verified',
    0.950
  )
on conflict (id) do update set city_id = excluded.city_id;

insert into routes (id, city_id, corridor_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score) values
  (
    'c2300000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000011',
    'c2200000-0000-4000-8000-000000000001',
    'c2200000-0000-4000-8000-000000000003',
    'car',
    'c2600000-0000-4000-8000-000000000001',
    'field_verified',
    0.950
  )
on conflict (id) do update set city_id = excluded.city_id;

insert into route_stages (id, route_id, sequence, park_id, name, location, is_official_park, source_id, verification_status, confidence_score, independent_confirmation_count) values
  ('c2310000-0000-4000-8000-000000000001', 'c2300000-0000-4000-8000-000000000001', 1, 'c2200000-0000-4000-8000-000000000001', 'E2E Origin', st_setsrid(st_makepoint(7.50, 9.05), 4326)::geography, true, 'c2600000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2),
  ('c2310000-0000-4000-8000-000000000002', 'c2300000-0000-4000-8000-000000000001', 2, 'c2200000-0000-4000-8000-000000000002', 'E2E Mid', st_setsrid(st_makepoint(7.48, 9.06), 4326)::geography, true, 'c2600000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2),
  ('c2310000-0000-4000-8000-000000000003', 'c2300000-0000-4000-8000-000000000001', 3, 'c2200000-0000-4000-8000-000000000003', 'E2E Destination', st_setsrid(st_makepoint(7.46, 9.07), 4326)::geography, true, 'c2600000-0000-4000-8000-000000000001', 'field_verified', 0.950, 2)
on conflict (id) do nothing;

insert into route_legs (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, independent_confirmation_count) values
  (
    'c2300000-0000-4000-8000-000000000011',
    'c2300000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000002',
    'car',
    100.00,
    'NGN',
    'c2600000-0000-4000-8000-000000000001',
    'field_verified',
    0.950,
    2
  ),
  (
    'c2300000-0000-4000-8000-000000000010',
    'c2300000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000002',
    'c2310000-0000-4000-8000-000000000003',
    'car',
    100.00,
    'NGN',
    'c2600000-0000-4000-8000-000000000001',
    'candidate',
    0.300,
    0
  )
on conflict (id) do update
  set verification_status = excluded.verification_status,
      fare_amount = excluded.fare_amount;

insert into route_through_fares (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, independent_confirmation_count) values
  (
    'c2300000-0000-4000-8000-000000000020',
    'c2300000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000003',
    'car',
    200.00,
    'NGN',
    'c2600000-0000-4000-8000-000000000001',
    'field_verified',
    0.950,
    2
  )
on conflict (id) do update set fare_amount = excluded.fare_amount;

insert into auth.users (id, aud, role, phone) values
  ('c2500000-0000-4000-8000-000000000101', 'authenticated', 'authenticated', '+2348000000401'),
  ('c2500000-0000-4000-8000-000000000102', 'authenticated', 'authenticated', '+2348000000402'),
  ('c2500000-0000-4000-8000-000000000103', 'authenticated', 'authenticated', '+2348000000403')
on conflict (id) do nothing;

insert into riders (id, home_city_id, trip_count, account_trust_weight) values
  ('c2500000-0000-4000-8000-000000000101', 'b1000000-0000-4000-8000-000000000001', 20, 1.000),
  ('c2500000-0000-4000-8000-000000000102', 'b1000000-0000-4000-8000-000000000001', 20, 1.000),
  ('c2500000-0000-4000-8000-000000000103', 'b1000000-0000-4000-8000-000000000001', 20, 1.000)
on conflict (id) do update set account_trust_weight = excluded.account_trust_weight;

insert into data_sources (id, source_type, actor_profile_id) values
  ('c2600000-0000-4000-8000-000000000101', 'rider_correction', 'c2500000-0000-4000-8000-000000000101'),
  ('c2600000-0000-4000-8000-000000000102', 'rider_correction', 'c2500000-0000-4000-8000-000000000102')
on conflict (id) do nothing;

delete from graph_confirmations
where target_id = 'c2300000-0000-4000-8000-000000000010';

insert into graph_confirmations (
  id, target_type, target_id, confirmer_profile_id, confirmer_role,
  trust_weight, proposed_value, source_id
) values
  (
    'c2700000-0000-4000-8000-000000000101',
    'route_leg',
    'c2300000-0000-4000-8000-000000000010',
    'c2500000-0000-4000-8000-000000000101',
    'rider',
    1.000,
    '{"fare": 100}'::jsonb,
    'c2600000-0000-4000-8000-000000000101'
  ),
  (
    'c2700000-0000-4000-8000-000000000102',
    'route_leg',
    'c2300000-0000-4000-8000-000000000010',
    'c2500000-0000-4000-8000-000000000102',
    'rider',
    1.000,
    '{"fare": 100}'::jsonb,
    'c2600000-0000-4000-8000-000000000102'
  );

delete from fare_corrections
where id in (
  'c2400000-0000-4000-8000-000000000010',
  'c2400000-0000-4000-8000-000000000011',
  'c2400000-0000-4000-8000-000000000012',
  'c2400000-0000-4000-8000-000000000013'
);

insert into fare_corrections (
  id,
  route_leg_id,
  route_id,
  from_stage_id,
  to_stage_id,
  submitted_by,
  submitter_role,
  proposed_fare,
  currency,
  fare_shown,
  status,
  source_id
) values
  (
    'c2400000-0000-4000-8000-000000000010',
    'c2300000-0000-4000-8000-000000000010',
    null,
    null,
    null,
    'c2500000-0000-4000-8000-000000000103',
    'rider',
    100.00,
    'NGN',
    100.00,
    'pending',
    'c2600000-0000-4000-8000-000000000001'
  ),
  (
    'c2400000-0000-4000-8000-000000000011',
    'c2300000-0000-4000-8000-000000000011',
    null,
    null,
    null,
    'c2500000-0000-4000-8000-000000000103',
    'rider',
    120.00,
    'NGN',
    100.00,
    'pending',
    'c2600000-0000-4000-8000-000000000001'
  ),
  (
    'c2400000-0000-4000-8000-000000000012',
    'c2300000-0000-4000-8000-000000000011',
    null,
    null,
    null,
    'c2500000-0000-4000-8000-000000000103',
    'rider',
    800.00,
    'NGN',
    100.00,
    'pending',
    'c2600000-0000-4000-8000-000000000001'
  ),
  (
    'c2400000-0000-4000-8000-000000000013',
    null,
    'c2300000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000001',
    'c2310000-0000-4000-8000-000000000003',
    'c2500000-0000-4000-8000-000000000103',
    'system',
    450.00,
    'NGN',
    500.00,
    'pending',
    'c2600000-0000-4000-8000-000000000001'
  );
