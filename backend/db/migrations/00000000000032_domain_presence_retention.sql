-- P3-A-02: presence retention (downsample/drop), history partitions, presence_stale hardening,
-- Realtime scale config (doc 02 §6, doc 03 §12, doc 04 §7.1).

-- ---------------------------------------------------------------------------
-- Config (doc 02 §2.3 — job cadence + Realtime client grace; thresholds unchanged)
-- ---------------------------------------------------------------------------
select config_default('presence.stale_job_interval_s', '15');
select config_default('realtime.ambient_stale_grace_s', '60');
select config_default('realtime.max_payload_bytes', '512');

-- ---------------------------------------------------------------------------
-- Partition maintenance — create upcoming + drop expired (doc 03 §12 ensure_partitions)
-- ---------------------------------------------------------------------------
create or replace function ensure_partitions()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_month date;
  v_end date;
  v_part text;
  v_drop_before date;
  v_retention_days int;
  i int;
  r record;
begin
  v_retention_days := cfg_num('presence.history_downsampled_days', null)::int;
  v_drop_before := date_trunc(
    'month',
    current_date - make_interval(days => v_retention_days + 31)
  )::date;

  for r in
    select c.relname as part_name
    from pg_inherits i
    join pg_class c on c.oid = i.inhrelid
    join pg_class p on p.oid = i.inhparent
    where p.relname = 'driver_presence_history'
      and c.relname ~ '^driver_presence_history_y[0-9]{4}_m[0-9]{2}$'
  loop
    begin
      v_month := make_date(
        (regexp_match(r.part_name, 'y([0-9]{4})_m([0-9]{2})$'))[1]::int,
        (regexp_match(r.part_name, 'y([0-9]{4})_m([0-9]{2})$'))[2]::int,
        1
      );
      if v_month < v_drop_before then
        execute format('drop table if exists %I', r.part_name);
      end if;
    exception
      when others then
        null;
    end;
  end loop;

  for i in 0..2 loop
    v_month := date_trunc('month', current_date + (i || ' months')::interval)::date;
    v_end := (v_month + interval '1 month')::date;

    v_part := 'driver_presence_history_y' || to_char(v_month, 'YYYY') || '_m' || to_char(v_month, 'MM');
    if to_regclass('public.' || v_part) is null then
      execute format(
        'create table %I partition of driver_presence_history for values from (%L) to (%L)',
        v_part, v_month, v_end
      );
    end if;

    v_part := 'trip_location_samples_y' || to_char(v_month, 'YYYY') || '_m' || to_char(v_month, 'MM');
    if to_regclass('public.' || v_part) is null then
      execute format(
        'create table %I partition of trip_location_samples for values from (%L) to (%L)',
        v_part, v_month, v_end
      );
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- History retention (doc 03 §12 presence_retention)
-- ---------------------------------------------------------------------------
create or replace function presence_retention()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_full_res_hours int;
  v_retention_days int;
  v_interval_s int;
  v_full_res_cutoff timestamptz;
  v_retention_cutoff timestamptz;
begin
  v_full_res_hours := cfg_num('presence.history_full_res_hours', null)::int;
  v_retention_days := cfg_num('presence.history_downsampled_days', null)::int;
  v_interval_s := cfg_num('presence.downsample_interval_s', null)::int;

  v_full_res_cutoff := now() - make_interval(hours => v_full_res_hours);
  v_retention_cutoff := now() - make_interval(days => v_retention_days);

  delete from driver_presence_history
  where ts < v_retention_cutoff;

  with candidates as (
    select
      h.id,
      h.driver_id,
      h.session_id,
      floor(extract(epoch from h.ts) / v_interval_s)::bigint as bucket
    from driver_presence_history h
    where h.ts < v_full_res_cutoff
      and h.ts >= v_retention_cutoff
      and not h.downsampled
  ),
  keepers as (
    select distinct on (c.driver_id, c.session_id, c.bucket) c.id
    from candidates c
    order by c.driver_id, c.session_id, c.bucket, c.id
  )
  delete from driver_presence_history h
  using candidates c
  where h.id = c.id
    and h.id not in (select id from keepers);

  update driver_presence_history h
  set downsampled = true
  where h.ts < v_full_res_cutoff
    and h.ts >= v_retention_cutoff
    and not h.downsampled;

  perform ensure_partitions();
end;
$$;

do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'presence_retention' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'presence_retention',
    '0 * * * *',
    $cron$select presence_retention()$cron$
  );
exception
  when undefined_table or undefined_object then
    null;
end;
$$;

revoke execute on function presence_retention() from authenticated;
grant execute on function presence_retention() to service_role;

-- ---------------------------------------------------------------------------
-- Stale/offline cleanup hardening (doc 04 §7.1 — presence_dropped broadcast)
-- ---------------------------------------------------------------------------
create or replace function presence_stale()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row record;
begin
  for v_row in
    select dp.driver_id, d.city_id, dp.last_ping_at
    from driver_presence dp
    join drivers d on d.id = dp.driver_id
    where dp.last_ping_at < now() - make_interval(
      secs => cfg_num('presence.offline_after_s', d.city_id)::int
    )
  loop
    begin
      perform realtime.send(
        jsonb_build_object('type', 'presence_dropped'),
        'presence_dropped',
        'driver:' || v_row.driver_id::text,
        true
      );
    exception
      when others then
        null;
    end;

    delete from driver_presence where driver_id = v_row.driver_id;
  end loop;
end;
$$;
