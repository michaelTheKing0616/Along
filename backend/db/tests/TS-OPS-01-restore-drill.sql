-- TS-OPS-01: post-restore verification — key table row counts + TS-LEDGER-01 invariant
-- Run against a restored database (scratch project or local along_restore_scratch).
-- Usage:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/db/tests/TS-OPS-01-restore-drill.sql

\set ON_ERROR_STOP on

begin;

-- pgTAP so pg_prove (db CI) runs it too; the extension is created inside the
-- transaction and rolled back, so a restored database is left untouched.
create extension if not exists pgtap;
select plan(3);

create temp table ts_ops_01_counts (
  table_name text primary key,
  row_count bigint not null
) on commit drop;

do $$
declare
  v_table text;
  v_count bigint;
  v_tables text[] := array[
    'cities', 'parks', 'routes', 'route_stages', 'route_legs', 'route_through_fares',
    'corridors', 'profiles', 'drivers', 'riders', 'trips', 'driver_ledger_entries',
    'payments', 'app_config', 'app_config_keys', 'deployments', 'countries'
  ];
begin
  foreach v_table in array v_tables loop
    if to_regclass(format('public.%I', v_table)) is null then
      raise exception 'TS-OPS-01 FAIL: expected table public.% missing after restore', v_table;
    end if;

    execute format('select count(*)::bigint from public.%I', v_table)
      into v_count;

    insert into ts_ops_01_counts (table_name, row_count)
    values (v_table, v_count);
  end loop;
end;
$$;
select pass('TS-OPS-01: every key table exists after restore');

select diag('=== TS-OPS-01 row counts ===');
select diag(table_name || ': ' || row_count)
from ts_ops_01_counts
order by table_name;

select diag('=== TS-OPS-01 ledger invariant (TS-LEDGER-01) ===');
do $$
declare
  v_violations int;
begin
  select count(*)::int
  into v_violations
  from (
    select
      dle.driver_id,
      sum(dle.amount) as sum_amount,
      (
        select dle2.balance_after
        from driver_ledger_entries dle2
        where dle2.driver_id = dle.driver_id
        order by dle2.id desc
        limit 1
      ) as latest_balance
    from driver_ledger_entries dle
    group by dle.driver_id
  ) x
  where x.sum_amount is distinct from x.latest_balance;

  if v_violations > 0 then
    raise exception 'TS-OPS-01 FAIL: ledger invariant broken for % driver(s) (sum(amount) <> latest balance_after)', v_violations;
  end if;

  raise notice 'TS-OPS-01 PASS: ledger invariant holds for all drivers with ledger rows';
end;
$$;
select pass('TS-OPS-01: ledger invariant holds (TS-LEDGER-01)');

select diag('=== TS-OPS-01 driver_balances view consistency ===');
do $$
begin
  if exists (
    select 1
    from driver_balances db
    join (
      select
        driver_id,
        sum(amount) as sum_amount,
        (
          select balance_after
          from driver_ledger_entries dle2
          where dle2.driver_id = dle.driver_id
          order by dle2.id desc
          limit 1
        ) as latest_balance
      from driver_ledger_entries dle
      group by driver_id
    ) x on x.driver_id = db.driver_id
    where db.balance is distinct from x.latest_balance
       or db.balance is distinct from x.sum_amount
  ) then
    raise exception 'TS-OPS-01 FAIL: driver_balances view disagrees with ledger running total';
  end if;

  raise notice 'TS-OPS-01 PASS: driver_balances view agrees with ledger';
end;
$$;
select pass('TS-OPS-01: driver_balances view agrees with ledger');

select diag('TS-OPS-01: verification complete');
select * from finish();
rollback;
