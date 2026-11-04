-- ensure_partitions(): also keep the previous month's partition.
-- Backfills / late samples (and pgTAP fixtures using now() - N days) early in a
-- month land in the prior month; with only current..+2 they had no partition
-- ("no partition of relation driver_presence_history found for row").

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

  for i in -1..2 loop
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

select ensure_partitions();
