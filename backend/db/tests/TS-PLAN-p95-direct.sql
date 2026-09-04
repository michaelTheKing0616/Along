-- pgTAP: planner_direct_candidates p95 budget on Zaria-Test seed (P1-A-06)
create extension if not exists pgtap;

begin;
select plan(1);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

do $perf$
declare
  v_start timestamptz;
  v_elapsed_ms double precision;
  v_times double precision[] := '{}';
  i int;
begin
  for i in 1..100 loop
    v_start := clock_timestamp();
    perform *
    from planner_direct_candidates_latlng(
      11.060 + (random() * 0.002),
      7.700 + (random() * 0.002),
      11.065 + (random() * 0.002),
      7.705 + (random() * 0.002),
      '0a000000-0000-4000-8000-000000000001'::uuid,
      '{"women_only": false, "load": {"flagged": false}}'::jsonb
    );
    v_elapsed_ms := extract(epoch from (clock_timestamp() - v_start)) * 1000;
    v_times := array_append(v_times, v_elapsed_ms);
  end loop;

  create temp table planner_perf as
  select percentile_cont(0.95) within group (order by t) as p95_ms
  from unnest(v_times) as u(t);
end;
$perf$;

select ok(
  (select p95_ms <= 800 from planner_perf),
  'TS-PLAN-09-lite: planner_direct_candidates p95 <= 800 ms on seed (100 samples)'
);

select * from finish();
rollback;
