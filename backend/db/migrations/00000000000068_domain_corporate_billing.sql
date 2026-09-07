-- P8-A-01: corporate accounts, trip policies/allocation on completion, monthly invoices, reconciliation (doc 02 §13)

-- ---------------------------------------------------------------------------
-- Config (ADR-0016)
-- ---------------------------------------------------------------------------
select config_default('jobs.corporate_invoice_day', '1');
select config_default('jobs.corporate_invoice_hour_utc', '4');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'jobs.corporate_invoice_day',
    '{"type":"integer","minimum":1,"maximum":28}',
    'Day of month (UTC) to generate corporate invoices for the prior billing period',
    array['global']::config_scope[],
    false
  ),
  (
    'jobs.corporate_invoice_hour_utc',
    '{"type":"integer","minimum":0,"maximum":23}',
    'Hour (UTC) on jobs.corporate_invoice_day when the corporate invoice job runs',
    array['global']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Tables (doc 02 §13 — corporate_* only; operator/sponsored/api deferred to P8-A-03)
-- ---------------------------------------------------------------------------
create type corporate_account_status as enum ('active', 'suspended');
create type corporate_invoice_status as enum ('draft', 'generated', 'sent', 'paid');

create table corporate_accounts (
  id uuid primary key default gen_random_uuid(),
  deployment_id uuid not null references deployments(id),
  name text not null,
  billing_email text not null,
  billing_address text,
  status corporate_account_status not null default 'active',
  monthly_budget numeric(12, 2),
  currency char(3) not null default 'NGN',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index corporate_accounts_deployment on corporate_accounts(deployment_id);

create trigger corporate_accounts_set_updated_at
  before update on corporate_accounts
  for each row execute function set_updated_at();

create table corporate_members (
  corporate_account_id uuid not null references corporate_accounts(id) on delete cascade,
  rider_id uuid not null references riders(id) on delete cascade,
  employee_ref text,
  department text,
  active boolean not null default true,
  since timestamptz not null default now(),
  primary key (corporate_account_id, rider_id)
);

create index corporate_members_rider on corporate_members(rider_id) where active;

create table corporate_trip_policies (
  id uuid primary key default gen_random_uuid(),
  corporate_account_id uuid not null references corporate_accounts(id) on delete cascade,
  name text not null,
  subsidy_pct numeric(5, 4) not null check (subsidy_pct > 0 and subsidy_pct <= 1),
  max_per_trip numeric(12, 2) check (max_per_trip is null or max_per_trip > 0),
  allowed_hours jsonb,
  allowed_zones geography(MultiPolygon, 4326),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index corporate_trip_policies_account on corporate_trip_policies(corporate_account_id) where active;

create trigger corporate_trip_policies_set_updated_at
  before update on corporate_trip_policies
  for each row execute function set_updated_at();

create table corporate_trip_allocations (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null unique references trips(id) on delete restrict,
  corporate_account_id uuid not null references corporate_accounts(id) on delete restrict,
  policy_id uuid not null references corporate_trip_policies(id) on delete restrict,
  subsidized_amount numeric(12, 2) not null check (subsidized_amount >= 0),
  created_at timestamptz not null default now()
);

create index corporate_trip_allocations_account_created
  on corporate_trip_allocations(corporate_account_id, created_at);

create table corporate_invoices (
  id uuid primary key default gen_random_uuid(),
  corporate_account_id uuid not null references corporate_accounts(id) on delete restrict,
  period_start timestamptz not null,
  period_end timestamptz not null,
  total numeric(12, 2) not null check (total >= 0),
  currency char(3) not null,
  status corporate_invoice_status not null default 'generated',
  generated_at timestamptz not null default now(),
  check (period_end > period_start),
  unique (corporate_account_id, period_start, period_end)
);

create table invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references corporate_invoices(id) on delete cascade,
  allocation_id uuid not null unique references corporate_trip_allocations(id) on delete restrict,
  amount numeric(12, 2) not null check (amount >= 0)
);

create index invoice_lines_invoice on invoice_lines(invoice_id);

-- corporate_admin scoping (doc 02 §13 RLS)
alter table admin_users
  add column if not exists corporate_account_id uuid references corporate_accounts(id);

create index admin_users_corporate_account
  on admin_users(corporate_account_id)
  where corporate_account_id is not null;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function admin_corporate_account_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.corporate_account_id
  from admin_users a
  where a.id = auth.uid()
    and a.disabled_at is null
    and a.role = 'corporate_admin'
$$;

create or replace function private.corporate_policy_applies(
  p_policy corporate_trip_policies,
  p_trip trips
)
returns boolean
language plpgsql
stable
set search_path = public
as $$
declare
  v_at timestamptz := coalesce(p_trip.ended_at, now());
  v_dow int;
  v_minute int;
  v_start_min int;
  v_end_min int;
  v_days jsonb;
  v_loc geography(Point, 4326);
begin
  if not p_policy.active then
    return false;
  end if;

  if p_policy.allowed_hours is not null then
    v_dow := extract(dow from v_at at time zone 'UTC')::int;
    v_minute := (extract(hour from v_at at time zone 'UTC') * 60
      + extract(minute from v_at at time zone 'UTC'))::int;
    v_days := coalesce(p_policy.allowed_hours->'days_of_week', 'null'::jsonb);
    if v_days is not null and v_days <> 'null'::jsonb then
      if not exists (
        select 1
        from jsonb_array_elements_text(v_days) d(day)
        where d.day::int = v_dow
      ) then
        return false;
      end if;
    end if;
    if p_policy.allowed_hours ? 'start' and p_policy.allowed_hours ? 'end' then
      v_start_min := (
        split_part(p_policy.allowed_hours->>'start', ':', 1)::int * 60
        + split_part(p_policy.allowed_hours->>'start', ':', 2)::int
      );
      v_end_min := (
        split_part(p_policy.allowed_hours->>'end', ':', 1)::int * 60
        + split_part(p_policy.allowed_hours->>'end', ':', 2)::int
      );
      if v_minute < v_start_min or v_minute > v_end_min then
        return false;
      end if;
    end if;
  end if;

  if p_policy.allowed_zones is not null then
    v_loc := coalesce(
      p_trip.boarding_location,
      (
        select rs.location
        from route_stages rs
        where rs.id = p_trip.boarding_stage_id
      ),
      p_trip.alighting_location,
      (
        select rs.location
        from route_stages rs
        where rs.id = p_trip.alighting_stage_id
      )
    );
    if v_loc is null or not st_covers(p_policy.allowed_zones, v_loc) then
      return false;
    end if;
  end if;

  return true;
end;
$$;

revoke all on function private.corporate_policy_applies(corporate_trip_policies, trips) from public;

create or replace function private.corporate_compute_subsidy(
  p_policy corporate_trip_policies,
  p_trip_total numeric
)
returns numeric
language sql
immutable
as $$
  select round(
    least(
      coalesce(p_policy.max_per_trip, p_trip_total),
      p_policy.subsidy_pct * p_trip_total
    ),
    2
  )
$$;

revoke all on function private.corporate_compute_subsidy(corporate_trip_policies, numeric) from public;

-- Idempotent allocation on trip completion (doc 02 §13)
create or replace function corporate_allocate_trip(p_trip_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_t trips%rowtype;
  v_member corporate_members%rowtype;
  v_account corporate_accounts%rowtype;
  v_policy corporate_trip_policies%rowtype;
  v_best_policy corporate_trip_policies%rowtype;
  v_best_amount numeric := -1;
  v_amount numeric;
  v_total numeric;
  v_allocation_id uuid;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null or v_t.status <> 'completed' then
    return null;
  end if;

  select a.id into v_allocation_id
  from corporate_trip_allocations a
  where a.trip_id = p_trip_id;
  if v_allocation_id is not null then
    return v_allocation_id;
  end if;

  select cm.* into v_member
  from corporate_members cm
  join corporate_accounts ca on ca.id = cm.corporate_account_id
  where cm.rider_id = v_t.rider_id
    and cm.active
    and ca.status = 'active'
  order by cm.since desc
  limit 1;

  if v_member.corporate_account_id is null then
    return null;
  end if;

  select * into v_account
  from corporate_accounts
  where id = v_member.corporate_account_id;

  v_total := v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0);

  for v_policy in
    select *
    from corporate_trip_policies
    where corporate_account_id = v_member.corporate_account_id
      and active
  loop
    if private.corporate_policy_applies(v_policy, v_t) then
      v_amount := private.corporate_compute_subsidy(v_policy, v_total);
      if v_amount > v_best_amount then
        v_best_amount := v_amount;
        v_best_policy := v_policy;
      end if;
    end if;
  end loop;

  if v_best_amount < 0 then
    return null;
  end if;

  insert into corporate_trip_allocations (
    trip_id,
    corporate_account_id,
    policy_id,
    subsidized_amount
  ) values (
    p_trip_id,
    v_member.corporate_account_id,
    v_best_policy.id,
    v_best_amount
  )
  on conflict (trip_id) do nothing
  returning id into v_allocation_id;

  return v_allocation_id;
end;
$$;

revoke all on function corporate_allocate_trip(uuid) from public;
grant execute on function corporate_allocate_trip(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- complete_trip — post corporate allocation after completion (P8-A-01)
-- ---------------------------------------------------------------------------
create or replace function complete_trip(
  p_trip_id uuid,
  p_alighting jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_commission numeric;
  v_fare numeric;
  v_surcharge numeric;
  v_total numeric;
  v_ledger_entry driver_ledger_entries%rowtype;
  v_ext trip_extensions%rowtype;
  v_ext_ledger driver_ledger_entries%rowtype;
  v_ext_commission_total numeric := 0;
  v_corporate_allocation_id uuid;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.driver_id is distinct from v_driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'in_transit' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_alighting is not null then
    update trips
    set
      alighting_location = st_setsrid(
        st_makepoint(
          (p_alighting->>'lng')::double precision,
          (p_alighting->>'lat')::double precision
        ),
        4326
      )::geography,
      alighting_stage_id = nullif(p_alighting->>'stage_id', '')::uuid
    where id = p_trip_id;
  end if;

  perform trip_transition(p_trip_id, 'completed', 'driver', v_driver_id);

  v_corporate_allocation_id := corporate_allocate_trip(p_trip_id);

  select * into v_t from trips where id = p_trip_id;
  v_fare := v_t.fare_shown;
  v_surcharge := coalesce(v_t.load_surcharge_amount, 0);
  v_total := v_fare + v_surcharge;
  v_commission := coalesce(v_t.commission_amount, round(v_total * v_t.commission_rate, 2));

  if v_t.payment_method = 'cash' and v_commission > 0 then
    v_ledger_entry := ledger_post(
      v_t.driver_id,
      'cash_commission_debit',
      -v_commission,
      v_t.fare_currency,
      jsonb_build_object('trip_id', p_trip_id),
      format('trip:%s:commission', p_trip_id),
      'system',
      null,
      null
    );
  end if;

  if v_t.payment_method = 'cash' then
    for v_ext in
      select *
      from trip_extensions
      where trip_id = p_trip_id
        and status = 'accepted'
        and coalesce(commission_delta, 0) > 0
      order by proposed_at
    loop
      v_ext_ledger := ledger_post(
        v_t.driver_id,
        'cash_commission_debit',
        -v_ext.commission_delta,
        v_ext.currency,
        jsonb_build_object(
          'trip_id', p_trip_id,
          'trip_extension_id', v_ext.id
        ),
        format('ext:%s', v_ext.id),
        'system',
        null,
        null
      );

      perform set_config('along.in_extension_update', 'on', true);
      update trip_extensions
      set ledger_entry_id = v_ext_ledger.id
      where id = v_ext.id;
      perform set_config('along.in_extension_update', '', true);

      v_ext_commission_total := v_ext_commission_total + v_ext.commission_delta;
    end loop;
  end if;

  return jsonb_build_object(
    'trip', build_trip_view(p_trip_id, v_driver_id),
    'fare', jsonb_build_object('amount', v_fare, 'currency', v_t.fare_currency),
    'surcharge', case
      when v_surcharge > 0 then jsonb_build_object('amount', v_surcharge, 'currency', v_t.fare_currency)
      else null
    end,
    'total', jsonb_build_object('amount', v_total, 'currency', v_t.fare_currency),
    'commission', jsonb_build_object(
      'amount', v_commission + v_ext_commission_total,
      'currency', v_t.fare_currency,
      'base', v_commission,
      'extension', v_ext_commission_total
    ),
    'ledger_entry_id', v_ledger_entry.id,
    'corporate_allocation_id', v_corporate_allocation_id
  );
end;
$$;

grant execute on function complete_trip(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Invoice generation + reconciliation
-- ---------------------------------------------------------------------------
create or replace function generate_corporate_invoices(
  p_period_start timestamptz,
  p_period_end timestamptz
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_account corporate_accounts%rowtype;
  v_invoice_id uuid;
  v_total numeric;
  v_count int := 0;
  v_line_count int;
begin
  if p_period_end <= p_period_start then
    raise exception 'INVALID_PERIOD' using errcode = 'P0001';
  end if;

  for v_account in
    select *
    from corporate_accounts
    where status = 'active'
  loop
    select coalesce(sum(a.subsidized_amount), 0), count(*)
    into v_total, v_line_count
    from corporate_trip_allocations a
    where a.corporate_account_id = v_account.id
      and a.created_at >= p_period_start
      and a.created_at < p_period_end;

    if v_line_count = 0 then
      continue;
    end if;

    insert into corporate_invoices (
      corporate_account_id,
      period_start,
      period_end,
      total,
      currency,
      status
    ) values (
      v_account.id,
      p_period_start,
      p_period_end,
      v_total,
      v_account.currency,
      'generated'
    )
    on conflict (corporate_account_id, period_start, period_end) do nothing
    returning id into v_invoice_id;

    if v_invoice_id is null then
      continue;
    end if;

    insert into invoice_lines (invoice_id, allocation_id, amount)
    select v_invoice_id, a.id, a.subsidized_amount
    from corporate_trip_allocations a
    where a.corporate_account_id = v_account.id
      and a.created_at >= p_period_start
      and a.created_at < p_period_end
    on conflict (allocation_id) do nothing;

    v_count := v_count + 1;
  end loop;

  return jsonb_build_object(
    'period_start', p_period_start,
    'period_end', p_period_end,
    'invoices_created', v_count
  );
end;
$$;

revoke all on function generate_corporate_invoices(timestamptz, timestamptz) from public;
grant execute on function generate_corporate_invoices(timestamptz, timestamptz) to service_role;

create or replace function generate_corporate_invoices_monthly()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_period_end timestamptz := date_trunc('month', now() at time zone 'UTC') at time zone 'UTC';
  v_period_start timestamptz := (v_period_end - interval '1 month');
begin
  return generate_corporate_invoices(v_period_start, v_period_end);
end;
$$;

revoke all on function generate_corporate_invoices_monthly() from public;
grant execute on function generate_corporate_invoices_monthly() to service_role;

create or replace function reconcile_corporate_invoice(p_invoice_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_invoice corporate_invoices%rowtype;
  v_line_total numeric;
  v_alloc_total numeric;
  v_expected_lines int;
  v_actual_lines int;
  v_missing int;
  v_extra int;
  v_mismatch int;
begin
  select * into v_invoice from corporate_invoices where id = p_invoice_id;
  if v_invoice.id is null then
    return jsonb_build_object('ok', false, 'reason', 'invoice_not_found');
  end if;

  select coalesce(sum(amount), 0), count(*)
  into v_line_total, v_actual_lines
  from invoice_lines
  where invoice_id = p_invoice_id;

  if v_line_total is distinct from v_invoice.total then
    return jsonb_build_object(
      'ok', false,
      'reason', 'invoice_total_mismatch',
      'invoice_total', v_invoice.total,
      'line_total', v_line_total
    );
  end if;

  select coalesce(sum(il.amount), 0)
  into v_alloc_total
  from invoice_lines il
  join corporate_trip_allocations a on a.id = il.allocation_id
  where il.invoice_id = p_invoice_id;

  if v_alloc_total is distinct from v_invoice.total then
    return jsonb_build_object(
      'ok', false,
      'reason', 'allocation_total_mismatch',
      'invoice_total', v_invoice.total,
      'allocation_total', v_alloc_total
    );
  end if;

  select count(*)
  into v_mismatch
  from invoice_lines il
  join corporate_trip_allocations a on a.id = il.allocation_id
  where il.invoice_id = p_invoice_id
    and il.amount is distinct from a.subsidized_amount;

  if v_mismatch > 0 then
    return jsonb_build_object(
      'ok', false,
      'reason', 'line_amount_mismatch',
      'mismatch_count', v_mismatch
    );
  end if;

  select count(*)
  into v_expected_lines
  from corporate_trip_allocations a
  where a.corporate_account_id = v_invoice.corporate_account_id
    and a.created_at >= v_invoice.period_start
    and a.created_at < v_invoice.period_end;

  if v_actual_lines <> v_expected_lines then
    return jsonb_build_object(
      'ok', false,
      'reason', 'allocation_coverage_mismatch',
      'expected_lines', v_expected_lines,
      'actual_lines', v_actual_lines
    );
  end if;

  select count(*)
  into v_extra
  from invoice_lines il
  join corporate_trip_allocations a on a.id = il.allocation_id
  where il.invoice_id = p_invoice_id
    and (
      a.corporate_account_id <> v_invoice.corporate_account_id
      or a.created_at < v_invoice.period_start
      or a.created_at >= v_invoice.period_end
    );

  if v_extra > 0 then
    return jsonb_build_object(
      'ok', false,
      'reason', 'extra_or_out_of_period_line',
      'extra_count', v_extra
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'invoice_id', p_invoice_id,
    'total', v_invoice.total,
    'line_count', v_actual_lines
  );
end;
$$;

revoke all on function reconcile_corporate_invoice(uuid) from public;
grant execute on function reconcile_corporate_invoice(uuid) to service_role, authenticated;

-- ---------------------------------------------------------------------------
-- Audit — admin-writable corporate tables (doc 02 §15)
-- ---------------------------------------------------------------------------
create trigger audit_corporate_accounts
  after insert or update or delete on corporate_accounts
  for each row execute function audit_admin_write();

create trigger audit_corporate_members
  after insert or update or delete on corporate_members
  for each row execute function audit_admin_write();

create trigger audit_corporate_trip_policies
  after insert or update or delete on corporate_trip_policies
  for each row execute function audit_admin_write();

-- ---------------------------------------------------------------------------
-- RLS (doc 02 §13: corporate_admin scoped to own account; others admin-only)
-- ---------------------------------------------------------------------------
alter table corporate_accounts enable row level security;
alter table corporate_members enable row level security;
alter table corporate_trip_policies enable row level security;
alter table corporate_trip_allocations enable row level security;
alter table corporate_invoices enable row level security;
alter table invoice_lines enable row level security;

create policy corporate_accounts_select_admin
  on corporate_accounts for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead'])
    and (
      has_admin_role(array['superadmin'])
      or deployment_id = (
        select a.deployment_id from admin_users a
        where a.id = auth.uid() and a.disabled_at is null
      )
    )
  );

create policy corporate_accounts_select_corporate_admin
  on corporate_accounts for select to authenticated
  using (id = admin_corporate_account_id());

create policy corporate_accounts_no_client_write
  on corporate_accounts for all to authenticated
  using (false)
  with check (false);

create policy corporate_members_select_admin
  on corporate_members for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead'])
    and exists (
      select 1 from corporate_accounts ca
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where ca.id = corporate_members.corporate_account_id
        and ca.deployment_id = au.deployment_id
    )
  );

create policy corporate_members_select_corporate_admin
  on corporate_members for select to authenticated
  using (corporate_account_id = admin_corporate_account_id());

create policy corporate_members_no_client_write
  on corporate_members for all to authenticated
  using (false)
  with check (false);

create policy corporate_trip_policies_select_admin
  on corporate_trip_policies for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead'])
    and exists (
      select 1 from corporate_accounts ca
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where ca.id = corporate_trip_policies.corporate_account_id
        and ca.deployment_id = au.deployment_id
    )
  );

create policy corporate_trip_policies_select_corporate_admin
  on corporate_trip_policies for select to authenticated
  using (corporate_account_id = admin_corporate_account_id());

create policy corporate_trip_policies_no_client_write
  on corporate_trip_policies for all to authenticated
  using (false)
  with check (false);

create policy corporate_trip_allocations_select_admin
  on corporate_trip_allocations for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead'])
    and exists (
      select 1 from corporate_accounts ca
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where ca.id = corporate_trip_allocations.corporate_account_id
        and ca.deployment_id = au.deployment_id
    )
  );

create policy corporate_trip_allocations_select_corporate_admin
  on corporate_trip_allocations for select to authenticated
  using (corporate_account_id = admin_corporate_account_id());

create policy corporate_trip_allocations_no_client_write
  on corporate_trip_allocations for all to authenticated
  using (false)
  with check (false);

create policy corporate_invoices_select_admin
  on corporate_invoices for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead'])
    and exists (
      select 1 from corporate_accounts ca
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where ca.id = corporate_invoices.corporate_account_id
        and ca.deployment_id = au.deployment_id
    )
  );

create policy corporate_invoices_select_corporate_admin
  on corporate_invoices for select to authenticated
  using (corporate_account_id = admin_corporate_account_id());

create policy corporate_invoices_no_client_write
  on corporate_invoices for all to authenticated
  using (false)
  with check (false);

create policy invoice_lines_select_admin
  on invoice_lines for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead'])
    and exists (
      select 1
      from corporate_invoices ci
      join corporate_accounts ca on ca.id = ci.corporate_account_id
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where ci.id = invoice_lines.invoice_id
        and ca.deployment_id = au.deployment_id
    )
  );

create policy invoice_lines_select_corporate_admin
  on invoice_lines for select to authenticated
  using (
    exists (
      select 1
      from corporate_invoices ci
      where ci.id = invoice_lines.invoice_id
        and ci.corporate_account_id = admin_corporate_account_id()
    )
  );

create policy invoice_lines_no_client_write
  on invoice_lines for all to authenticated
  using (false)
  with check (false);

grant select on corporate_accounts to authenticated;
grant select on corporate_members to authenticated;
grant select on corporate_trip_policies to authenticated;
grant select on corporate_trip_allocations to authenticated;
grant select on corporate_invoices to authenticated;
grant select on invoice_lines to authenticated;

-- ---------------------------------------------------------------------------
-- pg_cron — monthly corporate invoices (doc 03 §12)
-- ---------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
  v_day int;
  v_hour int;
  v_schedule text;
begin
  v_day := cfg_num('jobs.corporate_invoice_day')::int;
  v_hour := cfg_num('jobs.corporate_invoice_hour_utc')::int;
  v_schedule := format('0 %s %s * *', v_hour, v_day);

  for v_jobid in select jobid from cron.job where jobname = 'generate_corporate_invoices_monthly' loop
    perform cron.unschedule(v_jobid);
  end loop;

  perform cron.schedule(
    'generate_corporate_invoices_monthly',
    v_schedule,
    $cron$select generate_corporate_invoices_monthly()$cron$
  );
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule generate_corporate_invoices_monthly manually (doc 03 §12)';
  when others then
    raise notice 'pg_cron corporate invoice schedule skipped: %', sqlerrm;
end;
$$;
