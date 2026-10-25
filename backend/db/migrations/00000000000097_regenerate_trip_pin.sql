-- Rider can ask for a fresh pickup PIN while the trip is accepted and not
-- yet boarded, e.g. after the driver locked the old one. Rider of the trip
-- only; at most 3 new PINs per trip and one per 30 s. A new PIN resets the
-- driver's attempt counter.

alter table trip_pins
  add column regenerations int not null default 0,
  add column regenerated_at timestamptz;

create or replace function regenerate_trip_pin(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_p trip_pins%rowtype;
  v_pin char(4);
  v_max int := 3;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_t.rider_id is distinct from v_uid then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_t.status <> 'accepted' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;
  select * into v_p from trip_pins where trip_id = p_trip_id for update;
  if v_p.trip_id is null or v_p.verified_at is not null then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;
  if v_p.regenerations >= v_max then
    return jsonb_build_object('pin', v_p.pin, 'regenerated', false, 'limit_reached', true);
  end if;
  if v_p.regenerated_at > now() - interval '30 seconds' then
    return jsonb_build_object('pin', v_p.pin, 'regenerated', false, 'rate_limited', true);
  end if;
  loop
    v_pin := _mint_trip_pin();
    exit when v_pin <> v_p.pin;
  end loop;
  update trip_pins
  set pin = v_pin, attempts = 0, last_attempt_at = null,
      regenerations = regenerations + 1, regenerated_at = now()
  where trip_id = p_trip_id;
  return jsonb_build_object('pin', v_pin, 'regenerated', true);
end;
$$;

revoke execute on function regenerate_trip_pin(uuid) from public, anon;
grant execute on function regenerate_trip_pin(uuid) to authenticated;
