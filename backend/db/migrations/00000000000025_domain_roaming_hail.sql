-- P2-A-03: roaming hail — candidate tokens (HMAC), hail_roaming, dispatch cascade (doc 01 §6.4, 03 §4, 04 §10)

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------
select config_default('dispatch.candidate_token_ttl_s', '60');

-- ---------------------------------------------------------------------------
-- Candidate token HMAC (doc 03 §4 — key via runtime setting, same pattern as identity_hash_pepper)
-- ---------------------------------------------------------------------------
create or replace function candidate_token_hmac_key()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select nullif(current_setting('app.settings.candidate_token_hmac_key', true), '');
$$;

revoke all on function candidate_token_hmac_key() from public;
grant execute on function candidate_token_hmac_key() to service_role;

create or replace function _candidate_token_payload(
  p_driver_id uuid,
  p_session_id uuid,
  p_exp bigint
)
returns text
language sql
immutable
as $$
  select p_driver_id::text || '.' || p_session_id::text || '.' || p_exp::text;
$$;

create or replace function sign_candidate_token(
  p_driver_id uuid,
  p_session_id uuid,
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
  v_key := candidate_token_hmac_key();
  if v_key is null then
    raise exception 'candidate token HMAC key not configured'
      using errcode = '22023';
  end if;

  v_exp := extract(epoch from now())::bigint
    + cfg_num('dispatch.candidate_token_ttl_s', p_city_id)::bigint;
  v_payload := _candidate_token_payload(p_driver_id, p_session_id, v_exp);

  return encode(convert_to(v_payload, 'UTF8'), 'base64') || '.' || encode(
    extensions.hmac(convert_to(v_payload, 'UTF8'), convert_to(v_key, 'UTF8'), 'sha256'),
    'base64'
  );
end;
$$;

create or replace function verify_candidate_token(
  p_token text,
  p_city_id uuid default null
)
returns table (driver_id uuid, session_id uuid)
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

  v_key := candidate_token_hmac_key();
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
  if array_length(v_segs, 1) <> 3 then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  begin
    driver_id := v_segs[1]::uuid;
    session_id := v_segs[2]::uuid;
    v_exp := v_segs[3]::bigint;
  exception
    when others then
      raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end;

  if v_exp <= extract(epoch from now())::bigint then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  return next;
end;
$$;

revoke all on function sign_candidate_token(uuid, uuid, uuid) from public;
grant execute on function sign_candidate_token(uuid, uuid, uuid) to service_role, authenticated;

revoke all on function verify_candidate_token(text, uuid) from public;
grant execute on function verify_candidate_token(text, uuid) to service_role, authenticated;

-- ---------------------------------------------------------------------------
-- Roaming dispatch context (internal — cascade state)
-- ---------------------------------------------------------------------------
create table trip_dispatch_context (
  trip_id uuid primary key references trips(id) on delete cascade,
  hail_source text not null default 'roaming' check (hail_source = 'roaming'),
  origin geography(Point,4326) not null,
  destination geography(Point,4326) not null,
  ambient_cell text not null,
  mode_code text not null references mode_config(code),
  tried_driver_ids uuid[] not null default '{}'::uuid[],
  created_at timestamptz not null default now()
);

create index trip_dispatch_context_cell on trip_dispatch_context (ambient_cell, mode_code);

alter table trip_dispatch_context enable row level security;

create policy trip_dispatch_context_no_client_access
  on trip_dispatch_context for all to authenticated
  using (false)
  with check (false);

create policy trip_dispatch_context_service_all
  on trip_dispatch_context for all to service_role
  using (true)
  with check (true);

-- ---------------------------------------------------------------------------
-- Resolve roaming driver from verified token + live presence
-- ---------------------------------------------------------------------------
create or replace function _resolve_roaming_presence(
  p_driver_id uuid,
  p_session_id uuid,
  p_city_id uuid,
  p_destination geography default null,
  p_women_only boolean default false
)
returns table (
  driver_id uuid,
  vehicle_id uuid,
  profile_id uuid,
  mode_code text,
  current_location geography,
  ambient_cell text
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_precision int;
  v_dp driver_presence%rowtype;
  v_mode text;
begin
  v_precision := cfg_num('presence.ambient_cell_precision', p_city_id)::int;

  select dp.* into v_dp
  from driver_presence dp
  join drivers d on d.id = dp.driver_id
  where dp.driver_id = p_driver_id
    and dp.session_id = p_session_id
    and d.city_id = p_city_id
    and dp.status = 'roaming_available'
    and driver_is_matchable(dp.driver_id)
    and presence_is_fresh(dp.last_ping_at, p_city_id)
    and dp.seats_available >= 1
    and (not p_women_only or d.women_only_eligible);

  if v_dp.driver_id is null then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  if p_destination is not null
     and not presence_plausible(
       v_dp.current_location,
       v_dp.heading,
       v_dp.speed_mps,
       v_dp.nearest_stage_id,
       v_dp.declared_route_profile_id,
       v_dp.declared_route_leg_id,
       p_destination,
       p_city_id
     ) then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  select v.mode_code into v_mode from vehicles v where v.id = v_dp.vehicle_id;

  return query
  select
    v_dp.driver_id,
    v_dp.vehicle_id,
    v_dp.declared_route_profile_id,
    v_mode,
    v_dp.current_location,
    along_geohash(v_dp.current_location, v_precision);
end;
$$;

create or replace function _pick_next_roaming_driver(
  p_trip_id uuid
)
returns table (driver_id uuid, vehicle_id uuid, profile_id uuid)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_ctx trip_dispatch_context%rowtype;
  v_city_id uuid;
  v_precision int;
  v_women_only boolean;
begin
  select * into v_ctx from trip_dispatch_context where trip_id = p_trip_id;
  if v_ctx.trip_id is null then
    return;
  end if;

  select j.city_id, j.women_only
  into v_city_id, v_women_only
  from trips t
  join journeys j on j.id = t.journey_id
  where t.id = p_trip_id;

  v_precision := cfg_num('presence.ambient_cell_precision', v_city_id)::int;

  return query
  select dp.driver_id, dp.vehicle_id, dp.declared_route_profile_id
  from driver_presence dp
  join drivers d on d.id = dp.driver_id
  join vehicles v on v.id = dp.vehicle_id
  where d.city_id = v_city_id
    and v.mode_code = v_ctx.mode_code
    and along_geohash(dp.current_location, v_precision) = v_ctx.ambient_cell
    and dp.status = 'roaming_available'
    and driver_is_matchable(dp.driver_id)
    and presence_is_fresh(dp.last_ping_at, v_city_id)
    and dp.seats_available >= 1
    and not (dp.driver_id = any (v_ctx.tried_driver_ids))
    and (not v_women_only or d.women_only_eligible)
    and presence_plausible(
      dp.current_location,
      dp.heading,
      dp.speed_mps,
      dp.nearest_stage_id,
      dp.declared_route_profile_id,
      dp.declared_route_leg_id,
      v_ctx.destination,
      v_city_id
    )
  order by st_distance(dp.current_location, v_ctx.origin)
  limit 1;
end;
$$;

-- ---------------------------------------------------------------------------
-- Rider broadcast payload — no declining-driver identity (TS-DISC-06)
-- ---------------------------------------------------------------------------
create or replace function rider_trip_broadcast_payload(
  p_trip_id uuid,
  p_event_type text,
  p_message text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_t trips%rowtype;
  v_view jsonb;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_view := build_trip_view(p_trip_id, v_t.rider_id);

  return jsonb_build_object(
    'type', p_event_type,
    'message', coalesce(p_message, 'Finding another vehicle…'),
    'trip', v_view,
    'dispatch_attempt', v_t.dispatch_attempt
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

revoke all on function private.broadcast_rider_dispatch_retarget(uuid) from public;
grant execute on function private.broadcast_rider_dispatch_retarget(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- Dispatch cascade step (doc 04 §10 — SQL state; Edge orchestrates notify/broadcast)
-- ---------------------------------------------------------------------------
create or replace function dispatch_cascade_step(
  p_trip_id uuid,
  p_declining_driver_id uuid default null,
  p_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_t trips%rowtype;
  v_city_id uuid;
  v_max_cascade int;
  v_ttl int;
  v_next record;
  v_na record;
  v_terminal boolean := false;
  v_retargeted boolean := false;
begin
  select t.* into v_t from trips t where t.id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not exists (select 1 from trip_dispatch_context where trip_id = p_trip_id) then
    return jsonb_build_object('action', 'skip', 'reason', 'not_roaming');
  end if;

  if v_t.status <> 'requested' then
    return jsonb_build_object('action', 'skip', 'reason', 'not_requested');
  end if;

  if p_declining_driver_id is not null and v_t.driver_id is distinct from p_declining_driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select j.city_id into v_city_id from journeys j where j.id = v_t.journey_id;
  v_max_cascade := cfg_num('dispatch.max_cascade', v_city_id)::int;
  v_ttl := cfg_num('dispatch.request_ttl_s', v_city_id)::int;

  if p_declining_driver_id is not null then
    update trip_dispatch_context
    set tried_driver_ids = array_append(tried_driver_ids, p_declining_driver_id)
    where trip_id = p_trip_id
      and not (p_declining_driver_id = any (tried_driver_ids));
  end if;

  if v_t.dispatch_attempt >= v_max_cascade then
    v_terminal := true;
  else
    select * into v_next from _pick_next_roaming_driver(p_trip_id);
    if v_next.driver_id is null then
      v_terminal := true;
    end if;
  end if;

  if v_terminal then
    perform set_config('along.in_transition', 'on', true);
    update trips
    set
      status = 'expired',
      cancelled_at = now(),
      ended_at = now(),
      decline_reason = coalesce(p_reason, decline_reason)
    where id = p_trip_id;

    insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, reason, meta)
    values (
      p_trip_id,
      'requested',
      'expired',
      'system',
      null,
      p_reason,
      jsonb_build_object('cascade_exhausted', true, 'dispatch_attempt', v_t.dispatch_attempt)
    );
    perform set_config('along.in_transition', '', true);

    perform realtime.send(
      rider_trip_broadcast_payload(p_trip_id, 'dispatch_exhausted', 'No drivers available — please replan'),
      'dispatch_exhausted',
      'trip:' || p_trip_id::text,
      true
    );

    return jsonb_build_object('action', 'expired', 'trip_id', p_trip_id);
  end if;

  select * into v_na from generate_na_me_pairing(v_next.driver_id, v_t.rider_id, v_city_id);

  perform set_config('along.in_transition', 'on', true);
  update trips
  set
    driver_id = v_next.driver_id,
    vehicle_id = v_next.vehicle_id,
    driver_route_profile_id = v_next.profile_id,
    dispatch_attempt = dispatch_attempt + 1,
    expires_at = now() + make_interval(secs => v_ttl),
    id_signal_color = v_na.color_token,
    id_signal_shape = v_na.shape,
    status = 'requested'
  where id = p_trip_id;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, reason, meta)
  values (
    p_trip_id,
    'requested',
    'requested',
    'system',
    null,
    p_reason,
    jsonb_build_object('retarget', true, 'dispatch_attempt', v_t.dispatch_attempt + 1)
  );
  perform set_config('along.in_transition', '', true);

  perform private.notify_driver_trip_request(p_trip_id);
  perform private.broadcast_rider_dispatch_retarget(p_trip_id);

  v_retargeted := true;

  return jsonb_build_object(
    'action', 'retargeted',
    'trip_id', p_trip_id,
    'dispatch_attempt', v_t.dispatch_attempt + 1
  );
end;
$$;

revoke all on function dispatch_cascade_step(uuid, uuid, text) from public;
grant execute on function dispatch_cascade_step(uuid, uuid, text) to service_role;

create or replace function private.enqueue_dispatch(p_trip_id uuid, p_declining_driver_id uuid default null, p_reason text default null)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_url text;
  v_key text;
begin
  begin
    v_url := nullif(current_setting('app.settings.api_external_url', true), '');
    v_key := nullif(current_setting('app.settings.service_role_key', true), '');
  exception
    when others then
      v_url := null;
      v_key := null;
  end;

  if v_url is null or v_key is null then
    perform dispatch_cascade_step(p_trip_id, p_declining_driver_id, p_reason);
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/dispatch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'trip_id', p_trip_id,
      'declining_driver_id', p_declining_driver_id,
      'reason', p_reason
    )
  );
exception
  when others then
    perform dispatch_cascade_step(p_trip_id, p_declining_driver_id, p_reason);
end;
$$;

revoke all on function private.enqueue_dispatch(uuid, uuid, text) from public;
grant execute on function private.enqueue_dispatch(uuid, uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- build_trip_view — redact driver/vehicle for roaming rider before accept
-- ---------------------------------------------------------------------------
create or replace function build_trip_view(p_trip_id uuid, p_viewer_id uuid default auth.uid())
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_t record;
  v_is_rider boolean;
  v_is_driver boolean;
  v_show_vehicle boolean;
  v_roaming_pending boolean;
  v_rider_name text;
  v_driver_name text;
  v_plate text;
  v_vehicle_color text;
  v_make_model text;
  v_seat_capacity int;
  v_board jsonb;
  v_alight jsonb;
begin
  select
    t.*,
    j.city_id,
    exists (select 1 from trip_dispatch_context dc where dc.trip_id = t.id) as is_roaming_hail
  into v_t
  from trips t
  join journeys j on j.id = t.journey_id
  where t.id = p_trip_id;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_is_rider := p_viewer_id = v_t.rider_id;
  v_is_driver := p_viewer_id = v_t.driver_id;
  v_roaming_pending := v_t.is_roaming_hail and v_t.status = 'requested';

  if not v_is_rider and not v_is_driver then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_show_vehicle := v_is_driver or (
    not v_roaming_pending
    and (v_is_rider and v_t.status in ('accepted', 'boarded', 'in_transit', 'completed'))
  );

  select coalesce(p.display_name, 'Rider') into v_rider_name
  from profiles p where p.id = v_t.rider_id;

  if v_roaming_pending and v_is_rider then
    v_driver_name := '';
    v_plate := '';
    v_vehicle_color := '';
    v_make_model := '';
    v_seat_capacity := 0;
  else
    select coalesce(p.display_name, 'Driver') into v_driver_name
    from profiles p where p.id = v_t.driver_id;

    select v.plate_number, coalesce(v.color, ''), coalesce(v.make_model, ''), v.seat_capacity
    into v_plate, v_vehicle_color, v_make_model, v_seat_capacity
    from vehicles v
    where v.id = v_t.vehicle_id;
  end if;

  if v_t.boarding_stage_id is not null then
    select jsonb_build_object(
      'stage_id', rs.id,
      'name', rs.name,
      'location', jsonb_build_object(
        'lat', st_y(rs.location::geometry),
        'lng', st_x(rs.location::geometry)
      ),
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', true
    )
    into v_board
    from route_stages rs
    where rs.id = v_t.boarding_stage_id;
  elsif v_t.boarding_location is not null then
    v_board := jsonb_build_object(
      'stage_id', null,
      'name', 'Pickup',
      'location', jsonb_build_object(
        'lat', st_y(v_t.boarding_location::geometry),
        'lng', st_x(v_t.boarding_location::geometry)
      ),
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', false
    );
  else
    v_board := jsonb_build_object(
      'stage_id', null,
      'name', '',
      'location', jsonb_build_object('lat', 0, 'lng', 0),
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', false
    );
  end if;

  if v_t.alighting_stage_id is not null then
    select jsonb_build_object(
      'stage_id', rs.id,
      'name', rs.name,
      'location', jsonb_build_object(
        'lat', st_y(rs.location::geometry),
        'lng', st_x(rs.location::geometry)
      )
    )
    into v_alight
    from route_stages rs
    where rs.id = v_t.alighting_stage_id;
  elsif v_t.alighting_location is not null then
    v_alight := jsonb_build_object(
      'stage_id', null,
      'name', 'Drop-off',
      'location', jsonb_build_object(
        'lat', st_y(v_t.alighting_location::geometry),
        'lng', st_x(v_t.alighting_location::geometry)
      )
    );
  else
    v_alight := jsonb_build_object(
      'stage_id', null,
      'name', '',
      'location', jsonb_build_object('lat', 0, 'lng', 0)
    );
  end if;

  return jsonb_build_object(
    'trip_id', v_t.id,
    'journey_id', v_t.journey_id,
    'journey_sequence', v_t.journey_sequence,
    'status', v_t.status,
    'mode', _mode_ref(v_t.mode_code),
    'rider', jsonb_build_object(
      'display_name', v_rider_name,
      'rating', 0,
      'trip_count', coalesce((select r.trip_count from riders r where r.id = v_t.rider_id), 0)
    ),
    'driver', jsonb_build_object(
      'display_name', v_driver_name,
      'rating', coalesce((select d.rating from drivers d where d.id = v_t.driver_id), 0),
      'trips_completed', coalesce((
        select count(*)::int from trips tx
        where tx.driver_id = v_t.driver_id and tx.status = 'completed'
      ), 0),
      'photo_url', null
    ),
    'vehicle', case
      when v_show_vehicle and v_plate is not null and v_plate <> '' then jsonb_build_object(
        'plate_number', v_plate,
        'color', v_vehicle_color,
        'make_model', v_make_model,
        'seat_capacity', v_seat_capacity
      )
      else jsonb_build_object(
        'plate_number', '',
        'color', '',
        'make_model', '',
        'seat_capacity', 0
      )
    end,
    'board', v_board,
    'alight', v_alight,
    'route_leg_ids', to_jsonb(coalesce(v_t.route_leg_ids, '{}'::uuid[])),
    'fare', jsonb_build_object(
      'amount', v_t.fare_shown,
      'currency', v_t.fare_currency,
      'tier', v_t.fare_tier,
      'quote_id', v_t.fare_quote_id,
      'unconfirmed', v_t.fare_tier = 3
    ),
    'load', jsonb_build_object(
      'flagged', v_t.load_flagged,
      'size', v_t.load_size,
      'note', v_t.load_note
    ),
    'women_only', v_t.women_only,
    'na_me', jsonb_build_object(
      'color_token', v_t.id_signal_color,
      'shape', v_t.id_signal_shape,
      'label', _na_me_label(v_t.id_signal_color, v_t.id_signal_shape)
    ),
    'live_channel', 'trip:' || v_t.id::text,
    'expires_at', v_t.expires_at,
    'timestamps', jsonb_strip_nulls(jsonb_build_object(
      'requested_at', v_t.requested_at,
      'accepted_at', v_t.accepted_at,
      'boarded_at', v_t.boarded_at,
      'started_at', v_t.started_at,
      'ended_at', v_t.ended_at,
      'cancelled_at', v_t.cancelled_at
    )),
    'extension', null,
    'payment_method', v_t.payment_method,
    'dispatch_attempt', v_t.dispatch_attempt,
    'finding_vehicle', v_roaming_pending and v_is_rider
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- _resolve_trip_driver — roaming via verified candidate_token in leg supply
-- ---------------------------------------------------------------------------
create or replace function _resolve_trip_driver(
  p_source text,
  p_leg jsonb,
  p_candidate jsonb,
  p_city_id uuid
)
returns table (driver_id uuid, vehicle_id uuid, profile_id uuid)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_supply jsonb := coalesce(p_leg->'supply', '{}'::jsonb);
  v_driver uuid;
  v_vehicle uuid;
  v_profile uuid;
  v_board_stage uuid := (p_leg->'board'->>'stage_id')::uuid;
  v_token text := v_supply->>'candidate_token';
  v_verified record;
begin
  if p_source = 'roaming' then
    if v_token is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select * into v_verified from verify_candidate_token(v_token, p_city_id);

    select rp.driver_id, rp.vehicle_id, rp.profile_id
    into v_driver, v_vehicle, v_profile
    from _resolve_roaming_presence(
      v_verified.driver_id,
      v_verified.session_id,
      p_city_id,
      null,
      false
    ) rp;

    return query select v_driver, v_vehicle, v_profile;
    return;
  end if;

  if p_source = 'driver_profile' then
    v_profile := coalesce(
      (v_supply->>'profile_id')::uuid,
      (p_candidate->>'profile_id')::uuid,
      (p_candidate->>'driver_route_profile_id')::uuid
    );
    if v_profile is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select drp.driver_id into v_driver
    from driver_route_profiles drp
    where drp.id = v_profile
      and drp.active;

    if v_driver is null then
      raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
    end if;
  elsif p_source = 'parked' then
    v_driver := (v_supply->>'driver_id')::uuid;

    if v_driver is null then
      select dp.driver_id, dp.vehicle_id
      into v_driver, v_vehicle
      from driver_presence dp
      join drivers d on d.id = dp.driver_id
      where dp.status = 'at_park'
        and dp.nearest_stage_id = v_board_stage
        and d.city_id = p_city_id
        and driver_is_matchable(dp.driver_id)
      order by dp.started_at
      limit 1;
    end if;

    if v_driver is null then
      raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
    end if;
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if not driver_is_matchable(v_driver) then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  if v_vehicle is null then
    select dp.vehicle_id into v_vehicle
    from driver_presence dp
    where dp.driver_id = v_driver;

    if v_vehicle is null then
      select dv.vehicle_id into v_vehicle
      from driver_vehicles dv
      where dv.driver_id = v_driver
        and dv.active
      limit 1;
    end if;
  end if;

  if v_vehicle is null then
    raise exception 'DRIVER_NOT_MATCHABLE' using errcode = 'P0001';
  end if;

  return query select v_driver, v_vehicle, v_profile;
end;
$$;

-- ---------------------------------------------------------------------------
-- hail_roaming — doc 03 §4
-- ---------------------------------------------------------------------------
create or replace function hail_roaming(
  p_candidate_token text,
  p_destination jsonb,
  p_women_only boolean,
  p_client_ref uuid,
  p_load jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_rider_id uuid := auth.uid();
  v_verified record;
  v_presence record;
  v_city_id uuid;
  v_destination geography;
  v_origin geography;
  v_fare fare_resolution;
  v_quote_id uuid;
  v_trip_id uuid;
  v_journey_id uuid;
  v_na record;
  v_ttl int;
  v_commission_rate numeric;
  v_load_flagged boolean := coalesce((p_load->>'flagged')::boolean, false);
  v_load_size load_size;
  v_load_note text := p_load->>'note';
  v_board_stage uuid;
  v_alight_stage uuid;
  v_route_id uuid;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  v_destination := _point_from_json(p_destination);
  if v_destination is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_city_id := city_for_point(v_destination);

  select * into v_verified from verify_candidate_token(p_candidate_token, v_city_id);

  select * into v_presence
  from _resolve_roaming_presence(
    v_verified.driver_id,
    v_verified.session_id,
    v_city_id,
    v_destination,
    p_women_only
  );

  v_origin := v_presence.current_location;
  perform _validate_load_flag(p_load, v_presence.mode_code, v_city_id);

  if v_load_flagged and p_load ? 'size' then
    begin
      v_load_size := (p_load->>'size')::load_size;
    exception
      when invalid_text_representation then
        raise exception 'VALIDATION' using errcode = 'P0001';
    end;
  end if;

  v_board_stage := snap_stage(v_origin, null, v_city_id);
  v_alight_stage := snap_stage(v_destination, null, v_city_id);

  if v_alight_stage is not null then
    select rs.route_id into v_route_id from route_stages rs where rs.id = v_alight_stage;
  end if;

  if v_presence.profile_id is not null then
    v_fare := resolve_fare(
      p_profile_id := v_presence.profile_id,
      p_from_stage_id := v_board_stage,
      p_to_stage_id := v_alight_stage,
      p_from_point := case when v_board_stage is null then v_origin else null end,
      p_to_point := case when v_alight_stage is null then v_destination else null end,
      p_mode_code := v_presence.mode_code,
      p_city_id := v_city_id,
      p_load := p_load,
      p_rider_id := v_rider_id,
      p_driver_id := v_presence.driver_id
    );
  elsif v_route_id is not null and v_board_stage is not null and v_alight_stage is not null then
    v_fare := resolve_fare(
      p_route_id := v_route_id,
      p_from_stage_id := v_board_stage,
      p_to_stage_id := v_alight_stage,
      p_mode_code := v_presence.mode_code,
      p_city_id := v_city_id,
      p_load := p_load,
      p_rider_id := v_rider_id,
      p_driver_id := v_presence.driver_id
    );
  else
    v_fare := resolve_fare(
      p_from_point := v_origin,
      p_to_point := v_destination,
      p_mode_code := v_presence.mode_code,
      p_city_id := v_city_id,
      p_load := p_load,
      p_rider_id := v_rider_id,
      p_driver_id := v_presence.driver_id
    );
  end if;

  if v_fare.tier = 3 and v_fare.unconfirmed then
    raise exception 'FARE_UNRESOLVED' using errcode = 'P0001';
  end if;

  v_quote_id := v_fare.quote_id;
  select * into v_na from generate_na_me_pairing(v_presence.driver_id, v_rider_id, v_city_id);
  v_ttl := cfg_num('dispatch.request_ttl_s', v_city_id)::int;
  v_commission_rate := cfg_num('commission.rate', v_city_id);

  insert into journeys (
    rider_id, city_id, status, origin, destination, plan_snapshot,
    load_flagged, load_size, load_note, women_only
  ) values (
    v_rider_id,
    v_city_id,
    'planning',
    v_origin,
    v_destination,
    jsonb_build_object('source', 'roaming', 'candidate_token', p_candidate_token),
    v_load_flagged,
    v_load_size,
    v_load_note,
    p_women_only
  )
  returning id into v_journey_id;

  insert into trips (
    journey_id,
    journey_sequence,
    rider_id,
    driver_id,
    vehicle_id,
    mode_code,
    route_id,
    driver_route_profile_id,
    boarding_stage_id,
    alighting_stage_id,
    boarding_location,
    alighting_location,
    fare_quote_id,
    fare_shown,
    fare_currency,
    fare_tier,
    commission_rate,
    status,
    expires_at,
    id_signal_color,
    id_signal_shape,
    load_flagged,
    load_size,
    load_note,
    women_only
  ) values (
    v_journey_id,
    1,
    v_rider_id,
    v_presence.driver_id,
    v_presence.vehicle_id,
    v_presence.mode_code,
    v_route_id,
    v_presence.profile_id,
    v_board_stage,
    v_alight_stage,
    v_origin,
    v_destination,
    v_quote_id,
    v_fare.amount,
    v_fare.currency,
    v_fare.tier,
    v_commission_rate,
    'requested',
    now() + make_interval(secs => v_ttl),
    v_na.color_token,
    v_na.shape,
    v_load_flagged,
    v_load_size,
    v_load_note,
    p_women_only
  )
  returning id into v_trip_id;

  insert into trip_dispatch_context (
    trip_id, origin, destination, ambient_cell, mode_code, tried_driver_ids
  ) values (
    v_trip_id,
    v_origin,
    v_destination,
    v_presence.ambient_cell,
    v_presence.mode_code,
    array[v_presence.driver_id]
  );

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, meta)
  values (
    v_trip_id,
    null,
    'requested',
    'rider',
    v_rider_id,
    jsonb_build_object('client_ref', p_client_ref, 'hail_source', 'roaming')
  );

  perform private.notify_driver_trip_request(v_trip_id);

  return build_trip_view(v_trip_id, v_rider_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- request_trip — add roaming source support
-- ---------------------------------------------------------------------------
create or replace function request_trip(
  p_candidate_id uuid,
  p_leg_index int,
  p_women_only boolean,
  p_client_ref uuid,
  p_load jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_rider_id uuid := auth.uid();
  v_candidate jsonb;
  v_leg jsonb;
  v_planner_query_id uuid;
  v_journey_id uuid;
  v_city_id uuid;
  v_origin geography;
  v_destination geography;
  v_source text;
  v_driver_id uuid;
  v_vehicle_id uuid;
  v_profile_id uuid;
  v_quote_id uuid;
  v_quote record;
  v_trip_id uuid;
  v_na record;
  v_ttl int;
  v_commission_rate numeric;
  v_mode_code text;
  v_journey_seq smallint := 1;
  v_load_flagged boolean := coalesce((p_load->>'flagged')::boolean, false);
  v_load_size load_size;
  v_load_note text := p_load->>'note';
  v_presence record;
  v_token text;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select *
  into v_candidate, v_leg, v_planner_query_id, v_journey_id, v_city_id, v_origin, v_destination
  from _find_plan_leg(v_rider_id, p_candidate_id, p_leg_index);

  v_source := v_candidate->>'source';
  if v_source not in ('parked', 'driver_profile', 'roaming') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_mode_code := coalesce(v_leg->'mode'->>'code', v_leg->>'mode_code');
  perform _validate_load_flag(p_load, v_mode_code, v_city_id);

  if v_load_flagged and p_load ? 'size' then
    begin
      v_load_size := (p_load->>'size')::load_size;
    exception
      when invalid_text_representation then
        raise exception 'VALIDATION' using errcode = 'P0001';
    end;
  end if;

  v_quote_id := (v_leg->'fare'->>'quote_id')::uuid;
  select fq.* into v_quote
  from fare_quotes fq
  where fq.id = v_quote_id;

  if v_quote.id is null or v_quote.expires_at <= now() then
    raise exception 'CANDIDATE_EXPIRED' using errcode = 'P0001';
  end if;

  if v_source = 'roaming' then
    v_token := v_leg->'supply'->>'candidate_token';
    perform verify_candidate_token(v_token, v_city_id);
  end if;

  select rd.driver_id, rd.vehicle_id, rd.profile_id
  into v_driver_id, v_vehicle_id, v_profile_id
  from _resolve_trip_driver(v_source, v_leg, v_candidate, v_city_id) rd;

  select * into v_na
  from generate_na_me_pairing(v_driver_id, v_rider_id, v_city_id);

  v_ttl := cfg_num('dispatch.request_ttl_s', v_city_id)::int;
  v_commission_rate := cfg_num('commission.rate', v_city_id);

  if v_journey_id is null then
    insert into journeys (
      rider_id, city_id, status, origin, destination, plan_snapshot,
      planner_query_id, load_flagged, load_size, load_note, women_only
    ) values (
      v_rider_id,
      v_city_id,
      'planning',
      v_origin,
      v_destination,
      v_candidate,
      v_planner_query_id,
      v_load_flagged,
      v_load_size,
      v_load_note,
      p_women_only
    )
    returning id into v_journey_id;

    if v_planner_query_id is not null then
      update planner_queries
      set chosen_candidate_id = p_candidate_id
      where id = v_planner_query_id;
    end if;
  else
    select coalesce(max(journey_sequence), 0) + 1
    into v_journey_seq
    from trips
    where journey_id = v_journey_id;
  end if;

  insert into trips (
    journey_id,
    journey_sequence,
    rider_id,
    driver_id,
    vehicle_id,
    mode_code,
    route_id,
    driver_route_profile_id,
    route_leg_ids,
    boarding_stage_id,
    alighting_stage_id,
    boarding_location,
    alighting_location,
    fare_quote_id,
    fare_shown,
    fare_currency,
    fare_tier,
    commission_rate,
    status,
    expires_at,
    id_signal_color,
    id_signal_shape,
    load_flagged,
    load_size,
    load_note,
    women_only
  ) values (
    v_journey_id,
    v_journey_seq,
    v_rider_id,
    v_driver_id,
    v_vehicle_id,
    v_mode_code,
    (v_leg->>'route_id')::uuid,
    v_profile_id,
    coalesce(
      (
        select array_agg(x::uuid)
        from jsonb_array_elements_text(coalesce(v_leg->'route_leg_ids', '[]'::jsonb)) t(x)
      ),
      '{}'::uuid[]
    ),
    (v_leg->'board'->>'stage_id')::uuid,
    (v_leg->'alight'->>'stage_id')::uuid,
    case when v_leg->'board' ? 'location'
      then _point_from_json(v_leg->'board'->'location') else null end,
    case when v_leg->'alight' ? 'location'
      then _point_from_json(v_leg->'alight'->'location') else null end,
    v_quote_id,
    v_quote.amount,
    v_quote.currency,
    v_quote.tier,
    v_commission_rate,
    'requested',
    now() + make_interval(secs => v_ttl),
    v_na.color_token,
    v_na.shape,
    v_load_flagged,
    v_load_size,
    v_load_note,
    p_women_only
  )
  returning id into v_trip_id;

  if v_source = 'roaming' then
    select * into v_presence
    from _resolve_roaming_presence(
      v_driver_id,
      (select session_id from driver_presence where driver_id = v_driver_id),
      v_city_id,
      v_destination,
      p_women_only
    );

    insert into trip_dispatch_context (
      trip_id, origin, destination, ambient_cell, mode_code, tried_driver_ids
    ) values (
      v_trip_id,
      coalesce(v_origin, v_presence.current_location),
      v_destination,
      v_presence.ambient_cell,
      v_mode_code,
      array[v_driver_id]
    );
  end if;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, meta)
  values (
    v_trip_id,
    null,
    'requested',
    'rider',
    v_rider_id,
    jsonb_build_object('client_ref', p_client_ref, 'candidate_id', p_candidate_id)
  );

  perform private.notify_driver_trip_request(v_trip_id);

  return build_trip_view(v_trip_id, v_rider_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- respond_to_trip — roaming decline triggers cascade (doc 03 §4)
-- ---------------------------------------------------------------------------
create or replace function respond_to_trip(
  p_trip_id uuid,
  p_action text,
  p_decline_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_reasons jsonb;
  v_is_roaming boolean;
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

  if v_t.status <> 'requested' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_action = 'accept' then
    perform trip_transition(p_trip_id, 'accepted', 'driver', v_driver_id);
  elsif p_action = 'decline' then
    if p_decline_reason is not null then
      v_reasons := cfg('decline.reasons');
      if p_decline_reason <> 'no_room_for_load'
         and not v_reasons ?| array[p_decline_reason] then
        raise exception 'VALIDATION' using errcode = 'P0001';
      end if;
    end if;

    select exists (select 1 from trip_dispatch_context where trip_id = p_trip_id)
    into v_is_roaming;

    if v_is_roaming then
      perform private.enqueue_dispatch(p_trip_id, v_driver_id, p_decline_reason);
      return jsonb_build_object('declined', true, 'trip_id', p_trip_id);
    else
      perform trip_transition(p_trip_id, 'declined', 'driver', v_driver_id, p_decline_reason);
    end if;
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  return build_trip_view(p_trip_id, v_driver_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- expire_requests — roaming cascade before terminal expire
-- ---------------------------------------------------------------------------
create or replace function expire_requests()
returns int
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_trip uuid;
  v_count int := 0;
  v_is_roaming boolean;
begin
  for v_trip in
    select id from trips
    where status = 'requested'
      and expires_at <= now()
    for update skip locked
  loop
    select exists (select 1 from trip_dispatch_context where trip_id = v_trip)
    into v_is_roaming;

    if v_is_roaming then
      perform dispatch_cascade_step(v_trip, null, 'expired');
    else
      perform trip_transition(v_trip, 'expired', 'system');
    end if;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- ambient_vehicles — add opaque candidate_token per cell/mode (nearest vehicle)
-- ---------------------------------------------------------------------------
create or replace function ambient_vehicles(
  p_lat double precision,
  p_lng double precision,
  p_radius_m int,
  p_dest_lat double precision default null,
  p_dest_lng double precision default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_origin geography := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  v_destination geography;
  v_city_id uuid;
  v_precision int;
  v_cells jsonb;
begin
  if p_radius_m is null or p_radius_m <= 0 or p_radius_m > 3000 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_city_id := city_for_point(v_origin);

  if p_dest_lat is not null and p_dest_lng is not null then
    v_destination := st_setsrid(st_makepoint(p_dest_lng, p_dest_lat), 4326)::geography;
  end if;

  v_precision := cfg_num('presence.ambient_cell_precision', v_city_id)::int;

  with fresh as (
    select
      dp.*,
      v.mode_code,
      along_geohash(dp.current_location, v_precision) as cell,
      coalesce(dp.speed_mps, 0) as eff_speed
    from driver_presence dp
    join vehicles v on v.id = dp.vehicle_id
    join drivers d on d.id = dp.driver_id
    where d.city_id = v_city_id
      and driver_is_matchable(dp.driver_id)
      and presence_is_fresh(dp.last_ping_at, v_city_id)
      and st_dwithin(dp.current_location, v_origin, p_radius_m)
      and dp.status in ('at_park', 'roaming_available')
      and dp.seats_available >= 1
  ),
  vehicle_sectors as (
    select
      f.*,
      case
        when f.eff_speed < 1 and f.nearest_stage_id is not null then
          sector8(bearing_deg(f.current_location, rs.location))
        when f.heading is not null then
          sector8(f.heading::double precision)
        else null
      end as sector
    from fresh f
    left join route_stages rs on rs.id = f.nearest_stage_id
  ),
  nearest_per_cell as (
    select distinct on (vs.cell, vs.mode_code)
      vs.cell,
      vs.mode_code,
      vs.driver_id,
      vs.session_id
    from vehicle_sectors vs
    order by vs.cell, vs.mode_code, st_distance(vs.current_location, v_origin)
  ),
  grouped as (
    select
      vs.cell,
      vs.mode_code,
      count(*)::int as vehicle_count,
      min(
        ceil(
          distance_m(vs.current_location, v_origin)
          / greatest(vs.eff_speed, 3)
          / 60.0
        ) * 60
      )::int as eta_band_s,
      bool_or(
        presence_plausible(
          vs.current_location,
          vs.heading,
          vs.speed_mps,
          vs.nearest_stage_id,
          vs.declared_route_profile_id,
          vs.declared_route_leg_id,
          v_destination,
          v_city_id
        )
      ) as serves_destination,
      array_agg(vs.sector) filter (where vs.sector is not null) as sectors,
      npc.driver_id as nearest_driver_id,
      npc.session_id as nearest_session_id
    from vehicle_sectors vs
    join nearest_per_cell npc
      on npc.cell = vs.cell
     and npc.mode_code = vs.mode_code
    group by vs.cell, vs.mode_code, npc.driver_id, npc.session_id
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'cell', g.cell,
      'centroid', jsonb_build_object(
        'lat', st_y(geohash_centroid(g.cell, v_precision)::geometry),
        'lng', st_x(geohash_centroid(g.cell, v_precision)::geometry)
      ),
      'mode', _mode_ref(g.mode_code),
      'count_bucket', ambient_count_bucket(g.vehicle_count),
      'heading_sectors', heading_sector_counts(g.sectors),
      'serves_destination', coalesce(g.serves_destination, false),
      'eta_band_s', g.eta_band_s,
      'candidate_token', sign_candidate_token(g.nearest_driver_id, g.nearest_session_id, v_city_id)
    )
    order by g.cell, g.mode_code
  ), '[]'::jsonb)
  into v_cells
  from grouped g;

  return jsonb_build_object('as_of', to_jsonb(now()), 'cells', v_cells);
end;
$$;

-- ---------------------------------------------------------------------------
-- open_negotiation — patch roaming candidate_token to HMAC verify (00024)
-- ---------------------------------------------------------------------------
create or replace function open_negotiation(
  p_context negotiation_context,
  p_from jsonb,
  p_to jsonb,
  p_client_ref uuid,
  p_driver_id uuid default null,
  p_candidate_token text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_rider_id uuid := auth.uid();
  v_driver_id uuid := p_driver_id;
  v_from record;
  v_to record;
  v_route_id uuid;
  v_from_stage uuid;
  v_to_stage uuid;
  v_from_point geography;
  v_to_point geography;
  v_city_id uuid;
  v_mode text := 'car';
  v_fare fare_resolution;
  v_profile_id uuid;
  v_round_cap smallint;
  v_timeout smallint;
  v_eta eta_band;
  v_pickup int;
  v_expires timestamptz;
  v_open_dist double precision;
  v_rider_loc geography;
  v_neg_id uuid;
  v_steps numeric[];
  v_ref jsonb;
  v_presence record;
begin
  if v_rider_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if not exists (select 1 from riders where id = v_rider_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_from from _negotiation_parse_endpoint(p_from);
  select * into v_to from _negotiation_parse_endpoint(p_to);

  v_from_stage := v_from.stage_id;
  v_to_stage := v_to.stage_id;
  v_from_point := v_from.point;
  v_to_point := v_to.point;

  if p_context = 'roaming' then
    if v_driver_id is null and p_candidate_token is not null then
      select v.driver_id into v_driver_id
      from verify_candidate_token(p_candidate_token, null) v;
    end if;

    if v_driver_id is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    if v_from_point is null and v_from_stage is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select d.city_id, dp.declared_route_profile_id, dp.current_location
    into v_presence
    from drivers d
    join driver_presence dp on dp.driver_id = d.id
    where d.id = v_driver_id;

    v_city_id := v_presence.city_id;

    v_rider_loc := coalesce(
      v_from_point,
      (select rs.location from route_stages rs where rs.id = v_from_stage)
    );

    if v_to_stage is not null then
      select rs.route_id into v_route_id from route_stages rs where rs.id = v_to_stage;
    elsif v_to_point is not null then
      select snap_stage(v_to_point, null, v_city_id) into v_to_stage;
      if v_to_stage is not null then
        select rs.route_id into v_route_id from route_stages rs where rs.id = v_to_stage;
      end if;
    end if;

    if v_from_stage is null and v_from_point is not null then
      select snap_stage(v_from_point, null, v_city_id) into v_from_stage;
    end if;

    if v_presence.declared_route_profile_id is not null then
      v_profile_id := v_presence.declared_route_profile_id;
    end if;

    if v_profile_id is not null then
      v_fare := resolve_fare(
        p_profile_id := v_profile_id,
        p_from_stage_id := v_from_stage,
        p_to_stage_id := v_to_stage,
        p_from_point := case when v_from_stage is null then v_from_point else null end,
        p_to_point := case when v_to_stage is null then v_to_point else null end,
        p_mode_code := v_mode,
        p_city_id := v_city_id,
        p_rider_id := v_rider_id,
        p_driver_id := v_driver_id
      );
      if v_fare.tier <= 2 then
        raise exception 'STATE_INVALID' using errcode = 'P0001';
      end if;
    elsif v_route_id is not null and v_from_stage is not null and v_to_stage is not null then
      v_fare := resolve_fare(
        p_route_id := v_route_id,
        p_from_stage_id := v_from_stage,
        p_to_stage_id := v_to_stage,
        p_mode_code := v_mode,
        p_city_id := v_city_id,
        p_rider_id := v_rider_id,
        p_driver_id := v_driver_id
      );
      if v_fare.tier <= 2 then
        raise exception 'STATE_INVALID' using errcode = 'P0001';
      end if;
    else
      v_fare := resolve_fare(
        p_from_point := v_from_point,
        p_to_point := coalesce(v_to_point, v_from_point),
        p_mode_code := v_mode,
        p_city_id := v_city_id,
        p_rider_id := v_rider_id,
        p_driver_id := v_driver_id
      );
      if v_fare.tier <= 2 then
        raise exception 'STATE_INVALID' using errcode = 'P0001';
      end if;
    end if;

    select rp.eta_band, rp.round_cap, rp.round_timeout_s, rp.pickup_radius_m, rp.expires_at, rp.open_distance_m
    into v_eta, v_round_cap, v_timeout, v_pickup, v_expires, v_open_dist
    from _negotiation_roaming_params(v_driver_id, v_rider_loc, v_city_id) rp;

  elsif p_context in ('park', 'extension', 'load_surcharge') then
    if v_driver_id is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    select d.city_id into v_city_id from drivers d where d.id = v_driver_id;

    if v_from_stage is not null then
      select rs.route_id into v_route_id from route_stages rs where rs.id = v_from_stage;
    end if;

    if v_route_id is null or v_from_stage is null or v_to_stage is null then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    v_fare := resolve_fare(
      p_route_id := v_route_id,
      p_from_stage_id := v_from_stage,
      p_to_stage_id := v_to_stage,
      p_mode_code := v_mode,
      p_city_id := v_city_id,
      p_rider_id := v_rider_id,
      p_driver_id := v_driver_id
    );

    if v_fare.tier <= 2 then
      raise exception 'STATE_INVALID' using errcode = 'P0001';
    end if;

    v_round_cap := cfg_num('negotiation.park.round_cap', v_city_id)::smallint;
    v_timeout := cfg_num('negotiation.park.round_timeout_s', v_city_id)::smallint;
    v_eta := null;
    v_pickup := null;
    v_expires := now() + make_interval(secs => (v_round_cap + 1) * v_timeout);
    v_open_dist := null;
    v_rider_loc := null;
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_ref := jsonb_build_object(
    'route_id', v_route_id,
    'from_stage_id', v_from_stage,
    'to_stage_id', v_to_stage,
    'mode_code', v_mode,
    'city_id', v_city_id,
    'client_ref', p_client_ref,
    'open_distance_m', v_open_dist
  );

  if v_from_point is not null then
    v_ref := v_ref || jsonb_build_object(
      'from_location', jsonb_build_object(
        'lat', st_y(v_from_point::geometry),
        'lng', st_x(v_from_point::geometry)
      ),
      'rider_location', jsonb_build_object(
        'lat', st_y(v_from_point::geometry),
        'lng', st_x(v_from_point::geometry)
      )
    );
  end if;

  if v_to_point is not null then
    v_ref := v_ref || jsonb_build_object(
      'to_location', jsonb_build_object(
        'lat', st_y(v_to_point::geometry),
        'lng', st_x(v_to_point::geometry)
      )
    );
  end if;

  insert into price_negotiations (
    rider_id, driver_id, context, candidate_ref,
    anchor_amount, currency, anchor_quote_id,
    round_cap, round_timeout_s, eta_band, pickup_radius_m, expires_at
  ) values (
    v_rider_id, v_driver_id, p_context, v_ref,
    v_fare.amount, v_fare.currency, v_fare.quote_id,
    v_round_cap, v_timeout, v_eta, v_pickup, v_expires
  )
  returning id into v_neg_id;

  insert into price_negotiation_rounds (
    negotiation_id, round_number, proposed_by, amount
  ) values (
    v_neg_id, 1, 'rider', v_fare.amount
  );

  update fare_quotes
  set negotiation_id = v_neg_id
  where id = v_fare.quote_id;

  perform private.broadcast_negotiation(v_neg_id);

  v_steps := _negotiation_chip_steps(v_city_id);

  return jsonb_build_object(
    'negotiation_id', v_neg_id,
    'anchor', jsonb_build_object('amount', v_fare.amount, 'currency', v_fare.currency),
    'chip_steps', (
      select coalesce(jsonb_agg(jsonb_build_object('amount', s, 'currency', v_fare.currency)), '[]'::jsonb)
      from unnest(v_steps) s
    ),
    'round_cap', v_round_cap,
    'round_timeout_s', v_timeout,
    'eta_band', coalesce(v_eta::text, 'null'),
    'expires_at', v_expires
  );
end;
$$;


-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
grant execute on function hail_roaming(text, jsonb, boolean, uuid, jsonb) to authenticated;
grant execute on function rider_trip_broadcast_payload(uuid, text, text) to service_role;
grant execute on function dispatch_cascade_step(uuid, uuid, text) to service_role;
