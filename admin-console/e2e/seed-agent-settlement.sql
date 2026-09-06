-- E2E agent settlement seed (P4-E-01)
-- Password: AlongE2E2026! (same as seed-e2e-admins.sql)

delete from settlements
where driver_id = 'a0000000-0000-4000-8000-000000000002';

delete from driver_ledger_entries
where driver_id = 'a0000000-0000-4000-8000-000000000002';

delete from settlement_agents
where id = 'a0000000-0000-4000-8000-000000000010';

delete from drivers
where id = 'a0000000-0000-4000-8000-000000000002';

delete from profiles
where id in (
  'a0000000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000002'
);

delete from auth.identities
where user_id in (
  'a0000000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000002'
);

delete from auth.users
where id in (
  'a0000000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000002'
);

do $$
declare
  v_password text := crypt('AlongE2E2026!', gen_salt('bf'));
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) values
  (
    '00000000-0000-0000-0000-000000000000',
    'a0000000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'e2e-settlement-agent@along.local',
    v_password,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"E2E Settlement Agent"}'::jsonb,
    now(), now(), '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a0000000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'e2e-settlement-driver@along.local',
    v_password,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"E2E Settlement Driver"}'::jsonb,
    now(), now(), '', '', '', ''
  )
  on conflict (id) do update
    set encrypted_password = excluded.encrypted_password,
        email = excluded.email;

  insert into auth.identities (
    provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values
  (
    'a0000000-0000-4000-8000-000000000001',
    'a0000000-0000-4000-8000-000000000001',
    jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000001', 'email', 'e2e-settlement-agent@along.local'),
    'email',
    now(), now(), now()
  ),
  (
    'a0000000-0000-4000-8000-000000000002',
    'a0000000-0000-4000-8000-000000000002',
    jsonb_build_object('sub', 'a0000000-0000-4000-8000-000000000002', 'email', 'e2e-settlement-driver@along.local'),
    'email',
    now(), now(), now()
  )
  on conflict (provider_id, provider) do nothing;
end $$;

insert into profiles (id, phone_e164, display_name) values
  ('a0000000-0000-4000-8000-000000000001', '+2348000000301', 'E2E Settlement Agent'),
  ('a0000000-0000-4000-8000-000000000002', '+2348000000302', 'E2E Settlement Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, driver_code) values
  (
    'a0000000-0000-4000-8000-000000000002',
    'b1000000-0000-4000-8000-000000000001',
    'verified',
    'good_standing',
    'E2EAG01'
  )
on conflict (id) do update set
  city_id = excluded.city_id,
  driver_code = excluded.driver_code;

insert into settlement_agents (id, profile_id, city_id, business_name, active) values
  (
    'a0000000-0000-4000-8000-000000000010',
    'a0000000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000001',
    'E2E Abuja POS',
    true
  )
on conflict (id) do update set
  profile_id = excluded.profile_id,
  city_id = excluded.city_id,
  business_name = excluded.business_name,
  active = excluded.active;
