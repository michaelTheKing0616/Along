-- pgTAP: TS-LEDGER-09 — agent settlement codes (valid, replay, wrong city)
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0f200000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000007110'),
  ('0f200000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000007111'),
  ('0f300000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000007120')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f200000-0000-4000-8000-000000000010', '+2348000007110', 'Agent Driver'),
  ('0f200000-0000-4000-8000-000000000011', '+2348000007111', 'Zaria Agent'),
  ('0f300000-0000-4000-8000-000000000010', '+2348000007120', 'Other City Agent')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000010', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'AGD01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

-- Second city for wrong-city agent test (must exist before settlement_agents FK)
insert into deployments (id, tenant_name) values
  ('c0000000-0000-4000-8000-000000000099', 'Agent Test Tenant')
on conflict (id) do nothing;

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('NG', 'Nigeria', 'NGN', E'₦', '+234', 'Africa/Lagos', 'c0000000-0000-4000-8000-000000000099', true)
on conflict (code) do nothing;

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'c0000000-0000-4000-8000-000000000001',
  'NG',
  'Agent Other City',
  'agent-other-city',
  st_setsrid(st_makepoint(7.4, 9.0), 4326)::geography,
  'live'
) on conflict (id) do nothing;

insert into settlement_agents (id, profile_id, city_id, business_name, active) values
  ('0f800000-0000-4000-8000-000000000001', '0f200000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'Zaria POS', true),
  ('0f800000-0000-4000-8000-000000000002', '0f300000-0000-4000-8000-000000000010', 'c0000000-0000-4000-8000-000000000001', 'Other POS', true)
on conflict (id) do nothing;

-- Driver creates agent code
select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000010', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select set_config('test.agent_code', create_agent_code(200.00)->>'agent_code', true);

select ok(
  current_setting('test.agent_code') is not null,
  'TS-LEDGER-09: create_agent_code returns agent_code'
);

-- Valid agent redeems
select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000011', true);
set local role authenticated;

select ok(
  (confirm_agent_settlement(current_setting('test.agent_code'), 200.00)->>'ledger_entry_id') is not null,
  'TS-LEDGER-09: valid code posts digital_settlement_credit'
);

set local role postgres;

select is(
  (select count(*)::int from driver_ledger_entries
   where driver_id = '0f200000-0000-4000-8000-000000000010'
     and entry_type = 'digital_settlement_credit'
     and idempotency_key = format('agent:%s', current_setting('test.agent_code'))),
  1,
  'TS-LEDGER-09: exactly one ledger row for agent code'
);

-- Reused code → IDEMPOTENT_REPLAY
select throws_ok(
  format(
    $$ select confirm_agent_settlement(%L, 200.00) $$,
    current_setting('test.agent_code')
  ),
  'P0001',
  'IDEMPOTENT_REPLAY',
  'TS-LEDGER-09: reused code raises IDEMPOTENT_REPLAY'
);

-- Fresh code for wrong-city agent
select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000010', true);
set local role authenticated;

select set_config('test.other_code', create_agent_code(150.00)->>'agent_code', true);

select set_config('request.jwt.claim.sub', '0f300000-0000-4000-8000-000000000010', true);
set local role authenticated;

select throws_ok(
  format(
    $$ select confirm_agent_settlement(%L, 150.00) $$,
    current_setting('test.other_code')
  ),
  'P0001',
  'FORBIDDEN',
  'TS-LEDGER-09: agent from another city raises FORBIDDEN'
);

select * from finish();
rollback;
