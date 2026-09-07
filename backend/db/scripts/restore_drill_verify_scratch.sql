-- TS-OPS-01 verification against scratch schema (post local restore drill clone).
-- Requires session GUC: set restore.scratch_schema = 'along_restore_scratch';

\set ON_ERROR_STOP on

\echo '=== TS-OPS-01 ledger invariant (TS-LEDGER-01) on scratch schema ==='
do $$
declare
  v_schema text := current_setting('restore.scratch_schema');
  v_violations int;
begin
  execute format($sql$
    select count(*)::int
    from (
      select
        dle.driver_id,
        sum(dle.amount) as sum_amount,
        (
          select dle2.balance_after
          from %I.driver_ledger_entries dle2
          where dle2.driver_id = dle.driver_id
          order by dle2.id desc
          limit 1
        ) as latest_balance
      from %I.driver_ledger_entries dle
      group by dle.driver_id
    ) x
    where x.sum_amount is distinct from x.latest_balance
  $sql$, v_schema, v_schema)
  into v_violations;

  if v_violations > 0 then
    raise exception 'TS-OPS-01 FAIL: ledger invariant broken for % driver(s) in schema %', v_violations, v_schema;
  end if;

  raise notice 'TS-OPS-01 PASS: ledger invariant holds in schema %', v_schema;
end;
$$;

\echo 'TS-OPS-01 scratch verification complete'
