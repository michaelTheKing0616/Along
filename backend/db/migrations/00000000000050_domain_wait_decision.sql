-- P3-A-04: wait-decision backend — approach_band, refresh_wait, release_match,
-- rider_no_show_review (spec §4.1.2–4.1.3, doc 04 §10.5, doc 03 §4–5)

select config_default('disclosure.approach_band_s', '[120,300]');
select config_default('wait.stalled_window_s', '90');
select config_default('wait.stalled_progress_m', '25');
select config_default('wait.release_pickup_radius_m', '80');
select config_default('rider.no_show_review_count', '3');
select config_default('rider.no_show_window_days', '14');

alter type trip_status add value if not exists 'released_before_arrival';
alter type flag_type add value if not exists 'rider_no_show_pattern';

-- ---------------------------------------------------------------------------
-- OSRM foot duration (FM41) — test stub via along.test.osrm_foot_duration_s GUC
-- ---------------------------------------------------------------------------
create or replace function private.osrm_foot_duration_s(
  p_from geography,
  p_to geography,
  p_city_id uuid default null
)
returns int
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_override text;
  v_url text;
  v_from_lng double precision;
  v_from_lat double precision;
  v_to_lng double precision;
  v_to_lat double precision;
  v_response record;
  v_body jsonb;
  v_duration numeric;
begin
  v_override := nullif(current_setting('along.test.osrm_foot_duration_s', true), '');
  if v_override is not null then
    return v_override::int;
  end if;

  v_url := nullif(current_setting('app.settings.osrm_foot_url', true), '');
  if v_url is null then
    return null;
  end if;

  v_from_lng := st_x(p_from::geometry);
  v_from_lat := st_y(p_from::geometry);
  v_to_lng := st_x(p_to::geometry);
  v_to_lat := st_y(p_to::geometry);

  begin
    create extension if not exists http with schema extensions;
  exception
    when others then
      return null;
  end;

  begin
    select * into v_response
    from extensions.http((
      'GET',
      format(
        '%s/route/v1/foot/%s,%s;%s,%s?overview=false',
        rtrim(v_url, '/'),
        v_from_lng, v_from_lat,
        v_to_lng, v_to_lat
      ),
      null::text[],
      null::text,
      null::text
    )::extensions.http_request);

    if v_response.status <> 200 then
      return null;
    end if;

    v_body := v_response.content::jsonb;
    v_duration := (v_body->'routes'->0->>'duration')::numeric;
    if v_duration is null then
      return null;
    end if;

    return greatest(0, round(v_duration)::int);
  exception
    when others then
      return null;
  end;
end;
$$;

revoke all on function private.osrm_foot_duration_s(geography, geography, uuid) from public;

-- ---------------------------------------------------------------------------
-- approach_band — band OSRM foot seconds (FM42); never expose seconds pre-accept
-- ---------------------------------------------------------------------------
create or replace function approach_band_from_walk_s(p_walk_s int, p_city_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_thresholds jsonb;
  v_t0 int;
  v_t1 int;
begin
  if p_walk_s is null then
    return null;
  end if;

  v_thresholds := cfg('disclosure.approach_band_s', p_city_id);
  v_t0 := (v_thresholds->>0)::int;
  v_t1 := (v_thresholds->>1)::int;

  if p_walk_s < v_t0 then
    return 'under_2';
  elsif p_walk_s < v_t1 then
    return 'm2_5';
  else
    return 'over_5';
  end if;
end;
$$;

create or replace function private.trip_wait_endpoints(p_trip_id uuid)
returns table (rider_point geography, driver_point geography, city_id uuid)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_city uuid;
  v_rider geography;
  v_driver geography;
begin
  select t.*
  into v_t
  from trips t
  where t.id = p_trip_id;

  if v_t.id is null then
    return;
  end if;

  select j.city_id into v_city
  from journeys j
  where j.id = v_t.journey_id;

  city_id := v_city;

  select coalesce(
    (select s.location from _latest_trip_sample(p_trip_id, 'rider') s),
    (select dc.origin from trip_dispatch_context dc where dc.trip_id = p_trip_id),
    v_t.boarding_location,
    (select j.origin from journeys j where j.id = v_t.journey_id)
  ) into v_rider;

  select coalesce(
    (select s.location from _latest_trip_sample(p_trip_id, 'driver') s),
    (select dp.current_location from driver_presence dp where dp.driver_id = v_t.driver_id)
  ) into v_driver;

  rider_point := v_rider;
  driver_point := v_driver;
  return next;
end;
$$;

create or replace function compute_approach_band(p_trip_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_endpoints record;
  v_walk_s int;
begin
  select * into v_endpoints from private.trip_wait_endpoints(p_trip_id);

  if v_endpoints.rider_point is null or v_endpoints.driver_point is null then
    return null;
  end if;

  v_walk_s := private.osrm_foot_duration_s(
    v_endpoints.rider_point,
    v_endpoints.driver_point,
    v_endpoints.city_id
  );

  return approach_band_from_walk_s(v_walk_s, v_endpoints.city_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- refresh_wait — post-accept walking ETA + approach (doc 04 §10.5)
-- ---------------------------------------------------------------------------
create or replace function private.compute_wait_approach(
  p_trip_id uuid,
  p_city_id uuid
)
returns text
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_window_s int;
  v_progress_m numeric;
  v_sample_count int;
  v_driver geography;
  v_dist_start double precision;
  v_dist_end double precision;
begin
  v_window_s := cfg_num('wait.stalled_window_s', p_city_id)::int;
  v_progress_m := cfg_num('wait.stalled_progress_m', p_city_id);

  select count(*) into v_sample_count
  from trip_location_samples s
  where s.trip_id = p_trip_id
    and s.actor_type = 'rider'
    and s.ts >= now() - make_interval(secs => v_window_s);

  if v_sample_count < 2 then
    return 'unknown';
  end if;

  select coalesce(
    (select s.location from _latest_trip_sample(p_trip_id, 'driver') s),
    (select dp.current_location
     from driver_presence dp
     join trips t on t.driver_id = dp.driver_id
     where t.id = p_trip_id)
  ) into v_driver;

  if v_driver is null then
    return 'unknown';
  end if;

  select
    st_distance(
      (select s.location
       from trip_location_samples s
       where s.trip_id = p_trip_id
         and s.actor_type = 'rider'
         and s.ts >= now() - make_interval(secs => v_window_s)
       order by s.ts asc
       limit 1),
      v_driver
    ),
    st_distance(
      (select s.location
       from trip_location_samples s
       where s.trip_id = p_trip_id
         and s.actor_type = 'rider'
         and s.ts >= now() - make_interval(secs => v_window_s)
       order by s.ts desc
       limit 1),
      v_driver
    )
  into v_dist_start, v_dist_end;

  if v_dist_start is null or v_dist_end is null then
    return 'unknown';
  end if;

  if (v_dist_start - v_dist_end) < v_progress_m then
    return 'stalled';
  end if;

  return 'approaching';
end;
$$;

create or replace function private.broadcast_wait_update(
  p_trip_id uuid,
  p_wait jsonb
)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
begin
  perform realtime.send(
    jsonb_build_object(
      'type', 'wait',
      'walk_eta_s', (p_wait->>'walk_eta_s')::int,
      'approach', p_wait->>'approach',
      'ts', p_wait->>'updated_at'
    ),
    'wait',
    'trip:' || p_trip_id::text,
    true
  );
end;
$$;

create or replace function refresh_wait(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private, extensions
as $$
declare
  v_t trips%rowtype;
  v_city_id uuid;
  v_endpoints record;
  v_walk_s int;
  v_approach text;
  v_wait jsonb;
  v_last_refresh timestamptz;
begin
  select t.*
  into v_t
  from trips t
  where t.id = p_trip_id
  for update;

  if v_t.id is null or v_t.status <> 'accepted' then
    return null;
  end if;

  select j.city_id into v_city_id
  from journeys j
  where j.id = v_t.journey_id;

  v_last_refresh := nullif(v_t.meta->>'wait_refreshed_at', '')::timestamptz;

  if v_last_refresh is not null and v_last_refresh > now() - interval '10 seconds' then
    return v_t.meta->'wait';
  end if;

  select * into v_endpoints from private.trip_wait_endpoints(p_trip_id);

  if v_endpoints.rider_point is null or v_endpoints.driver_point is null then
    v_walk_s := null;
    v_approach := 'unknown';
  else
    v_walk_s := private.osrm_foot_duration_s(
      v_endpoints.rider_point,
      v_endpoints.driver_point,
      v_city_id
    );
    v_approach := private.compute_wait_approach(p_trip_id, v_city_id);
  end if;

  v_wait := jsonb_strip_nulls(jsonb_build_object(
    'walk_eta_s', v_walk_s,
    'approach', coalesce(v_approach, 'unknown'),
    'updated_at', to_jsonb(now())
  ));

  update trips
  set meta = coalesce(meta, '{}'::jsonb)
    || jsonb_build_object('wait', v_wait, 'wait_refreshed_at', to_jsonb(now()))
  where id = p_trip_id;

  perform private.broadcast_wait_update(p_trip_id, v_wait);

  return v_wait;
end;
$$;

revoke all on function refresh_wait(uuid) from public;
grant execute on function refresh_wait(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- release_match — doc 03 §4, spec §4.1.3 (not cancel_trip)
-- ---------------------------------------------------------------------------
create or replace function private.rider_entered_pickup_radius(p_trip_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_radius_m numeric;
  v_city_id uuid;
begin
  select t.*
  into v_t
  from trips t
  where t.id = p_trip_id;

  if v_t.id is null then
    return false;
  end if;

  select j.city_id into v_city_id
  from journeys j
  where j.id = v_t.journey_id;

  v_radius_m := cfg_num('wait.release_pickup_radius_m', v_city_id);

  return exists (
    select 1
    from trip_location_samples rs
    where rs.trip_id = p_trip_id
      and rs.actor_type = 'rider'
      and exists (
        select 1
        from trip_location_samples ds
        where ds.trip_id = p_trip_id
          and ds.actor_type = 'driver'
          and abs(extract(epoch from (ds.ts - rs.ts))) <= 30
          and st_dwithin(rs.location, ds.location, v_radius_m)
      )
  );
end;
$$;

create or replace function release_match(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_uid <> v_t.driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'accepted' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if private.rider_entered_pickup_radius(p_trip_id) then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  perform trip_transition(
    p_trip_id,
    'released_before_arrival',
    'driver',
    v_uid
  );

  return build_trip_view(p_trip_id, v_uid);
end;
$$;

revoke all on function release_match(uuid) from public;
grant execute on function release_match(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- rider_no_show_review — FM43 (admin review only, never auto-punish)
-- ---------------------------------------------------------------------------
create or replace function rider_no_show_review()
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_rider record;
  v_window_days int;
  v_threshold int;
begin
  v_window_days := cfg_num('rider.no_show_window_days', null)::int;
  v_threshold := cfg_num('rider.no_show_review_count', null)::int;

  for v_rider in
    select
      t.rider_id,
      count(*)::int as event_count,
      (array_agg(t.id order by coalesce(t.ended_at, t.updated_at) desc))[1] as latest_trip_id,
      (array_agg(t.driver_id order by coalesce(t.ended_at, t.updated_at) desc))[1] as latest_driver_id
    from trips t
    where t.status in ('no_show', 'released_before_arrival')
      and coalesce(t.ended_at, t.updated_at) >= now() - make_interval(days => v_window_days)
    group by t.rider_id
    having count(*) >= v_threshold
  loop
    if exists (
      select 1
      from trip_reconciliation_flags f
      join trips tx on tx.id = f.trip_id
      where f.flag_type = 'rider_no_show_pattern'
        and tx.rider_id = v_rider.rider_id
        and f.status = 'open'
    ) then
      continue;
    end if;

    insert into trip_reconciliation_flags (
      trip_id,
      driver_id,
      flag_type,
      score,
      evidence,
      rider_trace_quality,
      corroborating_rider_count
    ) values (
      v_rider.latest_trip_id,
      v_rider.latest_driver_id,
      'rider_no_show_pattern',
      1.0,
      jsonb_build_object(
        'rider_id', v_rider.rider_id,
        'event_count', v_rider.event_count,
        'window_days', v_window_days,
        'statuses', array['no_show', 'released_before_arrival']
      ),
      'none',
      0
    )
    on conflict (trip_id, flag_type) do nothing;
  end loop;
end;
$$;

revoke all on function rider_no_show_review() from public;
grant execute on function rider_no_show_review() to service_role;

-- ---------------------------------------------------------------------------
-- Disclosure grep helper — TS-DISC-07 / FM42
-- ---------------------------------------------------------------------------
create or replace function private.jsonb_has_coord_keys(p_value jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  v_elem jsonb;
  v_key text;
begin
  if p_value is null then
    return false;
  end if;

  if jsonb_typeof(p_value) = 'object' then
    for v_key in select jsonb_object_keys(p_value) loop
      if v_key in ('lat', 'lng') then
        return true;
      end if;
      if private.jsonb_has_coord_keys(p_value->v_key) then
        return true;
      end if;
    end loop;
  elsif jsonb_typeof(p_value) = 'array' then
    for v_elem in select value from jsonb_array_elements(p_value) loop
      if private.jsonb_has_coord_keys(v_elem) then
        return true;
      end if;
    end loop;
  end if;

  return false;
end;
$$;

create or replace function tripview_disclosure_violations(p_view jsonb)
returns text[]
language sql
stable
security definer
set search_path = public, private
as $$
  select coalesce(array_agg(distinct violation), '{}'::text[])
  from (
    select 'lat_or_lng' as violation
    where private.jsonb_has_coord_keys(p_view)
    union all
    select 'walk_eta_s'
    where p_view @@ '$.**.walk_eta_s'
    union all
    select 'polyline'
    where p_view @@ '$.**.polyline'
  ) v
$$;

revoke all on function tripview_disclosure_violations(jsonb) from public;
grant execute on function tripview_disclosure_violations(jsonb) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- build_trip_view — approach_band (pre-accept driver), wait (post-accept driver)
-- ---------------------------------------------------------------------------
create or replace function build_trip_view(p_trip_id uuid, p_viewer_id uuid default auth.uid())
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions, private
as $$
declare
  v_t record;
  v_is_rider boolean;
  v_is_driver boolean;
  v_show_vehicle boolean;
  v_roaming_pending boolean;
  v_pending_driver boolean;
  v_rider_name text;
  v_driver_name text;
  v_plate text;
  v_vehicle_color text;
  v_make_model text;
  v_seat_capacity int;
  v_board jsonb;
  v_alight jsonb;
  v_approach_band text;
  v_wait jsonb;
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
  v_pending_driver := v_is_driver and v_t.status = 'requested';

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
      'location', case
        when v_pending_driver then null
        else jsonb_build_object(
          'lat', st_y(rs.location::geometry),
          'lng', st_x(rs.location::geometry)
        )
      end,
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
      'location', case
        when v_pending_driver then null
        else jsonb_build_object(
          'lat', st_y(v_t.boarding_location::geometry),
          'lng', st_x(v_t.boarding_location::geometry)
        )
      end,
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', false
    );
  else
    v_board := jsonb_build_object(
      'stage_id', null,
      'name', '',
      'location', case when v_pending_driver then null else jsonb_build_object('lat', 0, 'lng', 0) end,
      'walk_m', 0,
      'walk_s', 0,
      'wayfinding_available', false
    );
  end if;

  if v_t.alighting_stage_id is not null then
    select jsonb_build_object(
      'stage_id', rs.id,
      'name', rs.name,
      'location', case
        when v_pending_driver then null
        else jsonb_build_object(
          'lat', st_y(rs.location::geometry),
          'lng', st_x(rs.location::geometry)
        )
      end
    )
    into v_alight
    from route_stages rs
    where rs.id = v_t.alighting_stage_id;
  elsif v_t.alighting_location is not null then
    v_alight := jsonb_build_object(
      'stage_id', null,
      'name', 'Drop-off',
      'location', case
        when v_pending_driver then null
        else jsonb_build_object(
          'lat', st_y(v_t.alighting_location::geometry),
          'lng', st_x(v_t.alighting_location::geometry)
        )
      end
    );
  else
    v_alight := jsonb_build_object(
      'stage_id', null,
      'name', '',
      'location', case when v_pending_driver then null else jsonb_build_object('lat', 0, 'lng', 0) end
    );
  end if;

  if v_pending_driver then
    v_board := v_board - 'location';
    v_alight := v_alight - 'location';
    v_approach_band := compute_approach_band(p_trip_id);
  else
    v_approach_band := null;
  end if;

  if v_is_driver and v_t.status = 'accepted' then
    v_wait := v_t.meta->'wait';
  else
    v_wait := null;
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
    'finding_vehicle', v_roaming_pending and v_is_rider,
    'approach_band', v_approach_band,
    'wait', v_wait
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- trip_location_sample — trigger refresh_wait after samples (doc 04 §10.5)
-- ---------------------------------------------------------------------------
create or replace function trip_location_sample(
  p_trip_id uuid,
  p_points jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_actor actor_type;
  v_point jsonb;
  v_ts timestamptz;
  v_loc geography;
  v_boarded_auto boolean := false;
  v_in_transit_auto boolean := false;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_uid = v_t.rider_id then
    v_actor := 'rider';
  elsif v_uid = v_t.driver_id then
    v_actor := 'driver';
  else
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status not in ('accepted', 'boarded', 'in_transit') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if jsonb_array_length(p_points) < 1 or jsonb_array_length(p_points) > 5 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  for v_point in select value from jsonb_array_elements(p_points) loop
    v_ts := coalesce((v_point->>'ts')::timestamptz, now());
    v_loc := st_setsrid(
      st_makepoint(
        (v_point->>'lng')::double precision,
        (v_point->>'lat')::double precision
      ),
      4326
    )::geography;

    insert into trip_location_samples (
      trip_id,
      actor_type,
      ts,
      location,
      accuracy_m,
      speed_mps,
      heading
    ) values (
      p_trip_id,
      v_actor,
      v_ts,
      v_loc,
      (v_point->>'accuracy_m')::numeric,
      (v_point->>'speed_mps')::numeric,
      (v_point->>'heading')::smallint
    );
  end loop;

  v_boarded_auto := auto_boarding_check(p_trip_id);
  v_in_transit_auto := auto_in_transit_check(p_trip_id);

  if (select status from trips where id = p_trip_id) = 'accepted' then
    perform refresh_wait(p_trip_id);
  end if;

  return jsonb_build_object('boarded_auto', v_boarded_auto);
end;
$$;

-- ---------------------------------------------------------------------------
-- trip_snapshot — include wait via build_trip_view (doc 03 §5)
-- ---------------------------------------------------------------------------
create or replace function trip_snapshot(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_view jsonb;
  v_status text;
begin
  if exists (
    select 1 from trips t
    where t.id = p_trip_id and t.status = 'accepted'
  ) then
    perform refresh_wait(p_trip_id);
  end if;

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

-- ---------------------------------------------------------------------------
-- trip_transition — released_before_arrival edge (doc 04 §10)
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
  end if;

  perform set_config('along.in_transition', '', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- reconcile_cancelled_trips — exclude released_before_arrival (spec §4.1.3)
-- ---------------------------------------------------------------------------
create or replace function reconcile_cancelled_trips()
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_t trips%rowtype;
  v_cancel_at timestamptz;
  v_city_id uuid;
  v_dest geography(Point,4326);
  v_route geography(LineString,4326);
  v_driver_locs geography(Point,4326)[];
  v_rider_quality trace_quality;
  v_dest_radius numeric;
  v_min_fraction numeric;
  v_extension_gap numeric;
  v_driver_reached boolean;
  v_driver_min_dist double precision;
  v_route_fraction numeric;
  v_rider_reached boolean;
  v_rider_min_dist double precision;
  v_corroborating int;
  v_score numeric;
  v_evidence jsonb;
begin
  for v_t in
    select t.*
    from trips t
    where t.driver_id is not null
      and t.status <> 'released_before_arrival'
      and coalesce(t.cancelled_at, t.ended_at, t.updated_at) > now() - interval '24 hours'
      and not exists (
        select 1
        from trip_reconciliation_flags f
        where f.trip_id = t.id
          and f.flag_type = 'premature_conversion'
      )
      and (
        (
          t.status = 'cancelled_by_driver'
          and private.reconciliation_cancel_from_status(t) in ('accepted', 'boarded', 'in_transit')
        )
        or (
          t.status = 'cancelled_by_rider'
          and private.reconciliation_cancel_from_status(t) = 'in_transit'
        )
      )
  loop
    v_cancel_at := coalesce(v_t.cancelled_at, v_t.ended_at, v_t.updated_at);
    v_city_id := (select j.city_id from journeys j where j.id = v_t.journey_id);
    v_dest := private.trip_alight_point(v_t);
    v_route := private.trip_route_path(v_t);
    v_dest_radius := cfg_num('reconciliation.dest_radius_m', v_city_id);
    v_min_fraction := cfg_num('reconciliation.min_route_fraction', v_city_id);

    v_driver_locs := private.reconciliation_driver_locations(
      v_t,
      v_cancel_at,
      v_cancel_at + interval '45 minutes'
    );

    with driver_pts as (
      select s.location, s.ts
      from trip_location_samples s
      where s.trip_id = v_t.id
        and s.actor_type = 'driver'
      union all
      select h.location, h.ts
      from driver_presence_history h
      where h.driver_id = v_t.driver_id
        and h.session_id = (
          select h2.session_id
          from driver_presence_history h2
          where h2.driver_id = v_t.driver_id
            and h2.ts <= v_cancel_at
            and h2.ts >= coalesce(v_t.accepted_at, v_t.requested_at) - interval '5 minutes'
          order by h2.ts desc
          limit 1
        )
        and h.ts > v_cancel_at
        and h.ts <= v_cancel_at + interval '30 minutes'
    ),
    post_cancel as (
      select location
      from driver_pts
      where ts between v_cancel_at and v_cancel_at + interval '45 minutes'
    )
    select
      coalesce((select min(st_distance(location, v_dest)) from post_cancel), 999999),
      coalesce((select bool_or(st_dwithin(location, v_dest, v_dest_radius)) from post_cancel), false)
    into v_driver_min_dist, v_driver_reached;

    v_route_fraction := private.route_trace_fraction(v_route, v_driver_locs);
    v_rider_quality := private.reconciliation_rider_quality(v_t, v_cancel_at);

    if v_rider_quality = 'none' then
      v_rider_reached := false;
      v_rider_min_dist := null;
    else
      select
        coalesce(min(st_distance(s.location, v_dest)), 999999),
        coalesce(bool_or(st_dwithin(s.location, v_dest, v_dest_radius)), false)
      into v_rider_min_dist, v_rider_reached
      from trip_location_samples s
      where s.trip_id = v_t.id
        and s.actor_type = 'rider'
        and s.ts <= v_cancel_at;
    end if;

    v_corroborating := private.reconciliation_corroborating_count(v_t, v_dest, v_cancel_at);

    v_score := 0;
    if v_driver_reached and v_route_fraction >= v_min_fraction then
      v_score := v_score + 0.5;
    end if;
    if v_rider_reached then
      v_score := v_score + 0.3;
    end if;
    if v_corroborating >= 1 then
      v_score := v_score + 0.2 * least(v_corroborating, 2)::numeric / 2;
    end if;
    if v_rider_quality = 'none' and v_corroborating = 0 then
      v_score := least(v_score, 0.5);
    end if;

    if v_score >= 0.5 then
      v_evidence := jsonb_build_object(
        'driver_trace', jsonb_build_object(
          'quality', case when array_length(v_driver_locs, 1) >= 3 then 'good' else 'partial' end,
          'reached_dest_m', round(v_driver_min_dist::numeric, 1),
          'route_fraction', round(v_route_fraction, 4),
          'reached_dest', v_driver_reached
        ),
        'rider_trace', jsonb_build_object(
          'quality', v_rider_quality::text,
          'reached_dest_m', round(v_rider_min_dist::numeric, 1),
          'reached_dest', v_rider_reached
        ),
        'corroborating_rider_count', v_corroborating,
        'score_components', jsonb_build_object(
          'driver_dest_route', case when v_driver_reached and v_route_fraction >= v_min_fraction then 0.5 else 0 end,
          'rider_dest', case when v_rider_reached then 0.3 else 0 end,
          'corroboration', case when v_corroborating >= 1 then 0.2 * least(v_corroborating, 2)::numeric / 2 else 0 end
        ),
        'cancelled_at', v_cancel_at,
        'dest_radius_m', v_dest_radius,
        'min_route_fraction', v_min_fraction
      );

      insert into trip_reconciliation_flags (
        trip_id,
        driver_id,
        flag_type,
        score,
        evidence,
        rider_trace_quality,
        corroborating_rider_count
      ) values (
        v_t.id,
        v_t.driver_id,
        'premature_conversion',
        round(v_score, 4),
        v_evidence,
        v_rider_quality,
        v_corroborating::smallint
      )
      on conflict (trip_id, flag_type) do nothing;
    end if;
  end loop;

  -- Undeclared extension — doc 04 §13 / §4.12
  for v_t in
    select t.*
    from trips t
    where t.status = 'completed'
      and t.payment_method = 'cash'
      and t.driver_id is not null
      and coalesce(t.ended_at, t.updated_at) > now() - interval '24 hours'
      and not exists (
        select 1
        from trip_reconciliation_flags f
        where f.trip_id = t.id
          and f.flag_type = 'undeclared_extension'
      )
  loop
    v_dest := private.trip_alight_point(v_t);
    if v_dest is null then
      continue;
    end if;

    v_city_id := (select j.city_id from journeys j where j.id = v_t.journey_id);
    v_extension_gap := cfg_num('reconciliation.extension_gap_m', v_city_id);
    v_cancel_at := coalesce(v_t.ended_at, v_t.updated_at);

    if exists (
      select 1
      from trip_location_samples ds
      join trip_location_samples rs
        on rs.trip_id = ds.trip_id
       and rs.actor_type = 'rider'
       and abs(extract(epoch from (rs.ts - ds.ts))) <= 120
       and st_dwithin(rs.location, ds.location, 80)
      where ds.trip_id = v_t.id
        and ds.actor_type = 'driver'
        and ds.ts >= v_cancel_at - interval '15 minutes'
        and st_distance(ds.location, v_dest) >= v_extension_gap
    ) then
      select max(st_distance(ds.location, v_dest))
      into v_driver_min_dist
      from trip_location_samples ds
      where ds.trip_id = v_t.id
        and ds.actor_type = 'driver'
        and ds.ts >= v_cancel_at - interval '15 minutes';

      insert into trip_reconciliation_flags (
        trip_id,
        driver_id,
        flag_type,
        score,
        evidence,
        rider_trace_quality,
        corroborating_rider_count
      ) values (
        v_t.id,
        v_t.driver_id,
        'undeclared_extension',
        1.0,
        jsonb_build_object(
          'driver_trace', jsonb_build_object('quality', 'good'),
          'rider_trace', jsonb_build_object('quality', 'good', 'co_located', true),
          'corroborating_rider_count', 0,
          'distance_beyond_alighting_m', round(v_driver_min_dist::numeric, 1),
          'extension_gap_m', v_extension_gap,
          'ended_at', v_cancel_at
        ),
        coalesce(private.reconciliation_rider_quality(v_t, v_cancel_at), 'good'::trace_quality),
        0
      )
      on conflict (trip_id, flag_type) do nothing;
    end if;
  end loop;
end;
$$;

revoke all on function reconcile_cancelled_trips() from public;
grant execute on function reconcile_cancelled_trips() to service_role;

-- ---------------------------------------------------------------------------
-- pg_cron — rider_no_show_review nightly (doc 04 §10.5)
-- ---------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'rider_no_show_review' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'rider_no_show_review',
    '15 4 * * *',
    $cron$select rider_no_show_review()$cron$
  );
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule rider_no_show_review manually';
  when others then
    raise notice 'pg_cron rider_no_show_review schedule skipped: %', sqlerrm;
end;
$$;
