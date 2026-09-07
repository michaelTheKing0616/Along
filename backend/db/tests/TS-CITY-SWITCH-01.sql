-- P9-B-01: set_home_city / set_driver_city validate active cities and own row.

begin;
select plan(4);

\set abuja_id 'b1000000-0000-4000-8000-000000000001'
\set zaria_id '0a000000-0000-4000-8000-000000000001'
\set rider_id 'a1000000-0000-4000-8000-000000000001'
\set driver_id 'a2000000-0000-4000-8000-000000000001'

insert into profiles (id, phone_e164, display_name)
values
  (:'rider_id', '+2348000000101', 'City Switch Rider'),
  (:'driver_id', '+2348000000102', 'City Switch Driver')
on conflict (id) do nothing;

insert into riders (id, home_city_id)
values (:'rider_id', :'abuja_id')
on conflict (id) do update set home_city_id = excluded.home_city_id;

insert into drivers (id, city_id)
values (:'driver_id', :'abuja_id')
on conflict (id) do update set city_id = excluded.city_id;

set local role authenticated;
select set_config('request.jwt.claim.sub', :'rider_id', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$ select set_home_city('0a000000-0000-4000-8000-000000000001'::uuid) $$,
  'rider can set home city to active Zaria-Test'
);

select is(
  (select home_city_id from riders where id = :'rider_id'),
  :'zaria_id'::uuid,
  'home_city_id persisted after set_home_city'
);

select set_config('request.jwt.claim.sub', :'driver_id', true);

select lives_ok(
  $$ select set_driver_city('0a000000-0000-4000-8000-000000000001'::uuid) $$,
  'driver can set city to active Zaria-Test'
);

select is(
  (select city_id from drivers where id = :'driver_id'),
  :'zaria_id'::uuid,
  'city_id persisted after set_driver_city'
);

select * from finish();
rollback;
