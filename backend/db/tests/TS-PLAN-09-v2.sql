-- pgTAP: TS-PLAN-09 p95 budget — combined direct + decompose with 50 presence rows
create extension if not exists pgtap;

begin;
select plan(1);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone)
select
  ('0a100000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'authenticated',
  'authenticated',
  '+2348000' || lpad(i::text, 7, '0')
from generate_series(1, 50) i
on conflict (id) do nothing;

insert into profiles (id, display_name)
select
  ('0a100000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'Perf Driver ' || i
from generate_series(1, 50) i
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id)
select
  ('0a100000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  '0a000000-0000-4000-8000-000000000001',
  'verified',
  'good_standing',
  'PERF' || lpad(i::text, 4, '0'),
  '0a020000-0000-4000-8000-000000000001'
from generate_series(1, 50) i
on conflict (id) do nothing;

insert into vehicles (id, country_code, mode_code, plate_number, seat_capacity, owner_profile_id)
select
  ('0a110000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'NG',
  'car',
  'PERF-' || lpad(i::text, 4, '0'),
  4,
  ('0a100000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
from generate_series(1, 50) i
on conflict (id) do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select
  ('0a100000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('0a110000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  true
from generate_series(1, 50) i
on conflict do nothing;

do $perf$
declare
  v_start timestamptz;
  v_elapsed_ms double precision;
  v_times double precision[] := '{}';
  i int;
  v_driver uuid;
begin
  for i in 1..100 loop
    v_driver := ('0a100000-0000-4000-8000-' || lpad((1 + (i % 50))::text, 12, '0'))::uuid;
    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    perform set_config('role', 'authenticated', true);

    begin
      perform set_presence(
        'at_park',
        jsonb_build_object('lat', 11.060 + (random() * 0.001), 'lng', 7.700 + (random() * 0.001)),
        3::smallint,
        null::smallint,
        '0a020000-0000-4000-8000-000000000001'::uuid
      );
    exception when others then
      null;
    end;

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
    perform *
    from planner_decompose_latlng(
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

  create temp table planner_v2_perf as
  select percentile_cont(0.95) within group (order by t) as p95_ms
  from unnest(v_times) as u(t);
end;
$perf$;

select ok(
  (select p95_ms <= 800 from planner_v2_perf),
  'TS-PLAN-09: combined direct+decompose p95 <= 800 ms with 50 presence rows'
);

select * from finish();
rollback;
