-- P5-A-03: Day planner — itineraries, stops, RPCs, prepare hooks (doc 02 §11, doc 03 §9, FM23)

-- ---------------------------------------------------------------------------
-- Enums & tables (doc 02 §11 — itineraries / itinerary_stops only)
-- ---------------------------------------------------------------------------
create type itinerary_status as enum ('active','completed','abandoned');
create type stop_status as enum ('pending','in_progress','completed','skipped');

create table itineraries (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id),
  status itinerary_status not null default 'active',
  plan_date date not null default current_date,
  load_flagged boolean not null default false,
  load_size load_size,
  load_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table itinerary_stops (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references itineraries(id) on delete cascade,
  sequence int not null,
  destination_description text not null,
  destination_location geography(Point,4326),
  target_time timestamptz,
  status stop_status not null default 'pending',
  linked_journey_id uuid references journeys(id),
  prepared_plan jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (itinerary_id, sequence)
);

create trigger itineraries_set_updated_at before update on itineraries
  for each row execute function set_updated_at();

create trigger itinerary_stops_set_updated_at before update on itinerary_stops
  for each row execute function set_updated_at();

create index itinerary_stops_itinerary_seq on itinerary_stops(itinerary_id, sequence);
create index itinerary_stops_pending on itinerary_stops(itinerary_id) where status = 'pending';

alter table journeys
  add constraint journeys_stop_fk foreign key (itinerary_stop_id) references itinerary_stops(id);

-- ---------------------------------------------------------------------------
-- Config (doc 03 §9 — prepare threshold; never literal in function bodies)
-- ---------------------------------------------------------------------------
select config_default('itinerary.prepare_eta_s', '600');

-- ---------------------------------------------------------------------------
-- RLS — rider own; writes via RPC only (doc 02 §11)
-- ---------------------------------------------------------------------------
alter table itineraries enable row level security;
alter table itinerary_stops enable row level security;

create policy itineraries_select_own
  on itineraries for select to authenticated
  using (rider_id = auth.uid());

create policy itineraries_no_client_write
  on itineraries for all to authenticated
  using (false)
  with check (false);

create policy itinerary_stops_select_own
  on itinerary_stops for select to authenticated
  using (
    exists (
      select 1 from itineraries i
      where i.id = itinerary_stops.itinerary_id
        and i.rider_id = auth.uid()
    )
  );

create policy itinerary_stops_no_client_write
  on itinerary_stops for all to authenticated
  using (false)
  with check (false);

grant select on itineraries to authenticated;
grant select on itinerary_stops to authenticated;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function _geo_point_json(p_point geography)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'lat', st_y(p_point::geometry),
    'lng', st_x(p_point::geometry)
  );
$$;

create or replace function _itinerary_next_pending_stop(p_itinerary_id uuid, p_after_sequence int default null)
returns itinerary_stops
language sql
stable
security definer
set search_path = public
as $$
  select s.*
  from itinerary_stops s
  where s.itinerary_id = p_itinerary_id
    and s.status = 'pending'
    and (p_after_sequence is null or s.sequence > p_after_sequence)
  order by s.sequence
  limit 1;
$$;

create or replace function _itinerary_origin_for_stop(p_itinerary_id uuid, p_stop itinerary_stops)
returns geography
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_prev itinerary_stops%rowtype;
  v_j journeys%rowtype;
  v_t trips%rowtype;
  v_point geography;
begin
  if p_stop.linked_journey_id is not null then
    select * into v_j from journeys where id = p_stop.linked_journey_id;
    if v_j.id is not null then
      return v_j.origin;
    end if;
  end if;

  select * into v_prev
  from itinerary_stops s
  where s.itinerary_id = p_itinerary_id
    and s.sequence < p_stop.sequence
    and s.status in ('completed', 'in_progress')
  order by s.sequence desc
  limit 1;

  if v_prev.id is not null and v_prev.destination_location is not null then
    return v_prev.destination_location;
  end if;

  select t.* into v_t
  from itinerary_stops s
  join journeys j on j.id = s.linked_journey_id
  join trips t on t.journey_id = j.id
  where s.itinerary_id = p_itinerary_id
    and s.sequence < p_stop.sequence
    and t.status in ('accepted', 'boarded', 'in_transit')
  order by s.sequence desc, t.journey_sequence desc
  limit 1;

  if v_t.id is not null then
    v_point := coalesce(
      v_t.alighting_location,
      (select j.destination from journeys j where j.id = v_t.journey_id)
    );
    if v_point is not null then
      return v_point;
    end if;
  end if;

  return null;
end;
$$;

create or replace function _build_itinerary_prepared_plan(
  p_rider_id uuid,
  p_city_id uuid,
  p_origin_lat double precision,
  p_origin_lng double precision,
  p_dest_lat double precision,
  p_dest_lng double precision,
  p_filters jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_query_id uuid := gen_random_uuid();
  v_direct jsonb := '[]'::jsonb;
  v_multi jsonb := '[]'::jsonb;
  v_candidates jsonb := '[]'::jsonb;
  v_direct_count int := 0;
  v_row jsonb;
  v_ids uuid[] := '{}'::uuid[];
begin
  for v_row in
    select c from planner_direct_candidates_latlng(
      p_origin_lat, p_origin_lng, p_dest_lat, p_dest_lng, p_city_id, p_filters
    ) c
    limit cfg_num('planner.max_candidates', p_city_id)::int
  loop
    v_direct := v_direct || jsonb_build_array(v_row);
    v_direct_count := v_direct_count + 1;
  end loop;

  for v_row in
    select c from planner_decompose_latlng(
      p_origin_lat, p_origin_lng, p_dest_lat, p_dest_lng, p_city_id, p_filters
    ) c
    limit greatest(cfg_num('planner.max_candidates', p_city_id)::int - v_direct_count, 0)
  loop
    v_multi := v_multi || jsonb_build_array(v_row);
  end loop;

  v_candidates := v_direct || v_multi;

  perform insert_planner_query(
    v_query_id,
    p_rider_id,
    p_city_id,
    p_origin_lat,
    p_origin_lng,
    p_dest_lat,
    p_dest_lng,
    p_filters,
    v_candidates,
    jsonb_array_length(v_candidates),
    v_direct_count,
    false,
    0
  );

  return jsonb_build_object(
    'query_id', v_query_id,
    'city_id', p_city_id,
    'degraded', false,
    'candidates', v_candidates,
    'sort_orders', jsonb_build_object(
      'recommended', coalesce(
        (select jsonb_agg(elem->>'candidate_id')
         from jsonb_array_elements(v_candidates) elem),
        '[]'::jsonb
      )
    ),
    'coverage_gap', null,
    'candidate_set_only', true,
    'match_requires_request_trip', true
  );
end;
$$;

create or replace function _itinerary_stop_row_json(p_stop itinerary_stops)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', p_stop.id,
    'sequence', p_stop.sequence,
    'destination_description', p_stop.destination_description,
    'destination_location', case
      when p_stop.destination_location is null then null
      else _geo_point_json(p_stop.destination_location)
    end,
    'target_time', p_stop.target_time,
    'status', p_stop.status,
    'linked_journey_id', p_stop.linked_journey_id,
    'prepared_plan', p_stop.prepared_plan
  );
$$;

create or replace function _itinerary_state_json(p_itinerary_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_itin itineraries%rowtype;
  v_next itinerary_stops%rowtype;
  v_stops jsonb := '[]'::jsonb;
begin
  select * into v_itin from itineraries where id = p_itinerary_id;
  if v_itin.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select coalesce(
    jsonb_agg(_itinerary_stop_row_json(s) order by s.sequence),
    '[]'::jsonb
  ) into v_stops
  from itinerary_stops s
  where s.itinerary_id = p_itinerary_id;

  select * into v_next from _itinerary_next_pending_stop(p_itinerary_id, null);

  return jsonb_build_object(
    'itinerary_id', v_itin.id,
    'status', v_itin.status,
    'plan_date', v_itin.plan_date,
    'load_flagged', v_itin.load_flagged,
    'load_size', v_itin.load_size,
    'load_note', v_itin.load_note,
    'stops', v_stops,
    'next_pending_stop_id', v_next.id,
    'next_prepared_plan', v_next.prepared_plan,
    'not_booked', true,
    'match_action', 'request_trip'
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: create_itinerary
-- ---------------------------------------------------------------------------
create or replace function create_itinerary(
  p_stops jsonb,
  p_load jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_itin_id uuid;
  v_stop jsonb;
  v_seq int;
  v_desc text;
  v_loc geography;
  v_load_flagged boolean := false;
  v_load_size load_size;
  v_load_note text;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_stops is null or jsonb_typeof(p_stops) <> 'array' or jsonb_array_length(p_stops) = 0 then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'p_stops must be a non-empty array';
  end if;

  if p_load is not null then
    v_load_flagged := coalesce((p_load->>'flagged')::boolean, false);
    if p_load ? 'size' and p_load->>'size' is not null then
      v_load_size := (p_load->>'size')::load_size;
    end if;
    v_load_note := nullif(btrim(p_load->>'note'), '');
  end if;

  insert into itineraries (rider_id, load_flagged, load_size, load_note)
  values (v_user_id, v_load_flagged, v_load_size, v_load_note)
  returning id into v_itin_id;

  for v_stop in select value from jsonb_array_elements(p_stops) value
  loop
    v_seq := (v_stop->>'sequence')::int;
    v_desc := nullif(btrim(v_stop->>'destination_description'), '');

    if v_seq is null or v_seq < 1 or v_desc is null then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'each stop requires sequence and destination_description';
    end if;

    v_loc := null;
    if v_stop ? 'location' and v_stop->'location' is not null then
      v_loc := _point_from_json(v_stop->'location');
    end if;

    insert into itinerary_stops (
      itinerary_id, sequence, destination_description, destination_location
    ) values (
      v_itin_id, v_seq, v_desc, v_loc
    );
  end loop;

  return _itinerary_state_json(v_itin_id);
end;
$$;

revoke all on function create_itinerary(jsonb, jsonb) from public;
grant execute on function create_itinerary(jsonb, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: update_itinerary_stops
-- ---------------------------------------------------------------------------
create or replace function update_itinerary_stops(
  p_itinerary_id uuid,
  p_ops jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_itin itineraries%rowtype;
  v_op jsonb;
  v_kind text;
  v_stop_id uuid;
  v_seq int;
  v_desc text;
  v_loc geography;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_itin from itineraries where id = p_itinerary_id;
  if v_itin.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_itin.rider_id <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_itin.status <> 'active' then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'itinerary not active';
  end if;

  if p_ops is null or jsonb_typeof(p_ops) <> 'array' then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'p_ops must be an array';
  end if;

  for v_op in select value from jsonb_array_elements(p_ops) value
  loop
    v_kind := v_op->>'op';

    if v_kind = 'remove' then
      v_stop_id := (v_op->>'stop_id')::uuid;
      delete from itinerary_stops s
      where s.id = v_stop_id
        and s.itinerary_id = p_itinerary_id
        and s.status = 'pending';
    elsif v_kind = 'edit' then
      v_stop_id := (v_op->>'stop_id')::uuid;
      v_desc := nullif(btrim(v_op->>'destination_description'), '');
      v_loc := case
        when v_op ? 'location' then _point_from_json(v_op->'location')
        else null
      end;
      update itinerary_stops s
      set
        destination_description = coalesce(v_desc, s.destination_description),
        destination_location = coalesce(v_loc, s.destination_location),
        updated_at = now()
      where s.id = v_stop_id
        and s.itinerary_id = p_itinerary_id
        and s.status = 'pending';
    elsif v_kind = 'add' then
      v_seq := (v_op->>'sequence')::int;
      v_desc := nullif(btrim(v_op->>'destination_description'), '');
      v_loc := case when v_op ? 'location' then _point_from_json(v_op->'location') else null end;
      insert into itinerary_stops (itinerary_id, sequence, destination_description, destination_location)
      values (p_itinerary_id, v_seq, v_desc, v_loc);
    elsif v_kind = 'reorder' then
      v_stop_id := (v_op->>'stop_id')::uuid;
      v_seq := (v_op->>'sequence')::int;
      update itinerary_stops s
      set sequence = v_seq, updated_at = now()
      where s.id = v_stop_id
        and s.itinerary_id = p_itinerary_id
        and s.status = 'pending';
    else
      raise exception 'VALIDATION' using errcode = 'P0001', message = format('unknown op %s', v_kind);
    end if;
  end loop;

  return _itinerary_state_json(p_itinerary_id);
end;
$$;

revoke all on function update_itinerary_stops(uuid, jsonb) from public;
grant execute on function update_itinerary_stops(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: itinerary_state
-- ---------------------------------------------------------------------------
create or replace function itinerary_state(p_itinerary_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_itin itineraries%rowtype;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_itin from itineraries where id = p_itinerary_id;
  if v_itin.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_itin.rider_id <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return _itinerary_state_json(p_itinerary_id);
end;
$$;

revoke all on function itinerary_state(uuid) from public;
grant execute on function itinerary_state(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: store_itinerary_prepared_plan (service role + internal)
-- ---------------------------------------------------------------------------
create or replace function store_itinerary_prepared_plan(
  p_stop_id uuid,
  p_prepared_plan jsonb
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_stop itinerary_stops%rowtype;
begin
  select * into v_stop from itinerary_stops where id = p_stop_id;
  if v_stop.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_stop.status <> 'pending' then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'stop no longer pending';
  end if;

  update itinerary_stops
  set prepared_plan = p_prepared_plan, updated_at = now()
  where id = p_stop_id;
end;
$$;

revoke all on function store_itinerary_prepared_plan(uuid, jsonb) from public;
grant execute on function store_itinerary_prepared_plan(uuid, jsonb) to service_role;

-- ---------------------------------------------------------------------------
-- RPC: itinerary_match_next — stores prepared_plan; does NOT create a trip (FM23)
-- ---------------------------------------------------------------------------
create or replace function itinerary_match_next(p_itinerary_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_user_id uuid := auth.uid();
  v_itin itineraries%rowtype;
  v_next itinerary_stops%rowtype;
  v_after_seq int;
  v_origin geography;
  v_city_id uuid;
  v_plan jsonb;
  v_filters jsonb := '{}'::jsonb;
begin
  if v_user_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_itin from itineraries where id = p_itinerary_id;
  if v_itin.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_itin.rider_id <> v_user_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_itin.status <> 'active' then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'itinerary not active';
  end if;

  select max(s.sequence) into v_after_seq
  from itinerary_stops s
  where s.itinerary_id = p_itinerary_id
    and s.status in ('completed', 'in_progress');

  select * into v_next from _itinerary_next_pending_stop(p_itinerary_id, v_after_seq);
  if v_next.id is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'no pending stop';
  end if;
  if v_next.destination_location is null then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'next stop has no destination location';
  end if;

  v_origin := _itinerary_origin_for_stop(p_itinerary_id, v_next);
  if v_origin is null then
    raise exception 'VALIDATION' using errcode = 'P0001', message = 'origin unavailable for next stop';
  end if;

  select coalesce(r.home_city_id, city_for_point(v_origin)) into v_city_id
  from riders r
  where r.id = v_user_id;

  if v_itin.load_flagged then
    v_filters := jsonb_build_object(
      'load', jsonb_build_object(
        'flagged', true,
        'size', v_itin.load_size
      )
    );
  end if;

  v_plan := _build_itinerary_prepared_plan(
    v_user_id,
    v_city_id,
    st_y(v_origin::geometry),
    st_x(v_origin::geometry),
    st_y(v_next.destination_location::geometry),
    st_x(v_next.destination_location::geometry),
    v_filters
  );

  update itinerary_stops
  set prepared_plan = v_plan, updated_at = now()
  where id = v_next.id
    and status = 'pending';

  return _itinerary_state_json(p_itinerary_id);
end;
$$;

revoke all on function itinerary_match_next(uuid) from public;
grant execute on function itinerary_match_next(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- itinerary-prepare context + enqueue (doc 03 §9, mirrors transfer-prefetch)
-- ---------------------------------------------------------------------------
create or replace function itinerary_prepare_context(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_j journeys%rowtype;
  v_current itinerary_stops%rowtype;
  v_next itinerary_stops%rowtype;
  v_from geography;
  v_remaining_s int;
  v_prepare_eta_s int;
  v_itin itineraries%rowtype;
  v_filters jsonb := '{}'::jsonb;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select * into v_j from journeys where id = v_t.journey_id;
  if v_j.itinerary_stop_id is null then
    return jsonb_build_object('eligible', false);
  end if;

  if v_t.status <> 'in_transit' then
    return jsonb_build_object('eligible', false);
  end if;

  select * into v_current from itinerary_stops where id = v_j.itinerary_stop_id;
  select * into v_itin from itineraries where id = v_current.itinerary_id;

  v_prepare_eta_s := cfg_num('itinerary.prepare_eta_s', v_j.city_id)::int;
  v_remaining_s := coalesce(
    _trip_planned_in_vehicle_s(v_t.id),
    0
  ) - extract(epoch from (now() - coalesce(v_t.started_at, v_t.boarded_at, v_t.accepted_at, now())))::int;

  if v_remaining_s > v_prepare_eta_s then
    return jsonb_build_object('eligible', false, 'remaining_s', v_remaining_s);
  end if;

  select * into v_next from _itinerary_next_pending_stop(v_current.itinerary_id, v_current.sequence);
  if v_next.id is null then
    return jsonb_build_object('eligible', false);
  end if;

  if v_next.prepared_plan is not null then
    return jsonb_build_object('eligible', false, 'reason', 'already_prepared');
  end if;

  if v_next.destination_location is null then
    return jsonb_build_object('eligible', false, 'reason', 'missing_destination');
  end if;

  v_from := coalesce(
    v_t.alighting_location,
    v_j.destination,
    v_current.destination_location
  );

  if v_itin.load_flagged then
    v_filters := jsonb_build_object(
      'women_only', v_j.women_only,
      'load', jsonb_build_object('flagged', true, 'size', v_itin.load_size)
    );
  else
    v_filters := jsonb_build_object('women_only', v_j.women_only);
  end if;

  return jsonb_build_object(
    'eligible', true,
    'trip_id', v_t.id,
    'itinerary_id', v_itin.id,
    'stop_id', v_next.id,
    'rider_id', v_j.rider_id,
    'city_id', v_j.city_id,
    'filters', v_filters,
    'from', _geo_point_json(v_from),
    'to', _geo_point_json(v_next.destination_location),
    'destination_label', v_next.destination_description
  );
end;
$$;

create or replace function private.maybe_enqueue_itinerary_prepare(p_trip_id uuid)
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
  v_ctx := itinerary_prepare_context(p_trip_id);
  if coalesce((v_ctx->>'eligible')::boolean, false) is not true then
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
    url := rtrim(v_url, '/') || '/functions/v1/itinerary-prepare',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object('trip_id', p_trip_id)
  );
exception
  when others then
    return;
end;
$$;

revoke all on function private.maybe_enqueue_itinerary_prepare(uuid) from public;
grant execute on function private.maybe_enqueue_itinerary_prepare(uuid) to service_role;

grant execute on function itinerary_prepare_context(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- trip_transition — also enqueue itinerary-prepare on in_transit (FM23-safe)
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
    when v_t.status = 'accepted' and p_to_status = 'no_show'
      then p_actor_type = 'driver' and p_actor_id = v_t.driver_id
    when v_t.status = 'accepted' and p_to_status = 'released_before_arrival'
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
        or p_to_status in (
          'declined', 'expired', 'cancelled_by_rider', 'cancelled_by_driver',
          'no_show', 'released_before_arrival'
        )
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
    decline_reason = case when p_to_status = 'declined' then p_reason else decline_reason end,
    meta = case
      when p_to_status = 'boarded' then coalesce(meta, '{}'::jsonb) - 'colocated_since'
      when p_to_status = 'in_transit' then coalesce(meta, '{}'::jsonb) - 'moving_since'
      else meta
    end
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
    perform _materialize_trip_paths(p_trip_id);
    select * into v_t from trips where id = p_trip_id;
    perform _advance_journey_on_trip_complete(v_t);
    update riders
    set trip_count = trip_count + 1
    where id = v_t.rider_id;
  elsif p_to_status = 'in_transit' then
    perform private.maybe_enqueue_transfer_prefetch(p_trip_id);
    perform private.maybe_enqueue_itinerary_prepare(p_trip_id);
  end if;

  perform set_config('along.in_transition', '', true);
end;
$$;
