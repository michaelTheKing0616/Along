-- pgTAP: TS-FARE-08 on Abuja pilot seed (ledger follow-up P0-A-04 / P0-E-04)
create extension if not exists pgtap;

begin;
\ir ../seed/seed_abuja_pilot/load.sql

select plan(1);

create temp table abuja_fare_perf (elapsed_ms numeric);

do $$
declare
  v_route record;
  v_from uuid;
  v_to uuid;
  v_from_seq int;
  v_to_seq int;
  v_t0 timestamptz;
  v_t1 timestamptz;
  i int;
  v_pairs int := 0;
begin
  while v_pairs < 1000 loop
    select r.id, r.mode_code into v_route
    from routes r
    where r.city_id = 'b1000000-0000-4000-8000-000000000001'
      and r.active
    order by random()
    limit 1;

    select rs_from.id, rs_from.sequence, rs_to.id, rs_to.sequence
    into v_from, v_from_seq, v_to, v_to_seq
    from route_stages rs_from
    join route_stages rs_to on rs_to.route_id = rs_from.route_id and rs_to.sequence > rs_from.sequence
    where rs_from.route_id = v_route.id
    order by random()
    limit 1;

    v_t0 := clock_timestamp();
    perform resolve_fare(
      p_route_id := v_route.id,
      p_from_stage_id := v_from,
      p_to_stage_id := v_to,
      p_mode_code := v_route.mode_code,
      p_city_id := 'b1000000-0000-4000-8000-000000000001'
    );
    v_t1 := clock_timestamp();

    insert into abuja_fare_perf (elapsed_ms)
    values (extract(epoch from (v_t1 - v_t0)) * 1000);

    v_pairs := v_pairs + 1;
  end loop;
end $$;

select ok(
  (select percentile_cont(0.95) within group (order by elapsed_ms) from abuja_fare_perf) <= 150,
  'TS-FARE-08: p95 resolve_fare <= 150 ms over 1,000 random pairs on Abuja seed'
);

select * from finish();
rollback;
