-- P4-A-06: reconcile_cancelled_trips, undeclared extension, compute_risk_scores (doc 04 §13, 02 §10)
-- FM13: flags NEVER call transition_standing or ledger_post.

-- ---------------------------------------------------------------------------
-- driver_risk_scores (doc 02 §10)
-- ---------------------------------------------------------------------------
create table driver_risk_scores (
  driver_id uuid not null references drivers(id),
  window_start date not null,
  window_end date not null,
  trips_matched int not null,
  cancels_after_match int not null,
  cash_cancels_after_match int not null,
  cancel_after_match_rate numeric(5,4) not null,
  open_flags int not null,
  actioned_flags int not null,
  computed_at timestamptz not null default now(),
  primary key (driver_id, window_start)
);

alter table driver_risk_scores enable row level security;

create policy driver_risk_scores_select_admin
  on driver_risk_scores for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

create policy driver_risk_scores_no_client_write
  on driver_risk_scores for all to authenticated
  using (false)
  with check (false);

grant select on driver_risk_scores to authenticated;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function private.trip_alight_point(p_t trips)
returns geography(Point,4326)
language sql
stable
as $$
  select coalesce(
    p_t.alighting_location,
    (select rs.location from route_stages rs where rs.id = p_t.alighting_stage_id)
  )
$$;

create or replace function private.trip_board_point(p_t trips)
returns geography(Point,4326)
language sql
stable
as $$
  select coalesce(
    p_t.boarding_location,
    (select rs.location from route_stages rs where rs.id = p_t.boarding_stage_id)
  )
$$;

create or replace function private.trip_route_path(p_t trips)
returns geography(LineString,4326)
language sql
stable
as $$
  select coalesce(
    (select r.path from routes r where r.id = p_t.route_id),
    case
      when private.trip_board_point(p_t) is not null
       and private.trip_alight_point(p_t) is not null then
        st_makeline(
          private.trip_board_point(p_t)::geometry,
          private.trip_alight_point(p_t)::geometry
        )::geography
      else null
    end
  )
$$;

create or replace function private.route_trace_fraction(
  p_route geography(LineString,4326),
  p_driver_locs geography(Point,4326)[]
)
returns numeric
language plpgsql
stable
as $$
declare
  v_route_len double precision;
  v_covered double precision;
  v_union geography;
begin
  if p_route is null or p_driver_locs is null or array_length(p_driver_locs, 1) is null then
    return 0;
  end if;

  v_route_len := st_length(p_route);
  if v_route_len <= 0 then
    return 0;
  end if;

  select st_union(st_buffer(loc, 60)::geometry)::geography
  into v_union
  from unnest(p_driver_locs) as loc;

  if v_union is null then
    return 0;
  end if;

  v_covered := st_length(st_intersection(p_route, v_union));
  return least(greatest(v_covered / v_route_len, 0), 1)::numeric;
end;
$$;

create or replace function private.reconciliation_cancel_from_status(p_t trips)
returns trip_status
language sql
stable
as $$
  select coalesce(
    (
      select te.from_status
      from trip_events te
      where te.trip_id = p_t.id
        and te.to_status = p_t.status
      order by te.created_at desc
      limit 1
    ),
    case
      when p_t.status = 'cancelled_by_driver' and p_t.accepted_at is not null then 'accepted'::trip_status
      when p_t.status = 'cancelled_by_rider' and p_t.started_at is not null then 'in_transit'::trip_status
      else null
    end
  )
$$;

create or replace function private.reconciliation_trip_window(p_t trips)
returns tstzrange
language sql
stable
as $$
  select tstzrange(
    coalesce(p_t.boarded_at, p_t.accepted_at, p_t.requested_at),
    coalesce(p_t.cancelled_at, p_t.ended_at, now()),
    '[]'
  )
$$;

create or replace function private.reconciliation_driver_locations(
  p_t trips,
  p_cancel_at timestamptz,
  p_until timestamptz
)
returns geography(Point,4326)[]
language sql
stable
security definer
set search_path = public, private
as $$
  with sample_locs as (
    select s.location
    from trip_location_samples s
    where s.trip_id = p_t.id
      and s.actor_type = 'driver'
      and s.ts <= p_until
  ),
  session_id as (
    select h.session_id
    from driver_presence_history h
    where h.driver_id = p_t.driver_id
      and h.ts <= p_cancel_at
      and h.ts >= coalesce(p_t.accepted_at, p_t.requested_at) - interval '5 minutes'
    order by h.ts desc
    limit 1
  ),
  presence_locs as (
    select h.location
    from driver_presence_history h
    join session_id si on si.session_id = h.session_id
    where h.driver_id = p_t.driver_id
      and h.ts > p_cancel_at
      and h.ts <= p_cancel_at + interval '30 minutes'
  )
  select coalesce(array_agg(distinct loc), '{}'::geography[])
  from (
    select location as loc from sample_locs
    union all
    select location as loc from presence_locs
  ) u
$$;

create or replace function private.reconciliation_rider_quality(
  p_t trips,
  p_cancel_at timestamptz
)
returns trace_quality
language sql
stable
as $$
  with rider_samples as (
    select s.ts
    from trip_location_samples s
    where s.trip_id = p_t.id
      and s.actor_type = 'rider'
      and s.ts <= p_cancel_at
  )
  select case
    when (select count(*) from rider_samples) < 3 then 'none'::trace_quality
    when (select max(ts) from rider_samples) < p_cancel_at - interval '5 minutes' then 'partial'::trace_quality
    else 'good'::trace_quality
  end
$$;

create or replace function private.reconciliation_corroborating_count(
  p_t trips,
  p_dest geography(Point,4326),
  p_cancel_at timestamptz
)
returns int
language sql
stable
security definer
set search_path = public, private
as $$
  select count(*)::int
  from trips peer
  where peer.driver_id = p_t.driver_id
    and peer.id <> p_t.id
    and peer.accepted_at is not null
    and private.reconciliation_trip_window(peer) && private.reconciliation_trip_window(p_t)
    and exists (
      select 1
      from trip_location_samples rs
      where rs.trip_id = peer.id
        and rs.actor_type = 'rider'
        and rs.ts <= coalesce(peer.cancelled_at, peer.ended_at, p_cancel_at)
        and st_dwithin(rs.location, p_dest, 200)
    )
$$;

-- ---------------------------------------------------------------------------
-- reconcile_cancelled_trips — doc 04 §13
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
-- compute_risk_scores — rolling 30-day aggregates for admin review UI only
-- ---------------------------------------------------------------------------
create or replace function compute_risk_scores()
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_window_start date := current_date - 30;
  v_window_end date := current_date;
begin
  insert into driver_risk_scores (
    driver_id,
    window_start,
    window_end,
    trips_matched,
    cancels_after_match,
    cash_cancels_after_match,
    cancel_after_match_rate,
    open_flags,
    actioned_flags,
    computed_at
  )
  select
    d.id,
    v_window_start,
    v_window_end,
    coalesce(tm.cnt, 0),
    coalesce(cm.cnt, 0),
    coalesce(ccm.cnt, 0),
    case
      when coalesce(tm.cnt, 0) = 0 then 0
      else round(coalesce(cm.cnt, 0)::numeric / tm.cnt, 4)
    end,
    coalesce(ofl.cnt, 0),
    coalesce(afl.cnt, 0),
    now()
  from drivers d
  left join lateral (
    select count(*)::int as cnt
    from trips t
    where t.driver_id = d.id
      and t.accepted_at is not null
      and coalesce(t.cancelled_at, t.ended_at, t.requested_at)::date between v_window_start and v_window_end
  ) tm on true
  left join lateral (
    select count(*)::int as cnt
    from trips t
    where t.driver_id = d.id
      and t.status in ('cancelled_by_driver', 'cancelled_by_rider')
      and t.accepted_at is not null
      and coalesce(t.cancelled_at, t.updated_at)::date between v_window_start and v_window_end
  ) cm on true
  left join lateral (
    select count(*)::int as cnt
    from trips t
    where t.driver_id = d.id
      and t.status in ('cancelled_by_driver', 'cancelled_by_rider')
      and t.payment_method = 'cash'
      and t.accepted_at is not null
      and coalesce(t.cancelled_at, t.updated_at)::date between v_window_start and v_window_end
  ) ccm on true
  left join lateral (
    select count(*)::int as cnt
    from trip_reconciliation_flags f
    where f.driver_id = d.id
      and f.status = 'open'
  ) ofl on true
  left join lateral (
    select count(*)::int as cnt
    from trip_reconciliation_flags f
    where f.driver_id = d.id
      and f.status = 'actioned'
  ) afl on true
  where coalesce(tm.cnt, 0) > 0
     or coalesce(ofl.cnt, 0) > 0
     or coalesce(afl.cnt, 0) > 0
  on conflict (driver_id, window_start) do update set
    window_end = excluded.window_end,
    trips_matched = excluded.trips_matched,
    cancels_after_match = excluded.cancels_after_match,
    cash_cancels_after_match = excluded.cash_cancels_after_match,
    cancel_after_match_rate = excluded.cancel_after_match_rate,
    open_flags = excluded.open_flags,
    actioned_flags = excluded.actioned_flags,
    computed_at = excluded.computed_at;
end;
$$;

revoke all on function compute_risk_scores() from public;
grant execute on function compute_risk_scores() to service_role;

-- ---------------------------------------------------------------------------
-- pg_cron — doc 03 §12
-- ---------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'reconcile_cancelled_trips' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'reconcile_cancelled_trips',
    '*/15 * * * *',
    $cron$select reconcile_cancelled_trips()$cron$
  );

  for v_jobid in select jobid from cron.job where jobname = 'compute_risk_scores' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'compute_risk_scores',
    '0 3 * * *',
    $cron$select compute_risk_scores()$cron$
  );
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule reconcile_cancelled_trips/compute_risk_scores manually (doc 03 §12)';
  when others then
    raise notice 'pg_cron schedule skipped: %', sqlerrm;
end;
$$;
