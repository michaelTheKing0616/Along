-- P4-A-01: ledger entries, ledger_post, driver_balances, driver_is_matchable balance gate,
-- complete_trip cash commission posting (doc 02 §9, doc 04 §12.1–12.2)

-- ---------------------------------------------------------------------------
-- Ledger types & append-only entries (doc 02 §9)
-- ---------------------------------------------------------------------------
create type ledger_entry_type as enum (
  'cash_commission_debit',
  'digital_settlement_credit',
  'onboarding_deposit',
  'deposit_drawdown',
  'payout_debit',
  'manual_adjustment'
);

create type ledger_actor as enum ('system', 'admin', 'agent', 'payment_webhook');

create table driver_ledger_entries (
  id bigserial primary key,
  driver_id uuid not null references drivers(id),
  trip_id uuid references trips(id),
  trip_extension_id uuid references trip_extensions(id),
  settlement_id uuid,
  entry_type ledger_entry_type not null,
  amount numeric(12,2) not null,
  currency char(3) not null,
  balance_after numeric(12,2) not null,
  created_by_type ledger_actor not null,
  created_by_id uuid,
  idempotency_key text not null unique,
  memo text,
  created_at timestamptz not null default now(),
  check (
    (entry_type in ('cash_commission_debit', 'deposit_drawdown', 'payout_debit') and amount < 0)
    or (entry_type in ('digital_settlement_credit', 'onboarding_deposit') and amount > 0)
    or (entry_type = 'manual_adjustment' and amount <> 0 and memo is not null)
  )
);

create index dle_driver_created on driver_ledger_entries(driver_id, created_at desc);

create trigger dle_ro before update or delete on driver_ledger_entries
  for each row execute function forbid_mutation();

alter table trip_extensions
  add constraint te_ledger_fk foreign key (ledger_entry_id)
  references driver_ledger_entries(id);

create or replace view driver_balances as
  select driver_id, currency, sum(amount) as balance, max(created_at) as as_of
  from driver_ledger_entries
  group by driver_id, currency;

-- ---------------------------------------------------------------------------
-- RLS (doc 02 §16)
-- ---------------------------------------------------------------------------
alter table driver_ledger_entries enable row level security;

create policy driver_ledger_entries_select_own
  on driver_ledger_entries for select to authenticated
  using (driver_id = auth.uid());

create policy driver_ledger_entries_select_admin
  on driver_ledger_entries for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy driver_ledger_entries_no_client_write
  on driver_ledger_entries for all to authenticated
  using (false)
  with check (false);

grant select on driver_ledger_entries to authenticated;
grant select on driver_balances to authenticated;

-- ---------------------------------------------------------------------------
-- ledger_post — advisory lock + idempotency (doc 04 §12.1)
-- ---------------------------------------------------------------------------
create or replace function ledger_post(
  p_driver_id uuid,
  p_entry_type ledger_entry_type,
  p_amount numeric,
  p_currency char(3),
  p_refs jsonb default '{}'::jsonb,
  p_idempotency_key text default null,
  p_actor_type ledger_actor default 'system',
  p_actor_id uuid default null,
  p_memo text default null
)
returns driver_ledger_entries
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_existing driver_ledger_entries%rowtype;
  v_prev numeric;
  v_row driver_ledger_entries%rowtype;
begin
  if p_idempotency_key is null or btrim(p_idempotency_key) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(hashtext(p_driver_id::text));

  select * into v_existing
  from driver_ledger_entries
  where idempotency_key = p_idempotency_key;

  if found then
    return v_existing;
  end if;

  select coalesce(
    (
      select dle.balance_after
      from driver_ledger_entries dle
      where dle.driver_id = p_driver_id
      order by dle.id desc
      limit 1
    ),
    0
  ) into v_prev;

  insert into driver_ledger_entries (
    driver_id,
    trip_id,
    trip_extension_id,
    settlement_id,
    entry_type,
    amount,
    currency,
    balance_after,
    created_by_type,
    created_by_id,
    idempotency_key,
    memo
  ) values (
    p_driver_id,
    nullif(p_refs->>'trip_id', '')::uuid,
    nullif(p_refs->>'trip_extension_id', '')::uuid,
    nullif(p_refs->>'settlement_id', '')::uuid,
    p_entry_type,
    p_amount,
    p_currency,
    v_prev + p_amount,
    p_actor_type,
    p_actor_id,
    p_idempotency_key,
    p_memo
  )
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function ledger_post(uuid, ledger_entry_type, numeric, char, jsonb, text, ledger_actor, uuid, text)
  from public;
grant execute on function ledger_post(uuid, ledger_entry_type, numeric, char, jsonb, text, ledger_actor, uuid, text)
  to service_role;

-- ---------------------------------------------------------------------------
-- driver_is_matchable — verification + standing + ledger balance (doc 04 §12.2)
-- ---------------------------------------------------------------------------
create or replace function driver_is_matchable(p_driver_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select d.verified_status = 'verified'
       and d.standing in ('good_standing', 'warned')
       and coalesce((
         select sum(db.balance)
         from driver_balances db
         where db.driver_id = d.id
       ), 0) > cfg_num('ledger.block_threshold', d.city_id)
    from drivers d
    where d.id = p_driver_id
  ), false)
$$;

grant execute on function driver_is_matchable(uuid) to authenticated, anon;

-- ---------------------------------------------------------------------------
-- complete_trip — wire cash commission ledger post (doc 04 §10, §12.1)
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
  v_ledger_entry driver_ledger_entries%rowtype;
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

  select * into v_t from trips where id = p_trip_id;
  v_fare := v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0);
  v_commission := coalesce(v_t.commission_amount, round(v_fare * v_t.commission_rate, 2));

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

  return jsonb_build_object(
    'trip', build_trip_view(p_trip_id, v_driver_id),
    'commission', jsonb_build_object('amount', v_commission, 'currency', v_t.fare_currency),
    'fare', jsonb_build_object('amount', v_fare, 'currency', v_t.fare_currency),
    'ledger_entry_id', v_ledger_entry.id
  );
end;
$$;

grant execute on function complete_trip(uuid, jsonb) to authenticated;
