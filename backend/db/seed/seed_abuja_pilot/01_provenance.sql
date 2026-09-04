-- Two-scout field provenance for Abuja pilot backbone (Phase 0 gate).
-- Reconciled pairs from P0-E-03 ingest; field_verified only where status = matched.

insert into auth.users (id, aud, role, phone) values
  ('b1200000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000000101'),
  ('b1200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000000102')
on conflict (id) do nothing;

insert into field_agents (id, city_id, active) values
  ('b1200000-0000-4000-8000-000000000010', 'b1000000-0000-4000-8000-000000000001', true),
  ('b1200000-0000-4000-8000-000000000011', 'b1000000-0000-4000-8000-000000000001', true)
on conflict (id) do nothing;

-- Shared field_agent data_sources (linked to reconciled submissions below)
insert into data_sources (id, source_type, notes) values
  ('b1300000-0000-4000-8000-000000000001', 'field_agent', 'Abuja pilot backbone — two-scout reconciled seed')
on conflict (id) do nothing;
