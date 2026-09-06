-- P3-A-03: Realtime location channel hardening — admin:{city} ops channel, payload size
-- bound, trip_snapshot polling fallback with live positions (doc 03 §5, doc 07 §5).

-- ---------------------------------------------------------------------------
-- Config (doc 07 §5 — heartbeat / live-paused thresholds)
-- ---------------------------------------------------------------------------
select config_default('realtime.heartbeat_stale_s', '15');
select config_default('realtime.live_paused_after_s', '30');

-- ---------------------------------------------------------------------------
-- Bounded Realtime send (doc 02 §2.3 — realtime.max_payload_bytes)
-- ---------------------------------------------------------------------------
create or replace function private.realtime_send_bounded(
  p_payload jsonb,
  p_event text,
  p_topic text,
  p_private boolean default true
)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_max int;
begin
  v_max := cfg_num('realtime.max_payload_bytes', null)::int;
  if octet_length(p_payload::text) > v_max then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  perform realtime.send(p_payload, p_event, p_topic, p_private);
end;
$$;

revoke all on function private.realtime_send_bounded(jsonb, text, text, boolean) from public;
grant execute on function private.realtime_send_bounded(jsonb, text, text, boolean) to service_role;
grant usage on schema private to service_role;

-- ---------------------------------------------------------------------------
-- Admin Realtime topic authorization (doc 08 §4 — Tier I ops live map)
-- ---------------------------------------------------------------------------
create or replace function realtime_admin_city(p_topic text, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from admin_users a
    join cities c on c.slug = split_part(p_topic, ':', 2)
    join countries k on k.code = c.country_code
    where p_topic like 'admin:%'
      and a.id = p_user_id
      and a.disabled_at is null
      and (
        a.role = 'superadmin'
        or (
          a.role = any(array['ops_lead', 'ops_agent', 'safety']::admin_role[])
          and (
            a.city_scope is null and a.deployment_id = k.deployment_id
            or c.id = any(a.city_scope)
          )
        )
      )
  )
$$;

revoke all on function realtime_admin_city(text, uuid) from public;
grant execute on function realtime_admin_city(text, uuid) to authenticated, service_role;

drop policy if exists realtime_admin_broadcast_select on realtime.messages;
create policy realtime_admin_broadcast_select
  on realtime.messages for select to authenticated
  using (
    realtime.messages.extension in ('broadcast', 'presence')
    and (select realtime.topic()) like 'admin:%'
    and realtime_admin_city((select realtime.topic()), (select auth.uid()))
  );

-- ---------------------------------------------------------------------------
-- Admin precise presence — service-role fanout payload (doc 08 §4)
-- ---------------------------------------------------------------------------
create or replace function admin_presence_fanout(p_city_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'type', 'presence',
    'as_of', to_jsonb(now()),
    'vehicles', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'driver_id', dp.driver_id,
          'lat', st_y(dp.current_location::geometry),
          'lng', st_x(dp.current_location::geometry),
          'heading', dp.heading,
          'speed_mps', coalesce(dp.speed_mps, 0),
          'status', dp.status,
          'mode', _mode_ref(ve.mode_code),
          'plate', ve.plate_number,
          'seats_available', dp.seats_available
        )
        order by dp.driver_id
      )
      from driver_presence dp
      join drivers d on d.id = dp.driver_id
      join vehicles ve on ve.id = dp.vehicle_id
      where d.city_id = p_city_id
        and driver_is_matchable(dp.driver_id)
        and presence_is_fresh(dp.last_ping_at, d.city_id)
        and dp.status in ('at_park', 'roaming_available', 'roaming_full')
    ), '[]'::jsonb)
  );
$$;

revoke all on function admin_presence_fanout(uuid) from public;
grant execute on function admin_presence_fanout(uuid) to service_role;

create or replace function admin_presence_snapshot(p_city_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'safety'])
     or not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return admin_presence_fanout(p_city_id);
end;
$$;

revoke all on function admin_presence_snapshot(uuid) from public;
grant execute on function admin_presence_snapshot(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- trip_snapshot — polling fallback with latest live positions (doc 03 §5, doc 07 §5)
-- ---------------------------------------------------------------------------
create or replace function trip_snapshot(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_view jsonb;
  v_status text;
begin
  v_view := build_trip_view(p_trip_id);
  v_status := v_view->>'status';

  if v_status in ('accepted', 'boarded', 'in_transit') then
    v_view := v_view || jsonb_build_object(
      'live', jsonb_strip_nulls(jsonb_build_object(
        'as_of', to_jsonb(now()),
        'driver', (
          select case
            when s.trip_id is not null then jsonb_build_object(
              'lat', st_y(s.location::geometry),
              'lng', st_x(s.location::geometry),
              'heading', s.heading,
              'speed_mps', s.speed_mps,
              'ts', s.ts
            )
            else null
          end
          from _latest_trip_sample(p_trip_id, 'driver') s
        ),
        'rider', (
          select case
            when s.trip_id is not null then jsonb_build_object(
              'lat', st_y(s.location::geometry),
              'lng', st_x(s.location::geometry),
              'heading', s.heading,
              'speed_mps', s.speed_mps,
              'ts', s.ts
            )
            else null
          end
          from _latest_trip_sample(p_trip_id, 'rider') s
        )
      ))
    );
  end if;

  return v_view;
end;
$$;

revoke all on function trip_snapshot(uuid) from public;
grant execute on function trip_snapshot(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Rewire small control-message senders through payload-size guard.
-- Large TripView payloads (trip_request) keep direct realtime.send — doc 07 §4
-- applies the ≤300 B rule to loc/status pings, not full TripView snapshots.
-- ---------------------------------------------------------------------------
create or replace function private.broadcast_driver_trip_request(p_trip_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_t record;
  v_view jsonb;
begin
  select t.id, t.driver_id, t.expires_at, t.status
  into v_t
  from trips t
  where t.id = p_trip_id;

  if v_t.id is null or v_t.status <> 'requested' then
    return;
  end if;

  v_view := build_trip_view(p_trip_id, v_t.driver_id);

  perform realtime.send(
    jsonb_build_object(
      'type', 'trip_request',
      'trip', v_view,
      'expires_at', v_t.expires_at
    ),
    'trip_request',
    'driver:' || v_t.driver_id::text,
    true
  );
end;
$$;

create or replace function private.broadcast_rider_dispatch_retarget(p_trip_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
begin
  perform realtime.send(
    rider_trip_broadcast_payload(p_trip_id, 'dispatch_retarget'),
    'dispatch_retarget',
    'trip:' || p_trip_id::text,
    true
  );
end;
$$;

create or replace function private.broadcast_negotiation(p_negotiation_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_n price_negotiations%rowtype;
  v_last price_negotiation_rounds%rowtype;
begin
  select * into v_n from price_negotiations where id = p_negotiation_id;
  if v_n.id is null then
    return;
  end if;

  select * into v_last from _negotiation_last_round(p_negotiation_id);

  perform private.realtime_send_bounded(
    jsonb_build_object(
      'round', coalesce(v_last.round_number, 0),
      'amount', coalesce(v_last.amount, v_n.anchor_amount),
      'proposed_by', coalesce(v_last.proposed_by::text, 'rider'),
      'expires_at', v_n.expires_at,
      'status', v_n.status
    ),
    'negotiation_update',
    'negotiation:' || p_negotiation_id::text,
    true
  );
end;
$$;

-- Trip location broadcast — doc 03 §5 loc payload, bounded by realtime.max_payload_bytes
create or replace function private.broadcast_trip_location(
  p_trip_id uuid,
  p_actor text,
  p_lat double precision,
  p_lng double precision,
  p_heading smallint default null,
  p_speed_mps numeric default null,
  p_ts timestamptz default now()
)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
begin
  perform private.realtime_send_bounded(
    jsonb_build_object(
      'type', 'loc',
      'actor', p_actor,
      'lat', p_lat,
      'lng', p_lng,
      'heading', p_heading,
      'speed_mps', p_speed_mps,
      'ts', p_ts
    ),
    'loc',
    'trip:' || p_trip_id::text,
    true
  );
end;
$$;

revoke all on function private.broadcast_trip_location(uuid, text, double precision, double precision, smallint, numeric, timestamptz) from public;
grant execute on function private.broadcast_trip_location(uuid, text, double precision, double precision, smallint, numeric, timestamptz) to service_role;

create or replace function presence_stale()
returns void
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_row record;
begin
  for v_row in
    select dp.driver_id, d.city_id, dp.last_ping_at
    from driver_presence dp
    join drivers d on d.id = dp.driver_id
    where dp.last_ping_at < now() - make_interval(
      secs => cfg_num('presence.offline_after_s', d.city_id)::int
    )
  loop
    begin
      perform private.realtime_send_bounded(
        jsonb_build_object('type', 'presence_dropped'),
        'presence_dropped',
        'driver:' || v_row.driver_id::text,
        true
      );
    exception
      when others then
        null;
    end;

    delete from driver_presence where driver_id = v_row.driver_id;
  end loop;
end;
$$;
