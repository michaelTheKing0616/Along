-- pgTAP: audit_log + audit_admin_write (doc 02 §15, P0-A-08)
create extension if not exists pgtap;

begin;
select plan(5);

-- superadmin: f0000000-0000-4000-8000-000000000001
insert into auth.users (id, aud, role, phone) values
  ('f0000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000000099');

select set_config('request.jwt.claim.sub', 'f0000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

insert into admin_users (id, role, deployment_id)
values (
  'f0000000-0000-4000-8000-000000000001',
  'superadmin',
  'a0000000-0000-4000-8000-000000000001'
);

update app_config
set value = '"0.080"'::jsonb
where key = 'commission.rate' and scope_type = 'global' and scope_id = '*';

select is(
  (select count(*)::int from audit_log where target_type = 'app_config' and action = 'update'),
  1,
  'admin update writes audit row'
);

select is(
  (select actor_id from audit_log where target_type = 'app_config' and action = 'update' limit 1),
  'f0000000-0000-4000-8000-000000000001'::uuid,
  'audit row captures actor_id from auth.uid()'
);

select is(
  (select target_id from audit_log where target_type = 'app_config' and action = 'update' limit 1),
  'commission.rate:global:*',
  'audit target_id encodes composite app_config key'
);

select throws_ok(
  $$ update audit_log set action = 'tampered' where id = (select min(id) from audit_log) $$,
  '42501',
  null,
  'audit_log rejects update (append-only)'
);

select throws_ok(
  $$ delete from audit_log where id = (select min(id) from audit_log) $$,
  '42501',
  null,
  'audit_log rejects delete (append-only)'
);

select * from finish();
rollback;
