-- pgTAP: P11-A-01 — city-scoped admin reads for profiles/riders; trips city_admin parity
create extension if not exists pgtap;

begin;
select plan(14);

insert into cities (id, country_code, name, slug, centroid, status)
values
  (
    'fa100000-0000-4000-8000-000000000001',
    'NG',
    'Authz Alpha',
    'authz-alpha',
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    'live'
  ),
  (
    'fa100000-0000-4000-8000-000000000002',
    'NG',
    'Authz Beta',
    'authz-beta',
    st_setsrid(st_makepoint(7.70, 9.15), 4326)::geography,
    'live'
  );

insert into auth.users (id, aud, role, phone) values
  ('fa200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000009101'),
  ('fa200000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000009102'),
  ('fa200000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', '+2348000009103'),
  ('fa200000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000009110'),
  ('fa200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000009111');

insert into profiles (id, phone_e164, display_name) values
  ('fa200000-0000-4000-8000-000000000002', '+2348000009102', 'Alpha Driver Profile'),
  ('fa200000-0000-4000-8000-000000000003', '+2348000009103', 'Beta Driver Profile'),
  ('fa200000-0000-4000-8000-000000000010', '+2348000009110', 'Alpha Rider Profile'),
  ('fa200000-0000-4000-8000-000000000011', '+2348000009111', 'Beta Rider Profile')
on conflict (id) do update set
  phone_e164 = excluded.phone_e164,
  display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('fa200000-0000-4000-8000-000000000010', 'fa100000-0000-4000-8000-000000000001'),
  ('fa200000-0000-4000-8000-000000000011', 'fa100000-0000-4000-8000-000000000002');

insert into admin_users (id, role, city_scope)
values (
  'fa200000-0000-4000-8000-000000000001',
  'city_admin',
  array['fa100000-0000-4000-8000-000000000001']::uuid[]
);

insert into drivers (id, city_id) values
  ('fa200000-0000-4000-8000-000000000002', 'fa100000-0000-4000-8000-000000000001'),
  ('fa200000-0000-4000-8000-000000000003', 'fa100000-0000-4000-8000-000000000002');

select set_config('request.jwt.claim.sub', 'fa200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select is(
  (select count(*)::int from profiles where id = 'fa200000-0000-4000-8000-000000000002'),
  1,
  'city_admin can read driver profile in scoped city'
);

select is(
  (select count(*)::int from profiles where id = 'fa200000-0000-4000-8000-000000000003'),
  0,
  'city_admin cannot read driver profile in another city'
);

select is(
  (select count(*)::int from riders where id = 'fa200000-0000-4000-8000-000000000010'),
  1,
  'city_admin can read rider in scoped city'
);

select is(
  (select count(*)::int from riders where id = 'fa200000-0000-4000-8000-000000000011'),
  0,
  'city_admin cannot read rider in another city'
);

reset role;

select ok(
  exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'trips'
      and p.policyname = 'trips_select_admin'
      and coalesce(p.qual, '') like '%city_admin%'
  ),
  'trips_select_admin includes city_admin role'
);

select ok(
  exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = 'profiles'
      and p.policyname = 'profiles_select_admin'
      and coalesce(p.qual, '') like '%admin_can_access_profile%'
  ),
  'profiles_select_admin uses admin_can_access_profile scope'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'private' and c.relname = 'guarantor_ack_tokens'),
  'private.guarantor_ack_tokens has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'private' and c.relname = 'payment_webhook_raw'),
  'private.payment_webhook_raw has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'private' and c.relname = 'qr_resolve_rate_buckets'),
  'private.qr_resolve_rate_buckets has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'private' and c.relname = 'api_rate_windows'),
  'private.api_rate_windows has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'itineraries'),
  'public.itineraries has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'journey_transfer_walks'),
  'public.journey_transfer_walks has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'trip_dispatch_context'),
  'public.trip_dispatch_context has RLS enabled'
);

select ok(
  (select c.relrowsecurity from pg_class c
   join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'trip_shares'),
  'public.trip_shares has RLS enabled'
);

select * from finish();
rollback;
