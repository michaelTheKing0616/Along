-- P2-A-04: journeys multi-trip state machine, transfer handling, transfer-walk prefetch hook (doc 04 §11)

select config_default('journey.abandon_after_min', '60');
select config_default('journey.transfer_prefetch_eta_s', '300');

-- ---------------------------------------------------------------------------
-- journey_transfer_walks — server-prefetched transfer wayfinding (doc 04 §11)
-- ---------------------------------------------------------------------------
create table journey_transfer_walks (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references journeys(id) on delete cascade,
  after_trip_sequence smallint not null check (after_trip_sequence >= 1),
  from_location geography(Point,4326) not null,
  to_location geography(Point,4326) not null,
  directions jsonb not null,
  prefetched_at timestamptz not null default now(),
  unique (journey_id, after_trip_sequence)
);

create index journey_transfer_walks_journey on journey_transfer_walks(journey_id);

alter table journey_transfer_walks enable row level security;

create policy journey_transfer_walks_select_own
  on journey_transfer_walks for select to authenticated
  using (
    exists (
      select 1 from journeys j
      where j.id = journey_id and j.rider_id = auth.uid()
    )
  );

create policy journey_transfer_walks_select_admin
  on journey_transfer_walks for select to authenticated
  using (
    exists (
      select 1 from journeys j
      where j.id = journey_id and admin_can_access_city(j.city_id)
    )
    and has_admin_role(array['superadmin','safety','ops_lead','ops_agent','finance','analyst'])
  );

create policy journey_transfer_walks_no_client_write
  on journey_transfer_walks for all to authenticated
  using (false)
  with check (false);

grant select on journey_transfer_walks to authenticated;

-- ---------------------------------------------------------------------------
-- Journey helpers
-- ---------------------------------------------------------------------------
create or replace function _journey_planned_leg_count(p_journey_id uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_array_length(j.plan_snapshot->'legs'), 0)::int
  from journeys j
  where j.id = p_journey_id;
$$;

create or replace function _journey_plan_leg(p_journey_id uuid, p_leg_index int)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select leg.value
  from journeys j
  cross join lateral jsonb_array_elements(coalesce(j.plan_snapshot->'legs', '[]'::jsonb)) leg(value)
  where j.id = p_journey_id
    and (leg.value->>'leg_index')::int = p_leg_index
  limit 1;
$$;

create or replace function _trip_planned_in_vehicle_s(p_trip_id uuid)
returns int
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_t trips%rowtype;
  v_leg jsonb;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    return null;
  end if;

  v_leg := _journey_plan_leg(v_t.journey_id, v_t.journey_sequence - 1);
  if v_leg is null then
    return null;
  end if;

  return coalesce((v_leg->>'in_vehicle_s')::int, (v_leg->>'in_vehicle_time_estimate_s')::int);
end;
$$;

create or replace function _advance_journey_on_trip_complete(p_trip trips)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_leg_count int;
begin
  v_leg_count := _journey_planned_leg_count(p_trip.journey_id);

  if v_leg_count <= 0 then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_trip.journey_sequence < v_leg_count then
    update journeys
    set
      status = 'transfer',
      current_trip_sequence = p_trip.journey_sequence + 1,
      updated_at = now()
    where id = p_trip.journey_id
      and status = 'active';
  else
    update journeys
    set
      status = 'completed',
      completed_at = now(),
      updated_at = now()
    where id = p_trip.journey_id
      and status in ('active', 'transfer');
  end if;
end;
$$;

create or replace function transfer_prefetch_context(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_j journeys%rowtype;
  v_leg_count int;
  v_current_leg jsonb;
  v_next_leg jsonb;
  v_from geography;
  v_to geography;
  v_remaining_s int;
  v_prefetch_eta_s int;
  v_wayfinding text;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select * into v_j from journeys where id = v_t.journey_id;
  v_leg_count := _journey_planned_leg_count(v_j.id);

  if v_t.status <> 'in_transit'
     or v_t.journey_sequence >= v_leg_count then
    return jsonb_build_object('eligible', false);
  end if;

  v_prefetch_eta_s := cfg_num('journey.transfer_prefetch_eta_s', v_j.city_id)::int;
  v_remaining_s := coalesce(
    _trip_planned_in_vehicle_s(v_t.id),
    0
  ) - extract(epoch from (now() - coalesce(v_t.started_at, v_t.boarded_at, v_t.accepted_at, now())))::int;

  if v_remaining_s > v_prefetch_eta_s then
    return jsonb_build_object('eligible', false, 'remaining_s', v_remaining_s);
  end if;

  v_current_leg := _journey_plan_leg(v_j.id, v_t.journey_sequence - 1);
  v_next_leg := _journey_plan_leg(v_j.id, v_t.journey_sequence);

  if v_current_leg is null or v_next_leg is null then
    return jsonb_build_object('eligible', false);
  end if;

  v_from := coalesce(
    v_t.alighting_location,
    case when v_current_leg->'alight' ? 'location'
      then _point_from_json(v_current_leg->'alight'->'location') else null end
  );
  v_to := case when v_next_leg->'board' ? 'location'
    then _point_from_json(v_next_leg->'board'->'location') else null end;

  if v_from is null or v_to is null then
    return jsonb_build_object('eligible', false);
  end if;

  select p.wayfinding_mode into v_wayfinding
  from profiles p
  where p.id = v_j.rider_id;

  return jsonb_build_object(
    'eligible', true,
    'journey_id', v_j.id,
    'after_trip_sequence', v_t.journey_sequence,
    'city_id', v_j.city_id,
    'wayfinding_mode', coalesce(v_wayfinding, 'text'),
    'from', jsonb_build_object(
      'lat', st_y(v_from::geometry),
      'lng', st_x(v_from::geometry)
    ),
    'to', jsonb_build_object(
      'lat', st_y(v_to::geometry),
      'lng', st_x(v_to::geometry)
    )
  );
end;
$$;

create or replace function store_transfer_walk_prefetch(
  p_trip_id uuid,
  p_directions jsonb
)
returns void
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_ctx jsonb;
  v_from geography;
  v_to geography;
begin
  v_ctx := transfer_prefetch_context(p_trip_id);
  if coalesce((v_ctx->>'eligible')::boolean, false) is not true then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_from := st_setsrid(
    st_makepoint(
      (v_ctx->'from'->>'lng')::double precision,
      (v_ctx->'from'->>'lat')::double precision
    ),
    4326
  )::geography;
  v_to := st_setsrid(
    st_makepoint(
      (v_ctx->'to'->>'lng')::double precision,
      (v_ctx->'to'->>'lat')::double precision
    ),
    4326
  )::geography;

  insert into journey_transfer_walks (
    journey_id,
    after_trip_sequence,
    from_location,
    to_location,
    directions
  ) values (
    (v_ctx->>'journey_id')::uuid,
    (v_ctx->>'after_trip_sequence')::smallint,
    v_from,
    v_to,
    p_directions
  )
  on conflict (journey_id, after_trip_sequence) do update
  set
    from_location = excluded.from_location,
    to_location = excluded.to_location,
    directions = excluded.directions,
    prefetched_at = now();
end;
$$;

revoke all on function store_transfer_walk_prefetch(uuid, jsonb) from public;
grant execute on function store_transfer_walk_prefetch(uuid, jsonb) to service_role;

create or replace function private.maybe_enqueue_transfer_prefetch(p_trip_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_ctx jsonb;
  v_url text;
  v_key text;
begin
  v_ctx := transfer_prefetch_context(p_trip_id);
  if coalesce((v_ctx->>'eligible')::boolean, false) is not true then
    return;
  end if;

  if exists (
    select 1
    from journey_transfer_walks jtw
    where jtw.journey_id = (v_ctx->>'journey_id')::uuid
      and jtw.after_trip_sequence = (v_ctx->>'after_trip_sequence')::smallint
  ) then
    return;
  end if;

  begin
    v_url := nullif(current_setting('app.settings.api_external_url', true), '');
    v_key := nullif(current_setting('app.settings.service_role_key', true), '');
  exception
    when others then
      return;
  end;

  if v_url is null or v_key is null then
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/transfer-prefetch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object('trip_id', p_trip_id)
  );
exception
  when others then
    null;
end;
$$;

revoke all on function private.maybe_enqueue_transfer_prefetch(uuid) from public;
grant execute on function private.maybe_enqueue_transfer_prefetch(uuid) to service_role;

create or replace function abandon_stale_journeys()
returns int
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_journey uuid;
  v_count int := 0;
  v_abandon_min int;
begin
  for v_journey in
    select j.id
    from journeys j
    where j.status in ('planning', 'active', 'transfer')
      and j.updated_at <= now() - make_interval(
        mins => cfg_num('journey.abandon_after_min', j.city_id)::int
      )
    for update skip locked
  loop
    update journeys
    set status = 'abandoned', updated_at = now()
    where id = v_journey;
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- Trip state machine — extend for lifecycle + journey advance (doc 04 §10–§11)
-- ---------------------------------------------------------------------------
create or replace function trip_transition(
  p_trip_id uuid,
  p_to_status trip_status,
  p_actor_type actor_type,
  p_actor_id uuid default null,
  p_reason text default null,
  p_meta jsonb default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_t trips%rowtype;
  v_allowed boolean := false;
  v_commission numeric;
begin
  select * into v_t from trips where id = p_trip_id for update;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.status = p_to_status then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_allowed := case
    when v_t.status = 'requested' and p_to_status = 'accepted'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id and driver_is_matchable(v_t.driver_id)
    when v_t.status = 'requested' and p_to_status = 'declined'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'requested' and p_to_status = 'expired'
      then p_actor_type = 'system'
    when v_t.status = 'requested' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    when v_t.status = 'accepted' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    when v_t.status = 'accepted' and p_to_status = 'cancelled_by_driver'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'accepted' and p_to_status = 'boarded'
      then p_actor_type in ('system', 'rider', 'driver')
        and (p_actor_type = 'system' or p_actor_id in (v_t.rider_id, v_t.driver_id))
    when v_t.status = 'boarded' and p_to_status = 'in_transit'
      then p_actor_type in ('system', 'driver') and (p_actor_type = 'system' or p_actor_id = v_t.driver_id)
    when v_t.status = 'boarded' and p_to_status = 'cancelled_by_driver'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'boarded' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    when v_t.status = 'in_transit' and p_to_status = 'completed'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'in_transit' and p_to_status = 'cancelled_by_driver'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'in_transit' and p_to_status = 'cancelled_by_rider'
      then p_actor_type = 'rider' and p_actor_id = v_t.rider_id
    else false
  end;

  if not v_allowed then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  perform set_config('along.in_transition', 'on', true);

  v_commission := round((v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0)) * v_t.commission_rate, 2);

  update trips
  set
    status = p_to_status,
    accepted_at = case when p_to_status = 'accepted' then now() else accepted_at end,
    boarded_at = case when p_to_status = 'boarded' then now() else boarded_at end,
    started_at = case when p_to_status = 'in_transit' then coalesce(started_at, now()) else started_at end,
    ended_at = case
      when p_to_status = 'completed'
        or p_to_status in ('declined', 'expired', 'cancelled_by_rider', 'cancelled_by_driver', 'no_show')
      then now()
      else ended_at
    end,
    cancelled_at = case when p_to_status::text like 'cancelled_%' or p_to_status in ('declined', 'expired')
      then now() else cancelled_at end,
    boarded_via = case
      when p_to_status = 'boarded' and p_actor_type = 'system' then 'auto_colocation'
      when p_to_status = 'boarded' and p_actor_type = 'rider' then 'manual_rider'
      when p_to_status = 'boarded' and p_actor_type = 'driver' then 'manual_driver'
      else boarded_via
    end,
    commission_amount = case when p_to_status = 'completed' then v_commission else commission_amount end,
    cancel_reason = case
      when p_to_status = 'cancelled_by_rider' or p_to_status = 'cancelled_by_driver' then p_reason
      else cancel_reason
    end,
    decline_reason = case when p_to_status = 'declined' then p_reason else decline_reason end
  where id = p_trip_id;

  insert into trip_events (trip_id, from_status, to_status, actor_type, actor_id, reason, meta)
  values (p_trip_id, v_t.status, p_to_status, p_actor_type, p_actor_id, p_reason, p_meta);

  if p_to_status = 'accepted' then
    if v_t.journey_sequence = 1 then
      update journeys
      set status = 'active', updated_at = now()
      where id = v_t.journey_id
        and status = 'planning';
    else
      update journeys
      set status = 'active', updated_at = now()
      where id = v_t.journey_id
        and status = 'transfer';
    end if;
  elsif p_to_status = 'completed' then
    select * into v_t from trips where id = p_trip_id;
    perform _advance_journey_on_trip_complete(v_t);
    update riders
    set trip_count = trip_count + 1
    where id = v_t.rider_id;
  elsif p_to_status = 'in_transit' then
    perform private.maybe_enqueue_transfer_prefetch(p_trip_id);
  end if;

  perform set_config('along.in_transition', '', true);
end;
$$;

grant execute on function transfer_prefetch_context(uuid) to service_role;
grant execute on function abandon_stale_journeys() to service_role;

do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'abandon_stale_journeys' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'abandon_stale_journeys',
    '*/15 * * * *',
    $cron$select abandon_stale_journeys()$cron$
  );
exception
  when undefined_table or undefined_object then
    null;
end;
$$;
