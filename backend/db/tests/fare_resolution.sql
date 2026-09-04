-- pgTAP: fare resolution (doc 04 §3, P0-A-04)
-- TS-FARE-01, TS-FARE-02, TS-FARE-03, TS-FARE-08
create extension if not exists pgtap;

begin;
select plan(10);

-- ---------------------------------------------------------------------------
-- Fixtures: 5-stage route with legs and one through-fare (S1→S4)
-- ---------------------------------------------------------------------------
insert into deployments (id, tenant_name)
values ('f0000000-0000-4000-8000-000000000001', 'Fare Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XF', 'Fare Test Country', 'NGN', E'₦', '+998', 'UTC', 'f0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'f0000000-0000-4000-8000-000000000002',
  'XF',
  'Fare Test City',
  'fare-test-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into data_sources (id, source_type)
values ('f0000000-0000-4000-8000-000000000020', 'admin');

insert into parks (id, city_id, name, location, source_id, verification_status, confidence_score)
values
  (
    'f0000000-0000-4000-8000-000000000030',
    'f0000000-0000-4000-8000-000000000002',
    'Fare Origin Park',
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    'f0000000-0000-4000-8000-000000000020',
    'field_verified',
    0.950
  ),
  (
    'f0000000-0000-4000-8000-000000000031',
    'f0000000-0000-4000-8000-000000000002',
    'Fare Destination Park',
    st_setsrid(st_makepoint(7.50, 9.15), 4326)::geography,
    'f0000000-0000-4000-8000-000000000020',
    'field_verified',
    0.950
  );

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score)
values (
  'f0000000-0000-4000-8000-000000000040',
  'f0000000-0000-4000-8000-000000000002',
  'f0000000-0000-4000-8000-000000000030',
  'f0000000-0000-4000-8000-000000000031',
  'car',
  'f0000000-0000-4000-8000-000000000020',
  'field_verified',
  0.950
);

insert into route_stages (id, route_id, sequence, location, source_id, verification_status, confidence_score) values
  ('f0000000-0000-4000-8000-000000000050', 'f0000000-0000-4000-8000-000000000040', 1, st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.950),
  ('f0000000-0000-4000-8000-000000000051', 'f0000000-0000-4000-8000-000000000040', 2, st_setsrid(st_makepoint(7.42, 9.07), 4326)::geography, 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.900),
  ('f0000000-0000-4000-8000-000000000052', 'f0000000-0000-4000-8000-000000000040', 3, st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography, 'f0000000-0000-4000-8000-000000000020', 'crowd_verified', 0.800),
  ('f0000000-0000-4000-8000-000000000053', 'f0000000-0000-4000-8000-000000000040', 4, st_setsrid(st_makepoint(7.46, 9.11), 4326)::geography, 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.850),
  ('f0000000-0000-4000-8000-000000000054', 'f0000000-0000-4000-8000-000000000040', 5, st_setsrid(st_makepoint(7.50, 9.15), 4326)::geography, 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.950);

-- Adjacent legs S1S2..S4S5 (100 each; S2S3 has lower confidence for TS-FARE-02)
insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score) values
  ('f0000000-0000-4000-8000-000000000040', 'f0000000-0000-4000-8000-000000000050', 'f0000000-0000-4000-8000-000000000051', 'car', 100.00, 'NGN', 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.950),
  ('f0000000-0000-4000-8000-000000000040', 'f0000000-0000-4000-8000-000000000051', 'f0000000-0000-4000-8000-000000000052', 'car', 100.00, 'NGN', 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.700),
  ('f0000000-0000-4000-8000-000000000040', 'f0000000-0000-4000-8000-000000000052', 'f0000000-0000-4000-8000-000000000053', 'car', 100.00, 'NGN', 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.900),
  ('f0000000-0000-4000-8000-000000000040', 'f0000000-0000-4000-8000-000000000053', 'f0000000-0000-4000-8000-000000000054', 'car', 100.00, 'NGN', 'f0000000-0000-4000-8000-000000000020', 'field_verified', 0.950);

-- Through-fare S1→S4 only (400 NGN, field_verified) — no through-fare for S2→S4
insert into route_through_fares (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score)
values (
  'f0000000-0000-4000-8000-000000000040',
  'f0000000-0000-4000-8000-000000000050',
  'f0000000-0000-4000-8000-000000000053',
  'car',
  400.00,
  'NGN',
  'f0000000-0000-4000-8000-000000000020',
  'field_verified',
  0.920
);

-- Through-fare S1→S5 (full route) for TS-FARE-03 comparison
insert into route_through_fares (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score)
values (
  'f0000000-0000-4000-8000-000000000040',
  'f0000000-0000-4000-8000-000000000050',
  'f0000000-0000-4000-8000-000000000054',
  'car',
  500.00,
  'NGN',
  'f0000000-0000-4000-8000-000000000020',
  'field_verified',
  0.930
);

-- ---------------------------------------------------------------------------
-- TS-FARE-01: Tier 1 through-fare S1→S4
-- ---------------------------------------------------------------------------
select is(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000050',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000053',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).amount,
  400.00::numeric,
  'TS-FARE-01: tier 1 amount equals through-fare for S1→S4'
);

select is(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000050',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000053',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).tier,
  1::smallint,
  'TS-FARE-01: tier 1'
);

select is(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000050',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000053',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).unconfirmed,
  false,
  'TS-FARE-01: unconfirmed=false'
);

-- ---------------------------------------------------------------------------
-- TS-FARE-02: Tier 2 leg sum S2→S4 (no through-fare)
-- ---------------------------------------------------------------------------
select is(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000051',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000053',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).amount,
  200.00::numeric,
  'TS-FARE-02: tier 2 amount = sum legs S2S3+S3S4'
);

select is(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000051',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000053',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).tier,
  2::smallint,
  'TS-FARE-02: tier 2'
);

select is(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000051',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000053',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).confidence,
  0.700::numeric,
  'TS-FARE-02: confidence = min(legs) = 0.700 from S2S3'
);

-- ---------------------------------------------------------------------------
-- TS-FARE-03: mid-route boarding S3→S5 < full-route S1→S5
-- ---------------------------------------------------------------------------
select ok(
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000052',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000054',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).amount
  <
  (resolve_fare(
    p_route_id := 'f0000000-0000-4000-8000-000000000040',
    p_from_stage_id := 'f0000000-0000-4000-8000-000000000050',
    p_to_stage_id := 'f0000000-0000-4000-8000-000000000054',
    p_mode_code := 'car',
    p_city_id := 'f0000000-0000-4000-8000-000000000002'
  )).amount,
  'TS-FARE-03: mid-route S3→S5 fare < full-route S1→S5 fare'
);

-- fare_quotes row written (doc 04 §3)
select ok(
  exists (
    select 1 from fare_quotes
    where route_id = 'f0000000-0000-4000-8000-000000000040'
      and from_stage_id = 'f0000000-0000-4000-8000-000000000050'
      and to_stage_id = 'f0000000-0000-4000-8000-000000000053'
      and tier = 1
      and amount = 400.00
  ),
  'fare_quotes row persisted for tier 1 resolution'
);

-- snap_stage prefers field_verified over candidate at equal distance
insert into route_stages (id, route_id, sequence, location, source_id, verification_status, confidence_score)
values (
  'f0000000-0000-4000-8000-000000000055',
  'f0000000-0000-4000-8000-000000000040',
  6,
  st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography,
  'f0000000-0000-4000-8000-000000000020',
  'candidate',
  0.300
);

select is(
  snap_stage(st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography, null, 'f0000000-0000-4000-8000-000000000002'),
  'f0000000-0000-4000-8000-000000000052'::uuid,
  'snap_stage prefers field_verified/crowd_verified over candidate at same location'
);

-- ---------------------------------------------------------------------------
-- TS-FARE-08: p95 resolve_fare ≤ 150 ms over 1,000 random pairs
-- Minimal perf fixture: 20-stage route (not full Abuja seed — P0-E-04 deferred)
-- ---------------------------------------------------------------------------
insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status)
values (
  'f0000000-0000-4000-8000-000000000041',
  'f0000000-0000-4000-8000-000000000002',
  'f0000000-0000-4000-8000-000000000030',
  'f0000000-0000-4000-8000-000000000031',
  'car',
  'f0000000-0000-4000-8000-000000000020',
  'field_verified'
);

create temp table perf_stages as
select gs as seq, gen_random_uuid() as id
from generate_series(1, 20) gs;

insert into route_stages (id, route_id, sequence, location, source_id, verification_status, confidence_score)
select
  ps.id,
  'f0000000-0000-4000-8000-000000000041',
  ps.seq,
  st_setsrid(st_makepoint(7.40 + (ps.seq * 0.005), 9.05 + (ps.seq * 0.005)), 4326)::geography,
  'f0000000-0000-4000-8000-000000000020',
  'field_verified',
  0.900
from perf_stages ps;

insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score)
select
  'f0000000-0000-4000-8000-000000000041',
  s1.id,
  s2.id,
  'car',
  100.00,
  'NGN',
  'f0000000-0000-4000-8000-000000000020',
  'field_verified',
  0.900
from perf_stages s1
join perf_stages s2 on s2.seq = s1.seq + 1;

create temp table fare_perf_samples (elapsed_ms numeric);

do $$
declare
  v_from uuid;
  v_to uuid;
  v_from_seq int;
  v_to_seq int;
  v_t0 timestamptz;
  v_t1 timestamptz;
  i int;
begin
  for i in 1..1000 loop
    v_from_seq := 1 + floor(random() * 19)::int;
    v_to_seq := v_from_seq + 1 + floor(random() * (20 - v_from_seq))::int;

    select id into v_from from perf_stages where seq = v_from_seq;
    select id into v_to from perf_stages where seq = v_to_seq;

    v_t0 := clock_timestamp();
    perform resolve_fare(
      p_route_id := 'f0000000-0000-4000-8000-000000000041',
      p_from_stage_id := v_from,
      p_to_stage_id := v_to,
      p_mode_code := 'car',
      p_city_id := 'f0000000-0000-4000-8000-000000000002'
    );
    v_t1 := clock_timestamp();

    insert into fare_perf_samples (elapsed_ms)
    values (extract(epoch from (v_t1 - v_t0)) * 1000);
  end loop;
end $$;

select ok(
  (select percentile_cont(0.95) within group (order by elapsed_ms) from fare_perf_samples) <= 150,
  'TS-FARE-08: p95 resolve_fare <= 150 ms over 1,000 random pairs'
);

select * from finish();
rollback;
