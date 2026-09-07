-- P7-A-03: speed-profiles job config + matched_traces aggregation guard (doc 04 §15, FM27).

select config_default('jobs.speed_profile_min_samples', '8');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'jobs.speed_profile_min_samples',
    '{"type":"number","minimum":3,"maximum":500}',
    'Minimum matched-trace observations per segment × dow × hour before upserting segment_speed_profiles',
    array['global','city']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- Ensure segment_speed_profiles exists with RLS (created in 00027; idempotent for fresh branches).
create table if not exists segment_speed_profiles (
  segment_key text not null,
  city_id uuid not null references cities(id),
  dow_bucket smallint not null check (dow_bucket in (0, 1)),
  hour_bucket smallint not null check (hour_bucket between 0 and 23),
  median_speed_mps numeric(5, 2) not null,
  p85_speed_mps numeric(5, 2),
  sample_count int not null check (sample_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (segment_key, dow_bucket, hour_bucket)
);

create index if not exists segment_speed_profiles_city on segment_speed_profiles(city_id);

alter table segment_speed_profiles enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'segment_speed_profiles'
      and policyname = 'segment_speed_profiles_select_admin'
  ) then
    create policy segment_speed_profiles_select_admin
      on segment_speed_profiles for select to authenticated
      using (
        has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
        and admin_can_access_city(city_id)
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'segment_speed_profiles'
      and policyname = 'segment_speed_profiles_no_client_write'
  ) then
    create policy segment_speed_profiles_no_client_write
      on segment_speed_profiles for all to authenticated
      using (false)
      with check (false);
  end if;
end $$;

grant select on segment_speed_profiles to authenticated;

-- Planner lookup uses planner.speed_profile_min_samples; job aggregation uses jobs.speed_profile_min_samples.
create or replace function segment_speed_profiles_lookup(
  p_city_id uuid,
  p_segment_keys text[],
  p_dow_bucket smallint,
  p_hour_bucket smallint
)
returns table (
  segment_key text,
  median_speed_mps numeric,
  sample_count int
)
language sql
stable
security definer
set search_path = public
as $$
  select
    sp.segment_key,
    sp.median_speed_mps,
    sp.sample_count
  from segment_speed_profiles sp
  where sp.city_id = p_city_id
    and sp.dow_bucket = p_dow_bucket
    and sp.hour_bucket = p_hour_bucket
    and sp.segment_key = any (coalesce(p_segment_keys, '{}'::text[]))
    and sp.sample_count >= cfg_num('planner.speed_profile_min_samples', p_city_id)::int
$$;

grant execute on function segment_speed_profiles_lookup(uuid, text[], smallint, smallint) to authenticated, service_role;

-- FM27: speed profile aggregation reads matched_traces only (never trip_location_samples).
create or replace function private.aggregate_speed_profiles_from_matched_traces(p_city_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_trace_count int := 0;
begin
  select count(*) into v_trace_count
  from matched_traces mt
  join trips t on t.id = mt.trip_id
  join journeys j on j.id = t.journey_id
  where (p_city_id is null or j.city_id = p_city_id)
    and mt.confidence >= cfg_num('jobs.map_match_min_confidence', j.city_id)
    and (
      mt.match_meta ? 'segment_observations'
      or coalesce(array_length(mt.osm_way_ids, 1), 0) > 0
    );

  return jsonb_build_object(
    'matched_traces_eligible', v_trace_count,
    'source', 'matched_traces_only'
  );
end;
$$;

revoke all on function private.aggregate_speed_profiles_from_matched_traces(uuid) from public;
grant execute on function private.aggregate_speed_profiles_from_matched_traces(uuid) to service_role;
