-- Rider wallet (PR #27): double-entry ledger, balances, RLS, idempotent RPCs.
-- Payment provider is stubbed: top-ups post against a system clearing account
-- (the provider receivable). No paid services are called from the database.
--
-- Invariants
--   * every wallet_transaction's entries sum to zero (deferred constraint trigger)
--   * rider balances never go negative (check constraint)
--   * entries and transactions are append-only (update/delete blocked)
--   * cached balances equal the sum of entries (wallet_ledger_check())
--   * every RPC is idempotent on (initiator, idempotency_key)

-- RLS: owner reads own account; admins read all; no direct writes.
create table wallet_accounts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references profiles(id) on delete restrict,
  kind text not null check (kind in ('rider', 'provider_clearing', 'fares')),
  balance numeric(12,2) not null default 0,
  currency text not null default 'NGN',
  created_at timestamptz not null default now(),
  constraint wallet_accounts_owner_kind check ((kind = 'rider') = (owner_id is not null)),
  constraint wallet_accounts_no_negative check (kind <> 'rider' or balance >= 0)
);
create unique index wallet_accounts_owner_uq on wallet_accounts(owner_id) where kind = 'rider';
create unique index wallet_accounts_system_uq on wallet_accounts(kind) where kind <> 'rider';

-- RLS: a party (initiator or entry-account owner) reads; no direct writes.
create table wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('top_up', 'fare', 'refund', 'send', 'pass', 'split')),
  initiator_id uuid not null references profiles(id) on delete restrict,
  idempotency_key text not null check (length(idempotency_key) between 8 and 128),
  memo jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint wallet_transactions_idem_uq unique (initiator_id, idempotency_key)
);

-- RLS: owner of the entry's account reads; no direct writes.
create table wallet_entries (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references wallet_transactions(id) on delete restrict,
  account_id uuid not null references wallet_accounts(id) on delete restrict,
  amount numeric(12,2) not null check (amount <> 0),
  created_at timestamptz not null default now()
);
create index wallet_entries_account_idx on wallet_entries(account_id, created_at desc);
create index wallet_entries_tx_idx on wallet_entries(transaction_id);

-- RLS: requester or payer reads; writes through RPCs only.
create table wallet_splits (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references profiles(id) on delete restrict,
  payer_id uuid not null references profiles(id) on delete restrict,
  trip_id uuid references trips(id) on delete set null,
  amount numeric(12,2) not null check (amount >= 50 and amount <= 50000),
  status text not null default 'pending' check (status in ('pending', 'paid', 'declined')),
  transaction_id uuid references wallet_transactions(id) on delete restrict,
  request_key text not null check (length(request_key) between 8 and 128),
  created_at timestamptz not null default now(),
  settled_at timestamptz,
  constraint wallet_splits_distinct check (requester_id <> payer_id),
  constraint wallet_splits_paid_tx check ((status = 'paid') = (transaction_id is not null))
);
create unique index wallet_splits_request_uq on wallet_splits(requester_id, request_key, payer_id);
create index wallet_splits_payer_idx on wallet_splits(payer_id, status);
create index wallet_splits_requester_idx on wallet_splits(requester_id, created_at desc);

alter table wallet_accounts enable row level security;
alter table wallet_transactions enable row level security;
alter table wallet_entries enable row level security;
alter table wallet_splits enable row level security;

create policy wallet_accounts_select_own
  on wallet_accounts for select to authenticated
  using (owner_id = auth.uid() or is_admin());

create policy wallet_entries_select_own
  on wallet_entries for select to authenticated
  using (is_admin() or exists (
    select 1 from wallet_accounts a
    where a.id = wallet_entries.account_id and a.owner_id = auth.uid()));

create policy wallet_transactions_select_party
  on wallet_transactions for select to authenticated
  using (initiator_id = auth.uid() or is_admin() or exists (
    select 1 from wallet_entries e join wallet_accounts a on a.id = e.account_id
    where e.transaction_id = wallet_transactions.id and a.owner_id = auth.uid()));

create policy wallet_splits_select_party
  on wallet_splits for select to authenticated
  using (requester_id = auth.uid() or payer_id = auth.uid() or is_admin());

revoke insert, update, delete, truncate on wallet_accounts, wallet_transactions, wallet_entries, wallet_splits from anon, authenticated;
grant select on wallet_accounts, wallet_transactions, wallet_entries, wallet_splits to authenticated;

-- Append-only ledger.
create or replace function private.wallet_block_mutation()
returns trigger
language plpgsql
set search_path = public, private
as $$
begin
  raise exception 'IMMUTABLE' using errcode = 'P0001';
end;
$$;

create trigger wallet_entries_immutable before update or delete on wallet_entries
  for each row execute function private.wallet_block_mutation();
create trigger wallet_transactions_immutable before update or delete on wallet_transactions
  for each row execute function private.wallet_block_mutation();

-- Double-entry: each transaction balances to zero at commit.
create or replace function private.wallet_check_balanced()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_sum numeric;
  v_legs int;
begin
  select coalesce(sum(amount), 0), count(*) into v_sum, v_legs
  from wallet_entries where transaction_id = new.transaction_id;
  if v_sum <> 0 or v_legs < 2 then
    raise exception 'UNBALANCED' using errcode = 'P0001';
  end if;
  return null;
end;
$$;

create constraint trigger wallet_entries_balanced
  after insert on wallet_entries
  deferrable initially deferred
  for each row execute function private.wallet_check_balanced();

revoke execute on function private.wallet_block_mutation() from public, anon, authenticated;
revoke execute on function private.wallet_check_balanced() from public, anon, authenticated;

insert into wallet_accounts (kind) values ('provider_clearing'), ('fares');

create or replace function private.wallet_account_for(p_owner uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_id uuid;
begin
  select id into v_id from wallet_accounts where owner_id = p_owner and kind = 'rider';
  if v_id is null then
    insert into wallet_accounts (owner_id, kind) values (p_owner, 'rider')
    on conflict (owner_id) where kind = 'rider' do nothing
    returning id into v_id;
    if v_id is null then
      select id into v_id from wallet_accounts where owner_id = p_owner and kind = 'rider';
    end if;
  end if;
  return v_id;
end;
$$;

create or replace function private.wallet_system_account(p_kind text)
returns uuid
language sql
stable
security definer
set search_path = public, private
as $$
  select id from wallet_accounts where kind = p_kind;
$$;

-- Posts one balanced transaction: debit p_from, credit p_to. Returns
-- (transaction_id, replayed). Replays of the same key return the original.
create or replace function private.wallet_post(
  p_kind text,
  p_initiator uuid,
  p_key text,
  p_from uuid,
  p_to uuid,
  p_amount numeric,
  p_memo jsonb default '{}'::jsonb
)
returns table (transaction_id uuid, replayed boolean)
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_tx uuid;
begin
  if p_key is null or length(p_key) < 8 or length(p_key) > 128 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select t.id into v_tx from wallet_transactions t
  where t.initiator_id = p_initiator and t.idempotency_key = p_key;
  if v_tx is not null then
    return query select v_tx, true;
    return;
  end if;
  if p_amount is null or p_amount <= 0 or p_from = p_to then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  -- Lock both accounts in a stable order to avoid deadlocks.
  perform 1 from wallet_accounts where id in (p_from, p_to) order by id for update;

  insert into wallet_transactions (kind, initiator_id, idempotency_key, memo)
  values (p_kind, p_initiator, p_key, coalesce(p_memo, '{}'::jsonb))
  returning id into v_tx;

  insert into wallet_entries (transaction_id, account_id, amount)
  values (v_tx, p_from, -p_amount), (v_tx, p_to, p_amount);

  begin
    update wallet_accounts set balance = balance - p_amount where id = p_from;
  exception when check_violation then
    raise exception 'INSUFFICIENT_FUNDS' using errcode = 'P0001';
  end;
  update wallet_accounts set balance = balance + p_amount where id = p_to;

  return query select v_tx, false;
end;
$$;

revoke execute on function private.wallet_account_for(uuid) from public, anon, authenticated;
revoke execute on function private.wallet_system_account(text) from public, anon, authenticated;
revoke execute on function private.wallet_post(text, uuid, text, uuid, uuid, numeric, jsonb) from public, anon, authenticated;

-- Caller's balance, recent history (newest first) and open split requests.
create or replace function get_wallet()
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_account uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  v_account := private.wallet_account_for(v_user);
  return jsonb_build_object(
    'balance', (select balance from wallet_accounts where id = v_account),
    'currency', 'NGN',
    'entries', coalesce((
      select jsonb_agg(row_to_json(x)::jsonb order by x.created_at desc, x.id desc)
      from (
        select e.id, t.kind, e.amount, e.created_at, t.memo
        from wallet_entries e join wallet_transactions t on t.id = e.transaction_id
        where e.account_id = v_account
        order by e.created_at desc, e.id desc
        limit 50
      ) x), '[]'::jsonb),
    'splits_owed', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id, 'amount', s.amount, 'trip_id', s.trip_id, 'created_at', s.created_at,
        'requester_name', coalesce(p.display_name, '')) order by s.created_at desc)
      from wallet_splits s join profiles p on p.id = s.requester_id
      where s.payer_id = v_user and s.status = 'pending'), '[]'::jsonb)
  );
end;
$$;

-- Stubbed provider top-up: credits the rider from provider_clearing.
create or replace function wallet_top_up(p_amount numeric, p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_res record;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_amount is null or p_amount < 100 or p_amount > 50000 or p_amount <> round(p_amount, 2) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select * into v_res from private.wallet_post(
    'top_up', v_user, p_idempotency_key,
    private.wallet_system_account('provider_clearing'),
    private.wallet_account_for(v_user), p_amount,
    jsonb_build_object('provider', 'stub'));
  return jsonb_build_object('transaction_id', v_res.transaction_id, 'replayed', v_res.replayed,
    'balance', (select balance from wallet_accounts where owner_id = v_user and kind = 'rider'));
end;
$$;

-- Send credit to another rider by phone number.
create or replace function wallet_send(p_to_phone text, p_amount numeric, p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_to uuid;
  v_res record;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_amount is null or p_amount < 50 or p_amount > 50000 or p_amount <> round(p_amount, 2) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select id into v_to from profiles where phone_e164 = p_to_phone;
  if v_to is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_to = v_user then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select * into v_res from private.wallet_post(
    'send', v_user, p_idempotency_key,
    private.wallet_account_for(v_user), private.wallet_account_for(v_to), p_amount,
    jsonb_build_object('to', (select coalesce(display_name, '') from profiles where id = v_to),
                       'from', (select coalesce(display_name, '') from profiles where id = v_user)));
  return jsonb_build_object('transaction_id', v_res.transaction_id, 'replayed', v_res.replayed,
    'balance', (select balance from wallet_accounts where owner_id = v_user and kind = 'rider'));
end;
$$;

-- Buy the monthly Along Pass (fixed price) from wallet credit.
create or replace function wallet_buy_pass(p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_res record;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_res from private.wallet_post(
    'pass', v_user, p_idempotency_key,
    private.wallet_account_for(v_user), private.wallet_system_account('fares'), 2000,
    jsonb_build_object('pass', 'monthly'));
  return jsonb_build_object('transaction_id', v_res.transaction_id, 'replayed', v_res.replayed,
    'balance', (select balance from wallet_accounts where owner_id = v_user and kind = 'rider'));
end;
$$;

-- Ask co-riders (by phone) to pay their share of a fare. Idempotent per key.
create or replace function wallet_request_split(
  p_phones text[], p_share numeric, p_trip_id uuid, p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_payers uuid[];
  v_ids uuid[];
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_share is null or p_share < 50 or p_share > 50000
     or coalesce(array_length(p_phones, 1), 0) not between 1 and 5
     or p_idempotency_key is null or length(p_idempotency_key) not between 8 and 128 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_trip_id is not null and not exists (
    select 1 from trips t where t.id = p_trip_id and t.rider_id = v_user) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  select array_agg(distinct p.id) into v_payers from profiles p
  where p.phone_e164 = any(p_phones) and p.id <> v_user;
  if coalesce(array_length(v_payers, 1), 0) <> (select count(distinct x) from unnest(p_phones) x) then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  perform pg_advisory_xact_lock(hashtext('wallet_split:' || v_user || ':' || p_idempotency_key));
  select array_agg(s.id order by s.id) into v_ids from wallet_splits s
  where s.requester_id = v_user and s.request_key = p_idempotency_key;
  if v_ids is not null then
    return jsonb_build_object('split_ids', to_jsonb(v_ids), 'replayed', true);
  end if;
  with ins as (
    insert into wallet_splits (requester_id, payer_id, trip_id, amount, request_key)
    select v_user, unnest(v_payers), p_trip_id, p_share, p_idempotency_key
    returning id)
  select array_agg(id order by id) into v_ids from ins;
  return jsonb_build_object('split_ids', to_jsonb(v_ids), 'replayed', false);
end;
$$;

-- Payer accepts (pays requester from wallet) or declines a pending split.
create or replace function wallet_settle_split(p_split_id uuid, p_accept boolean, p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user uuid := auth.uid();
  v_split wallet_splits%rowtype;
  v_res record;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_split from wallet_splits where id = p_split_id for update;
  if v_split.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_split.payer_id <> v_user then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_split.status = 'paid' and p_accept then
    return jsonb_build_object('status', 'paid', 'replayed', true,
      'balance', (select balance from wallet_accounts where owner_id = v_user and kind = 'rider'));
  end if;
  if v_split.status = 'declined' and not p_accept then
    return jsonb_build_object('status', 'declined', 'replayed', true,
      'balance', (select balance from wallet_accounts where owner_id = v_user and kind = 'rider'));
  end if;
  if v_split.status <> 'pending' then
    raise exception 'CONFLICT' using errcode = 'P0001';
  end if;
  if p_accept then
    select * into v_res from private.wallet_post(
      'split', v_user, p_idempotency_key,
      private.wallet_account_for(v_user), private.wallet_account_for(v_split.requester_id),
      v_split.amount,
      jsonb_build_object('split_id', v_split.id,
        'to', (select coalesce(display_name, '') from profiles where id = v_split.requester_id),
        'from', (select coalesce(display_name, '') from profiles where id = v_user)));
    update wallet_splits set status = 'paid', transaction_id = v_res.transaction_id, settled_at = now()
    where id = v_split.id;
  else
    update wallet_splits set status = 'declined', settled_at = now() where id = v_split.id;
  end if;
  return jsonb_build_object('status', case when p_accept then 'paid' else 'declined' end, 'replayed', false,
    'balance', (select balance from wallet_accounts where owner_id = v_user and kind = 'rider'));
end;
$$;

-- Integrity report (admin / service role): unbalanced transactions, balance
-- drift between cached balance and entry sums, and negative rider balances.
create or replace function wallet_ledger_check()
returns table (problem text, ref uuid, detail numeric)
language plpgsql
stable
security definer
set search_path = public, private
as $$
begin
  if auth.uid() is not null and not is_admin() then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
    select 'unbalanced'::text, e.transaction_id, sum(e.amount)
    from wallet_entries e group by e.transaction_id having sum(e.amount) <> 0
  union all
    select 'drift'::text, a.id, a.balance - coalesce(sum(e.amount), 0)
    from wallet_accounts a left join wallet_entries e on e.account_id = a.id
    group by a.id, a.balance having a.balance <> coalesce(sum(e.amount), 0)
  union all
    select 'negative'::text, a.id, a.balance
    from wallet_accounts a where a.kind = 'rider' and a.balance < 0;
end;
$$;

revoke execute on function get_wallet() from public, anon;
revoke execute on function wallet_top_up(numeric, text) from public, anon;
revoke execute on function wallet_send(text, numeric, text) from public, anon;
revoke execute on function wallet_buy_pass(text) from public, anon;
revoke execute on function wallet_request_split(text[], numeric, uuid, text) from public, anon;
revoke execute on function wallet_settle_split(uuid, boolean, text) from public, anon;
revoke execute on function wallet_ledger_check() from public, anon;

grant execute on function get_wallet() to authenticated;
grant execute on function wallet_top_up(numeric, text) to authenticated;
grant execute on function wallet_send(text, numeric, text) to authenticated;
grant execute on function wallet_buy_pass(text) to authenticated;
grant execute on function wallet_request_split(text[], numeric, uuid, text) to authenticated;
grant execute on function wallet_settle_split(uuid, boolean, text) to authenticated;
grant execute on function wallet_ledger_check() to authenticated, service_role;
