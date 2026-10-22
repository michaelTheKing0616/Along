-- P7-A-02: map-match job tables (doc 02 §12, doc 04 §15, FM27).

select config_default('jobs.map_match_min_samples', '10');
select config_default('jobs.map_match_min_confidence', '0.6');
select config_default('jobs.map_match_default_radius_m', '25');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  ('jobs.map_match_min_samples', '{"type":"number","minimum":3,"maximum":500}', 'Minimum trip_location_samples before OSRM Match runs', array['global','city']::config_scope[], false),
  ('jobs.map_match_min_confidence', '{"type":"number","minimum":0,"maximum":1}', 'Minimum OSRM Match confidence to persist matched_traces', array['global','city']::config_scope[], false),
  ('jobs.map_match_default_radius_m', '{"type":"number","minimum":1,"maximum":200}', 'OSRM Match search radius (m) when trip_location_samples.accuracy_m is null', array['global','city']::config_scope[], false)
on conflict (key) do nothing;

create table job_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  status text not null default 'running' check (status in ('running', 'succeeded', 'failed')),
  params jsonb,
  stats jsonb,
  error text
);

create index job_runs_name_started on job_runs (job_name, started_at desc);

alter table data_sources
  add constraint data_sources_job_fk
  foreign key (job_run_id) references job_runs(id);

create table matched_traces (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  actor_type actor_type not null,
  geometry geography(LineString,4326) not null,
  confidence numeric(4,3) not null,
  osm_way_ids bigint[] not null default '{}',
  match_meta jsonb,
  created_at timestamptz not null default now(),
  unique (trip_id, actor_type),
  check (actor_type in ('rider', 'driver'))
);

create index matched_traces_trip on matched_traces (trip_id);

alter table job_runs enable row level security;
alter table matched_traces enable row level security;

create policy job_runs_select_admin
  on job_runs for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'analyst']));

create policy job_runs_no_client_write
  on job_runs for all to authenticated
  using (false)
  with check (false);

create policy matched_traces_select_admin
  on matched_traces for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and exists (
      select 1
      from trips t
      join journeys j on j.id = t.journey_id
      where t.id = matched_traces.trip_id
        and admin_can_access_city(j.city_id)
    )
  );

create policy matched_traces_no_client_write
  on matched_traces for all to authenticated
  using (false)
  with check (false);

grant select on job_runs to authenticated;
grant select on matched_traces to authenticated;

-- FM27 guard: geometry/route proposal writers must use matched_traces, never raw samples.
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

  -- P7-A-03/A-04 implement geometry/route inference from v_matched.geometry here.
  return '[]'::jsonb;
end;
$$;

revoke all on function private.propose_from_traces(uuid, actor_type) from public;
grant execute on function private.propose_from_traces(uuid, actor_type) to service_role;
