-- Test drivers for TS-* scenarios (doc 10 §2). Requires city graph seed applied first.
-- driver_presence rows deferred until Phase 1 migration lands.

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000001001'),
  ('0a100000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000001002'),
  ('0a100000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000001003'),
  ('0a100000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '+2348000001004'),
  ('0a100000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', '+2348000001005'),
  ('0a100000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', '+2348000001006')
on conflict (id) do nothing;

-- Uses Zaria-Test city when applied after city_zaria_test.sql; override city_id if using Abuja min.
insert into drivers (id, city_id, verified_status, standing, women_only_eligible, driver_code) values
  ('0a100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', false, 'TSTDRV01'),
  ('0a100000-0000-4000-8000-000000000002', '0a000000-0000-4000-8000-000000000001', 'verified', 'warned', false, 'TSTDRV02'),
  ('0a100000-0000-4000-8000-000000000003', '0a000000-0000-4000-8000-000000000001', 'verified', 'matching_paused', false, 'TSTDRV03'),
  ('0a100000-0000-4000-8000-000000000004', '0a000000-0000-4000-8000-000000000001', 'unverified', 'good_standing', false, 'TSTDRV04'),
  ('0a100000-0000-4000-8000-000000000005', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', true, 'TSTDRV05'),
  ('0a100000-0000-4000-8000-000000000006', '0a000000-0000-4000-8000-000000000001', 'verified', 'deactivated', false, 'TSTDRV06')
on conflict (id) do nothing;

-- Paused driver: balance −5,200 (doc 10 §2) — ledger deferred to Phase 4; standing encodes pause.
