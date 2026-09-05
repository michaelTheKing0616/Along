-- E2E verification queue seed (P1-D-01).
-- Requires: seed_core, seed_abuja_pilot/00_city_and_corridors, seed-e2e-admins.

insert into auth.users (id, aud, role, phone) values
  (
    'c2000000-0000-4000-8000-000000000010',
    'authenticated',
    'authenticated',
    '+2348000000301'
  ),
  (
    'c2000000-0000-4000-8000-000000000011',
    'authenticated',
    'authenticated',
    '+2348000000302'
  )
on conflict (id) do nothing;

update profiles
set display_name = 'E2E Approve Driver',
    gender = 'female'
where id = 'c2000000-0000-4000-8000-000000000010';

update profiles
set display_name = 'E2E Reject Driver',
    gender = 'male'
where id = 'c2000000-0000-4000-8000-000000000011';

insert into drivers (id, city_id, verified_status, standing, driver_code) values
  (
    'c2000000-0000-4000-8000-000000000010',
    'b1000000-0000-4000-8000-000000000001',
    'pending',
    'good_standing',
    'E2EVR010'
  ),
  (
    'c2000000-0000-4000-8000-000000000011',
    'b1000000-0000-4000-8000-000000000001',
    'pending',
    'good_standing',
    'E2EVR011'
  )
on conflict (id) do update
  set city_id = excluded.city_id,
      verified_status = excluded.verified_status;

insert into vehicles (
  id, country_code, mode_code, plate_number, color, make_model, seat_capacity
) values
  (
    'c2100000-0000-4000-8000-000000000010',
    'NG',
    'car',
    'E2E-APPROVE',
    'green',
    'Toyota Corolla',
    4
  ),
  (
    'c2100000-0000-4000-8000-000000000011',
    'NG',
    'car',
    'E2E-REJECT',
    'blue',
    'Honda Accord',
    4
  )
on conflict (id) do update
  set plate_number = excluded.plate_number,
      color = excluded.color,
      make_model = excluded.make_model;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('c2000000-0000-4000-8000-000000000010', 'c2100000-0000-4000-8000-000000000010', true),
  ('c2000000-0000-4000-8000-000000000011', 'c2100000-0000-4000-8000-000000000011', true)
on conflict do nothing;

delete from driver_verifications
where driver_id in (
  'c2000000-0000-4000-8000-000000000010',
  'c2000000-0000-4000-8000-000000000011'
);

insert into driver_verifications (
  id,
  driver_id,
  vehicle_id,
  country_code,
  document_type,
  status,
  storage_path,
  ocr_extract,
  face_match_score,
  submitted_at
) values
  (
    'c2200000-0000-4000-8000-000000000010',
    'c2000000-0000-4000-8000-000000000010',
    'c2100000-0000-4000-8000-000000000010',
    'NG',
    'nin',
    'pending',
    'c2000000-0000-4000-8000-000000000010/nin/front.jpg',
    '{"hints":{"full_name":"E2E Approve Driver","id_number":"12345678901"}}'::jsonb,
    0.912,
    now() - interval '2 hours'
  ),
  (
    'c2200000-0000-4000-8000-000000000011',
    'c2000000-0000-4000-8000-000000000011',
    'c2100000-0000-4000-8000-000000000011',
    'NG',
    'drivers_license',
    'pending',
    'c2000000-0000-4000-8000-000000000011/drivers_license/front.jpg',
    '{"hints":{"full_name":"E2E Reject Driver","license_number":"ABC12345"}}'::jsonb,
    0.845,
    now() - interval '30 minutes'
  )
on conflict (id) do update
  set status = excluded.status,
      storage_path = excluded.storage_path,
      ocr_extract = excluded.ocr_extract,
      face_match_score = excluded.face_match_score,
      submitted_at = excluded.submitted_at;
