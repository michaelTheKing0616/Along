-- P9-E-02: nightly ledger invariant check (TS-LEDGER-01) + job_runs audit row
-- Alert: docs/runbooks/observability.md alert-ledger-invariant

create or replace function check_ledger_invariant()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_violations jsonb;
  v_count int;
  v_job_id uuid;
  v_ok boolean;
begin
  insert into job_runs (job_name, params)
  values ('ledger_invariant', '{}'::jsonb)
  returning id into v_job_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'driver_id', x.driver_id,
        'sum_amount', x.sum_amount,
        'latest_balance', x.latest_balance
      )
    ),
    '[]'::jsonb
  )
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

  v_count := jsonb_array_length(v_violations);
  v_ok := v_count = 0;

  update job_runs
  set
    status = case when v_ok then 'succeeded' else 'failed' end,
    finished_at = now(),
    stats = jsonb_build_object(
      'ok', v_ok,
      'violation_count', v_count,
      'violations', v_violations
    ),
    error = case
      when v_ok then null
      else format('ledger invariant failed for %s driver(s)', v_count)
    end
  where id = v_job_id;

  return jsonb_build_object(
    'ok', v_ok,
    'job_run_id', v_job_id,
    'violation_count', v_count,
    'violations', v_violations
  );
end;
$$;

comment on function check_ledger_invariant() is
  'TS-LEDGER-01 nightly invariant: sum(amount) = latest balance_after per driver; writes job_runs.';

revoke all on function check_ledger_invariant() from public;
grant execute on function check_ledger_invariant() to service_role;

-- pg_cron — nightly 03:00 UTC (doc 09 §8, observability alert-ledger-invariant)
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'ledger_invariant' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'ledger_invariant',
    '0 3 * * *',
    $cron$select check_ledger_invariant()$cron$
  );
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule check_ledger_invariant manually (doc 09 §8)';
  when others then
    raise notice 'pg_cron ledger_invariant schedule skipped: %', sqlerrm;
end;
$$;
