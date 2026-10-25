-- PR #17: phone privacy, driver PIN check, bank name on payouts, capped online time.
--
-- 1. build_trip_view.handoff no longer carries the driver's phone number. It
--    carries `contact_available`; the app asks the trip-contact Edge Function
--    for a short-lived contact action instead (server-side relay abstraction).
-- 2. verify_trip_pin(): only the trip's accepted driver, 5 attempts, one try
--    per second. A correct PIN boards the rider. start_trip and the automatic
--    in-transit check refuse to move a trip whose PIN was never cleared. A
--    rider who confirms boarding themselves (mark_boarded as rider) clears it.
-- 3. drivers.payout_bank_name, written with the last 4 at bank-detail save.
--    driver_earnings_context labels payouts "<bank> ••1234".
-- 4. Online time counts only gaps of 5 minutes or less between pings.

-- ---------------------------------------------------------------------------
-- 1. Handoff without the raw phone
-- ---------------------------------------------------------------------------
create or replace function build_trip_view(p_trip_id uuid, p_viewer_id uuid default auth.uid())
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions, private
as $$
declare
  v_view jsonb;
  v_rider uuid;
  v_driver uuid;
  v_status trip_status;
  v_pin text;
begin
  v_view := _build_trip_view_core(p_trip_id, p_viewer_id);

  select t.rider_id, t.driver_id, t.status
  into v_rider, v_driver, v_status
  from trips t
  where t.id = p_trip_id;

  if p_viewer_id = v_rider
    and v_driver is not null
    and v_status in ('accepted', 'boarded', 'in_transit')
    and coalesce((v_view->>'finding_vehicle')::boolean, false) = false
  then
    if v_status = 'accepted' then
      select tp.pin into v_pin
      from trip_pins tp
      where tp.trip_id = p_trip_id and tp.verified_at is null;
    end if;
    return v_view || jsonb_build_object(
      'handoff', jsonb_build_object('pin', v_pin, 'contact_available', true)
    );
  end if;

  return v_view || jsonb_build_object('handoff', null);
end;
$$;

revoke execute on function build_trip_view(uuid, uuid) from public, anon;
grant execute on function build_trip_view(uuid, uuid) to authenticated;

-- Who may contact whom on a live trip. Used by the trip-contact Edge Function
-- (service role) so the phone lookup never reaches a client query.
create or replace function trip_contact_target(p_trip_id uuid, p_caller uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_t trips%rowtype;
  v_target uuid;
  v_role text;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if p_caller = v_t.rider_id then
    v_target := v_t.driver_id;
    v_role := 'rider';
  elsif p_caller is not null and p_caller = v_t.driver_id then
    v_target := v_t.rider_id;
    v_role := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_target is null or v_t.status not in ('accepted', 'boarded', 'in_transit') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;
  return jsonb_build_object(
    'trip_id', v_t.id,
    'caller_role', v_role,
    'caller_phone', (select phone_e164 from profiles where id = p_caller),
    'target_phone', (select phone_e164 from profiles where id = v_target)
  );
end;
$$;

revoke execute on function trip_contact_target(uuid, uuid) from public, anon, authenticated;
grant execute on function trip_contact_target(uuid, uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 2. PIN verification
-- ---------------------------------------------------------------------------
alter table trip_pins
  add column attempts int not null default 0,
  add column last_attempt_at timestamptz,
  add column verified_at timestamptz,
  add column verified_by actor_type;

create or replace function _trip_pin_cleared(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from trip_pins tp where tp.trip_id = p_trip_id and tp.verified_at is null
  );
$$;

revoke execute on function _trip_pin_cleared(uuid) from public, anon, authenticated;

create or replace function verify_trip_pin(p_trip_id uuid, p_pin text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_p trip_pins%rowtype;
  v_max int := 5;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_t.driver_id is distinct from v_uid then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_t.status not in ('accepted', 'boarded') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_p from trip_pins where trip_id = p_trip_id for update;
  if v_p.trip_id is null or v_p.verified_at is not null then
    if v_t.status = 'accepted' then
      perform trip_transition(p_trip_id, 'boarded', 'driver', v_uid);
    end if;
    return jsonb_build_object('verified', true, 'attempts_left', v_max);
  end if;

  if v_p.attempts >= v_max then
    return jsonb_build_object('verified', false, 'attempts_left', 0, 'locked', true);
  end if;
  if v_p.last_attempt_at > now() - interval '1 second' then
    return jsonb_build_object(
      'verified', false, 'attempts_left', v_max - v_p.attempts, 'rate_limited', true
    );
  end if;

  if p_pin is distinct from v_p.pin::text then
    update trip_pins
    set attempts = attempts + 1, last_attempt_at = now()
    where trip_id = p_trip_id;
    return jsonb_build_object(
      'verified', false,
      'attempts_left', v_max - v_p.attempts - 1,
      'locked', v_p.attempts + 1 >= v_max
    );
  end if;

  update trip_pins
  set verified_at = now(), verified_by = 'driver', last_attempt_at = now()
  where trip_id = p_trip_id;
  if v_t.status = 'accepted' then
    perform trip_transition(p_trip_id, 'boarded', 'driver', v_uid);
  end if;
  return jsonb_build_object('verified', true, 'attempts_left', v_max - v_p.attempts);
end;
$$;

revoke execute on function verify_trip_pin(uuid, text) from public, anon;
grant execute on function verify_trip_pin(uuid, text) to authenticated;

-- A rider confirming boarding themselves clears the PIN.
create or replace function _trips_rider_board_clears_pin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'boarded' and old.status = 'accepted' and auth.uid() = new.rider_id then
    update trip_pins
    set verified_at = now(), verified_by = 'rider'
    where trip_id = new.id and verified_at is null;
  end if;
  return new;
end;
$$;

revoke execute on function _trips_rider_board_clears_pin() from public, anon, authenticated;

create trigger trips_rider_board_clears_pin
  after update of status on trips
  for each row execute function _trips_rider_board_clears_pin();

create or replace function start_trip(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from trips t
    where t.id = p_trip_id
      and t.driver_id = v_driver_id
      and t.status = 'boarded'
  ) then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if not _trip_pin_cleared(p_trip_id) then
    raise exception 'PIN_REQUIRED' using errcode = 'P0001';
  end if;

  perform trip_transition(p_trip_id, 'in_transit', 'driver', v_driver_id);
  return build_trip_view(p_trip_id, v_driver_id);
end;
$$;

grant execute on function start_trip(uuid) to authenticated;

-- The automatic in-transit check waits for the PIN too.
alter function auto_in_transit_check(uuid) rename to _auto_in_transit_check_core;
revoke execute on function _auto_in_transit_check_core(uuid) from public, anon, authenticated;

create or replace function auto_in_transit_check(p_trip_id uuid)
returns boolean
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if not _trip_pin_cleared(p_trip_id) then
    return false;
  end if;
  return _auto_in_transit_check_core(p_trip_id);
end;
$$;

revoke execute on function auto_in_transit_check(uuid) from public, anon, authenticated;
grant execute on function auto_in_transit_check(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 3. Bank name
-- ---------------------------------------------------------------------------
alter table drivers add column payout_bank_name text
  check (payout_bank_name is null or length(btrim(payout_bank_name)) between 2 and 40);

create or replace function protect_driver_bank_name()
returns trigger
language plpgsql
as $$
begin
  if coalesce(current_setting('role', true), '') = 'service_role'
    -- nosemgrep: along-postgres-current-user-bypass -- reviewed: protect_* trigger, migration/service path only
     or current_user in ('postgres', 'supabase_admin') then
    return new;
  end if;
  if new.payout_bank_name is distinct from old.payout_bank_name then
    raise exception 'cannot update payout_bank_name' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger drivers_protect_bank_name before update on drivers
  for each row execute function protect_driver_bank_name();

drop function persist_driver_payout_bank(text, text);

create function persist_driver_payout_bank(
  p_subaccount_code text,
  p_bank_last4 text,
  p_bank_name text default null
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
  v_bank text := nullif(btrim(coalesce(p_bank_name, '')), '');
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

  if p_bank_last4 is null or p_bank_last4 !~ '^\d{4}$' then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'bank_last4 must be 4 digits';
  end if;

  if v_bank is not null and length(v_bank) > 40 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'bank_name too long';
  end if;

  update drivers
  set
    payout_subaccount_code = btrim(p_subaccount_code),
    payout_bank_last4 = p_bank_last4,
    payout_bank_name = v_bank,
    driver_code = coalesce(driver_code, generate_driver_code())
  where id = v_driver_id
  returning driver_code into v_code;

  return jsonb_build_object(
    'payout_subaccount_code', btrim(p_subaccount_code),
    'payout_bank_last4', p_bank_last4,
    'payout_bank_name', v_bank,
    'driver_code', v_code
  );
end;
$$;

revoke execute on function persist_driver_payout_bank(text, text, text) from public, anon;
grant execute on function persist_driver_payout_bank(text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3 + 4. driver_earnings_context: bank label, capped online time
-- ---------------------------------------------------------------------------
create or replace function driver_earnings_context(p_days int default 7)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_driver uuid := auth.uid();
  v_days int := greatest(1, least(coalesce(p_days, 7), 31));
  v_from timestamptz;
  v_online jsonb;
  v_payout jsonb;
  v_bank text;
  v_last4 text;
begin
  if v_driver is null or not exists (select 1 from drivers d where d.id = v_driver) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_from := (date_trunc('day', now() at time zone 'Africa/Lagos')
    - make_interval(days => v_days - 1)) at time zone 'Africa/Lagos';

  -- Online time: sum of gaps between consecutive non-offline pings in a
  -- session, counting only gaps of 5 minutes or less. Credited to the Lagos
  -- day of the later ping.
  select coalesce(jsonb_object_agg(day, seconds), '{}'::jsonb)
  into v_online
  from (
    select g.day::date::text as day, sum(g.gap)::int as seconds
    from (
      select
        date_trunc('day', h.ts at time zone 'Africa/Lagos') as day,
        extract(epoch from h.ts - lag(h.ts) over (partition by h.session_id order by h.ts)) as gap
      from driver_presence_history h
      where h.driver_id = v_driver
        and h.ts >= v_from
        and h.status <> 'offline'
    ) g
    where g.gap is not null and g.gap <= 300
    group by g.day
  ) d;

  select d.payout_bank_name, d.payout_bank_last4
  into v_bank, v_last4
  from drivers d
  where d.id = v_driver;

  select jsonb_build_object(
    'status', p.status,
    'amount', p.amount,
    'currency', p.currency,
    'created_at', p.created_at,
    'confirmed_at', p.confirmed_at,
    'bank_name', v_bank,
    'account_last4', v_last4,
    'account_label', case
      when v_last4 is null then v_bank
      else coalesce(v_bank, 'Bank') || ' ••' || v_last4
    end
  )
  into v_payout
  from driver_payouts p
  where p.driver_id = v_driver
  order by p.created_at desc
  limit 1;

  return jsonb_build_object(
    'from', v_from,
    'online_seconds_by_day', v_online,
    'latest_payout', v_payout
  );
end;
$$;

revoke execute on function driver_earnings_context(int) from public, anon;
grant execute on function driver_earnings_context(int) to authenticated;
