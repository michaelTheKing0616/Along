-- Live ETA. One payload for pickup, the trip, and each remaining stop.
-- Segment blend, dwell, and smoothing match backend/functions/_shared/eta/estimate.ts.
-- Recomputed from a driver location sample, throttled to about 15 seconds.

create table if not exists live_segment_observations (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  segment_key text not null,
  speed_mps numeric(6, 2) not null check (speed_mps > 0),
  observed_at timestamptz not null,
  trip_id uuid references trips(id),
  created_at timestamptz not null default now()
);

create index if not exists live_segment_observations_key_at
  on live_segment_observations (segment_key, observed_at desc);

create table if not exists stage_dwell_samples (
  id uuid primary key default gen_random_uuid(),
  stage_id uuid not null references route_stages(id),
  city_id uuid not null references cities(id),
  trip_id uuid references trips(id),
  hour_bucket smallint not null check (hour_bucket between 0 and 23),
  dwell_s int not null check (dwell_s >= 0),
  observed_at timestamptz not null default now()
);

create index if not exists stage_dwell_samples_stage_hour
  on stage_dwell_samples (stage_id, hour_bucket);

alter table live_segment_observations enable row level security;
alter table stage_dwell_samples enable row level security;

drop policy if exists live_segment_observations_select_admin on live_segment_observations;
create policy live_segment_observations_select_admin
  on live_segment_observations for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

drop policy if exists live_segment_observations_no_client_write on live_segment_observations;
create policy live_segment_observations_no_client_write
  on live_segment_observations for all to authenticated
  using (false)
  with check (false);

drop policy if exists stage_dwell_samples_select_admin on stage_dwell_samples;
create policy stage_dwell_samples_select_admin
  on stage_dwell_samples for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

drop policy if exists stage_dwell_samples_no_client_write on stage_dwell_samples;
create policy stage_dwell_samples_no_client_write
  on stage_dwell_samples for all to authenticated
  using (false)
  with check (false);

grant select on live_segment_observations to authenticated;
grant select on stage_dwell_samples to authenticated;

create or replace function _eta_minute(p_seconds numeric)
returns int
language sql
immutable
as $$
  select greatest(0, round(coalesce(p_seconds, 0) / 60.0)::int);
$$;

create or replace function _eta_scaled(p_planned numeric, p_baseline numeric, p_speed numeric)
returns int
language sql
immutable
as $$
  select case
    when coalesce(p_planned, 0) <= 0
      or coalesce(p_baseline, 0) <= 0
      or coalesce(p_speed, 0) <= 0
      then greatest(1, round(coalesce(p_planned, 1))::int)
    else greatest(1, round(p_planned * (p_baseline / p_speed))::int)
  end;
$$;

create or replace function _eta_lagos_clock(p_at timestamptz)
returns text
language sql
stable
as $$
  select extract(hour from p_at at time zone 'Africa/Lagos')::int::text
    || ':'
    || lpad(extract(minute from p_at at time zone 'Africa/Lagos')::int::text, 2, '0');
$$;

create or replace function _eta_format(p_low int, p_high int)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_low_m int := _eta_minute(p_low);
  v_high_m int := _eta_minute(p_high);
begin
  if v_low_m = v_high_m then
    return jsonb_build_object(
      'kind', 'single',
      'low_s', p_low,
      'high_s', p_low,
      'label', v_low_m::text || ' min'
    );
  end if;
  return jsonb_build_object(
    'kind', 'range',
    'low_s', least(p_low, p_high),
    'high_s', greatest(p_low, p_high),
    'label', least(v_low_m, v_high_m)::text || '–' || greatest(v_low_m, v_high_m)::text || ' min'
  );
end;
$$;

-- Live median, hour profile, then the planned duration. Range when they disagree.
create or replace function _eta_blend(
  p_planned numeric,
  p_baseline numeric,
  p_live_median numeric,
  p_live_samples int,
  p_profile_median numeric,
  p_profile_p85 numeric,
  p_profile_samples int,
  p_osrm_degraded boolean
)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_planned int := greatest(1, round(coalesce(p_planned, 1))::int);
  v_live_ok boolean := coalesce(p_live_samples, 0) >= 4 and coalesce(p_live_median, 0) > 0;
  v_profile_ok boolean := coalesce(p_profile_samples, 0) >= 8 and coalesce(p_profile_median, 0) > 0;
  v_p85 numeric := coalesce(p_profile_p85, 0);
  v_source text := 'planned';
  v_chosen int;
  v_low int;
  v_high int;
  v_kind text := 'single';
  v_agree boolean;
  v_edge int;
  v_mid numeric;
  v_pad int;
begin
  v_chosen := v_planned;
  if v_live_ok then
    v_source := 'live';
    v_chosen := _eta_scaled(v_planned, p_baseline, p_live_median);
  elsif v_profile_ok then
    v_source := 'profile';
    v_chosen := _eta_scaled(v_planned, p_baseline, p_profile_median);
  end if;

  v_low := v_chosen;
  v_high := v_chosen;
  v_agree := v_live_ok
    and v_profile_ok
    and coalesce(p_profile_median, 0) > 0
    and abs(p_live_median - p_profile_median) / p_profile_median <= 0.15;

  if not v_agree and v_p85 > 0 and (v_profile_ok or v_live_ok) then
    v_edge := _eta_scaled(v_planned, p_baseline, v_p85);
    v_low := least(v_chosen, v_edge);
    v_high := greatest(v_chosen, v_edge);
    v_kind := case when v_low = v_high then 'single' else 'range' end;
  end if;

  if coalesce(p_osrm_degraded, false) then
    v_mid := (v_low + v_high) / 2.0;
    v_pad := greatest(120, round(v_mid * 0.25)::int);
    v_low := greatest(1, v_low - v_pad);
    v_high := v_high + v_pad;
    v_kind := 'range';
  end if;

  return jsonb_build_object(
    'low_s', v_low,
    'high_s', v_high,
    'kind', v_kind,
    'source', v_source
  );
end;
$$;

create or replace function _eta_smooth(
  p_raw_low int,
  p_raw_high int,
  p_live_speed numeric,
  p_previous jsonb
)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_raw_low int := p_raw_low;
  v_raw_high int := p_raw_high;
  v_spike boolean := false;
  v_prev_live numeric;
  v_prev_raw int;
  v_prev_published_low int;
  v_prev_published_high int;
  v_prev_ema int;
  v_prev_spike boolean;
  v_ema int;
  v_span int;
  v_next_low int;
  v_next_high int;
  v_pending_low int;
  v_pending_high int;
  v_state jsonb;
begin
  if p_previous is not null and p_previous <> 'null'::jsonb then
    v_prev_live := nullif(p_previous->>'live_speed_mps', '')::numeric;
    v_prev_raw := nullif(p_previous->>'raw_s', '')::int;
    v_prev_published_low := nullif(p_previous->>'published_low_s', '')::int;
    v_prev_published_high := nullif(p_previous->>'published_high_s', '')::int;
    v_prev_ema := nullif(p_previous->>'ema_s', '')::int;
    v_prev_spike := coalesce((p_previous->>'spike_rejected')::boolean, false);
    if p_live_speed is not null and v_prev_live is not null and v_prev_raw is not null then
      if p_live_speed > v_prev_live * 2
        and v_raw_low < v_prev_raw * 0.75
        and not v_prev_spike
      then
        v_raw_low := v_prev_raw;
        v_raw_high := greatest(v_raw_low, coalesce(v_prev_published_high, v_raw_low));
        v_spike := true;
      end if;
    end if;
  end if;

  if p_previous is null or p_previous = 'null'::jsonb or v_prev_ema is null then
    v_ema := v_raw_low;
  else
    v_ema := round(0.7 * v_prev_ema + 0.3 * v_raw_low)::int;
  end if;

  if p_previous is not null
    and p_previous <> 'null'::jsonb
    and v_prev_published_low is not null
    and (
      v_raw_low >= v_prev_published_low + 90
      or v_raw_high >= coalesce(v_prev_published_high, v_prev_published_low) + 90
    )
  then
    v_state := jsonb_build_object(
      'ema_s', v_raw_low,
      'raw_s', v_raw_low,
      'published_low_s', v_raw_low,
      'published_high_s', greatest(v_raw_low, v_raw_high),
      'pending_low_s', null,
      'pending_high_s', null,
      'spike_rejected', false,
      'live_speed_mps', p_live_speed
    );
    return jsonb_build_object(
      'low_s', v_raw_low,
      'high_s', greatest(v_raw_low, v_raw_high),
      'state', v_state
    );
  end if;

  v_next_low := v_ema;
  v_span := greatest(0, v_raw_high - v_raw_low);
  v_next_high := v_next_low + v_span;

  if p_previous is null or p_previous = 'null'::jsonb or v_prev_published_low is null then
    v_state := jsonb_build_object(
      'ema_s', v_next_low,
      'raw_s', v_raw_low,
      'published_low_s', v_next_low,
      'published_high_s', v_next_high,
      'pending_low_s', null,
      'pending_high_s', null,
      'spike_rejected', v_spike,
      'live_speed_mps', p_live_speed
    );
    return jsonb_build_object('low_s', v_next_low, 'high_s', v_next_high, 'state', v_state);
  end if;

  if _eta_minute(v_next_low) = _eta_minute(v_prev_published_low)
    and _eta_minute(v_next_high) = _eta_minute(v_prev_published_high)
  then
    v_state := jsonb_build_object(
      'ema_s', v_next_low,
      'raw_s', v_raw_low,
      'published_low_s', v_prev_published_low,
      'published_high_s', v_prev_published_high,
      'pending_low_s', null,
      'pending_high_s', null,
      'spike_rejected', v_spike,
      'live_speed_mps', p_live_speed
    );
    return jsonb_build_object(
      'low_s', v_prev_published_low,
      'high_s', v_prev_published_high,
      'state', v_state
    );
  end if;

  v_pending_low := nullif(p_previous->>'pending_low_s', '')::int;
  v_pending_high := nullif(p_previous->>'pending_high_s', '')::int;
  if v_pending_low is not null
    and _eta_minute(v_pending_low) = _eta_minute(v_next_low)
    and _eta_minute(coalesce(v_pending_high, v_pending_low)) = _eta_minute(v_next_high)
  then
    v_state := jsonb_build_object(
      'ema_s', v_next_low,
      'raw_s', v_raw_low,
      'published_low_s', v_next_low,
      'published_high_s', v_next_high,
      'pending_low_s', null,
      'pending_high_s', null,
      'spike_rejected', v_spike,
      'live_speed_mps', p_live_speed
    );
    return jsonb_build_object('low_s', v_next_low, 'high_s', v_next_high, 'state', v_state);
  end if;

  v_state := jsonb_build_object(
    'ema_s', v_next_low,
    'raw_s', v_raw_low,
    'published_low_s', v_prev_published_low,
    'published_high_s', v_prev_published_high,
    'pending_low_s', v_next_low,
    'pending_high_s', v_next_high,
    'spike_rejected', v_spike,
    'live_speed_mps', p_live_speed
  );
  return jsonb_build_object(
    'low_s', v_prev_published_low,
    'high_s', v_prev_published_high,
    'state', v_state
  );
end;
$$;

create or replace function _eta_live_median(p_keys text[], p_at timestamptz)
returns table (median_mps numeric, samples int)
language sql
stable
as $$
  select
    percentile_cont(0.5) within group (order by o.speed_mps)::numeric,
    count(*)::int
  from live_segment_observations o
  where o.segment_key = any (coalesce(p_keys, '{}'::text[]))
    and o.observed_at >= p_at - interval '10 minutes'
    and o.speed_mps > 0
  having count(*) >= 4;
$$;

-- Observed dwell for this stage and Lagos hour after 8 trips, else the mode default.
create or replace function _eta_dwell_s(p_stage_id uuid, p_hour int, p_default int)
returns int
language sql
stable
as $$
  select coalesce((
    select round(percentile_cont(0.5) within group (order by d.dwell_s))::int
    from stage_dwell_samples d
    where d.stage_id = p_stage_id
      and d.hour_bucket = p_hour
    having count(distinct d.trip_id) >= 8
  ), greatest(0, coalesce(p_default, 0)));
$$;

create or replace function _eta_segment_estimate(
  p_planned numeric,
  p_baseline numeric,
  p_keys text[],
  p_city uuid,
  p_hour int,
  p_dow int,
  p_at timestamptz,
  p_degraded boolean
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_live_median numeric;
  v_live_samples int;
  v_profile_median numeric;
  v_profile_p85 numeric;
  v_profile_samples int;
  v_blend jsonb;
begin
  select m.median_mps, m.samples
  into v_live_median, v_live_samples
  from _eta_live_median(p_keys, p_at) m;

  select
    percentile_cont(0.5) within group (order by sp.median_speed_mps),
    percentile_cont(0.5) within group (order by sp.p85_speed_mps),
    min(sp.sample_count)::int
  into v_profile_median, v_profile_p85, v_profile_samples
  from segment_speed_profiles sp
  where sp.city_id = p_city
    and sp.segment_key = any (coalesce(p_keys, '{}'::text[]))
    and sp.dow_bucket = p_dow
    and sp.hour_bucket = p_hour
    and sp.sample_count >= 8
    and sp.median_speed_mps > 0;

  v_blend := _eta_blend(
    p_planned,
    p_baseline,
    v_live_median,
    coalesce(v_live_samples, 0),
    v_profile_median,
    v_profile_p85,
    coalesce(v_profile_samples, 0),
    p_degraded
  );
  return v_blend || jsonb_build_object(
    'live_median', v_live_median,
    'live_samples', coalesce(v_live_samples, 0)
  );
end;
$$;

create or replace function _eta_record_speeds(p_trip_id uuid, p_points jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_city uuid;
  v_key text;
  v_point jsonb;
  v_speed numeric;
  v_at timestamptz;
  v_use text;
  v_next uuid;
  v_prev uuid;
  v_leg_id uuid;
  v_keys text[];
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null or v_t.status not in ('accepted', 'boarded', 'in_transit') then
    return;
  end if;

  select j.city_id into v_city from journeys j where j.id = v_t.journey_id;
  if v_city is null then
    return;
  end if;

  v_key := 'trip:' || p_trip_id::text;
  if v_t.status = 'accepted' then
    v_key := 'pickup:' || p_trip_id::text;
  elsif v_t.route_id is not null and v_t.boarding_stage_id is not null then
    select rs.id into v_next
    from route_stages rs
    where rs.route_id = v_t.route_id
      and rs.sequence >= coalesce((select sequence from route_stages where id = v_t.boarding_stage_id), 0)
      and (
        v_t.alighting_stage_id is null
        or rs.sequence <= coalesce((select sequence from route_stages where id = v_t.alighting_stage_id), rs.sequence)
      )
      and coalesce(v_t.meta->'eta_progress'->rs.id::text->>'departed_at', '') = ''
    order by rs.sequence
    limit 1;

    if v_next is not null and v_next is distinct from v_t.boarding_stage_id then
      select prev.id into v_prev
      from route_stages prev
      where prev.route_id = v_t.route_id
        and prev.sequence < (select sequence from route_stages where id = v_next)
      order by prev.sequence desc
      limit 1;

      select rl.id, rl.segment_keys
      into v_leg_id, v_keys
      from route_legs rl
      where rl.route_id = v_t.route_id
        and rl.from_stage_id = v_prev
        and rl.to_stage_id = v_next
        and rl.mode_code = v_t.mode_code
      limit 1;

      if v_leg_id is not null then
        v_key := coalesce(v_keys[1], 'leg:' || v_leg_id::text);
      end if;
    elsif v_next is not null then
      v_key := 'pickup:' || p_trip_id::text;
    end if;
  end if;

  for v_point in select value from jsonb_array_elements(coalesce(p_points, '[]'::jsonb)) loop
    v_speed := nullif(v_point->>'speed_mps', '')::numeric;
    v_at := coalesce(nullif(v_point->>'ts', '')::timestamptz, now());
    v_use := coalesce(nullif(v_point->>'segment_key', ''), v_key);
    if v_speed is not null and v_speed > 0 and v_use is not null then
      insert into live_segment_observations (city_id, segment_key, speed_mps, observed_at, trip_id)
      values (v_city, v_use, v_speed, v_at, p_trip_id);
      delete from live_segment_observations
      where segment_key = v_use
        and observed_at < v_at - interval '15 minutes';
    end if;
  end loop;
end;
$$;

create or replace function refresh_trip_eta(p_trip_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions, private
as $$
declare
  v_t trips%rowtype;
  v_city uuid;
  v_baseline numeric;
  v_dwell_default int := 120;
  v_hour int;
  v_dow int;
  v_now timestamptz := now();
  v_last timestamptz;
  v_driver geography;
  v_progress jsonb;
  v_prev_state jsonb;
  v_from_seq int;
  v_to_seq int;
  v_stages jsonb := '[]'::jsonb;
  v_stage record;
  v_total int := 0;
  v_index int := 0;
  v_row record;
  v_item jsonb;
  v_stage_id uuid;
  v_stage_key text;
  v_name text;
  v_loc geography;
  v_prev_id uuid;
  v_prev_loc geography;
  v_entry jsonb;
  v_dist float;
  v_arrived text;
  v_departed text;
  v_later boolean;
  v_passed boolean;
  v_current boolean;
  v_upcoming boolean;
  v_last_stop boolean;
  v_cursor int := 0;
  v_raw_low int := 0;
  v_raw_high int := 0;
  v_has_ride boolean := false;
  v_has_pickup boolean := false;
  v_known boolean := false;
  v_live_speed numeric;
  v_pickup_low int;
  v_pickup_high int;
  v_est jsonb;
  v_low int;
  v_high int;
  v_dwell int;
  v_label text;
  v_state_name text;
  v_stops jsonb := '[]'::jsonb;
  v_leg_id uuid;
  v_leg_seconds int;
  v_leg_distance int;
  v_leg_keys text[];
  v_planned numeric;
  v_degraded boolean;
  v_keys text[];
  v_leg_m float;
  v_fraction numeric;
  v_first_upcoming boolean := true;
  v_smooth jsonb;
  v_trip jsonb;
  v_pickup jsonb;
  v_state jsonb;
  v_payload jsonb;
  v_status text;
begin
  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    return null;
  end if;
  if v_t.status not in ('accepted', 'boarded', 'in_transit') then
    return v_t.meta->'eta';
  end if;

  v_last := nullif(v_t.meta->>'eta_refreshed_at', '')::timestamptz;
  if v_last is not null
    and v_now < v_last + interval '15 seconds'
    and v_t.meta ? 'eta'
  then
    return v_t.meta->'eta';
  end if;

  select j.city_id into v_city from journeys j where j.id = v_t.journey_id;
  v_baseline := greatest(coalesce(cfg_num('planner.baseline_speed_mps', v_city), 8.33), 0.1);
  select coalesce(mc.default_dwell_s, 120) into v_dwell_default
  from mode_config mc
  where mc.code = v_t.mode_code;
  v_dwell_default := coalesce(v_dwell_default, 120);
  v_hour := extract(hour from v_now at time zone 'Africa/Lagos')::int;
  v_dow := case
    when extract(dow from v_now at time zone 'Africa/Lagos') in (0, 6) then 1
    else 0
  end;

  select s.location into v_driver
  from trip_location_samples s
  where s.trip_id = p_trip_id
    and s.actor_type = 'driver'
  order by s.ts desc
  limit 1;
  if v_driver is null and v_t.driver_id is not null then
    select dp.current_location into v_driver
    from driver_presence dp
    where dp.driver_id = v_t.driver_id;
  end if;

  v_progress := coalesce(v_t.meta->'eta_progress', '{}'::jsonb);
  v_prev_state := v_t.meta->'eta_state';
  if v_prev_state = 'null'::jsonb then
    v_prev_state := null;
  end if;

  select sequence into v_from_seq from route_stages where id = v_t.boarding_stage_id;
  select sequence into v_to_seq from route_stages where id = v_t.alighting_stage_id;

  if v_t.route_id is not null and v_from_seq is not null and v_to_seq is not null and v_from_seq <= v_to_seq then
    for v_stage in
      select rs.id, rs.name, rs.location
      from route_stages rs
      where rs.route_id = v_t.route_id
        and rs.sequence between v_from_seq and v_to_seq
      order by rs.sequence
    loop
      v_entry := coalesce(v_progress->v_stage.id::text, '{}'::jsonb);
      if v_driver is not null and v_stage.location is not null then
        v_dist := st_distance(v_driver, v_stage.location);
        if nullif(v_entry->>'arrived_at', '') is null and v_dist <= 50 then
          v_entry := jsonb_build_object('arrived_at', v_now);
        elsif nullif(v_entry->>'arrived_at', '') is not null
          and nullif(v_entry->>'departed_at', '') is null
          and v_dist >= 80
        then
          insert into stage_dwell_samples (stage_id, city_id, trip_id, hour_bucket, dwell_s, observed_at)
          values (
            v_stage.id,
            v_city,
            p_trip_id,
            v_hour,
            greatest(0, extract(epoch from (v_now - (v_entry->>'arrived_at')::timestamptz))::int),
            v_now
          );
          v_entry := v_entry || jsonb_build_object('departed_at', v_now);
        end if;
      end if;
      v_progress := jsonb_set(v_progress, array[v_stage.id::text], v_entry, true);
      v_stages := v_stages || jsonb_build_array(jsonb_build_object(
        'id', v_stage.id,
        'name', v_stage.name,
        'lat', st_y(v_stage.location::geometry),
        'lng', st_x(v_stage.location::geometry)
      ));
    end loop;
  end if;

  if jsonb_array_length(v_stages) = 0 then
    if v_t.boarding_location is not null or v_t.boarding_stage_id is not null then
      v_stages := v_stages || jsonb_build_array(jsonb_build_object(
        'key', 'board',
        'name', coalesce((select name from route_stages where id = v_t.boarding_stage_id), 'Pickup'),
        'lat', st_y(coalesce(v_t.boarding_location, (select location from route_stages where id = v_t.boarding_stage_id))::geometry),
        'lng', st_x(coalesce(v_t.boarding_location, (select location from route_stages where id = v_t.boarding_stage_id))::geometry)
      ));
    end if;
    if v_t.alighting_location is not null or v_t.alighting_stage_id is not null then
      v_stages := v_stages || jsonb_build_array(jsonb_build_object(
        'key', 'alight',
        'name', coalesce((select name from route_stages where id = v_t.alighting_stage_id), 'Drop-off'),
        'lat', st_y(coalesce(v_t.alighting_location, (select location from route_stages where id = v_t.alighting_stage_id))::geometry),
        'lng', st_x(coalesce(v_t.alighting_location, (select location from route_stages where id = v_t.alighting_stage_id))::geometry)
      ));
    end if;
  end if;

  v_total := jsonb_array_length(v_stages);
  for v_row in select value as item from jsonb_array_elements(v_stages) loop
    v_item := v_row.item;
    v_index := v_index + 1;
    v_stage_id := nullif(v_item->>'id', '')::uuid;
    v_stage_key := coalesce(v_stage_id::text, v_item->>'key');
    v_name := coalesce(v_item->>'name', 'Stop');
    v_loc := st_setsrid(st_makepoint((v_item->>'lng')::float, (v_item->>'lat')::float), 4326)::geography;
    v_entry := coalesce(v_progress->v_stage_key, '{}'::jsonb);
    v_arrived := nullif(v_entry->>'arrived_at', '');
    v_departed := nullif(v_entry->>'departed_at', '');
    v_later := exists (
      select 1
      from jsonb_array_elements(v_stages) with ordinality later(value, ord)
      where later.ord > v_index
        and nullif(v_progress->coalesce(nullif(later.value->>'id', ''), later.value->>'key')->>'arrived_at', '') is not null
    );
    v_passed := v_departed is not null or v_later;
    v_current := v_arrived is not null and not v_passed;
    v_upcoming := not v_passed and not v_current;
    v_last_stop := v_index = v_total;
    if v_passed or v_current then
      v_known := true;
    end if;

    v_low := 0;
    v_high := 0;
    v_dwell := 0;
    if v_upcoming then
      v_planned := null;
      v_degraded := false;
      v_keys := array['trip:' || p_trip_id::text];
      v_leg_id := null;
      v_leg_seconds := null;
      v_leg_distance := null;
      v_leg_keys := null;
      if v_stage_id is not null and v_prev_id is not null then
        select rl.id, rl.in_vehicle_time_estimate_s, rl.distance_m, rl.segment_keys
        into v_leg_id, v_leg_seconds, v_leg_distance, v_leg_keys
        from route_legs rl
        where rl.route_id = v_t.route_id
          and rl.from_stage_id = v_prev_id
          and rl.to_stage_id = v_stage_id
          and rl.mode_code = v_t.mode_code
        limit 1;
        if not found then
          v_leg_id := null;
        end if;
      end if;

      if v_leg_id is not null and coalesce(v_leg_seconds, 0) > 0 then
        v_planned := v_leg_seconds;
        v_keys := case
          when v_leg_keys is not null and cardinality(v_leg_keys) > 0 then v_leg_keys
          else array['leg:' || v_leg_id::text]
        end;
        v_leg_m := coalesce(nullif(v_leg_distance, 0), st_distance(v_prev_loc, v_loc));
        v_fraction := 1;
        if v_first_upcoming and v_driver is not null and v_leg_m > 1 then
          v_fraction := least(1, greatest(0, st_distance(v_driver, v_loc) / v_leg_m));
        end if;
        v_planned := greatest(1, round(v_planned * v_fraction));
      elsif v_driver is not null then
        v_planned := greatest(1, round(st_distance(v_driver, v_loc) / v_baseline));
        v_degraded := true;
        if v_leg_id is not null then
          v_keys := array['leg:' || v_leg_id::text];
        else
          v_keys := array['pickup:' || p_trip_id::text];
        end if;
      else
        v_planned := 1;
        v_degraded := true;
      end if;

      v_est := _eta_segment_estimate(
        v_planned, v_baseline, v_keys, v_city, v_hour, v_dow, v_now, v_degraded
      );
      v_low := coalesce((v_est->>'low_s')::int, 1);
      v_high := coalesce((v_est->>'high_s')::int, v_low);
      if v_live_speed is null and coalesce((v_est->>'live_samples')::int, 0) >= 4 then
        v_live_speed := nullif(v_est->>'live_median', '')::numeric;
      end if;
      v_cursor := v_cursor + v_low;
      if not v_last_stop and v_stage_id is not null then
        v_dwell := _eta_dwell_s(v_stage_id, v_hour, v_dwell_default);
      elsif not v_last_stop then
        v_dwell := v_dwell_default;
      end if;
      v_raw_low := v_raw_low + v_low + v_dwell;
      v_raw_high := v_raw_high + v_high + v_dwell;
      v_has_ride := true;
      v_first_upcoming := false;
      if v_t.status = 'accepted' and (v_stage_id = v_t.boarding_stage_id or v_stage_key = 'board') and not v_has_pickup then
        v_pickup_low := v_low;
        v_pickup_high := v_high;
        v_has_pickup := true;
      end if;
    end if;

    if v_passed then
      v_state_name := 'passed';
      v_label := case
        when v_arrived is not null then _eta_lagos_clock(v_arrived::timestamptz)
        else 'Passed'
      end;
    elsif v_current then
      v_state_name := 'current';
      v_label := 'Now';
    else
      v_state_name := 'upcoming';
      v_label := _eta_lagos_clock(v_now + make_interval(secs => v_cursor));
      if not v_last_stop then
        v_cursor := v_cursor + v_dwell;
      end if;
    end if;

    v_stops := v_stops || jsonb_build_array(jsonb_build_object(
      'id', coalesce(v_stage_id::text, v_stage_key),
      'name', v_name,
      'state', v_state_name,
      'label', v_label
    ));
    v_prev_id := v_stage_id;
    v_prev_loc := v_loc;
  end loop;

  if not v_has_ride and not v_has_pickup and not v_known then
    v_status := 'calculating';
    v_trip := null;
    v_pickup := null;
    v_state := v_prev_state;
    if v_total = 0 then
      v_stops := '[]'::jsonb;
    end if;
  else
    v_status := 'ready';
    if v_has_ride then
      v_smooth := _eta_smooth(v_raw_low, v_raw_high, v_live_speed, v_prev_state);
      v_trip := _eta_format((v_smooth->>'low_s')::int, (v_smooth->>'high_s')::int);
      v_state := v_smooth->'state';
    else
      v_trip := null;
      v_state := v_prev_state;
    end if;
    if v_has_pickup then
      v_pickup := _eta_format(v_pickup_low, v_pickup_high);
    else
      v_pickup := null;
    end if;
  end if;

  v_payload := jsonb_build_object(
    'status', v_status,
    'pickup', v_pickup,
    'trip', v_trip,
    'stops', v_stops,
    'updated_at', v_now
  );

  update trips
  set meta = coalesce(meta, '{}'::jsonb) || jsonb_build_object(
    'eta', v_payload,
    'eta_state', v_state,
    'eta_progress', v_progress,
    'eta_refreshed_at', v_now
  )
  where id = p_trip_id;

  return v_payload;
end;
$$;

revoke all on function _eta_minute(numeric) from public;
revoke all on function _eta_scaled(numeric, numeric, numeric) from public;
revoke all on function _eta_lagos_clock(timestamptz) from public;
revoke all on function _eta_format(int, int) from public;
revoke all on function _eta_blend(numeric, numeric, numeric, int, numeric, numeric, int, boolean) from public;
revoke all on function _eta_smooth(int, int, numeric, jsonb) from public;
revoke all on function _eta_live_median(text[], timestamptz) from public;
revoke all on function _eta_dwell_s(uuid, int, int) from public;
revoke all on function _eta_segment_estimate(numeric, numeric, text[], uuid, int, int, timestamptz, boolean) from public;
revoke all on function _eta_record_speeds(uuid, jsonb) from public;
revoke all on function refresh_trip_eta(uuid) from public;

grant execute on function refresh_trip_eta(uuid) to authenticated, service_role;
grant execute on function _eta_record_speeds(uuid, jsonb) to service_role;

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
    'wait', v_wait,
    'eta', coalesce(
      v_t.meta->'eta',
      jsonb_build_object(
        'status', 'calculating',
        'pickup', null,
        'trip', null,
        'stops', '[]'::jsonb,
        'updated_at', to_jsonb(now())
      )
    )
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

  if v_actor = 'driver' then
    perform _eta_record_speeds(p_trip_id, p_points);
    perform refresh_trip_eta(p_trip_id);
  end if;

  return jsonb_build_object('boarded_auto', v_boarded_auto);
end;
$$;


-- ---------------------------------------------------------------------------
-- shared_trip_view — anon; minimal disclosure while journey active + token valid
-- ---------------------------------------------------------------------------
create or replace function shared_trip_view(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_share trip_shares%rowtype;
  v_j journeys%rowtype;
  v_t trips%rowtype;
  v_loc geography(Point,4326);
  v_loc_ts timestamptz;
  v_plate text;
  v_color text;
  v_rider_first text;
  v_driver_first text;
  v_dest_label text;
  v_eta_s int := 0;
  v_eta jsonb;
  v_alight geography(Point,4326);
begin
  if p_token is null or btrim(p_token) = '' then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_share
  from trip_shares
  where token_hash = digest(btrim(p_token), 'sha256');

  if v_share.id is null then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  if v_share.revoked_at is not null or v_share.expires_at <= now() then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_j from journeys where id = v_share.journey_id;
  if v_j.id is null or v_j.status not in ('active', 'transfer') then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_t
  from trips t
  where t.journey_id = v_j.id
    and t.status in ('accepted', 'boarded', 'in_transit')
  order by t.journey_sequence desc
  limit 1;

  if v_t.id is null then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  select private.first_name_from_display(p.display_name)
  into v_rider_first
  from profiles p where p.id = v_j.rider_id;

  select private.first_name_from_display(p.display_name)
  into v_driver_first
  from profiles p where p.id = v_t.driver_id;

  select v.plate_number, coalesce(v.color, '')
  into v_plate, v_color
  from vehicles v
  where v.id = v_t.vehicle_id;

  select dp.current_location, dp.last_ping_at
  into v_loc, v_loc_ts
  from driver_presence dp
  where dp.driver_id = v_t.driver_id
    and dp.last_ping_at >= now() - interval '30 seconds';

  if v_loc is null then
    select s.location, s.ts
    into v_loc, v_loc_ts
    from trip_location_samples s
    where s.trip_id = v_t.id
      and s.actor_type = 'driver'
      and s.ts >= now() - interval '30 seconds'
    order by s.ts desc
    limit 1;
  end if;

  if v_loc is null then
    raise exception 'SHARE_INVALID' using errcode = 'P0001';
  end if;

  v_dest_label := coalesce(
    v_j.destination_label,
    (select rs.name from route_stages rs where rs.id = v_t.alighting_stage_id),
    'Destination'
  );

  v_alight := coalesce(
    v_t.alighting_location,
    (select rs.location from route_stages rs where rs.id = v_t.alighting_stage_id)
  );

  v_eta := v_t.meta->'eta';
  if v_eta is null or v_eta->>'status' is distinct from 'ready' then
    v_eta := jsonb_build_object(
      'status', 'calculating',
      'pickup', null,
      'trip', null,
      'stops', '[]'::jsonb,
      'updated_at', to_jsonb(now())
    );
    v_eta_s := 0;
  else
    v_eta_s := coalesce(
      nullif(v_eta #>> '{trip,low_s}', '')::int,
      nullif(v_eta #>> '{pickup,low_s}', '')::int,
      0
    );
  end if;

  return jsonb_build_object(
    'rider_first_name', v_rider_first,
    'status', v_t.status::text,
    'mode', _mode_ref(v_t.mode_code),
    'vehicle', jsonb_build_object('plate', coalesce(v_plate, ''), 'color', v_color),
    'driver_first_name', v_driver_first,
    'current_location', jsonb_build_object(
      'lat', st_y(v_loc::geometry),
      'lng', st_x(v_loc::geometry)
    ),
    'destination_label', v_dest_label,
    'eta_s', v_eta_s,
    'eta', v_eta,
    'legs_progress', private.shared_trip_legs_progress(v_j.id)
  );
end;
$$;

