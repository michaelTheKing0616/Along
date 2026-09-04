-- E2E field reconciliation seed (P0-D-02).
-- Requires: seed_core (NG deployment), seed_abuja_pilot/00_city_and_corridors, seed-e2e-admins.

insert into auth.users (id, aud, role, phone) values
  ('c1000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000000201'),
  ('c1000000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000000202')
on conflict (id) do nothing;

insert into field_agents (id, city_id, active) values
  ('c1000000-0000-4000-8000-000000000010', 'b1000000-0000-4000-8000-000000000001', true),
  ('c1000000-0000-4000-8000-000000000011', 'b1000000-0000-4000-8000-000000000001', true)
on conflict (id) do nothing;

insert into field_submissions (
  id, city_id, scout_profile_id, form_id, form_version, submission_uid,
  payload, entity_type, entity_key, submitted_at, status
) values
  (
    'c1100000-0000-4000-8000-000000000020',
    'b1000000-0000-4000-8000-000000000001',
    'c1000000-0000-4000-8000-000000000010',
    'along_park_v1',
    '1',
    'e2e-scout-a-park-reconcile',
    '{"name":"E2E Reconcile Park","lat":9.061,"lng":7.411,"name_aliases":["E2E"]}'::jsonb,
    'park',
    'park:abuja:e2e-reconcile-park',
    now(),
    'received'
  ),
  (
    'c1100000-0000-4000-8000-000000000021',
    'b1000000-0000-4000-8000-000000000001',
    'c1000000-0000-4000-8000-000000000011',
    'along_park_v1',
    '1',
    'e2e-scout-b-park-reconcile',
    '{"name":"E2E Reconcile Park","lat":9.0611,"lng":7.4111,"name_aliases":["E2E"]}'::jsonb,
    'park',
    'park:abuja:e2e-reconcile-park',
    now(),
    'received'
  )
on conflict (submission_uid) do nothing;

-- Build matched two-scout reconciliation (no SQL publish — UI must call admin_publish_field_entity).
select reconcile_field_submission('c1100000-0000-4000-8000-000000000020');
select reconcile_field_submission('c1100000-0000-4000-8000-000000000021');

-- Ensure reconciliation is matched and unpublished for E2E.
update field_reconciliations
set status = 'matched',
    published_target_id = null,
    published_target_type = null
where entity_key = 'park:abuja:e2e-reconcile-park';
