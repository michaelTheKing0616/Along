-- pgTAP: P8-A-01 — corporate allocation, invoice generation, reconciliation (doc 02 §13)
create extension if not exists pgtap;

begin;
select plan(12);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

-- Fixture ids (corporate_accounts, corporate_members, corporate_trip_policies,
-- corporate_trip_allocations, corporate_invoices, invoice_lines)
insert into auth.users (id, aud, role, phone) values
  ('0f100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007101'),
  ('0f200000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007102')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f100000-0000-4000-8000-000000000001', '+2348000007101', 'Corp Rider'),
  ('0f200000-0000-4000-8000-000000000001', '+2348000007102', 'Corp Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into riders (id, home_city_id) values
  ('0f100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f200000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'CORP01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('0f300000-0000-4000-8000-000000000001', 'NG', 'car', 'CORP-01', 4, '0f200000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('0f200000-0000-4000-8000-000000000001', '0f300000-0000-4000-8000-000000000001', true)
on conflict do nothing;

insert into corporate_accounts (
  id, deployment_id, name, billing_email, status, monthly_budget, currency
) values (
  '0f400000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000001',
  'Acme Corp',
  'billing@acme.test',
  'active',
  50000.00,
  'NGN'
);

insert into corporate_members (corporate_account_id, rider_id, employee_ref, department, active)
values (
  '0f400000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  'E-1001',
  'Operations',
  true
);

insert into corporate_trip_policies (
  id, corporate_account_id, name, subsidy_pct, max_per_trip, active
) values (
  '0f500000-0000-4000-8000-000000000001',
  '0f400000-0000-4000-8000-000000000001',
  'Standard 50%',
  0.5000,
  200.00,
  true
);

insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f600000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  '0f200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 320.00, 'NGN', '[{"kind":"through","amount":320}]'::jsonb, 0.900,
  now() + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0f700000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'planning',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{"candidate_id":"0f800000-0000-4000-8000-000000000001","source":"parked","kind":"direct","legs":[{"leg_index":0}]}'::jsonb
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id
) values (
  '0f900000-0000-4000-8000-000000000001',
  '0f700000-0000-4000-8000-000000000001',
  '0f100000-0000-4000-8000-000000000001',
  '0f200000-0000-4000-8000-000000000001',
  '0f300000-0000-4000-8000-000000000001',
  'car',
  '0f600000-0000-4000-8000-000000000001',
  320.00, 'NGN', 2, 0.075,
  'requested',
  now() + interval '25 seconds',
  'color.naMe.green', 'diamond',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005'
);

select trip_transition(
  '0f900000-0000-4000-8000-000000000001'::uuid,
  'accepted'::trip_status,
  'driver'::actor_type,
  '0f200000-0000-4000-8000-000000000001'::uuid
);

select set_config('request.jwt.claim.sub', '0f200000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select verify_trip_pin('0f900000-0000-4000-8000-000000000001'::uuid,
  (select pin::text from trip_pins where trip_id = '0f900000-0000-4000-8000-000000000001'));
select start_trip('0f900000-0000-4000-8000-000000000001'::uuid);
select complete_trip('0f900000-0000-4000-8000-000000000001'::uuid);

-- Allocation on completion: 50% of 320 capped at 200 → 160
select is(
  (select subsidized_amount from corporate_trip_allocations where trip_id = '0f900000-0000-4000-8000-000000000001'),
  160.00::numeric,
  'TS-CORP-01: completion creates corporate_trip_allocations with policy subsidy'
);

-- Idempotent on trip_id unique
select is(
  corporate_allocate_trip('0f900000-0000-4000-8000-000000000001'::uuid),
  (select id from corporate_trip_allocations where trip_id = '0f900000-0000-4000-8000-000000000001'),
  'TS-CORP-01: corporate_allocate_trip is idempotent on trip_id'
);

select is(
  (select count(*)::int from corporate_trip_allocations where trip_id = '0f900000-0000-4000-8000-000000000001'),
  1,
  'TS-CORP-01: exactly one allocation row per trip'
);

-- Invoice generation for period containing the allocation
select set_config('request.jwt.claim.sub', '', true);

select generate_corporate_invoices(
  date_trunc('month', now() at time zone 'UTC') at time zone 'UTC',
  (date_trunc('month', now() at time zone 'UTC') + interval '1 month') at time zone 'UTC'
);

select ok(
  exists (
    select 1
    from corporate_invoices ci
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
      and ci.total = 160.00
  ),
  'TS-CORP-01: monthly job creates corporate_invoices with allocation total'
);

select ok(
  exists (
    select 1
    from invoice_lines il
    join corporate_invoices ci on ci.id = il.invoice_id
    join corporate_trip_allocations a on a.id = il.allocation_id
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
      and il.amount = 160.00
      and a.trip_id = '0f900000-0000-4000-8000-000000000001'
  ),
  'TS-CORP-01: invoice_lines link allocations in period'
);

select ok(
  (
    select (reconcile_corporate_invoice(ci.id)->>'ok')::boolean
    from corporate_invoices ci
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
    limit 1
  ),
  'TS-CORP-01: reconcile passes when invoice total equals allocation sum'
);

-- Discrepancy: amount mismatch on a line
update invoice_lines il
set amount = amount + 1
from corporate_invoices ci
where il.invoice_id = ci.id
  and ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001';

select ok(
  not (
    select (reconcile_corporate_invoice(ci.id)->>'ok')::boolean
    from corporate_invoices ci
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
    limit 1
  ),
  'TS-CORP-01: reconcile FAILS on line amount mismatch'
);

-- Restore line amount, then remove a line (missing allocation)
update invoice_lines il
set amount = amount - 1
from corporate_invoices ci
where il.invoice_id = ci.id
  and ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001';

delete from invoice_lines il
using corporate_invoices ci
where il.invoice_id = ci.id
  and ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001';

select ok(
  not (
    select (reconcile_corporate_invoice(ci.id)->>'ok')::boolean
    from corporate_invoices ci
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
    limit 1
  ),
  'TS-CORP-01: reconcile FAILS when allocation line is missing'
);

-- Extra line pointing at allocation already on a second invoice is covered by re-insert + duplicate;
-- add orphan extra line with wrong amount on re-built invoice
insert into invoice_lines (invoice_id, allocation_id, amount)
select ci.id, a.id, a.subsidized_amount
from corporate_invoices ci
join corporate_trip_allocations a on a.corporate_account_id = ci.corporate_account_id
where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001';

select ok(
  (
    select (reconcile_corporate_invoice(ci.id)->>'ok')::boolean
    from corporate_invoices ci
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
    limit 1
  ),
  'TS-CORP-01: reconcile passes again after lines restored'
);

-- Extra line: allocation outside invoice period linked on invoice
insert into fare_quotes (
  id, rider_id, driver_id, route_id, from_stage_id, to_stage_id,
  mode_code, tier, amount, currency, components, confidence, expires_at
) values (
  '0f600000-0000-4000-8000-000000000002',
  '0f100000-0000-4000-8000-000000000001',
  '0f200000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  'car', 2, 100.00, 'NGN', '[]'::jsonb, 0.900,
  timestamptz '2020-01-01 08:00:00+00' + interval '10 minutes'
);

insert into journeys (
  id, rider_id, city_id, status, origin, destination, plan_snapshot
) values (
  '0f700000-0000-4000-8000-000000000002',
  '0f100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'completed',
  st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography,
  st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
  '{}'::jsonb
);

insert into trips (
  id, journey_id, rider_id, driver_id, vehicle_id, mode_code,
  fare_quote_id, fare_shown, fare_currency, fare_tier, commission_rate,
  status, expires_at, id_signal_color, id_signal_shape,
  boarding_stage_id, alighting_stage_id, ended_at
) values (
  '0f900000-0000-4000-8000-000000000002',
  '0f700000-0000-4000-8000-000000000002',
  '0f100000-0000-4000-8000-000000000001',
  '0f200000-0000-4000-8000-000000000001',
  '0f300000-0000-4000-8000-000000000001',
  'car',
  '0f600000-0000-4000-8000-000000000002',
  100.00, 'NGN', 2, 0.075,
  'completed',
  timestamptz '2020-01-01 08:00:00+00' + interval '25 seconds',
  'color.naMe.blue', 'circle',
  '0a040000-0000-4000-8000-000000000001',
  '0a040000-0000-4000-8000-000000000005',
  timestamptz '2020-01-15 12:00:00+00'
);

insert into corporate_trip_allocations (
  id, trip_id, corporate_account_id, policy_id, subsidized_amount, created_at
) values (
  '0fa00000-0000-4000-8000-000000000001',
  '0f900000-0000-4000-8000-000000000002',
  '0f400000-0000-4000-8000-000000000001',
  '0f500000-0000-4000-8000-000000000001',
  25.00,
  timestamptz '2020-01-15 12:00:00+00'
);

insert into invoice_lines (invoice_id, allocation_id, amount)
select ci.id, '0fa00000-0000-4000-8000-000000000001', 25.00
from corporate_invoices ci
where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
limit 1;

select ok(
  not (
    select (reconcile_corporate_invoice(ci.id)->>'ok')::boolean
    from corporate_invoices ci
    where ci.corporate_account_id = '0f400000-0000-4000-8000-000000000001'
    limit 1
  ),
  'TS-CORP-01: reconcile FAILS on extra out-of-period invoice line'
);

-- RLS smoke: corporate_admin sees own account only
insert into auth.users (id, aud, role, phone) values
  ('0fb00000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007199')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0fb00000-0000-4000-8000-000000000001', '+2348000007199', 'Corp Admin')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id, corporate_account_id) values
  ('0fb00000-0000-4000-8000-000000000001', 'corporate_admin', 'a0000000-0000-4000-8000-000000000001', '0f400000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, corporate_account_id = excluded.corporate_account_id;

select set_config('request.jwt.claim.sub', '0fb00000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::int from corporate_accounts),
  1,
  'TS-CORP-01: corporate_admin RLS scoped to own corporate_accounts row'
);

select ok(
  exists (select 1 from audit_log where target_type = 'corporate_accounts'),
  'TS-CORP-01: audit_admin_write logs corporate_accounts admin inserts'
);

select * from finish();
rollback;
