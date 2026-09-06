-- P4-A-07: manual ledger adjustments (dual control), driver payouts (Paystack transfer),
-- finance admin RPCs (doc 03 §11, doc 08 §5, ADR-0010)

-- ---------------------------------------------------------------------------
-- Pending manual adjustments (dual control enforced in SQL)
-- ---------------------------------------------------------------------------
create type ledger_adjustment_status as enum ('pending', 'approved', 'rejected');

create table pending_ledger_adjustments (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  amount numeric(12,2) not null check (amount <> 0),
  currency char(3) not null,
  memo text not null check (btrim(memo) <> ''),
  status ledger_adjustment_status not null default 'pending',
  requested_by uuid not null references admin_users(id),
  approved_by uuid references admin_users(id),
  ledger_entry_id bigint references driver_ledger_entries(id),
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  check (approved_by is null or approved_by <> requested_by)
);

create index pla_driver_status on pending_ledger_adjustments(driver_id, status)
  where status = 'pending';

create trigger pending_ledger_adjustments_audit
  after insert or update or delete on pending_ledger_adjustments
  for each row execute function audit_admin_write();

alter table pending_ledger_adjustments enable row level security;

create policy pending_ledger_adjustments_select_admin
  on pending_ledger_adjustments for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy pending_ledger_adjustments_no_client_write
  on pending_ledger_adjustments for all to authenticated
  using (false)
  with check (false);

grant select on pending_ledger_adjustments to authenticated;

-- ---------------------------------------------------------------------------
-- Driver payouts (Along paying positive balance out via Paystack transfer)
-- ---------------------------------------------------------------------------
create type driver_payout_status as enum ('pending', 'confirmed', 'failed');

create table driver_payouts (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  amount numeric(12,2) not null check (amount > 0),
  currency char(3) not null,
  status driver_payout_status not null default 'pending',
  provider_reference text not null unique,
  recipient_subaccount_code text not null,
  ledger_entry_id bigint references driver_ledger_entries(id),
  initiated_by uuid not null references admin_users(id),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);

create index driver_payouts_driver_created on driver_payouts(driver_id, created_at desc);
create index driver_payouts_pending on driver_payouts(driver_id) where status = 'pending';

create trigger driver_payouts_audit
  after insert or update or delete on driver_payouts
  for each row execute function audit_admin_write();

alter table driver_payouts enable row level security;

create policy driver_payouts_select_own
  on driver_payouts for select to authenticated
  using (driver_id = auth.uid());

create policy driver_payouts_select_admin
  on driver_payouts for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy driver_payouts_no_client_write
  on driver_payouts for all to authenticated
  using (false)
  with check (false);

grant select on driver_payouts to authenticated;

-- ---------------------------------------------------------------------------
-- Audit helper for finance RPCs (explicit action names beyond table triggers)
-- ---------------------------------------------------------------------------
create or replace function private.audit_finance_action(
  p_action text,
  p_target_type text,
  p_target_id text,
  p_before jsonb default null,
  p_after jsonb default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_role text;
begin
  select a.role::text into v_actor_role
  from admin_users a
  where a.id = auth.uid() and a.disabled_at is null;

  insert into audit_log (
    actor_id, actor_role, action, target_type, target_id, before, after
  ) values (
    auth.uid(),
    v_actor_role,
    p_action,
    p_target_type,
    p_target_id,
    p_before,
    p_after
  );
end;
$$;

revoke all on function private.audit_finance_action(text, text, text, jsonb, jsonb) from public;
grant execute on function private.audit_finance_action(text, text, text, jsonb, jsonb)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- admin_manual_ledger_adjustment — doc 03 §11
-- ---------------------------------------------------------------------------
create or replace function admin_manual_ledger_adjustment(
  p_driver_id uuid,
  p_amount numeric,
  p_memo text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_driver drivers%rowtype;
  v_currency char(3);
  v_threshold numeric;
  v_request pending_ledger_adjustments%rowtype;
  v_ledger driver_ledger_entries%rowtype;
begin
  if not has_admin_role(array['finance']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_memo is null or btrim(p_memo) = '' then
    raise exception using errcode = 'P0001', message = 'memo is required';
  end if;

  if p_amount is null or p_amount = 0 then
    raise exception using errcode = 'P0001', message = 'amount must be non-zero';
  end if;

  select * into v_driver from drivers where id = p_driver_id;
  if v_driver.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_driver.city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select c.currency_code into v_currency
  from cities ci
  join countries c on c.code = ci.country_code
  where ci.id = v_driver.city_id;

  v_threshold := cfg_num('ledger.dual_control_threshold', v_driver.city_id);

  if abs(p_amount) > v_threshold then
    insert into pending_ledger_adjustments (
      driver_id, amount, currency, memo, requested_by
    ) values (
      p_driver_id, p_amount, v_currency, btrim(p_memo), auth.uid()
    )
    returning * into v_request;

    perform private.audit_finance_action(
      'request_adjustment',
      'pending_ledger_adjustments',
      v_request.id::text,
      null,
      jsonb_build_object(
        'driver_id', p_driver_id,
        'amount', p_amount,
        'memo', btrim(p_memo),
        'status', 'pending'
      )
    );

    return jsonb_build_object(
      'status', 'pending',
      'request_id', v_request.id,
      'requires_approval', true
    );
  end if;

  v_ledger := ledger_post(
    p_driver_id,
    'manual_adjustment',
    p_amount,
    v_currency,
    '{}'::jsonb,
    format('manual_adj:%s:%s', p_driver_id, gen_random_uuid()),
    'admin',
    auth.uid(),
    btrim(p_memo)
  );

  perform private.audit_finance_action(
    'post_adjustment',
    'driver_ledger_entries',
    v_ledger.id::text,
    null,
    jsonb_build_object(
      'driver_id', p_driver_id,
      'amount', p_amount,
      'memo', btrim(p_memo),
      'entry_type', 'manual_adjustment'
    )
  );

  return jsonb_build_object(
    'status', 'posted',
    'ledger_entry_id', v_ledger.id,
    'balance_after', v_ledger.balance_after
  );
end;
$$;

grant execute on function admin_manual_ledger_adjustment(uuid, numeric, text) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_approve_adjustment — second distinct finance/ops_lead approver
-- ---------------------------------------------------------------------------
create or replace function admin_approve_adjustment(p_request_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_request pending_ledger_adjustments%rowtype;
  v_ledger driver_ledger_entries%rowtype;
  v_city_id uuid;
begin
  if not has_admin_role(array['finance', 'ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_request
  from pending_ledger_adjustments
  where id = p_request_id
  for update;

  if v_request.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select d.city_id into v_city_id
  from drivers d
  where d.id = v_request.driver_id;

  if not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_request.status <> 'pending' then
    raise exception using errcode = 'P0001', message = 'request is not pending';
  end if;

  if v_request.requested_by = auth.uid() then
    raise exception using errcode = 'P0001', message = 'cannot approve own adjustment request';
  end if;

  v_ledger := ledger_post(
    v_request.driver_id,
    'manual_adjustment',
    v_request.amount,
    v_request.currency,
    '{}'::jsonb,
    format('manual_adj:approved:%s', p_request_id),
    'admin',
    auth.uid(),
    v_request.memo
  );

  update pending_ledger_adjustments
  set
    status = 'approved',
    approved_by = auth.uid(),
    approved_at = now(),
    ledger_entry_id = v_ledger.id
  where id = p_request_id;

  perform private.audit_finance_action(
    'approve_adjustment',
    'pending_ledger_adjustments',
    p_request_id::text,
    jsonb_build_object('status', 'pending', 'requested_by', v_request.requested_by),
    jsonb_build_object(
      'status', 'approved',
      'approved_by', auth.uid(),
      'ledger_entry_id', v_ledger.id
    )
  );

  return jsonb_build_object(
    'status', 'approved',
    'request_id', p_request_id,
    'ledger_entry_id', v_ledger.id,
    'balance_after', v_ledger.balance_after
  );
end;
$$;

grant execute on function admin_approve_adjustment(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_payout_positive_balance — pending payout; ledger on transfer webhook
-- ---------------------------------------------------------------------------
create or replace function admin_payout_positive_balance(p_driver_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_driver drivers%rowtype;
  v_balance numeric;
  v_currency char(3);
  v_payout_id uuid;
  v_reference text;
  v_existing uuid;
begin
  if not has_admin_role(array['finance']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_driver from drivers where id = p_driver_id for update;
  if v_driver.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_driver.city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_driver.payout_subaccount_code is null or btrim(v_driver.payout_subaccount_code) = '' then
    raise exception using errcode = 'P0001', message = 'driver has no payout subaccount';
  end if;

  select coalesce(sum(db.balance), 0) into v_balance
  from driver_balances db
  where db.driver_id = p_driver_id;

  if v_balance <= 0 then
    raise exception using errcode = 'P0001', message = 'driver balance is not positive';
  end if;

  select id into v_existing
  from driver_payouts
  where driver_id = p_driver_id and status = 'pending'
  limit 1;

  if v_existing is not null then
    raise exception using errcode = 'P0001', message = 'payout already pending for driver';
  end if;

  select c.currency_code into v_currency
  from cities ci
  join countries c on c.code = ci.country_code
  where ci.id = v_driver.city_id;

  v_payout_id := gen_random_uuid();
  v_reference := format('payout_%s', replace(v_payout_id::text, '-', ''));

  insert into driver_payouts (
    id,
    driver_id,
    amount,
    currency,
    status,
    provider_reference,
    recipient_subaccount_code,
    initiated_by
  ) values (
    v_payout_id,
    p_driver_id,
    v_balance,
    v_currency,
    'pending',
    v_reference,
    v_driver.payout_subaccount_code,
    auth.uid()
  );

  perform private.audit_finance_action(
    'initiate_payout',
    'driver_payouts',
    v_payout_id::text,
    null,
    jsonb_build_object(
      'driver_id', p_driver_id,
      'amount', v_balance,
      'provider_reference', v_reference,
      'recipient_subaccount_code', v_driver.payout_subaccount_code
    )
  );

  return jsonb_build_object(
    'payout_id', v_payout_id,
    'provider_reference', v_reference,
    'amount', v_balance,
    'currency', v_currency,
    'recipient_subaccount_code', v_driver.payout_subaccount_code,
    'status', 'pending'
  );
end;
$$;

grant execute on function admin_payout_positive_balance(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- apply_paystack_transfer_success — idempotent payout_debit (webhook / tests)
-- OPEN QUESTION: Paystack transfer.success payload shape for subaccount recipients
-- is not fully specified in doc 14; metadata.payout_id is the Along idempotency anchor.
-- ---------------------------------------------------------------------------
create or replace function apply_paystack_transfer_success(
  p_reference text,
  p_amount numeric,
  p_metadata jsonb default '{}'::jsonb
)
returns driver_ledger_entries
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_existing driver_ledger_entries%rowtype;
  v_payout driver_payouts%rowtype;
  v_payout_id uuid;
  v_idempotency text;
  v_ledger driver_ledger_entries%rowtype;
begin
  if p_reference is null or btrim(p_reference) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_idempotency := format('paystack_transfer:%s', p_reference);

  select * into v_existing
  from driver_ledger_entries
  where idempotency_key = v_idempotency;

  if found then
    return v_existing;
  end if;

  v_payout_id := nullif(p_metadata->>'payout_id', '')::uuid;

  if v_payout_id is not null then
    select * into v_payout
    from driver_payouts
    where id = v_payout_id
    for update;
  else
    select * into v_payout
    from driver_payouts
    where provider_reference = p_reference
    for update;
  end if;

  if v_payout.id is null then
    raise exception using errcode = 'P0001', message = 'payout not found';
  end if;

  if v_payout.status = 'confirmed' then
    select * into v_existing
    from driver_ledger_entries
    where id = v_payout.ledger_entry_id;
    if found then
      return v_existing;
    end if;
  end if;

  if v_payout.status <> 'pending' then
    raise exception using errcode = 'P0001', message = 'payout is not pending';
  end if;

  if p_amount is distinct from v_payout.amount then
    raise exception using errcode = 'P0001', message = 'amount mismatch';
  end if;

  v_ledger := ledger_post(
    v_payout.driver_id,
    'payout_debit',
    -v_payout.amount,
    v_payout.currency,
    jsonb_build_object('payout_id', v_payout.id),
    v_idempotency,
    'payment_webhook',
    null,
    format('Paystack payout %s', p_reference)
  );

  update driver_payouts
  set
    status = 'confirmed',
    ledger_entry_id = v_ledger.id,
    confirmed_at = now()
  where id = v_payout.id;

  return v_ledger;
end;
$$;

revoke all on function apply_paystack_transfer_success(text, numeric, jsonb) from public;
grant execute on function apply_paystack_transfer_success(text, numeric, jsonb) to service_role;
