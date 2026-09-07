-- pgTAP: TS-GRAPH-08 — candidate park clustering (doc 04 §14, FM26)
create extension if not exists pgtap;

begin;
select plan(7);

select ok(
  to_regclass('public.candidate_park_clusters') is not null,
  'candidate_park_clusters table exists'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.candidate_park_clusters'::regclass),
  'candidate_park_clusters has RLS enabled'
);

select is(
  cfg_num('inference.frechet_m'),
  150::numeric,
  'inference.frechet_m default is 150'
);

select is(
  cfg_num('geometry.cluster_m'),
  20::numeric,
  'geometry.cluster_m default is 20'
);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql
select ensure_partitions();

-- ensure_partitions() only creates current + 2 future months; backfill August for 10-day fixture
do $$
declare
  v_month date := date '2026-08-01';
  v_end date := date '2026-09-01';
  v_part text := 'driver_presence_history_y2026_m08';
begin
  if to_regclass('public.' || v_part) is null then
    execute format(
      'create table %I partition of driver_presence_history for values from (%L) to (%L)',
      v_part, v_month, v_end
    );
  end if;
end;
$$;

-- Remote location — not near existing Zaria-Test parks/stages
-- FM26 false positive: 1 driver idling 10 days at home → no candidate
insert into auth.users (id, aud, role, phone) values
  ('0f400000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000007401')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0f400000-0000-4000-8000-000000000001', '+2348000007401', 'TS-GRAPH-08 Solo Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0f400000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'GRPH0801', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into driver_presence_history (
  driver_id, session_id, ts, location, speed_mps, status
)
select
  '0f400000-0000-4000-8000-000000000001',
  '0f410000-0000-4000-8000-000000000001'::uuid,
  now() - make_interval(days => day.day, hours => hr.hour),
  st_setsrid(st_makepoint(7.900, 11.200), 4326)::geography,
  0.0,
  'at_park'
from generate_series(0, 9) as day(day),
     generate_series(0, 2) as hr(hour);

select cluster_candidate_parks('0a000000-0000-4000-8000-000000000001'::uuid);

select is(
  (select count(*)::int from candidate_park_clusters
   where city_id = '0a000000-0000-4000-8000-000000000001'),
  0,
  'TS-GRAPH-08: 1 driver idling 10 days → no candidate park cluster'
);

-- True positive: 5 drivers × 4 days
insert into auth.users (id, aud, role, phone)
select
  ('0f420000-0000-4000-8000-00000000000' || g.i)::uuid,
  'authenticated',
  'authenticated',
  '+23480000075' || lpad(g.i::text, 2, '0')
from generate_series(1, 5) as g(i)
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name)
select
  ('0f420000-0000-4000-8000-00000000000' || g.i)::uuid,
  '+23480000075' || lpad(g.i::text, 2, '0'),
  'TS-GRAPH-08 Driver ' || g.i
from generate_series(1, 5) as g(i)
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id)
select
  ('0f420000-0000-4000-8000-00000000000' || g.i)::uuid,
  '0a000000-0000-4000-8000-000000000001',
  'verified',
  'good_standing',
  'GRPH08' || g.i,
  '0a020000-0000-4000-8000-000000000001'
from generate_series(1, 5) as g(i)
on conflict (id) do update set verified_status = excluded.verified_status;

insert into driver_presence_history (
  driver_id, session_id, ts, location, speed_mps, status
)
select
  ('0f420000-0000-4000-8000-00000000000' || d.i)::uuid,
  ('0f430000-0000-4000-8000-00000000000' || d.i)::uuid,
  now() - make_interval(days => day.i, hours => ping.i),
  st_setsrid(
    st_makepoint(7.901 + (d.i * 0.00001), 11.201 + (d.i * 0.00001)),
    4326
  )::geography,
  0.0,
  'roaming_available'
from generate_series(1, 5) as d(i),
     generate_series(0, 3) as day(i),
     generate_series(0, 3) as ping(i);

create temp table stage_count_before as
select count(*)::int as n
from route_stages rs
join routes r on r.id = rs.route_id
where r.city_id = '0a000000-0000-4000-8000-000000000001';

select cluster_candidate_parks('0a000000-0000-4000-8000-000000000001'::uuid);

select ok(
  (select count(*) >= 1 from candidate_park_clusters
   where city_id = '0a000000-0000-4000-8000-000000000001'
     and status = 'new'
     and distinct_driver_count >= 4
     and distinct_day_count >= 3),
  'TS-GRAPH-08: 5 drivers × 4 days → candidate park cluster'
);

select is(
  (select count(*)::int from route_stages rs
   join routes r on r.id = rs.route_id
   where r.city_id = '0a000000-0000-4000-8000-000000000001'),
  (select n from stage_count_before),
  'TS-GRAPH-08: cluster_candidate_parks does not write route_stages'
);

select * from finish();
rollback;
