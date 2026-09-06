-- pgTAP: P3-A-02 — presence_retention downsample/drop verified by fixture
create extension if not exists pgtap;

begin;
select plan(5);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select ensure_partitions();

insert into auth.users (id, aud, role, phone) values
  ('0b100000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000003001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id) values
  ('0b100000-0000-4000-8000-000000000001', '0a000000-0000-4000-8000-000000000001', 'verified', 'good_standing', 'RETDRV01', '0a020000-0000-4000-8000-000000000001')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into vehicles (country_code, mode_code, plate_number, seat_capacity, owner_profile_id) values
  ('NG', 'keke', 'TST-RET-01', 3, '0b100000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into driver_vehicles (driver_id, vehicle_id, active)
select '0b100000-0000-4000-8000-000000000001', v.id, true
from vehicles v where v.plate_number = 'TST-RET-01'
on conflict do nothing;

create temp table ret_ctx as
select
  '0b100000-0000-4000-8000-000000000001'::uuid as driver_id,
  gen_random_uuid() as session_id,
  cfg_num('presence.history_full_res_hours', null)::int as full_res_h,
  cfg_num('presence.history_downsampled_days', null)::int as retention_d,
  cfg_num('presence.downsample_interval_s', null)::int as interval_s;

-- Recent full-resolution row (within full_res window)
insert into driver_presence_history (
  driver_id, session_id, ts, location, heading, speed_mps, status, downsampled
)
select
  c.driver_id,
  c.session_id,
  now() - make_interval(hours => 1),
  st_setsrid(st_makepoint(7.702, 11.062), 4326)::geography,
  45::smallint,
  5::numeric,
  'roaming_available'::presence_status,
  false
from ret_ctx c;

-- Downsample zone: 4 pings at the same instant (> full_res, < retention)
insert into driver_presence_history (
  driver_id, session_id, ts, location, heading, speed_mps, status, downsampled
)
select
  c.driver_id,
  c.session_id,
  now() - make_interval(hours => c.full_res_h + 1),
  st_setsrid(st_makepoint(7.702 + gs.i * 0.0001, 11.062), 4326)::geography,
  45::smallint,
  5::numeric,
  'roaming_available'::presence_status,
  false
from ret_ctx c
cross join generate_series(0, 3) gs(i);

-- Ensure partition for drop-zone month (ensure_partitions only creates current + 2 future)
do $$
declare
  v_month date;
  v_end date;
  v_part text;
  v_retention_days int;
begin
  v_retention_days := cfg_num('presence.history_downsampled_days', null)::int;
  v_month := date_trunc(
    'month',
    now() - make_interval(days => v_retention_days + 1)
  )::date;
  v_end := (v_month + interval '1 month')::date;
  v_part := 'driver_presence_history_y' || to_char(v_month, 'YYYY') || '_m' || to_char(v_month, 'MM');
  if to_regclass('public.' || v_part) is null then
    execute format(
      'create table %I partition of driver_presence_history for values from (%L) to (%L)',
      v_part, v_month, v_end
    );
  end if;
end;
$$;

-- Drop zone: row older than retention window
insert into driver_presence_history (
  driver_id, session_id, ts, location, heading, speed_mps, status, downsampled
)
select
  c.driver_id,
  c.session_id,
  now() - make_interval(days => c.retention_d + 1),
  st_setsrid(st_makepoint(7.703, 11.063), 4326)::geography,
  90::smallint,
  3::numeric,
  'roaming_available'::presence_status,
  false
from ret_ctx c;

select presence_retention();

select is(
  (select count(*)::int
   from driver_presence_history h
   join ret_ctx c on c.session_id = h.session_id
   where h.ts > now() - interval '2 hours'),
  1,
  'retention fixture: recent full-res history row preserved'
);

select is(
  (select count(*)::int
   from driver_presence_history h
   join ret_ctx c on c.session_id = h.session_id
   where h.ts < now() - make_interval(hours => (select full_res_h from ret_ctx))
     and h.ts >= now() - make_interval(days => (select retention_d from ret_ctx))),
  1,
  'retention fixture: downsample zone collapses to one row per interval bucket'
);

select ok(
  (select bool_and(h.downsampled)
   from driver_presence_history h
   join ret_ctx c on c.session_id = h.session_id
   where h.ts < now() - make_interval(hours => (select full_res_h from ret_ctx))
     and h.ts >= now() - make_interval(days => (select retention_d from ret_ctx))),
  'retention fixture: surviving downsample-zone rows marked downsampled'
);

select is(
  (select count(*)::int
   from driver_presence_history h
   join ret_ctx c on c.session_id = h.session_id
   where h.ts < now() - make_interval(days => (select retention_d from ret_ctx))),
  0,
  'retention fixture: rows older than retention window dropped'
);

select ok(
  to_regclass(
    'public.driver_presence_history_y'
    || to_char(date_trunc('month', current_date), 'YYYY')
    || '_m'
    || to_char(date_trunc('month', current_date), 'MM')
  ) is not null,
  'retention fixture: ensure_partitions keeps current-month history partition'
);

select * from finish();
rollback;
