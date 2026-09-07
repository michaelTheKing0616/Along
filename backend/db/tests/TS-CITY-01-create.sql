-- TS-CITY-01: Generic city onboarding via admin_create_city (P9-E-01)
-- Requires seed_core applied on the target database (NG country active).
create extension if not exists pgtap;

begin;

select plan(5);

insert into auth.users (id, aud, role, phone) values
  ('0f000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000000102')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id) values
  ('0f000000-0000-4000-8000-000000000002', 'superadmin', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', '0f000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  admin_create_city(
    'CLI Test City',
    'cli-test-city',
    'NG',
    10.510,
    7.417,
    'Test fixture',
    'alpha',
    jsonb_build_object('commission.rate', to_jsonb(0.06)),
    true
  )->>'action',
  'create',
  'dry-run returns create action for new slug'
);

select is(
  (
    admin_create_city(
      'CLI Test City',
      'cli-test-city',
      'NG',
      10.510,
      7.417,
      'Test fixture',
      'alpha',
      jsonb_build_object('commission.rate', to_jsonb(0.06)),
      false
    )->>'slug'
  ),
  'cli-test-city',
  'apply creates city row'
);

select ok(
  exists (select 1 from cities c where c.slug = 'cli-test-city'),
  'city row exists after apply'
);

select ok(
  exists (
    select 1
    from app_config ac
    join cities c on c.id::text = ac.scope_id
    where c.slug = 'cli-test-city'
      and ac.key = 'commission.rate'
      and ac.scope_type = 'city'
  ),
  'city config override applied'
);

select is(
  admin_create_city(
    'CLI Test City',
    'cli-test-city',
    'NG',
    10.510,
    7.417,
    null,
    'alpha',
    '{}'::jsonb,
    true
  )->>'action',
  'skip',
  'second dry-run skips existing slug'
);

select * from finish();
rollback;
