-- P7-A-04: trace intelligence candidates + cluster_candidate_parks (doc 04 §14–15, FM26–28).

select config_default('inference.frechet_m', '150');
select config_default('geometry.cluster_m', '20');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  ('inference.frechet_m', '{"type":"number","minimum":50,"maximum":500}', 'Max discrete Fréchet distance (m) for route inference trace clustering', array['global','city']::config_scope[], false),
  ('geometry.cluster_m', '{"type":"number","minimum":5,"maximum":100}', 'Spatial cluster radius (m) for geometry correction candidates', array['global','city']::config_scope[], false),
  ('geometry.min_supporting_traces', '{"type":"number","minimum":3,"maximum":500}', 'Minimum distinct trips supporting a geometry correction candidate', array['global','city']::config_scope[], false),
  ('inference.min_trips', '{"type":"number","minimum":3,"maximum":500}', 'Minimum matched trips for a route inference candidate', array['global','city']::config_scope[], false),
  ('clustering.eps_m', '{"type":"number","minimum":10,"maximum":200}', 'DBSCAN epsilon (m) for candidate park clustering', array['global','city']::config_scope[], false),
  ('clustering.min_points', '{"type":"number","minimum":3,"maximum":500}', 'DBSCAN min points for candidate park clustering', array['global','city']::config_scope[], false),
  ('clustering.min_distinct_drivers', '{"type":"number","minimum":2,"maximum":100}', 'Distinct drivers required for candidate park cluster', array['global','city']::config_scope[], false),
  ('clustering.min_distinct_days', '{"type":"number","minimum":2,"maximum":30}', 'Distinct days required for candidate park cluster', array['global','city']::config_scope[], false),
  ('clustering.window_days', '{"type":"number","minimum":7,"maximum":90}', 'Presence history window (days) for candidate park clustering', array['global','city']::config_scope[], false)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Intelligence candidate tables (doc 02 §12)
-- ---------------------------------------------------------------------------
create table candidate_park_clusters (
  id uuid primary key default gen_random_uuid(),
  job_run_id uuid not null references job_runs(id),
  city_id uuid not null references cities(id),
  centroid geography(Point,4326) not null,
  distinct_driver_count int not null,
  distinct_day_count int not null,
  sample_count int not null,
  first_seen timestamptz not null,
  last_seen timestamptz not null,
  status text not null default 'new' check (status in ('new', 'promoted_to_stage', 'dismissed')),
  route_stage_id uuid references route_stages(id),
  reviewed_by uuid references admin_users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index candidate_park_clusters_city_status on candidate_park_clusters (city_id, status);
create index candidate_park_clusters_centroid_gix on candidate_park_clusters using gist (centroid);

create table road_geometry_corrections (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  geometry geography(LineString,4326) not null,
  supporting_trace_count int not null,
  status text not null default 'candidate' check (status in ('candidate', 'internal_applied', 'reviewed_for_osm', 'submitted_osm', 'rejected')),
  reviewed_by uuid references admin_users(id),
  reviewed_at timestamptz,
  osm_changeset_id text,
  created_at timestamptz not null default now()
);

create index road_geometry_corrections_city_status on road_geometry_corrections (city_id, status);
create index road_geometry_corrections_geom_gix on road_geometry_corrections using gist (geometry);

create table route_inference_candidates (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  mode_code text references mode_config(code),
  geometry geography(LineString,4326) not null,
  origin_cluster geography(Point,4326),
  destination_cluster geography(Point,4326),
  supporting_trip_count int not null,
  status text not null default 'new' check (status in ('new', 'promoted_to_route', 'dismissed')),
  route_id uuid references routes(id),
  reviewed_by uuid references admin_users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index route_inference_candidates_city_status on route_inference_candidates (city_id, status);
create index route_inference_candidates_geom_gix on route_inference_candidates using gist (geometry);

alter table candidate_park_clusters enable row level security;
alter table road_geometry_corrections enable row level security;
alter table route_inference_candidates enable row level security;

create policy candidate_park_clusters_select_admin
  on candidate_park_clusters for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

create policy candidate_park_clusters_no_client_write
  on candidate_park_clusters for all to authenticated
  using (false)
  with check (false);

create policy road_geometry_corrections_select_admin
  on road_geometry_corrections for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

create policy road_geometry_corrections_no_client_write
  on road_geometry_corrections for all to authenticated
  using (false)
  with check (false);

create policy route_inference_candidates_select_admin
  on route_inference_candidates for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

create policy route_inference_candidates_no_client_write
  on route_inference_candidates for all to authenticated
  using (false)
  with check (false);

grant select on candidate_park_clusters to authenticated;
grant select on road_geometry_corrections to authenticated;
grant select on route_inference_candidates to authenticated;

-- ---------------------------------------------------------------------------
-- cluster_candidate_parks — doc 04 §14 (FM26: distinct drivers + days)
-- ---------------------------------------------------------------------------
create or replace function cluster_candidate_parks(p_city_id uuid default null)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_job_id uuid;
  v_city_id uuid;
  v_inserted int := 0;
  v_eps numeric;
  v_min_points int;
  v_min_drivers int;
  v_min_days int;
  v_window_days int;
  v_merge_radius numeric;
  v_cluster record;
begin
  insert into job_runs (job_name, params)
  values ('cluster_candidate_parks', jsonb_build_object('city_id', p_city_id))
  returning id into v_job_id;

  for v_city_id in
    select c.id
    from cities c
    where c.status = 'live'
      and (p_city_id is null or c.id = p_city_id)
  loop
    v_eps := cfg_num('clustering.eps_m', v_city_id);
    v_min_points := cfg_num('clustering.min_points', v_city_id)::int;
    v_min_drivers := cfg_num('clustering.min_distinct_drivers', v_city_id)::int;
    v_min_days := cfg_num('clustering.min_distinct_days', v_city_id)::int;
    v_window_days := cfg_num('clustering.window_days', v_city_id)::int;
    v_merge_radius := cfg_num('graph.stage_merge_radius_m', v_city_id);

    for v_cluster in
      with pts as (
        select
          h.driver_id,
          h.ts,
          h.location,
          d.city_id
        from driver_presence_history h
        join drivers d on d.id = h.driver_id
        where d.city_id = v_city_id
          and h.status in ('at_park', 'roaming_available')
          and coalesce(h.speed_mps, 0) < 0.5
          and h.ts > now() - make_interval(days => v_window_days)
          and not exists (
            select 1
            from parks p
            where p.city_id = v_city_id
              and st_dwithin(h.location, p.location, v_merge_radius)
          )
          and not exists (
            select 1
            from route_stages rs
            join routes r on r.id = rs.route_id
            where r.city_id = v_city_id
              and st_dwithin(h.location, rs.location, v_merge_radius)
          )
      ),
      clustered as (
        select
          p.*,
          st_clusterdbscan(
            st_transform(p.location::geometry, 32631),
            eps := v_eps,
            minpoints := v_min_points
          ) over () as cluster_id
        from pts p
      ),
      agg as (
        select
          cluster_id,
          city_id,
          st_centroid(st_collect(location::geometry))::geography as centroid,
          count(distinct driver_id)::int as distinct_drivers,
          count(distinct date(ts))::int as distinct_days,
          count(*)::int as sample_count,
          min(ts) as first_seen,
          max(ts) as last_seen
        from clustered
        where cluster_id is not null
        group by cluster_id, city_id
      )
      select *
      from agg
      where distinct_drivers >= v_min_drivers
        and distinct_days >= v_min_days
    loop
      if not exists (
        select 1
        from candidate_park_clusters cpc
        where cpc.city_id = v_cluster.city_id
          and cpc.status = 'new'
          and st_dwithin(cpc.centroid, v_cluster.centroid, v_eps)
      ) then
        insert into candidate_park_clusters (
          job_run_id,
          city_id,
          centroid,
          distinct_driver_count,
          distinct_day_count,
          sample_count,
          first_seen,
          last_seen,
          status
        ) values (
          v_job_id,
          v_cluster.city_id,
          v_cluster.centroid,
          v_cluster.distinct_drivers,
          v_cluster.distinct_days,
          v_cluster.sample_count,
          v_cluster.first_seen,
          v_cluster.last_seen,
          'new'
        );
        v_inserted := v_inserted + 1;
      end if;
    end loop;
  end loop;

  update job_runs
  set status = 'succeeded',
      finished_at = now(),
      stats = jsonb_build_object('candidates_inserted', v_inserted)
  where id = v_job_id;

  return jsonb_build_object(
    'candidates_inserted', v_inserted,
    'job_run_id', v_job_id
  );
exception
  when others then
    update job_runs
    set status = 'failed',
        finished_at = now(),
        error = sqlerrm
    where id = v_job_id;
    raise;
end;
$$;

revoke all on function cluster_candidate_parks(uuid) from public;
grant execute on function cluster_candidate_parks(uuid) to service_role;

-- FM27 guard remains: proposals only from matched_traces (jobs worker implements inference).
create or replace function private.propose_from_traces(p_trip_id uuid, p_actor_type actor_type)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_city_id uuid;
  v_matched matched_traces%rowtype;
  v_min_confidence numeric;
begin
  if p_actor_type not in ('rider', 'driver') then
    return '[]'::jsonb;
  end if;

  select j.city_id into v_city_id
  from trips t
  join journeys j on j.id = t.journey_id
  where t.id = p_trip_id;

  if v_city_id is null then
    return '[]'::jsonb;
  end if;

  v_min_confidence := cfg_num('jobs.map_match_min_confidence', v_city_id);

  select * into v_matched
  from matched_traces mt
  where mt.trip_id = p_trip_id
    and mt.actor_type = p_actor_type;

  if not found or v_matched.confidence < v_min_confidence then
    return '[]'::jsonb;
  end if;

  -- Route/geometry inference runs in backend/jobs (route-inference, geometry-corrections).
  return '[]'::jsonb;
end;
$$;

-- pg_cron — daily 03:30 (doc 03 §12)
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'cluster_candidate_parks' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'cluster_candidate_parks',
    '30 3 * * *',
    $cron$select cluster_candidate_parks()$cron$
  );
exception
  when undefined_table or undefined_object then
    raise notice 'pg_cron unavailable — schedule cluster_candidate_parks manually (doc 03 §12)';
  when others then
    raise notice 'pg_cron cluster_candidate_parks schedule skipped: %', sqlerrm;
end;
$$;
