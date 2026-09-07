-- E2E safety board seed (P5-D-01 / A-12)

insert into auth.users (id, aud, role, phone) values
  ('c5000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000000501')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('c5000000-0000-4000-8000-000000000001', '+2348000000501', 'E2E SOS Rider')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('c5000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into journeys (id, rider_id, city_id, status, origin, destination, destination_label, plan_snapshot) values
  (
    'c5300000-0000-4000-8000-000000000001',
    'c5000000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000001',
    'active',
    st_setsrid(st_makepoint(7.595, 9.012), 4326)::geography,
    st_setsrid(st_makepoint(7.433, 9.067), 4326)::geography,
    'Berger Junction',
    '{}'::jsonb
  )
on conflict (id) do nothing;

delete from device_tokens where profile_id = 'c5000000-0000-4000-8000-000000000001';

insert into device_tokens (profile_id, platform, token, app) values
  ('c5000000-0000-4000-8000-000000000001', 'android', 'e2e-rider-sos-token', 'rider');

delete from sos_alerts where id = 'c5500000-0000-4000-8000-000000000001';

insert into sos_alerts (
  id, trip_id, journey_id, raised_by, raised_role, location, status, created_at
) values (
  'c5500000-0000-4000-8000-000000000001',
  null,
  'c5300000-0000-4000-8000-000000000001',
  'c5000000-0000-4000-8000-000000000001',
  'rider',
  st_setsrid(st_makepoint(7.596, 9.013), 4326)::geography,
  'open',
  now()
);

delete from incidents where id = 'c5600000-0000-4000-8000-000000000001';

insert into incidents (
  id, trip_id, type, severity, status, reported_by, reported_role, description
) values (
  'c5600000-0000-4000-8000-000000000001',
  null,
  'safety',
  2,
  'open',
  'c5000000-0000-4000-8000-000000000001',
  'rider',
  'E2E safety incident awaiting triage'
);
