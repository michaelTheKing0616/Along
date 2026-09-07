-- pgTAP: P6-D-04 — admin invite/disable RPCs + audit.page_size config
create extension if not exists pgtap;

begin;
select plan(6);

insert into auth.users (id, aud, role, phone, email) values
  ('d0000000-0000-4000-8000-000000000201', 'authenticated', 'authenticated', null, 'p6-super@along.local')
on conflict (id) do nothing;

insert into profiles (id, display_name) values
  ('d0000000-0000-4000-8000-000000000201', 'P6 Super')
on conflict (id) do update set display_name = excluded.display_name;

insert into admin_users (id, role, deployment_id) values
  ('d0000000-0000-4000-8000-000000000201', 'superadmin', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, disabled_at = null;

select set_config('request.jwt.claim.sub', 'd0000000-0000-4000-8000-000000000201', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select ok(
  cfg_num('audit.page_size') >= 10,
  'audit.page_size resolves after migration 00058'
);

select ok(
  exists (select 1 from app_config_keys where key = 'audit.page_size'),
  'audit.page_size registered in app_config_keys'
);

select lives_ok(
  $$ select admin_invite_admin(
    'p6-invited@along.local',
    'analyst'::admin_role,
    'a0000000-0000-4000-8000-000000000001'::uuid,
    null,
    'Invited Analyst'
  ) $$,
  'admin_invite_admin creates auth user + admin_users row'
);

select is(
  (select count(*)::int from admin_users au join auth.users u on u.id = au.id where u.email = 'p6-invited@along.local'),
  1,
  'invited admin exists'
);

select is(
  (select count(*)::int from audit_log where target_type = 'admin_users' and action = 'insert'
     and target_id = (select id::text from auth.users where email = 'p6-invited@along.local')),
  1,
  'invite writes audit_log via admin_users trigger'
);

select lives_ok(
  $$ select admin_disable_admin((select id from auth.users where email = 'p6-invited@along.local')) $$,
  'admin_disable_admin soft-disables invited admin'
);

select * from finish();
rollback;
