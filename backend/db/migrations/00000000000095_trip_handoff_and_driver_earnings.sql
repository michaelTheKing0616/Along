-- PR #16: rider pickup handoff (trip PIN + driver contact) and driver earnings context.
--
-- 1. trip_pins: a 4-digit PIN minted when a driver accepts a trip. The rider
--    shows it at the door; it is returned only to the trip's rider.
-- 2. build_trip_view gains a `handoff` object for the rider while the trip is
--    live: { pin (accepted only), driver_phone }. No phone masking or proxy
--    exists in this repo, so the driver's profile number is returned as-is,
--    only to the rider of that trip, only while the trip is live.
-- 3. driver_earnings_context(): online seconds per Lagos day (derived from
--    driver_presence_history sessions) and the driver's latest payout record.

-- ---------------------------------------------------------------------------
-- trip_pins
-- RLS: rider of the trip may select; no client writes; drivers cannot read.
-- ---------------------------------------------------------------------------
create table trip_pins (
  trip_id uuid primary key references trips(id) on delete cascade,
  pin char(4) not null check (pin ~ '^[0-9]{4}$'),
  created_at timestamptz not null default now()
);

alter table trip_pins enable row level security;

create policy trip_pins_select_rider
  on trip_pins for select to authenticated
  using (
    exists (
      select 1 from trips t
      where t.id = trip_pins.trip_id
        and t.rider_id = (select auth.uid())
    )
  );

create policy trip_pins_no_client_write
  on trip_pins for all to authenticated
  using (false)
  with check (false);

grant select on trip_pins to authenticated;

create or replace function _mint_trip_pin()
returns char(4)
language sql
volatile
set search_path = public, extensions
as $$
  select lpad(
    (('x' || encode(extensions.gen_random_bytes(2), 'hex'))::bit(16)::int % 10000)::text,
    4,
    '0'
  )::char(4);
$$;

revoke execute on function _mint_trip_pin() from public, anon, authenticated;

create or replace function _trips_mint_pin()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if new.status = 'accepted' and (tg_op = 'INSERT' or old.status is distinct from 'accepted') then
    insert into trip_pins (trip_id, pin)
    values (new.id, _mint_trip_pin())
    on conflict (trip_id) do nothing;
  end if;
  return new;
end;
$$;

revoke execute on function _trips_mint_pin() from public, anon, authenticated;

create trigger trips_mint_pin
  after insert or update of status on trips
  for each row execute function _trips_mint_pin();

insert into trip_pins (trip_id, pin)
select t.id, _mint_trip_pin()
from trips t
where t.status = 'accepted'
on conflict (trip_id) do nothing;

-- ---------------------------------------------------------------------------
-- build_trip_view + handoff
-- ---------------------------------------------------------------------------
alter function build_trip_view(uuid, uuid) rename to _build_trip_view_core;
revoke execute on function _build_trip_view_core(uuid, uuid) from public, anon, authenticated;

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
  v_phone text;
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
      select tp.pin into v_pin from trip_pins tp where tp.trip_id = p_trip_id;
    end if;
    select p.phone_e164 into v_phone from profiles p where p.id = v_driver;
  end if;

  return v_view || jsonb_build_object(
    'handoff',
    case
      when v_pin is null and v_phone is null then null
      else jsonb_build_object('pin', v_pin, 'driver_phone', v_phone)
    end
  );
end;
$$;

revoke execute on function build_trip_view(uuid, uuid) from public, anon;
grant execute on function build_trip_view(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- driver_earnings_context
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
begin
  if v_driver is null or not exists (select 1 from drivers d where d.id = v_driver) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_from := (date_trunc('day', now() at time zone 'Africa/Lagos')
    - make_interval(days => v_days - 1)) at time zone 'Africa/Lagos';

  -- Online time: per presence session and Lagos day, first-to-last non-offline ping.
  select coalesce(jsonb_object_agg(day, seconds), '{}'::jsonb)
  into v_online
  from (
    select s.day::date::text as day, sum(s.span)::int as seconds
    from (
      select
        h.session_id,
        date_trunc('day', h.ts at time zone 'Africa/Lagos') as day,
        extract(epoch from max(h.ts) - min(h.ts)) as span
      from driver_presence_history h
      where h.driver_id = v_driver
        and h.ts >= v_from
        and h.status <> 'offline'
      group by h.session_id, date_trunc('day', h.ts at time zone 'Africa/Lagos')
    ) s
    group by s.day
  ) d;

  select jsonb_build_object(
    'status', p.status,
    'amount', p.amount,
    'currency', p.currency,
    'created_at', p.created_at,
    'confirmed_at', p.confirmed_at,
    'account_label', 'Paystack ••' || right(p.recipient_subaccount_code, 4)
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
