-- Dev/staging superadmin bootstrap (P0-A-08).
-- NOT applied by default on `supabase db reset` — run manually when you need a local admin login.
--
-- Local:
--   psql "$DATABASE_URL" -f backend/db/seed/seed_admin_dev.sql
--
-- Staging:
--   Manual ops runbook only — not wired into supabase config seed paths or CI auto-apply.
--   Run once per environment after migrations when an admin login is needed.
--   Replace the password before any shared/staging use; credentials here are dev-only placeholders.
--
-- Sign-in (local Supabase Auth):
--   Email:    dev-superadmin@along.local
--   Password: AlongDevOnly2026!

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) values (
  '00000000-0000-0000-0000-000000000000',
  'b0000000-0000-4000-8000-000000000001',
  'authenticated',
  'authenticated',
  'dev-superadmin@along.local',
  crypt('AlongDevOnly2026!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Dev Superadmin"}'::jsonb,
  now(),
  now(),
  '',
  '',
  '',
  ''
) on conflict (id) do nothing;

insert into auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
) values (
  'b0000000-0000-4000-8000-000000000001',
  'b0000000-0000-4000-8000-000000000001',
  jsonb_build_object(
    'sub', 'b0000000-0000-4000-8000-000000000001',
    'email', 'dev-superadmin@along.local'
  ),
  'email',
  now(),
  now(),
  now()
) on conflict (provider_id, provider) do nothing;

insert into admin_users (id, role, deployment_id)
values (
  'b0000000-0000-4000-8000-000000000001',
  'superadmin',
  'a0000000-0000-4000-8000-000000000001'
) on conflict (id) do update
  set role = excluded.role,
      deployment_id = excluded.deployment_id,
      disabled_at = null;
