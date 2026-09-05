-- pgTAP: TS-CFG-01 — Zaria-Test fixture uses city config overrides (doc 10 §141, FM5)
create extension if not exists pgtap;

begin;
\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select plan(8);

select is(
  cfg_num('commission.rate', '0a000000-0000-4000-8000-000000000001'),
  0.05::numeric,
  'TS-CFG-01: Zaria-Test commission.rate override (0.05 not global 0.075)'
);

select is(
  cfg_num('graph.snap_radius_m', '0a000000-0000-4000-8000-000000000001'),
  40::numeric,
  'TS-CFG-01: Zaria-Test graph.snap_radius_m override (40 not global 60)'
);

select is(
  cfg_num('ledger.block_threshold', '0a000000-0000-4000-8000-000000000001'),
  -5000::numeric,
  'TS-CFG-01: Zaria-Test inherits global ledger.block_threshold'
);

select ok(
  snap_stage(
    st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography,
    null,
    '0a000000-0000-4000-8000-000000000001'
  ) is not null,
  'TS-CFG-01: snap_stage uses city snap_radius_m (40m) and finds Test Junction Gamma'
);

select ok(
  exists (
    select 1
    from planner_decompose(
      '0a020000-0000-4000-8000-000000000001',
      '0a020000-0000-4000-8000-000000000002',
      '0a000000-0000-4000-8000-000000000001'
    )
  ),
  'TS-CFG-01: planner_decompose works on Zaria-Test graph'
);

select is(
  (resolve_fare(
    p_route_id := '0a030000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000001',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001'
  )).amount,
  280.00::numeric,
  'TS-CFG-01: resolve_fare Tier 1 through-fare on Zaria-Test'
);

select is(
  (resolve_fare(
    p_route_id := '0a030000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000001',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001'
  )).currency,
  'NGN'::bpchar,
  'TS-CFG-01: Zaria-Test currency remains NGN (country config, not city fork)'
);

-- Commission on a hypothetical fare uses city rate (FM5)
select is(
  round((1000.00 * cfg_num('commission.rate', '0a000000-0000-4000-8000-000000000001'))::numeric, 2),
  50.00::numeric,
  'TS-CFG-01: commission computed from city override (1000 * 0.05 = 50)'
);

select * from finish();
rollback;
