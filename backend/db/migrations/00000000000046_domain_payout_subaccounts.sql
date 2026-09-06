-- P4-A-08: Paystack subaccounts — payout bank persist, re-auth, split settlement reconciliation
-- (doc 03 §7, ADR-0010)

select config_default('auth.payout_reauth_window_s', '300');

-- ---------------------------------------------------------------------------
-- profiles.phone_reauth_at — fresh OTP before sensitive driver actions (doc 12 T7)
-- ---------------------------------------------------------------------------
alter table profiles add column if not exists phone_reauth_at timestamptz;

-- ---------------------------------------------------------------------------
-- split_settlement_alerts — finance-visible mismatch vs provider split totals
-- ---------------------------------------------------------------------------
create table split_settlement_alerts (
  id uuid primary key default gen_random_uuid(),
  reconciliation_day date not null,
  driver_id uuid not null references drivers(id),
  subaccount_code text not null,
  expected_driver_total numeric(12,2) not null,
  provider_reported_total numeric(12,2) not null,
  delta numeric(12,2) not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index split_settlement_alerts_day on split_settlement_alerts(reconciliation_day desc);
create index split_settlement_alerts_open on split_settlement_alerts(status, created_at desc)
  where status = 'open';

alter table split_settlement_alerts enable row level security;

create policy split_settlement_alerts_select_finance
  on split_settlement_alerts for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'finance']));

create policy split_settlement_alerts_no_client_write
  on split_settlement_alerts for all to authenticated
  using (false)
  with check (false);

grant select on split_settlement_alerts to authenticated;

-- ---------------------------------------------------------------------------
-- protect payout columns from direct client updates
-- ---------------------------------------------------------------------------
create or replace function protect_driver_columns()
returns trigger
language plpgsql
as $$
begin
  if coalesce(current_setting('role', true), '') = 'service_role'
     or current_user in ('postgres', 'supabase_admin') then
    return new;
  end if;

  if new.verified_status is distinct from old.verified_status then
    raise exception 'cannot update verified_status' using errcode = '42501';
  end if;
  if new.standing is distinct from old.standing then
    raise exception 'cannot update standing' using errcode = '42501';
  end if;
  if new.rating is distinct from old.rating then
    raise exception 'cannot update rating' using errcode = '42501';
  end if;
  if new.rating_count is distinct from old.rating_count then
    raise exception 'cannot update rating_count' using errcode = '42501';
  end if;
  if new.women_only_eligible is distinct from old.women_only_eligible then
    raise exception 'cannot update women_only_eligible' using errcode = '42501';
  end if;
  if new.payout_subaccount_code is distinct from old.payout_subaccount_code then
    raise exception 'cannot update payout_subaccount_code' using errcode = '42501';
  end if;
  if new.payout_bank_last4 is distinct from old.payout_bank_last4 then
    raise exception 'cannot update payout_bank_last4' using errcode = '42501';
  end if;
  if new.driver_code is distinct from old.driver_code then
    raise exception 'cannot update driver_code' using errcode = '42501';
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- record_phone_reauth — client calls after successful verifyOtp (doc 12 T7)
-- ---------------------------------------------------------------------------
create or replace function record_phone_reauth()
returns timestamptz
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_now timestamptz := now();
begin
  if auth.uid() is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  update profiles
  set phone_reauth_at = v_now
  where id = auth.uid();

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  return v_now;
end;
$$;

grant execute on function record_phone_reauth() to authenticated;

-- ---------------------------------------------------------------------------
-- assert_payout_reauth — raises REAUTH_REQUIRED when OTP window expired
-- ---------------------------------------------------------------------------
create or replace function assert_payout_reauth(p_user_id uuid default auth.uid())
returns void
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_reauth_at timestamptz;
  v_window_s numeric;
begin
  if p_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select p.phone_reauth_at into v_reauth_at
  from profiles p
  where p.id = p_user_id;

  if v_reauth_at is null then
    raise exception 'REAUTH_REQUIRED' using errcode = 'P0001';
  end if;

  v_window_s := cfg_num('auth.payout_reauth_window_s', null);

  if v_reauth_at < now() - make_interval(secs => v_window_s::int) then
    raise exception 'REAUTH_REQUIRED' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function assert_payout_reauth(uuid) from public;
grant execute on function assert_payout_reauth(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- persist_driver_payout_bank — own driver only; never accepts full account number
-- ---------------------------------------------------------------------------
create or replace function persist_driver_payout_bank(
  p_subaccount_code text,
  p_bank_last4 text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_code text;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (select 1 from drivers d where d.id = v_driver_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001', message = 'not a driver';
  end if;

  perform assert_payout_reauth(v_driver_id);

  if p_subaccount_code is null or btrim(p_subaccount_code) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'subaccount_code required';
  end if;

  if p_bank_last4 is null or btrim(p_bank_last4) = '' or length(p_bank_last4) <> 4 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'bank_last4 required';
  end if;

  if p_bank_last4 !~ '^\d{4}$' then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'bank_last4 must be 4 digits';
  end if;

  update drivers
  set
    payout_subaccount_code = btrim(p_subaccount_code),
    payout_bank_last4 = p_bank_last4,
    driver_code = coalesce(driver_code, generate_driver_code())
  where id = v_driver_id
  returning driver_code into v_code;

  return jsonb_build_object(
    'payout_subaccount_code', btrim(p_subaccount_code),
    'payout_bank_last4', p_bank_last4,
    'driver_code', v_code
  );
end;
$$;

grant execute on function persist_driver_payout_bank(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- reconcile_split_settlements — compare payments.driver_amount vs injected totals
-- ---------------------------------------------------------------------------
create or replace function reconcile_split_settlements(
  p_day date,
  p_provider_totals jsonb default '{}'::jsonb
)
returns int
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_row record;
  v_provider_total numeric;
  v_inserted int := 0;
begin
  if p_day is null then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'day required';
  end if;

  for v_row in
    select
      d.id as driver_id,
      d.payout_subaccount_code as subaccount_code,
      coalesce(sum(p.driver_amount), 0)::numeric(12,2) as expected_total
    from drivers d
    join payments p on p.driver_id = d.id
    where p.status = 'succeeded'
      and d.payout_subaccount_code is not null
      and btrim(d.payout_subaccount_code) <> ''
      and p.confirmed_at >= p_day::timestamptz
      and p.confirmed_at < (p_day + 1)::timestamptz
    group by d.id, d.payout_subaccount_code
  loop
    v_provider_total := coalesce(
      (p_provider_totals ->> v_row.subaccount_code)::numeric,
      -1
    );

    if v_provider_total is distinct from v_row.expected_total then
      insert into split_settlement_alerts (
        reconciliation_day,
        driver_id,
        subaccount_code,
        expected_driver_total,
        provider_reported_total,
        delta
      ) values (
        p_day,
        v_row.driver_id,
        v_row.subaccount_code,
        v_row.expected_total,
        v_provider_total,
        v_row.expected_total - v_provider_total
      );
      v_inserted := v_inserted + 1;
    end if;
  end loop;

  return v_inserted;
end;
$$;

revoke all on function reconcile_split_settlements(date, jsonb) from public;
grant execute on function reconcile_split_settlements(date, jsonb) to service_role;
