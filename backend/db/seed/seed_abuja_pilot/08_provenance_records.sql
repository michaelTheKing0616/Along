-- Reconciliation records backing field_verified graph rows (Phase 0 two-scout gate).
-- Represents reconciled ingest from P0-E-03 field forms (synthetic reconciled values).

insert into field_submissions (
  id, city_id, corridor_id, scout_profile_id, form_id, form_version, submission_uid,
  payload, entity_type, entity_key, submitted_at, status
) values
  (
    'b1500000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000011',
    'b1200000-0000-4000-8000-000000000010',
    'along_route_v1', '1', 'abuja-seed-scout-a-nyanya-car',
    '{"origin_park":"nyanya-park","destination_park":"berger-junction","mode":"car"}'::jsonb,
    'route', 'route:abuja:nyanya-cbd:car', '2026-09-01T08:00:00Z', 'reconciled'
  ),
  (
    'b1500000-0000-4000-8000-000000000002',
    'b1000000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000011',
    'b1200000-0000-4000-8000-000000000011',
    'along_route_v1', '1', 'abuja-seed-scout-b-nyanya-car',
    '{"origin_park":"nyanya-park","destination_park":"berger-junction","mode":"car"}'::jsonb,
    'route', 'route:abuja:nyanya-cbd:car', '2026-09-01T09:00:00Z', 'reconciled'
  )
on conflict (submission_uid) do nothing;

insert into field_reconciliations (
  id, entity_type, entity_key, submission_a, submission_b, variance, status,
  published_target_type, published_target_id
) values (
  'b1510000-0000-4000-8000-000000000001',
  'route',
  'route:abuja:nyanya-cbd:car',
  'b1500000-0000-4000-8000-000000000001',
  'b1500000-0000-4000-8000-000000000002',
  '{"location_m":12,"fare_pct":0.02}'::jsonb,
  'matched',
  'route',
  'b1400000-0000-4000-8000-000000000011'
)
on conflict (id) do nothing;

update data_sources
set field_submission_id = 'b1500000-0000-4000-8000-000000000001'
where id = 'b1300000-0000-4000-8000-000000000001';
