-- E2E admin users for Playwright (P0-D-01). Applied by check_playwright.sh after db reset.
-- Password for all: AlongE2E2026!

delete from auth.mfa_factors
where user_id in (
  select id from auth.users
  where email like 'e2e-%@along.local'
);

delete from admin_users
where id in (
  select id from auth.users
  where email like 'e2e-%@along.local'
);

delete from auth.identities
where user_id in (
  select id from auth.users
  where email like 'e2e-%@along.local'
);

delete from auth.users
where email like 'e2e-%@along.local';

do $$
declare
  v_password text := crypt('AlongE2E2026!', gen_salt('bf'));
  v_users jsonb := '[
    {"id":"b0000000-0000-4000-8000-000000000101","email":"e2e-superadmin@along.local","role":"superadmin"},
    {"id":"b0000000-0000-4000-8000-000000000102","email":"e2e-finance@along.local","role":"finance"},
    {"id":"b0000000-0000-4000-8000-000000000103","email":"e2e-verifier@along.local","role":"verifier"},
    {"id":"b0000000-0000-4000-8000-000000000104","email":"e2e-analyst@along.local","role":"analyst"},
    {"id":"b0000000-0000-4000-8000-000000000105","email":"e2e-ops-agent@along.local","role":"ops_agent"}
  ]'::jsonb;
  v_user jsonb;
begin
  for v_user in select * from jsonb_array_elements(v_users)
  loop
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      (v_user->>'id')::uuid,
      'authenticated',
      'authenticated',
      v_user->>'email',
      v_password,
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('display_name', v_user->>'role'),
      now(),
      now(),
      '', '', '', ''
    ) on conflict (id) do update
      set encrypted_password = excluded.encrypted_password,
          email = excluded.email;

    insert into auth.identities (
      provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      v_user->>'id',
      (v_user->>'id')::uuid,
      jsonb_build_object('sub', v_user->>'id', 'email', v_user->>'email'),
      'email',
      now(), now(), now()
    ) on conflict (provider_id, provider) do nothing;

    insert into admin_users (id, role, deployment_id)
    values (
      (v_user->>'id')::uuid,
      (v_user->>'role')::admin_role,
      'a0000000-0000-4000-8000-000000000001'
    ) on conflict (id) do update
      set role = excluded.role,
          deployment_id = excluded.deployment_id,
          disabled_at = null;
  end loop;
end $$;
