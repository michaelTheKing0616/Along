-- P4-A-04: payments, ratings, confirm_fare, rate_trip; complete_trip itemisation;
-- apply_paystack_charge_success payment_id path (doc 02 §9/§11, doc 03 §5/§7, ADR-0010)

-- ---------------------------------------------------------------------------
-- payments (doc 02 §9)
-- ---------------------------------------------------------------------------
create table payments (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  trip_id uuid references trips(id),
  rider_id uuid references riders(id),
  source text not null check (source in ('app_trip', 'qr_static', 'qr_dynamic', 'web_anonymous')),
  channel text not null check (channel in ('app', 'web')),
  amount numeric(12,2) not null,
  currency char(3) not null,
  commission_amount numeric(12,2) not null,
  driver_amount numeric(12,2) not null,
  fee_bearer text not null check (fee_bearer in ('account', 'subaccount')),
  provider_fee numeric(12,2),
  provider text not null default 'paystack',
  provider_reference text not null unique,
  method text not null,
  status text not null check (status in ('initiated', 'pending', 'succeeded', 'failed', 'expired', 'refunded')),
  payer_phone_e164 text,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);

create index payments_driver_created on payments(driver_id, created_at desc);
create unique index payments_one_success_per_trip on payments(trip_id)
  where trip_id is not null and status = 'succeeded';

-- ---------------------------------------------------------------------------
-- ratings (doc 02 §11)
-- ---------------------------------------------------------------------------
create table ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  rater_profile_id uuid not null references profiles(id),
  ratee_profile_id uuid not null references profiles(id),
  rater_role text not null check (rater_role in ('rider', 'driver')),
  score smallint not null check (score between 1 and 5),
  tags text[] not null default '{}',
  comment text check (char_length(comment) <= 280),
  created_at timestamptz not null default now(),
  unique (trip_id, rater_profile_id)
);

create index ratings_ratee_created on ratings(ratee_profile_id, created_at desc);

-- ---------------------------------------------------------------------------
-- RLS — payments (doc 02 §16)
-- ---------------------------------------------------------------------------
alter table payments enable row level security;

create policy payments_select_rider
  on payments for select to authenticated
  using (rider_id = auth.uid());

create policy payments_select_driver
  on payments for select to authenticated
  using (driver_id = auth.uid());

create policy payments_select_admin
  on payments for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy payments_no_client_write
  on payments for all to authenticated
  using (false)
  with check (false);

grant select on payments to authenticated;

-- ---------------------------------------------------------------------------
-- RLS — ratings (doc 02 §16)
-- ---------------------------------------------------------------------------
alter table ratings enable row level security;

create policy ratings_select_party
  on ratings for select to authenticated
  using (
    exists (
      select 1 from trips t
      where t.id = trip_id
        and (t.rider_id = auth.uid() or t.driver_id = auth.uid())
    )
  );

create policy ratings_select_admin
  on ratings for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'safety']));

create policy ratings_no_client_write
  on ratings for all to authenticated
  using (false)
  with check (false);

grant select on ratings to authenticated;

-- ---------------------------------------------------------------------------
-- trip_payable_total — server-side amount lock (TS-UI-04)
-- ---------------------------------------------------------------------------
create or replace function trip_payable_total(p_trip_id uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select t.fare_shown + coalesce(t.load_surcharge_amount, 0)
  from trips t
  where t.id = p_trip_id
$$;

revoke all on function trip_payable_total(uuid) from public;
grant execute on function trip_payable_total(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- _rider_fare_confirm_source — provenance for confirm_fare corrections
-- ---------------------------------------------------------------------------
create or replace function _rider_fare_confirm_source()
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  select id into v_id
  from data_sources
  where source_type = 'rider_correction'
  order by created_at
  limit 1;

  if v_id is null then
    insert into data_sources (source_type, notes)
    values ('rider_correction', 'Rider post-trip fare confirmation')
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on function _rider_fare_confirm_source() from public;

-- ---------------------------------------------------------------------------
-- confirm_fare — rider only; Tier 3 always creates fare_corrections (FM33)
-- ---------------------------------------------------------------------------
create or replace function confirm_fare(
  p_trip_id uuid,
  p_outcome text,
  p_paid_amount numeric default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_rider_id uuid := auth.uid();
  v_t trips%rowtype;
  v_proposed numeric;
  v_total numeric;
  v_correction_id uuid;
  v_source uuid;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_outcome not in ('as_shown', 'different') then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid outcome';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.rider_id is distinct from v_rider_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'completed' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_total := v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0);

  if p_outcome = 'different' then
    if p_paid_amount is null or p_paid_amount <= 0 then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'paid amount required';
    end if;
    v_proposed := p_paid_amount;
  elsif v_t.fare_tier = 3 then
    v_proposed := coalesce(p_paid_amount, v_total);
  else
    update trips set fare_reported_paid = v_total where id = p_trip_id;
    return jsonb_build_object(
      'trip_id', p_trip_id,
      'outcome', p_outcome,
      'fare_correction_id', null
    );
  end if;

  v_source := _rider_fare_confirm_source();

  insert into fare_corrections (
    route_id,
    from_stage_id,
    to_stage_id,
    trip_id,
    submitted_by,
    submitter_role,
    proposed_fare,
    currency,
    fare_shown,
    source_id
  ) values (
    v_t.route_id,
    v_t.boarding_stage_id,
    v_t.alighting_stage_id,
    p_trip_id,
    v_rider_id,
    'rider',
    v_proposed,
    v_t.fare_currency,
    v_t.fare_shown,
    v_source
  )
  returning id into v_correction_id;

  update trips set fare_reported_paid = v_proposed where id = p_trip_id;

  return jsonb_build_object(
    'trip_id', p_trip_id,
    'outcome', p_outcome,
    'fare_correction_id', v_correction_id
  );
end;
$$;

grant execute on function confirm_fare(uuid, text, numeric) to authenticated;

-- ---------------------------------------------------------------------------
-- rate_trip — party to trip; unique per rater; allowlisted tags
-- ---------------------------------------------------------------------------
create or replace function rate_trip(
  p_trip_id uuid,
  p_score smallint,
  p_tags text[] default '{}',
  p_comment text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_t trips%rowtype;
  v_rater_role text;
  v_ratee uuid;
  v_allowed jsonb;
  v_tag text;
  v_city_id uuid;
  v_rating_id uuid;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_score is null or p_score < 1 or p_score > 5 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'score must be 1-5';
  end if;

  if p_comment is not null and char_length(p_comment) > 280 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'comment too long';
  end if;

  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.status <> 'completed' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_t.rider_id = v_user_id then
    v_rater_role := 'rider';
    v_ratee := v_t.driver_id;
  elsif v_t.driver_id = v_user_id then
    v_rater_role := 'driver';
    v_ratee := v_t.rider_id;
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_ratee is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'missing ratee';
  end if;

  select j.city_id into v_city_id from journeys j where j.id = v_t.journey_id;
  v_allowed := cfg('rating.tags', v_city_id);

  if p_tags is not null then
    foreach v_tag in array p_tags loop
      if not v_allowed ? v_tag then
        raise exception 'VALIDATION' using errcode = 'P0001', message = format('invalid tag: %s', v_tag);
      end if;
    end loop;
  end if;

  insert into ratings (
    trip_id,
    rater_profile_id,
    ratee_profile_id,
    rater_role,
    score,
    tags,
    comment
  ) values (
    p_trip_id,
    v_user_id,
    v_ratee,
    v_rater_role,
    p_score,
    coalesce(p_tags, '{}'),
    nullif(btrim(p_comment), '')
  )
  returning id into v_rating_id;

  return jsonb_build_object(
    'rating_id', v_rating_id,
    'trip_id', p_trip_id,
    'score', p_score
  );
end;
$$;

grant execute on function rate_trip(uuid, smallint, text[], text) to authenticated;

-- ---------------------------------------------------------------------------
-- complete_trip — explicit fare / surcharge / commission itemisation
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

  return jsonb_build_object(
    'trip', build_trip_view(p_trip_id, v_driver_id),
    'fare', jsonb_build_object('amount', v_fare, 'currency', v_t.fare_currency),
    'surcharge', case
      when v_surcharge > 0 then jsonb_build_object('amount', v_surcharge, 'currency', v_t.fare_currency)
      else null
    end,
    'total', jsonb_build_object('amount', v_total, 'currency', v_t.fare_currency),
    'commission', jsonb_build_object('amount', v_commission, 'currency', v_t.fare_currency),
    'ledger_entry_id', v_ledger_entry.id
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_paystack_charge_success — payment_id path (doc 14 §4.3)
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
  v_payment payments%rowtype;
  v_trip trips%rowtype;
  v_driver_id uuid;
  v_credit numeric;
  v_currency char(3);
  v_idempotency text;
  v_ledger driver_ledger_entries%rowtype;
  v_settlement_id uuid;
  v_trip_id uuid;
  v_payment_id uuid;
  v_has_cash_debit boolean;
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

  v_payment_id := nullif(p_metadata->>'payment_id', '')::uuid;

  if v_payment_id is not null then
    select * into v_payment
    from payments
    where id = v_payment_id
    for update;

    if v_payment.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'payment not found';
    end if;

    if v_payment.status = 'succeeded' then
      select * into v_existing
      from driver_ledger_entries
      where idempotency_key in (
        v_idempotency,
        format('trip:%s:digital_offset', v_payment.trip_id)
      )
      order by id desc
      limit 1;
      if found then
        return v_existing;
      end if;
      return null;
    end if;

    if p_amount is distinct from v_payment.amount then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'amount mismatch';
    end if;

    update payments
    set
      status = 'succeeded',
      provider_reference = p_reference,
      confirmed_at = now()
    where id = v_payment_id;

    if v_payment.trip_id is null then
      return null;
    end if;

    update trips
    set payment_method = 'digital'
    where id = v_payment.trip_id;

    v_trip_id := v_payment.trip_id;
    v_credit := v_payment.commission_amount;
    v_currency := v_payment.currency;
    v_driver_id := v_payment.driver_id;

    select exists (
      select 1
      from driver_ledger_entries dle
      where dle.trip_id = v_trip_id
        and dle.entry_type = 'cash_commission_debit'
    ) into v_has_cash_debit;

    if v_has_cash_debit then
      return ledger_post(
        v_driver_id,
        'digital_settlement_credit',
        v_credit,
        v_currency,
        jsonb_build_object('trip_id', v_trip_id),
        format('trip:%s:digital_offset', v_trip_id),
        'payment_webhook',
        null,
        'late digital payment offset'
      );
    end if;

    if v_credit <= 0 then
      return null;
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

  raise exception 'VALIDATION' using errcode = 'P0001', message = 'missing payment_id, settlement_id or trip_id in metadata';
end;
$$;
