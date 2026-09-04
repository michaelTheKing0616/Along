-- pgTAP: cfg() resolution order corridor > city > country > global
create extension if not exists pgtap;

begin;
select plan(4);

-- Fixture: geo hierarchy for scoped overrides
insert into deployments (id, tenant_name) values
  ('b0000000-0000-4000-8000-000000000001', 'Cfg Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XT', 'Cfg Test Country', 'XXX', 'X', '+999', 'UTC', 'b0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'c0000000-0000-4000-8000-000000000001',
  'XT',
  'Cfg Test City',
  'cfg-test-city',
  st_setsrid(st_makepoint(7.4, 9.0), 4326)::geography,
  'live'
);

insert into corridors (id, city_id, name, slug, status)
values (
  'd0000000-0000-4000-8000-000000000001',
  'c0000000-0000-4000-8000-000000000001',
  'Cfg Test Corridor',
  'cfg-test-corridor',
  'live'
);

insert into app_config (key, scope_type, scope_id, value) values
  ('test.cfg.resolution', 'global', '*', '"global"'),
  ('test.cfg.resolution', 'country', 'XT', '"country"'),
  ('test.cfg.resolution', 'city', 'c0000000-0000-4000-8000-000000000001', '"city"'),
  ('test.cfg.resolution', 'corridor', 'd0000000-0000-4000-8000-000000000001', '"corridor"');

select is(
  cfg(
    'test.cfg.resolution',
    'c0000000-0000-4000-8000-000000000001'::uuid,
    'd0000000-0000-4000-8000-000000000001'::uuid
  ),
  '"corridor"'::jsonb,
  'corridor scope wins when all scopes present'
);

delete from app_config
where key = 'test.cfg.resolution' and scope_type = 'corridor';

select is(
  cfg('test.cfg.resolution', 'c0000000-0000-4000-8000-000000000001'::uuid, null),
  '"city"'::jsonb,
  'city scope wins over country and global when corridor absent'
);

delete from app_config
where key = 'test.cfg.resolution' and scope_type = 'city';

select is(
  cfg('test.cfg.resolution', 'c0000000-0000-4000-8000-000000000001'::uuid, null),
  '"country"'::jsonb,
  'country scope wins over global when city absent'
);

delete from app_config
where key = 'test.cfg.resolution' and scope_type = 'country';

select is(
  cfg('test.cfg.resolution', 'c0000000-0000-4000-8000-000000000001'::uuid, null),
  '"global"'::jsonb,
  'global scope is fallback when no narrower override exists'
);

select * from finish();
rollback;
