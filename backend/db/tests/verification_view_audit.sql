-- pgTAP: P1-D-01 — admin_log_view_document writes audit_log row
create extension if not exists pgtap;

begin;
select plan(3);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select set_config('app.settings.identity_hash_pepper', 'along-test-pepper-do-not-commit', true);

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000020', 'authenticated', 'authenticated', '+2348000001020'),
  ('b0000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000001998')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code) values
  ('0a100000-0000-4000-8000-000000000020', '0a000000-0000-4000-8000-000000000001', 'pending', 'good_standing', 'TSTVR020')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into admin_users (id, role, deployment_id) values
  ('b0000000-0000-4000-8000-000000000003', 'verifier', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, disabled_at = null;

insert into driver_verifications (
  id, driver_id, country_code, document_type, status, storage_path
) values (
  '0a200000-0000-4000-8000-000000000001',
  '0a100000-0000-4000-8000-000000000020',
  'NG',
  'nin',
  'pending',
  '0a100000-0000-4000-8000-000000000020/nin/front.jpg'
) on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', 'b0000000-0000-4000-8000-000000000003', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (admin_log_view_document('0a200000-0000-4000-8000-000000000001'::uuid)->>'logged')::boolean,
  'admin_log_view_document returns logged=true'
);

set local role postgres;

select is(
  (select count(*)::int from audit_log
   where action = 'view_document'
     and target_type = 'driver_verifications'
     and target_id = '0a200000-0000-4000-8000-000000000001'),
  1,
  'view_document audit row inserted'
);

select is(
  (select actor_id from audit_log
   where action = 'view_document'
     and target_id = '0a200000-0000-4000-8000-000000000001'
   limit 1),
  'b0000000-0000-4000-8000-000000000003'::uuid,
  'view_document audit actor is verifier admin'
);

select * from finish();
rollback;
