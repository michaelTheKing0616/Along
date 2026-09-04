-- pgTAP: TS-FARE-04/05/06/07 — profile fare tiers, load surcharge, city commission (P1-A-03)
create extension if not exists pgtap;

begin;
select plan(10);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000001001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, driver_code, home_park_id)
values (
  '0a100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'verified',
  'TSTDRV01',
  '0a020000-0000-4000-8000-000000000001'
)
on conflict (id) do update set home_park_id = excluded.home_park_id;

-- ---------------------------------------------------------------------------
-- TS-FARE-04: Tier 3 on candidate route — unknown pair, unconfirmed, anchor ±30%
-- ---------------------------------------------------------------------------
insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score)
values (
  '0a030000-0000-4000-8000-000000000099',
  '0a000000-0000-4000-8000-000000000001',
  '0a020000-0000-4000-8000-000000000001',
  '0a020000-0000-4000-8000-000000000002',
  'car',
  '0a010000-0000-4000-8000-000000000001',
  'candidate',
  0.300
);

insert into route_stages (id, route_id, sequence, location, source_id, verification_status, confidence_score) values
  ('0a090000-0000-4000-8000-000000000001', '0a030000-0000-4000-8000-000000000099', 1, st_setsrid(st_makepoint(7.700, 11.060), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300),
  ('0a090000-0000-4000-8000-000000000002', '0a030000-0000-4000-8000-000000000099', 2, st_setsrid(st_makepoint(7.701, 11.061), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300),
  ('0a090000-0000-4000-8000-000000000003', '0a030000-0000-4000-8000-000000000099', 3, st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300),
  ('0a090000-0000-4000-8000-000000000004', '0a030000-0000-4000-8000-000000000099', 4, st_setsrid(st_makepoint(7.704, 11.064), 4326)::geography, '0a010000-0000-4000-8000-000000000001', 'candidate', 0.300);

-- Only first leg exists — S2→S4 has no tier 1/2 coverage
insert into route_legs (route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id, verification_status, confidence_score, distance_m)
values (
  '0a030000-0000-4000-8000-000000000099',
  '0a090000-0000-4000-8000-000000000001',
  '0a090000-0000-4000-8000-000000000002',
  'car',
  80.00,
  'NGN',
  '0a010000-0000-4000-8000-000000000001',
  'crowd_verified',
  0.800,
  800
);

create temp table tier3_result as
select resolve_fare(
  p_route_id := '0a030000-0000-4000-8000-000000000099',
  p_from_stage_id := '0a090000-0000-4000-8000-000000000002',
  p_to_stage_id := '0a090000-0000-4000-8000-000000000004',
  p_mode_code := 'car',
  p_city_id := '0a000000-0000-4000-8000-000000000001'
) as r;

select is((select (r).tier from tier3_result), 3::smallint, 'TS-FARE-04: tier 3');
select is((select (r).unconfirmed from tier3_result), true, 'TS-FARE-04: unconfirmed=true');

select ok(
  exists (
    select 1 from fare_quotes fq
    where fq.route_id = '0a030000-0000-4000-8000-000000000099'
      and fq.from_stage_id = '0a090000-0000-4000-8000-000000000002'
      and fq.to_stage_id = '0a090000-0000-4000-8000-000000000004'
      and fq.tier = 3
  ),
  'TS-FARE-04: fare_quotes row written'
);

select ok(
  (select (r).amount from tier3_result)
  between (
    select round_to_minor(
      (greatest(
        (cfg('fare.min_fare', '0a000000-0000-4000-8000-000000000001')->>'car')::numeric,
        (cfg('fare.default_rate_per_km', '0a000000-0000-4000-8000-000000000001')->>'car')::numeric
          * (distance_m(
              (select location from route_stages where id = '0a090000-0000-4000-8000-000000000002'),
              (select location from route_stages where id = '0a090000-0000-4000-8000-000000000004')
            ) * 1.3 / 1000.0)
      ) * 0.7)::numeric,
      '0a000000-0000-4000-8000-000000000001'::uuid
    )
  ) and (
    select round_to_minor(
      (greatest(
        (cfg('fare.min_fare', '0a000000-0000-4000-8000-000000000001')->>'car')::numeric,
        (cfg('fare.default_rate_per_km', '0a000000-0000-4000-8000-000000000001')->>'car')::numeric
          * (distance_m(
              (select location from route_stages where id = '0a090000-0000-4000-8000-000000000002'),
              (select location from route_stages where id = '0a090000-0000-4000-8000-000000000004')
            ) * 1.3 / 1000.0)
      ) * 1.3)::numeric,
      '0a000000-0000-4000-8000-000000000001'::uuid
    )
  ),
  'TS-FARE-04: anchor within ±30% of distance model'
);

-- ---------------------------------------------------------------------------
-- TS-FARE-05: Tier 0 profile prices [400,300,150,0], board 2 alight 4 → 300
-- ---------------------------------------------------------------------------
insert into driver_route_profiles (id, driver_id, route_id, mode_code, active)
values (
  '0a200000-0000-4000-8000-000000000001',
  '0a100000-0000-4000-8000-000000000001',
  '0a030000-0000-4000-8000-000000000001',
  'car',
  true
);

insert into driver_route_stops (profile_id, sequence, route_stage_id, price_to_end, currency) values
  ('0a200000-0000-4000-8000-000000000001', 1, '0a040000-0000-4000-8000-000000000001', 400.00, 'NGN'),
  ('0a200000-0000-4000-8000-000000000001', 2, '0a040000-0000-4000-8000-000000000002', 300.00, 'NGN'),
  ('0a200000-0000-4000-8000-000000000001', 3, '0a040000-0000-4000-8000-000000000003', 150.00, 'NGN'),
  ('0a200000-0000-4000-8000-000000000001', 4, '0a040000-0000-4000-8000-000000000004', 0.00, 'NGN');

select is(
  (resolve_fare(
    p_profile_id := '0a200000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000002',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001'
  )).amount,
  300.00::numeric,
  'TS-FARE-05: board stop 2 alight stop 4 → 300'
);

select throws_ok(
  $$ select resolve_fare(
    p_profile_id := '0a200000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000002',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001'
  ) $$,
  '22023',
  'resolve_fare: boarding stop must precede alighting stop on profile (direction matters)',
  'TS-FARE-05: reverse direction raises error'
);

-- ---------------------------------------------------------------------------
-- TS-FARE-06: Load surcharge component vs pending
-- ---------------------------------------------------------------------------
update driver_route_profiles
set load_surcharge_amount = 100.00, load_surcharge_currency = 'NGN'
where id = '0a200000-0000-4000-8000-000000000001';

select ok(
  (resolve_fare(
    p_profile_id := '0a200000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000002',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001',
    p_load := '{"flagged": true}'::jsonb
  )).components @> '[{"kind":"load_surcharge","amount":100}]'::jsonb,
  'TS-FARE-06: profile surcharge 100 → load_surcharge component'
);

update driver_route_profiles
set load_surcharge_amount = null, load_surcharge_currency = null
where id = '0a200000-0000-4000-8000-000000000001';

select is(
  (resolve_fare(
    p_profile_id := '0a200000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000002',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001',
    p_load := '{"flagged": true}'::jsonb
  )).load_surcharge_pending,
  true,
  'TS-FARE-06: without profile surcharge → load_surcharge_pending'
);

-- ---------------------------------------------------------------------------
-- TS-FARE-07: Zaria-Test commission.rate override (FM5)
-- ---------------------------------------------------------------------------
select is(
  (resolve_fare(
    p_route_id := '0a030000-0000-4000-8000-000000000001',
    p_from_stage_id := '0a040000-0000-4000-8000-000000000001',
    p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
    p_mode_code := 'car',
    p_city_id := '0a000000-0000-4000-8000-000000000001'
  )).currency,
  'NGN'::bpchar,
  'TS-FARE-07: currency from country config (NGN)'
);

select is(
  round((
    (resolve_fare(
      p_route_id := '0a030000-0000-4000-8000-000000000001',
      p_from_stage_id := '0a040000-0000-4000-8000-000000000001',
      p_to_stage_id := '0a040000-0000-4000-8000-000000000004',
      p_mode_code := 'car',
      p_city_id := '0a000000-0000-4000-8000-000000000001'
    )).amount
    * cfg_num('commission.rate', '0a000000-0000-4000-8000-000000000001')
  )::numeric, 2),
  round(280.00 * 0.05, 2),
  'TS-FARE-07: commission uses Zaria-Test city rate (0.05 not global 0.075)'
);

select * from finish();
rollback;
