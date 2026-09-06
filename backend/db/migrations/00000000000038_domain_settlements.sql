-- P4-A-03: settlements, settlement_agents, agent codes, Paystack webhook raw store,
-- FK driver_ledger_entries.settlement_id → settlements (doc 02 §9, doc 03 §7, ADR-0010)

-- ---------------------------------------------------------------------------
-- Config defaults (TTL / thresholds via cfg_num)
-- ---------------------------------------------------------------------------
select config_default('settlement.agent_code_ttl_min', '15');
select config_default('settlement.initiate_ttl_min', '30');

-- ---------------------------------------------------------------------------
-- Settlement agents (doc 02 §9)
-- ---------------------------------------------------------------------------
create table settlement_agents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id),
  city_id uuid not null references cities(id),
  business_name text not null,
  location geography(Point, 4326),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index settlement_agents_profile on settlement_agents(profile_id);
create index settlement_agents_city on settlement_agents(city_id) where active;

create trigger settlement_agents_updated_at
  before update on settlement_agents
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- Settlements
-- ---------------------------------------------------------------------------
create type settlement_channel as enum (
  'paystack_transfer',
  'paystack_ussd',
  'paystack_card',
  'agent_cash',
  'bank_manual'
);

create type settlement_status as enum ('pending', 'confirmed', 'failed', 'expired');

create table settlements (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  amount numeric(12,2) not null check (amount > 0),
  currency char(3) not null,
  channel settlement_channel not null,
  status settlement_status not null default 'pending',
  provider_reference text unique,
  agent_id uuid references settlement_agents(id),
  agent_code text unique,
  ledger_entry_id bigint references driver_ledger_entries(id),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  expires_at timestamptz
);

create index settlements_driver_created on settlements(driver_id, created_at desc);
create index settlements_agent_code_pending on settlements(agent_code) where status = 'pending';

alter table driver_ledger_entries
  add constraint dle_settlement_fk foreign key (settlement_id) references settlements(id);

create trigger settlements_audit
  after insert or update or delete on settlements
  for each row execute function audit_admin_write();

-- ---------------------------------------------------------------------------
-- Paystack webhook raw store (doc 02 §9, doc 12 T4)
-- ---------------------------------------------------------------------------
create table private.payment_webhook_raw (
  id bigserial primary key,
  provider text not null default 'paystack',
  received_at timestamptz not null default now(),
  signature_ok boolean not null,
  body jsonb not null
);

grant usage on schema private to service_role;
grant select, insert on private.payment_webhook_raw to service_role;
grant usage, select on sequence private.payment_webhook_raw_id_seq to service_role;

-- ---------------------------------------------------------------------------
-- RLS — settlements (doc 02 §16)
-- ---------------------------------------------------------------------------
alter table settlements enable row level security;

create policy settlements_select_own
  on settlements for select to authenticated
  using (driver_id = auth.uid());

create policy settlements_select_agent
  on settlements for select to authenticated
  using (
    agent_id is not null
    and agent_id in (
      select sa.id
      from settlement_agents sa
      where sa.profile_id = auth.uid() and sa.active
    )
  );

create policy settlements_select_admin
  on settlements for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy settlements_no_client_write
  on settlements for all to authenticated
  using (false)
  with check (false);

grant select on settlements to authenticated;

-- ---------------------------------------------------------------------------
-- RLS — settlement_agents
-- ---------------------------------------------------------------------------
alter table settlement_agents enable row level security;

create policy settlement_agents_select_own
  on settlement_agents for select to authenticated
  using (profile_id = auth.uid());

create policy settlement_agents_select_admin
  on settlement_agents for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city(city_id)
  );

create policy settlement_agents_no_client_write
  on settlement_agents for all to authenticated
  using (false)
  with check (false);

grant select on settlement_agents to authenticated;

-- ---------------------------------------------------------------------------
-- Helper: generate unique 6-char agent code
-- ---------------------------------------------------------------------------
create or replace function private.generate_agent_code()
returns text
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
  v_attempts int := 0;
begin
  loop
    v_attempts := v_attempts + 1;
    if v_attempts > 20 then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'agent code generation failed';
    end if;
    v_code := upper(substr(encode(gen_random_bytes(5), 'base64'), 1, 6));
    v_code := regexp_replace(v_code, '[^A-Z0-9]', 'X', 'g');
    exit when not exists (select 1 from settlements s where s.agent_code = v_code);
  end loop;
  return v_code;
end;
$$;

revoke all on function private.generate_agent_code() from public;
grant execute on function private.generate_agent_code() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- rpc.create_agent_code(p_amount) — driver own, 15 min TTL (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function create_agent_code(p_amount numeric)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_city_id uuid;
  v_currency char(3);
  v_code text;
  v_expires timestamptz;
  v_settlement_id uuid;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select d.city_id, c.currency_code
  into v_city_id, v_currency
  from drivers d
  join cities ci on ci.id = d.city_id
  join countries c on c.code = ci.country_code
  where d.id = v_driver_id;

  if v_city_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_code := private.generate_agent_code();
  v_expires := now() + (cfg_num('settlement.agent_code_ttl_min', v_city_id) || ' minutes')::interval;

  insert into settlements (
    driver_id,
    amount,
    currency,
    channel,
    status,
    agent_code,
    expires_at
  ) values (
    v_driver_id,
    p_amount,
    v_currency,
    'agent_cash',
    'pending',
    v_code,
    v_expires
  )
  returning id into v_settlement_id;

  return jsonb_build_object(
    'agent_code', v_code,
    'expires_at', v_expires,
    'settlement_id', v_settlement_id
  );
end;
$$;

grant execute on function create_agent_code(numeric) to authenticated;

-- ---------------------------------------------------------------------------
-- rpc.confirm_agent_settlement(p_agent_code, p_amount) — active agent, same city
-- ---------------------------------------------------------------------------
create or replace function confirm_agent_settlement(p_agent_code text, p_amount numeric)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_agent settlement_agents%rowtype;
  v_settlement settlements%rowtype;
  v_driver_city uuid;
  v_ledger driver_ledger_entries%rowtype;
  v_idempotency text;
begin
  if auth.uid() is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_agent
  from settlement_agents
  where profile_id = auth.uid() and active
  limit 1;

  if v_agent.id is null then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_settlement
  from settlements
  where agent_code = p_agent_code
  for update;

  if v_settlement.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_settlement.status = 'confirmed' then
    raise exception 'IDEMPOTENT_REPLAY' using errcode = 'P0001';
  end if;

  if v_settlement.status <> 'pending' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_settlement.expires_at is not null and v_settlement.expires_at <= now() then
    update settlements set status = 'expired' where id = v_settlement.id;
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'agent code expired';
  end if;

  if v_settlement.amount is distinct from p_amount then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'amount mismatch';
  end if;

  select d.city_id into v_driver_city
  from drivers d
  where d.id = v_settlement.driver_id;

  if v_driver_city is distinct from v_agent.city_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_idempotency := format('agent:%s', p_agent_code);

  v_ledger := ledger_post(
    v_settlement.driver_id,
    'digital_settlement_credit',
    p_amount,
    v_settlement.currency,
    jsonb_build_object('settlement_id', v_settlement.id),
    v_idempotency,
    'agent',
    v_agent.id,
    'agent-assisted settlement'
  );

  update settlements
  set
    status = 'confirmed',
    agent_id = v_agent.id,
    ledger_entry_id = v_ledger.id,
    confirmed_at = now()
  where id = v_settlement.id;

  return jsonb_build_object(
    'ledger_entry_id', v_ledger.id,
    'settlement_id', v_settlement.id,
    'balance_after', v_ledger.balance_after
  );
end;
$$;

grant execute on function confirm_agent_settlement(text, numeric) to authenticated;

-- ---------------------------------------------------------------------------
-- apply_paystack_charge_success — idempotent ledger credit (webhook / tests)
-- ---------------------------------------------------------------------------
create or replace function apply_paystack_charge_success(
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
  v_settlement settlements%rowtype;
  v_trip trips%rowtype;
  v_driver_id uuid;
  v_credit numeric;
  v_currency char(3);
  v_idempotency text;
  v_ledger driver_ledger_entries%rowtype;
  v_settlement_id uuid;
  v_trip_id uuid;
begin
  if p_reference is null or btrim(p_reference) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_idempotency := format('paystack:%s', p_reference);

  select * into v_existing
  from driver_ledger_entries
  where idempotency_key = v_idempotency;

  if found then
    return v_existing;
  end if;

  v_settlement_id := nullif(p_metadata->>'settlement_id', '')::uuid;
  v_trip_id := nullif(p_metadata->>'trip_id', '')::uuid;

  if v_settlement_id is not null then
    select * into v_settlement
    from settlements
    where id = v_settlement_id
    for update;

    if v_settlement.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'settlement not found';
    end if;

    if v_settlement.status = 'confirmed' then
      select * into v_existing
      from driver_ledger_entries
      where settlement_id = v_settlement.id
        and entry_type = 'digital_settlement_credit'
      order by id desc
      limit 1;
      if found then
        return v_existing;
      end if;
    end if;

    if p_amount is distinct from v_settlement.amount then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'amount mismatch';
    end if;

    v_driver_id := v_settlement.driver_id;
    v_credit := v_settlement.amount;
    v_currency := v_settlement.currency;

    v_ledger := ledger_post(
      v_driver_id,
      'digital_settlement_credit',
      v_credit,
      v_currency,
      jsonb_build_object('settlement_id', v_settlement.id),
      v_idempotency,
      'payment_webhook',
      null,
      'Paystack settlement'
    );

    update settlements
    set
      status = 'confirmed',
      provider_reference = p_reference,
      ledger_entry_id = v_ledger.id,
      confirmed_at = now()
    where id = v_settlement.id;

    return v_ledger;
  end if;

  if v_trip_id is not null then
    select * into v_trip from trips where id = v_trip_id;
    if v_trip.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'trip not found';
    end if;

    v_driver_id := v_trip.driver_id;
    v_currency := v_trip.fare_currency;
    v_credit := coalesce(
      v_trip.commission_amount,
      round((v_trip.fare_shown + coalesce(v_trip.load_surcharge_amount, 0)) * v_trip.commission_rate, 2)
    );

    if v_credit <= 0 then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'zero commission';
    end if;

    return ledger_post(
      v_driver_id,
      'digital_settlement_credit',
      v_credit,
      v_currency,
      jsonb_build_object('trip_id', v_trip_id),
      v_idempotency,
      'payment_webhook',
      null,
      'digital trip commission (informational)'
    );
  end if;

  raise exception 'VALIDATION' using errcode = 'P0001', message = 'missing settlement_id or trip_id in metadata';
end;
$$;

revoke all on function apply_paystack_charge_success(text, numeric, jsonb) from public;
grant execute on function apply_paystack_charge_success(text, numeric, jsonb) to service_role;
