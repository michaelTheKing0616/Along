-- P4-A-09: QR scan-to-pay — rider_payment_methods, payment tokens, QR RPCs, expiry job
-- (doc 14 §4–5, doc 03 §7, ADR-0014)

select config_default('payments.initiate_ttl_s', '1800');

-- ---------------------------------------------------------------------------
-- payments — expiry + web receipt token
-- ---------------------------------------------------------------------------
alter table payments add column if not exists expires_at timestamptz;
alter table payments add column if not exists receipt_token text unique;

create index if not exists payments_expires_pending
  on payments(expires_at)
  where status in ('initiated', 'pending');

-- ---------------------------------------------------------------------------
-- rider_payment_methods — provider tokens only (doc 14 §5)
-- ---------------------------------------------------------------------------
create table rider_payment_methods (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id) on delete cascade,
  provider text not null default 'paystack',
  authorization_code text not null,
  brand text,
  last4 text,
  exp_month smallint,
  exp_year smallint,
  bank text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (rider_id, authorization_code)
);

create unique index rider_payment_methods_default
  on rider_payment_methods(rider_id) where is_default;

alter table rider_payment_methods enable row level security;

create policy rider_payment_methods_select_own
  on rider_payment_methods for select to authenticated
  using (rider_id = auth.uid());

create policy rider_payment_methods_no_client_write
  on rider_payment_methods for all to authenticated
  using (false)
  with check (false);

grant select on rider_payment_methods to authenticated;

create or replace view rider_payment_methods_safe
with (security_invoker = true) as
select
  id,
  rider_id,
  provider,
  brand,
  last4,
  exp_month,
  exp_year,
  bank,
  is_default,
  created_at
from rider_payment_methods;

grant select on rider_payment_methods_safe to authenticated;

-- ---------------------------------------------------------------------------
-- QR sticker reprint requests (doc 14 §6 D-25)
-- ---------------------------------------------------------------------------
create table qr_sticker_requests (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  driver_code text not null,
  reason text not null check (reason in ('initial', 'rotation')),
  status text not null default 'pending' check (status in ('pending', 'fulfilled', 'cancelled')),
  created_at timestamptz not null default now()
);

create index qr_sticker_requests_driver on qr_sticker_requests(driver_id, created_at desc);

alter table qr_sticker_requests enable row level security;

create policy qr_sticker_requests_select_own
  on qr_sticker_requests for select to authenticated
  using (driver_id = auth.uid());

create policy qr_sticker_requests_select_admin
  on qr_sticker_requests for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy qr_sticker_requests_no_client_write
  on qr_sticker_requests for all to authenticated
  using (false)
  with check (false);

grant select on qr_sticker_requests to authenticated;

-- ---------------------------------------------------------------------------
-- Rate-limit buckets for qr/resolve (doc 14 §4.1)
-- ---------------------------------------------------------------------------
create table private.qr_resolve_rate_buckets (
  ip_hash text not null,
  window_start timestamptz not null,
  hit_count int not null default 1,
  primary key (ip_hash, window_start)
);

create or replace function private.qr_resolve_rate_key()
returns text
language sql
stable
as $$
  select coalesce(
    nullif(current_setting('request.headers', true), '')::jsonb->>'x-forwarded-for',
    nullif(current_setting('request.headers', true), '')::jsonb->>'x-real-ip',
    'unknown'
  );
$$;

create or replace function check_qr_resolve_rate(
  p_ip text,
  p_limit int default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_limit int;
  v_window timestamptz;
  v_hash text;
  v_count int;
begin
  v_limit := coalesce(p_limit, cfg_num('payments.qr_resolve_rate_per_min', null)::int);
  v_window := date_trunc('minute', now());
  v_hash := encode(digest(coalesce(nullif(btrim(p_ip), ''), 'unknown'), 'sha256'), 'hex');

  insert into private.qr_resolve_rate_buckets (ip_hash, window_start, hit_count)
  values (v_hash, v_window, 1)
  on conflict (ip_hash, window_start) do update
    set hit_count = private.qr_resolve_rate_buckets.hit_count + 1
  returning hit_count into v_count;

  return v_count <= v_limit;
end;
$$;

revoke all on function check_qr_resolve_rate(text, int) from public;
grant execute on function check_qr_resolve_rate(text, int) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- trip_payable_total — include accepted extension deltas (TS-QR-02)
-- ---------------------------------------------------------------------------
create or replace function trip_payable_total(p_trip_id uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select t.fare_shown
    + coalesce(t.load_surcharge_amount, 0)
    + coalesce((
      select sum(te.fare_delta)
      from trip_extensions te
      where te.trip_id = p_trip_id
        and te.status = 'accepted'
    ), 0)
  from trips t
  where t.id = p_trip_id
$$;

-- ---------------------------------------------------------------------------
-- Payment token HMAC (doc 14 §4.2 — same pattern as candidate_token)
-- Payload: trip_id.driver_id.amount.exp
-- ---------------------------------------------------------------------------
create or replace function payment_token_hmac_key()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    nullif(current_setting('app.settings.payment_token_hmac_key', true), ''),
    candidate_token_hmac_key()
  );
$$;

revoke all on function payment_token_hmac_key() from public;
grant execute on function payment_token_hmac_key() to service_role;

create or replace function _payment_token_payload(
  p_trip_id uuid,
  p_driver_id uuid,
  p_amount_kobo bigint,
  p_exp bigint
)
returns text
language sql
immutable
as $$
  select p_trip_id::text || '.' || p_driver_id::text || '.' || p_amount_kobo::text || '.' || p_exp::text;
$$;

create or replace function sign_payment_token(
  p_trip_id uuid,
  p_driver_id uuid,
  p_amount numeric,
  p_city_id uuid
)
returns text
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  v_exp bigint;
  v_payload text;
begin
  v_key := payment_token_hmac_key();
  if v_key is null then
    raise exception 'payment token HMAC key not configured' using errcode = '22023';
  end if;

  v_exp := extract(epoch from now())::bigint
    + cfg_num('payments.dynamic_qr_ttl_s', p_city_id)::bigint;
  v_payload := _payment_token_payload(
    p_trip_id,
    p_driver_id,
    round(p_amount * 100)::bigint,
    v_exp
  );

  return encode(convert_to(v_payload, 'UTF8'), 'base64') || '.' || encode(
    extensions.hmac(convert_to(v_payload, 'UTF8'), convert_to(v_key, 'UTF8'), 'sha256'),
    'base64'
  );
end;
$$;

revoke all on function sign_payment_token(uuid, uuid, numeric, uuid) from public;
grant execute on function sign_payment_token(uuid, uuid, numeric, uuid) to service_role, authenticated;

create or replace function verify_payment_token(
  p_token text,
  p_city_id uuid default null
)
returns table (trip_id uuid, driver_id uuid, amount numeric)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  v_parts text[];
  v_payload text;
  v_sig text;
  v_expected text;
  v_segs text[];
  v_exp bigint;
begin
  if p_token is null or btrim(p_token) = '' then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  v_key := payment_token_hmac_key();
  if v_key is null then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  v_parts := string_to_array(p_token, '.');
  if array_length(v_parts, 1) <> 2 then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  begin
    v_payload := convert_from(decode(v_parts[1], 'base64'), 'UTF8');
    v_sig := v_parts[2];
  exception
    when others then
      raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end;

  v_expected := encode(
    extensions.hmac(convert_to(v_payload, 'UTF8'), convert_to(v_key, 'UTF8'), 'sha256'),
    'base64'
  );

  if v_expected is distinct from v_sig then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  v_segs := string_to_array(v_payload, '.');
  if array_length(v_segs, 1) <> 4 then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  v_exp := v_segs[4]::bigint;
  if v_exp <= extract(epoch from now())::bigint then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  trip_id := v_segs[1]::uuid;
  driver_id := v_segs[2]::uuid;
  amount := (v_segs[3]::bigint / 100.0)::numeric(12,2);
  return next;
end;
$$;

revoke all on function verify_payment_token(text, uuid) from public;
grant execute on function verify_payment_token(text, uuid) to service_role, authenticated;

-- ---------------------------------------------------------------------------
-- Driver QR active check
-- ---------------------------------------------------------------------------
create or replace function private.driver_qr_active(p_driver drivers)
returns boolean
language sql
stable
as $$
  select p_driver.verified_status = 'verified'
    and p_driver.standing not in ('deactivated', 'guarantor_referred')
    and p_driver.driver_code is not null
    and btrim(p_driver.driver_code) <> '';
$$;

create or replace function private.driver_accepts_digital_qr(p_driver drivers)
returns boolean
language sql
stable
as $$
  select p_driver.accepts_digital
    and p_driver.payout_subaccount_code is not null
    and btrim(p_driver.payout_subaccount_code) <> '';
$$;

-- ---------------------------------------------------------------------------
-- qr_suggested_amounts — doc 03 §7
-- ---------------------------------------------------------------------------
create or replace function qr_suggested_amounts(p_driver_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_city_id uuid;
  v_mode text;
  v_min_fare numeric;
  v_amounts numeric[];
begin
  select d.city_id into v_city_id from drivers d where d.id = p_driver_id;
  if v_city_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select coalesce(
    (select v.mode_code
     from driver_vehicles dv
     join vehicles v on v.id = dv.vehicle_id
     where dv.driver_id = p_driver_id and dv.active
     limit 1),
    'car'
  ) into v_mode;

  v_min_fare := (cfg('fare.min_fare', v_city_id)->>v_mode)::numeric;

  select coalesce(array_agg(distinct amt order by amt), '{}')
  into v_amounts
  from (
    select distinct s2.price_to_end - s1.price_to_end as amt
    from driver_route_profiles p
    join driver_route_stops s1 on s1.profile_id = p.id
    join driver_route_stops s2 on s2.profile_id = p.id and s2.sequence > s1.sequence
    where p.driver_id = p_driver_id
      and p.active
      and s2.price_to_end > s1.price_to_end
    order by amt
    limit 6
  ) diffs;

  if v_min_fare is not null and v_min_fare > 0 then
    v_amounts := array_prepend(v_min_fare, v_amounts);
  end if;

  return coalesce(
    (select jsonb_agg(jsonb_build_object('amount', a, 'currency', 'NGN'))
     from (select distinct unnest(v_amounts) as a limit 7) u),
    '[]'::jsonb
  );
end;
$$;

grant execute on function qr_suggested_amounts(uuid) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- resolve_qr_driver — core resolver (doc 14 §4.1)
-- ---------------------------------------------------------------------------
create or replace function resolve_qr_driver(
  p_driver_code text,
  p_rider_id uuid default null,
  p_token text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_driver drivers%rowtype;
  v_first_name text;
  v_plate text;
  v_mode text;
  v_active boolean;
  v_accepts boolean;
  v_context jsonb;
  v_warning text;
  v_trip trips%rowtype;
  v_other_driver uuid;
  v_lookback interval;
  v_min_amount numeric;
  v_token_row record;
begin
  -- Uniform path: always scan drivers by code (404 class for unknown)
  select * into v_driver
  from drivers d
  where d.driver_code = p_driver_code;

  if v_driver.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_active := private.driver_qr_active(v_driver);
  v_accepts := private.driver_accepts_digital_qr(v_driver);
  v_min_amount := cfg_num('payments.min_digital_amount', v_driver.city_id);

  if not v_active then
    return jsonb_build_object(
      'driver', jsonb_build_object('active', false, 'accepts_digital', false),
      'suggested_amounts', qr_suggested_amounts(v_driver.id),
      'currency', 'NGN',
      'min_amount', jsonb_build_object('amount', v_min_amount, 'currency', 'NGN')
    );
  end if;

  select split_part(p.display_name, ' ', 1), v.plate_number, v.mode_code
  into v_first_name, v_plate, v_mode
  from profiles p
  left join driver_vehicles dv on dv.driver_id = v_driver.id and dv.active
  left join vehicles v on v.id = dv.vehicle_id
  where p.id = v_driver.id;

  v_context := null;
  v_warning := null;

  if p_rider_id is not null then
    v_lookback := make_interval(hours => cfg_num('payments.unattributed_lookback_hours', v_driver.city_id)::int);

    select t.* into v_trip
    from trips t
    where t.rider_id = p_rider_id
      and t.driver_id = v_driver.id
      and t.status in ('accepted', 'boarded', 'in_transit', 'completed')
      and (
        t.status <> 'completed'
        or coalesce(t.ended_at, t.updated_at) >= now() - v_lookback
      )
      and not exists (
        select 1 from payments pay
        where pay.trip_id = t.id and pay.status = 'succeeded'
      )
    order by
      case t.status
        when 'in_transit' then 1
        when 'boarded' then 2
        when 'accepted' then 3
        when 'completed' then 4
      end,
      t.requested_at desc
    limit 1;

    if v_trip.id is not null then
      v_context := jsonb_build_object(
        'trip_id', v_trip.id,
        'amount', jsonb_build_object(
          'amount', trip_payable_total(v_trip.id),
          'currency', v_trip.fare_currency
        ),
        'label', 'Trip fare',
        'locked', true
      );
    end if;

    select t.driver_id into v_other_driver
    from trips t
    where t.rider_id = p_rider_id
      and t.status in ('accepted', 'boarded', 'in_transit')
      and t.driver_id is distinct from v_driver.id
    order by t.requested_at desc
    limit 1;

    if v_other_driver is not null then
      v_warning := 'different_driver';
    end if;
  end if;

  if p_token is not null and btrim(p_token) <> '' then
    select * into v_token_row from verify_payment_token(p_token, v_driver.city_id);
    if v_token_row.driver_id is distinct from v_driver.id then
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
    v_context := jsonb_build_object(
      'trip_id', v_token_row.trip_id,
      'amount', jsonb_build_object('amount', v_token_row.amount, 'currency', 'NGN'),
      'label', 'Payment request',
      'locked', true
    );
  end if;

  return jsonb_build_object(
    'driver', jsonb_build_object(
      'first_name', v_first_name,
      'plate', v_plate,
      'mode', v_mode,
      'accepts_digital', v_accepts,
      'active', true
    ),
    'context', v_context,
    'suggested_amounts', qr_suggested_amounts(v_driver.id),
    'currency', 'NGN',
    'min_amount', jsonb_build_object('amount', v_min_amount, 'currency', 'NGN'),
    'warning', v_warning
  );
end;
$$;

revoke all on function resolve_qr_driver(text, uuid, text) from public;
grant execute on function resolve_qr_driver(text, uuid, text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- create_payment_request — dynamic trip QR (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function create_payment_request(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_amount numeric;
  v_token text;
  v_exp timestamptz;
  v_code text;
  v_origin text;
  v_url text;
  v_city_id uuid;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.driver_id is distinct from v_driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status not in ('boarded', 'in_transit', 'completed') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from payments p
    where p.trip_id = p_trip_id and p.status = 'succeeded'
  ) then
    raise exception 'CONFLICT' using errcode = 'P0001', message = 'trip already paid';
  end if;

  v_city_id := (select j.city_id from journeys j where j.id = v_t.journey_id);
  v_amount := trip_payable_total(p_trip_id);
  v_token := sign_payment_token(p_trip_id, v_driver_id, v_amount, v_city_id);
  v_exp := now() + make_interval(secs => cfg_num('payments.dynamic_qr_ttl_s', v_city_id)::int);

  select d.driver_code into v_code from drivers d where d.id = v_driver_id;
  v_origin := nullif(btrim(replace(cfg('public.origin', v_city_id)::text, '"', '')), '');

  if v_origin is not null then
    v_url := v_origin || '/p/' || v_code || '?t=' || v_token;
  else
    v_url := 'along://p/' || v_code || '?t=' || v_token;
  end if;

  return jsonb_build_object(
    'url', v_url,
    'token', v_token,
    'amount', jsonb_build_object('amount', v_amount, 'currency', v_t.fare_currency),
    'expires_at', v_exp
  );
end;
$$;

grant execute on function create_payment_request(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- rotate_driver_code — invalidate old stickers (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function rotate_driver_code()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_old_code text;
  v_new_code text;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select driver_code into v_old_code from drivers where id = v_driver_id for update;
  if v_old_code is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'no driver code';
  end if;

  v_new_code := generate_driver_code();

  update drivers
  set driver_code = v_new_code, driver_code_rotated_at = now()
  where id = v_driver_id;

  insert into qr_sticker_requests (driver_id, driver_code, reason)
  values (v_driver_id, v_new_code, 'rotation');

  insert into audit_log (actor_id, actor_role, action, target_type, target_id, after)
  values (
    v_driver_id,
    'driver',
    'rotate_driver_code',
    'drivers',
    v_driver_id::text,
    jsonb_build_object('old_code', v_old_code, 'new_code', v_new_code)
  );

  return jsonb_build_object(
    'driver_code', v_new_code,
    'rotated_at', now()
  );
end;
$$;

grant execute on function rotate_driver_code() to authenticated;

-- ---------------------------------------------------------------------------
-- set_accepts_digital — pause/resume QR (doc 03 §7)
-- ---------------------------------------------------------------------------
create or replace function set_accepts_digital(p_enabled boolean)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (select 1 from drivers d where d.id = v_driver_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  update drivers set accepts_digital = p_enabled where id = v_driver_id;

  return jsonb_build_object('accepts_digital', p_enabled);
end;
$$;

grant execute on function set_accepts_digital(boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- Rider payment method RPCs (server-side only writes)
-- ---------------------------------------------------------------------------
create or replace function upsert_rider_payment_method(
  p_authorization_code text,
  p_brand text default null,
  p_last4 text default null,
  p_exp_month smallint default null,
  p_exp_year smallint default null,
  p_bank text default null,
  p_set_default boolean default true
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_rider_id uuid := auth.uid();
  v_id uuid;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_authorization_code is null or btrim(p_authorization_code) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_set_default then
    update rider_payment_methods set is_default = false where rider_id = v_rider_id;
  end if;

  insert into rider_payment_methods (
    rider_id, authorization_code, brand, last4, exp_month, exp_year, bank, is_default
  ) values (
    v_rider_id, btrim(p_authorization_code), p_brand, p_last4, p_exp_month, p_exp_year, p_bank, p_set_default
  )
  on conflict (rider_id, authorization_code) do update set
    brand = excluded.brand,
    last4 = excluded.last4,
    exp_month = excluded.exp_month,
    exp_year = excluded.exp_year,
    bank = excluded.bank,
    is_default = case when p_set_default then true else rider_payment_methods.is_default end
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function upsert_rider_payment_method(text, text, text, smallint, smallint, text, boolean)
  to authenticated, service_role;

create or replace function remove_rider_payment_method(p_payment_method_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_rider_id uuid := auth.uid();
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  delete from rider_payment_methods
  where id = p_payment_method_id and rider_id = v_rider_id;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
end;
$$;

grant execute on function remove_rider_payment_method(uuid) to authenticated, service_role;

create or replace function set_default_rider_payment_method(p_payment_method_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_rider_id uuid := auth.uid();
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from rider_payment_methods
    where id = p_payment_method_id and rider_id = v_rider_id
  ) then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  update rider_payment_methods set is_default = false where rider_id = v_rider_id;
  update rider_payment_methods set is_default = true
  where id = p_payment_method_id and rider_id = v_rider_id;
end;
$$;

grant execute on function set_default_rider_payment_method(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- payment receipt lookup
-- ---------------------------------------------------------------------------
create or replace function payment_receipt_payload(p_payment_id uuid, p_receipt_token text default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_pay payments%rowtype;
  v_rider_id uuid := auth.uid();
begin
  select * into v_pay from payments where id = p_payment_id;
  if v_pay.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_pay.status <> 'succeeded' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_rider_id is not null then
    if v_pay.rider_id is distinct from v_rider_id then
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
  elsif p_receipt_token is null or v_pay.receipt_token is distinct from p_receipt_token then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'payment_id', v_pay.id,
    'amount', jsonb_build_object('amount', v_pay.amount, 'currency', v_pay.currency),
    'commission', jsonb_build_object('amount', v_pay.commission_amount, 'currency', v_pay.currency),
    'driver_amount', jsonb_build_object('amount', v_pay.driver_amount, 'currency', v_pay.currency),
    'source', v_pay.source,
    'trip_id', v_pay.trip_id,
    'paid_at', v_pay.confirmed_at
  );
end;
$$;

revoke all on function payment_receipt_payload(uuid, text) from public;
grant execute on function payment_receipt_payload(uuid, text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- apply_paystack_charge_success — fix early webhook: no ledger before completion (TS-QR-07)
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

    select * into v_trip from trips where id = v_payment.trip_id;

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
        jsonb_build_object('trip_id', v_trip_id, 'payment_id', v_payment_id),
        format('trip:%s:digital_offset', v_trip_id),
        'payment_webhook',
        null,
        'late digital payment offset'
      );
    end if;

    -- TS-QR-07: webhook before trip completion — no ledger row yet
    if v_trip.status <> 'completed' then
      return null;
    end if;

    if v_credit <= 0 then
      return null;
    end if;

    return ledger_post(
      v_driver_id,
      'digital_settlement_credit',
      v_credit,
      v_currency,
      jsonb_build_object('trip_id', v_trip_id, 'payment_id', v_payment_id),
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

-- ---------------------------------------------------------------------------
-- expire_payments — doc 14 §4.4
-- ---------------------------------------------------------------------------
create or replace function expire_payments()
returns int
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_count int;
begin
  update payments
  set status = 'expired'
  where status in ('initiated', 'pending')
    and coalesce(expires_at, created_at + make_interval(secs => cfg_num('payments.initiate_ttl_s', null)::int)) < now();

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function expire_payments() from public;
grant execute on function expire_payments() to service_role;

-- ---------------------------------------------------------------------------
-- pg_cron — payments.expired + daily split reconciliation (doc 03 §12, TS-QR-12)
-- ---------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'payments.expired' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'payments.expired',
    '* * * * *',
    $cron$select expire_payments()$cron$
  );

  for v_jobid in select jobid from cron.job where jobname = 'reconcile_split_settlements_daily' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'reconcile_split_settlements_daily',
    '5 4 * * *',
    $cron$select reconcile_split_settlements((current_date - 1)::date, '{}'::jsonb)$cron$
  );
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule payments.expired manually (doc 03 §12)';
  when others then
    raise notice 'pg_cron schedule skipped: %', sqlerrm;
end;
$$;
