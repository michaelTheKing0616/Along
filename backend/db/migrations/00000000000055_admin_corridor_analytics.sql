-- P6-D-01: admin_corridor_analytics — bounded/paginated corridor KPIs (doc 03 §11, A-02/A-15)

select config_default('analytics.page_size', '24');
select config_default('analytics.max_window_days', '31');
select config_default('analytics.bucket_interval_s', '3600');

-- ---------------------------------------------------------------------------
-- Corridor point membership (origin within walk radius of any corridor route stage)
-- ---------------------------------------------------------------------------
create or replace function private.corridor_contains_point(
  p_corridor_id uuid,
  p_point geography,
  p_city_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from routes r
    join route_stages rs on rs.route_id = r.id
    where r.corridor_id = p_corridor_id
      and r.city_id = p_city_id
      and r.active
      and st_dwithin(
        p_point,
        rs.location,
        cfg_num('planner.walk_radius_m', p_city_id)
      )
  )
$$;

revoke all on function private.corridor_contains_point(uuid, geography, uuid) from public;
grant execute on function private.corridor_contains_point(uuid, geography, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_corridor_analytics — analyst+; read-only aggregates (FM13 diagnostic conversion)
-- ---------------------------------------------------------------------------
create or replace function admin_corridor_analytics(
  p_corridor_id uuid,
  p_from timestamptz,
  p_to timestamptz,
  p_cursor text default null,
  p_limit int default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_corridor corridors%rowtype;
  v_limit int;
  v_max_window_days numeric;
  v_bucket_s int;
  v_fare_tol_pct numeric;
  v_cursor_ts timestamptz;
  v_series jsonb := '[]'::jsonb;
  v_gaps jsonb := '[]'::jsonb;
  v_next_cursor text;
  v_summary jsonb;
begin
  if not has_admin_role(array['superadmin', 'ops_lead', 'analyst']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_from is null or p_to is null or p_to <= p_from then
    raise exception using errcode = 'P0001', message = 'invalid time window';
  end if;

  select * into v_corridor from corridors where id = p_corridor_id;
  if v_corridor.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_corridor.city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_limit := least(
    greatest(
      coalesce(p_limit, cfg_num('analytics.page_size', v_corridor.city_id)::int),
      1
    ),
    50
  );

  v_max_window_days := cfg_num('analytics.max_window_days', v_corridor.city_id);
  if p_to - p_from > make_interval(days => v_max_window_days::int) then
    raise exception using errcode = 'P0001', message = 'time window exceeds analytics.max_window_days';
  end if;

  v_bucket_s := cfg_num('analytics.bucket_interval_s', v_corridor.city_id)::int;
  v_fare_tol_pct := cfg_num('promotion.fare_tolerance_pct', v_corridor.city_id);

  if p_cursor is not null and btrim(p_cursor) <> '' then
    begin
      v_cursor_ts := p_cursor::timestamptz;
    exception
      when others then
        raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid cursor';
    end;
  end if;

  with corridor_queries as (
    select pq.*
    from planner_queries pq
    where pq.city_id = v_corridor.city_id
      and pq.created_at >= p_from
      and pq.created_at < p_to
      and private.corridor_contains_point(p_corridor_id, pq.origin, v_corridor.city_id)
  ),
  corridor_trips as (
    select t.*
    from trips t
    join journeys j on j.id = t.journey_id
    where j.city_id = v_corridor.city_id
      and t.requested_at >= p_from
      and t.requested_at < p_to
      and (
        (t.route_id is not null and exists (
          select 1 from routes r where r.id = t.route_id and r.corridor_id = p_corridor_id
        ))
        or (
          t.boarding_location is not null
          and private.corridor_contains_point(p_corridor_id, t.boarding_location, v_corridor.city_id)
        )
      )
  ),
  corridor_gaps as (
    select cgr.*
    from coverage_gap_reports cgr
    where cgr.city_id = v_corridor.city_id
      and cgr.searched_at >= p_from
      and cgr.searched_at < p_to
      and private.corridor_contains_point(p_corridor_id, cgr.searched_location, v_corridor.city_id)
  ),
  summary_row as (
    select
      (select count(*)::int from corridor_queries) as searches,
      (select count(*)::int from corridor_queries where candidate_count > 0) as ambient_views,
      (select count(*)::int from corridor_queries where chosen_candidate_id is not null) as commits,
      (select count(*)::int from corridor_trips) as requests,
      (select count(*)::int from corridor_trips where accepted_at is not null) as accepts,
      (select count(*)::int from corridor_trips where status = 'completed') as completed_trips,
      (
        select percentile_cont(0.5) within group (
          order by extract(epoch from (accepted_at - requested_at))
        )
        from corridor_trips
        where accepted_at is not null
      ) as median_wait_s,
      (
        select count(*)::int
        from corridor_trips ct
        where ct.fare_reported_paid is not null
          and ct.fare_shown > 0
          and abs(ct.fare_reported_paid - ct.fare_shown) / ct.fare_shown * 100.0 > v_fare_tol_pct
      ) as fare_discrepancies,
      (
        select count(*)::int
        from corridor_trips ct
        where ct.fare_reported_paid is not null and ct.fare_shown > 0
      ) as fare_confirmations,
      coalesce((select avg(candidate_count)::numeric from corridor_queries), 0) as avg_candidates,
      coalesce((select avg(direct_count)::numeric from corridor_queries), 0) as avg_direct_candidates,
      (select count(*)::int from corridor_gaps) as coverage_gap_count
  )
  select jsonb_build_object(
    'searches', s.searches,
    'ambient_views', s.ambient_views,
    'commits', s.commits,
    'ambient_to_commit_rate',
      case when s.ambient_views > 0 then round(s.commits::numeric / s.ambient_views, 4) else null end,
    'ambient_to_commit_diagnostic', true,
    'requests', s.requests,
    'accept_rate',
      case when s.requests > 0 then round(s.accepts::numeric / s.requests, 4) else null end,
    'completed_trips', s.completed_trips,
    'fulfilment_rate',
      case when s.accepts > 0 then round(s.completed_trips::numeric / s.accepts, 4) else null end,
    'median_wait_s', round(coalesce(s.median_wait_s, 0)::numeric, 1),
    'fare_discrepancy_rate',
      case when s.fare_confirmations > 0
        then round(s.fare_discrepancies::numeric / s.fare_confirmations, 4)
        else null end,
    'avg_candidates_per_search', round(s.avg_candidates, 2),
    'avg_direct_candidates', round(s.avg_direct_candidates, 2),
    'coverage_gap_count', s.coverage_gap_count
  )
  into v_summary
  from summary_row s;

  with buckets as (
    select
      b.bucket_start,
      b.bucket_start + make_interval(secs => v_bucket_s) as bucket_end
    from generate_series(
      date_trunc('hour', p_from),
      p_to - make_interval(secs => 1),
      make_interval(secs => v_bucket_s)
    ) as b(bucket_start)
    where v_cursor_ts is null or b.bucket_start > v_cursor_ts
    order by b.bucket_start
    limit v_limit
  ),
  bucket_metrics as (
    select
      b.bucket_start,
      b.bucket_end,
      (
        select count(*)::int
        from planner_queries pq
        where pq.city_id = v_corridor.city_id
          and pq.created_at >= b.bucket_start
          and pq.created_at < b.bucket_end
          and private.corridor_contains_point(p_corridor_id, pq.origin, v_corridor.city_id)
      ) as searches,
      (
        select count(*)::int
        from planner_queries pq
        where pq.city_id = v_corridor.city_id
          and pq.created_at >= b.bucket_start
          and pq.created_at < b.bucket_end
          and private.corridor_contains_point(p_corridor_id, pq.origin, v_corridor.city_id)
          and pq.candidate_count > 0
      ) as ambient_views,
      (
        select count(*)::int
        from planner_queries pq
        where pq.city_id = v_corridor.city_id
          and pq.created_at >= b.bucket_start
          and pq.created_at < b.bucket_end
          and private.corridor_contains_point(p_corridor_id, pq.origin, v_corridor.city_id)
          and pq.chosen_candidate_id is not null
      ) as commits,
      (
        select count(*)::int
        from trips t
        join journeys j on j.id = t.journey_id
        where j.city_id = v_corridor.city_id
          and t.requested_at >= b.bucket_start
          and t.requested_at < b.bucket_end
          and (
            (t.route_id is not null and exists (
              select 1 from routes r where r.id = t.route_id and r.corridor_id = p_corridor_id
            ))
            or (
              t.boarding_location is not null
              and private.corridor_contains_point(p_corridor_id, t.boarding_location, v_corridor.city_id)
            )
          )
      ) as requests,
      (
        select count(*)::int
        from trips t
        join journeys j on j.id = t.journey_id
        where j.city_id = v_corridor.city_id
          and t.requested_at >= b.bucket_start
          and t.requested_at < b.bucket_end
          and t.status = 'completed'
          and (
            (t.route_id is not null and exists (
              select 1 from routes r where r.id = t.route_id and r.corridor_id = p_corridor_id
            ))
            or (
              t.boarding_location is not null
              and private.corridor_contains_point(p_corridor_id, t.boarding_location, v_corridor.city_id)
            )
          )
      ) as completed_trips
    from buckets b
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'bucket_start', bm.bucket_start,
        'bucket_end', bm.bucket_end,
        'searches', bm.searches,
        'ambient_views', bm.ambient_views,
        'commits', bm.commits,
        'ambient_to_commit_rate',
          case when bm.ambient_views > 0 then round(bm.commits::numeric / bm.ambient_views, 4) else null end,
        'requests', bm.requests,
        'completed_trips', bm.completed_trips
      )
      order by bm.bucket_start
    ),
    '[]'::jsonb
  )
  into v_series
  from bucket_metrics bm;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', g.id,
        'searched_at', g.searched_at,
        'nearest_stage_id', g.nearest_known_stage_id,
        'nearest_stage_name', rs.name,
        'nearest_stage_distance_m', g.nearest_known_stage_distance_m,
        'ambient_vehicle_count', g.ambient_vehicle_count,
        'location', jsonb_build_object(
          'lat', st_y(g.searched_location::geometry),
          'lng', st_x(g.searched_location::geometry)
        )
      )
      order by g.searched_at desc
    ),
    '[]'::jsonb
  )
  into v_gaps
  from (
    select cgr.*
    from coverage_gap_reports cgr
    where cgr.city_id = v_corridor.city_id
      and cgr.searched_at >= p_from
      and cgr.searched_at < p_to
      and private.corridor_contains_point(p_corridor_id, cgr.searched_location, v_corridor.city_id)
    order by cgr.searched_at desc
    limit v_limit
  ) g
  left join route_stages rs on rs.id = g.nearest_known_stage_id;

  if jsonb_array_length(v_series) = v_limit then
    v_next_cursor := v_series->(v_limit - 1)->>'bucket_start';
  end if;

  return jsonb_build_object(
    'corridor_id', p_corridor_id,
    'corridor_name', v_corridor.name,
    'city_id', v_corridor.city_id,
    'from', p_from,
    'to', p_to,
    'summary', v_summary,
    'series', v_series,
    'coverage_gaps', v_gaps,
    'meta', jsonb_build_object(
      'next_cursor', v_next_cursor,
      'page_size', v_limit,
      'bucket_interval_s', v_bucket_s,
      'diagnostic_only', true
    )
  );
end;
$$;

revoke all on function admin_corridor_analytics(uuid, timestamptz, timestamptz, text, int) from public;
grant execute on function admin_corridor_analytics(uuid, timestamptz, timestamptz, text, int) to authenticated;
