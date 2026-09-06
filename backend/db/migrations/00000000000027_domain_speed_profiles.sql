-- P2-A-05: segment_speed_profiles table + planner speed-calibration config (doc 02 §12, doc 04 §4.4 / §15)

select config_default('planner.baseline_speed_mps', '8.33');       -- ~30 km/h reference for seeded in_vehicle estimates
select config_default('planner.speed_profile_min_samples', '8');   -- doc 04 §15 minimum trace samples per bucket

create table segment_speed_profiles (
  segment_key text not null,                      -- '{osm_way_id}:{direction}'
  city_id uuid not null references cities(id),
  dow_bucket smallint not null check (dow_bucket in (0, 1)),   -- 0 weekday, 1 weekend
  hour_bucket smallint not null check (hour_bucket between 0 and 23),
  median_speed_mps numeric(5, 2) not null,
  p85_speed_mps numeric(5, 2),
  sample_count int not null check (sample_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (segment_key, dow_bucket, hour_bucket)
);

create index segment_speed_profiles_city on segment_speed_profiles(city_id);

alter table segment_speed_profiles enable row level security;

create policy segment_speed_profiles_select_admin
  on segment_speed_profiles for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

create policy segment_speed_profiles_no_client_write
  on segment_speed_profiles for all to authenticated
  using (false)
  with check (false);

grant select on segment_speed_profiles to authenticated;

-- Optional segment keys on route legs — populated by P7 speed-profiles job; empty until then.
alter table route_legs add column if not exists segment_keys text[] not null default '{}';

-- Lookup profiles for planner calibration (service role / security definer).
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

create or replace function _route_leg_segment_keys(
  p_route_id uuid,
  p_from_stage_id uuid,
  p_to_stage_id uuid
)
returns text[]
language sql
stable
as $$
  with bounds as (
    select
      (select sequence from route_stages where id = p_from_stage_id and route_id = p_route_id) as from_seq,
      (select sequence from route_stages where id = p_to_stage_id and route_id = p_route_id) as to_seq
  )
  select coalesce(
    array_agg(distinct sk order by sk) filter (where sk is not null),
    '{}'::text[]
  )
  from (
    select unnest(rl.segment_keys) as sk
    from route_legs rl
    join route_stages rs_from on rs_from.id = rl.from_stage_id
    join route_stages rs_to on rs_to.id = rl.to_stage_id
    cross join bounds b
    where rl.route_id = p_route_id
      and b.from_seq is not null
      and b.to_seq is not null
      and b.from_seq < b.to_seq
      and rs_from.sequence >= b.from_seq
      and rs_to.sequence <= b.to_seq
  ) keys
$$;

create or replace function route_leg_segment_keys(
  p_route_id uuid,
  p_from_stage_id uuid,
  p_to_stage_id uuid
)
returns text[]
language sql
stable
security definer
set search_path = public
as $$
  select _route_leg_segment_keys(p_route_id, p_from_stage_id, p_to_stage_id)
$$;

grant execute on function route_leg_segment_keys(uuid, uuid, uuid) to authenticated, service_role;
