-- pgTAP: TS-PLAN-10 — roaming direction plausibility (P1-A-04)
create extension if not exists pgtap;

begin;
select plan(3);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

-- Destination: Test Park Beta (7.705, 11.065)
-- Driver positions near Test Junction Gamma (7.701, 11.061)

select ok(
  presence_plausible(
    st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
    45::smallint,
    5::numeric,
    '0a040000-0000-4000-8000-000000000002'::uuid,
    null,
    null,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '0a000000-0000-4000-8000-000000000001'::uuid
  ),
  'TS-PLAN-10: heading toward destination is plausible'
);

select ok(
  not presence_plausible(
    st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
    225::smallint,
    5::numeric,
    '0a040000-0000-4000-8000-000000000002'::uuid,
    null,
    null,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '0a000000-0000-4000-8000-000000000001'::uuid
  ),
  'TS-PLAN-10: heading away from destination is not plausible'
);

select ok(
  presence_plausible(
    st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
    225::smallint,
    0.5::numeric,
    '0a040000-0000-4000-8000-000000000002'::uuid,
    null,
    null,
    st_setsrid(st_makepoint(7.705, 11.065), 4326)::geography,
    '0a000000-0000-4000-8000-000000000001'::uuid
  ),
  'TS-PLAN-10: stationary vehicle is plausible regardless of heading'
);

select * from finish();
rollback;
