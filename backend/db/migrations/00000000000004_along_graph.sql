-- P0-A-03: doc 02 §4 — along-graph (data_sources, parks, routes, route_stages,
-- route_legs, route_through_fares, transfer_points, graph_confirmations,
-- graph_revisions, fare_corrections) + adjacency/order triggers + graph_revisions
-- triggers + RLS. drivers.home_park_id FK deferred from P0-A-02.

-- Enums
create type graph_verification as enum ('candidate','crowd_verified','field_verified');
create type source_type as enum (
  'field_agent','driver_declared','rider_correction','driver_correction',
  'presence_cluster','trace_inference','pricing_negotiation','admin','import'
);
create type correction_status as enum ('pending','approved','rejected','auto_merged');

-- Provenance
create table data_sources (
  id uuid primary key default gen_random_uuid(),
  source_type source_type not null,
  actor_profile_id uuid references profiles(id),
  field_submission_id uuid,
  job_run_id uuid,
  trip_id uuid,
  notes text,
  created_at timestamptz not null default now()
);

-- Parks
create table parks (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  name text not null,
  name_aliases text[] not null default '{}',
  location geography(Point,4326) not null,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  source_id uuid not null references data_sources(id),
  verified_by uuid references admin_users(id),
  verified_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index parks_location_gix on parks using gist (location);
create index parks_name_trgm on parks using gin (name gin_trgm_ops);

-- drivers.home_park_id FK (doc 02 §3 — deferred from P0-A-02 until parks exist)
alter table drivers
  add constraint drivers_home_park_fk
  foreign key (home_park_id) references parks(id) deferrable initially deferred;

-- Routes
create table routes (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  corridor_id uuid references corridors(id),
  origin_park_id uuid not null references parks(id),
  destination_park_id uuid not null references parks(id),
  mode_code text not null references mode_config(code),
  is_direct boolean not null default true,
  name text,
  path geography(LineString,4326),
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  source_id uuid not null references data_sources(id),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (origin_park_id <> destination_park_id)
);
create index routes_city_mode on routes(city_id, mode_code) where active;
create index routes_path_gix on routes using gist (path);

create table route_stages (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references routes(id) on delete cascade,
  sequence int not null,
  park_id uuid references parks(id),
  location geography(Point,4326) not null,
  name text,
  is_official_park boolean not null default false,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  independent_confirmation_count int not null default 0,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (route_id, sequence)
);
create index route_stages_location_gix on route_stages using gist (location);

create table route_legs (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references routes(id) on delete cascade,
  from_stage_id uuid not null references route_stages(id),
  to_stage_id uuid not null references route_stages(id),
  mode_code text not null references mode_config(code),
  fare_amount numeric(12,2) not null check (fare_amount >= 0),
  fare_currency char(3) not null,
  fare_last_verified_at timestamptz,
  frequency_estimate_per_hour numeric(6,2),
  operating_hours jsonb,
  avg_wait_time_estimate_s int,
  in_vehicle_time_estimate_s int,
  distance_m int,
  boarding_walk_distance_m int not null default 0,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  independent_confirmation_count int not null default 0,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (route_id, from_stage_id, to_stage_id)
);

create table route_through_fares (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references routes(id) on delete cascade,
  from_stage_id uuid not null references route_stages(id),
  to_stage_id uuid not null references route_stages(id),
  mode_code text not null references mode_config(code),
  fare_amount numeric(12,2) not null check (fare_amount >= 0),
  fare_currency char(3) not null,
  fare_last_verified_at timestamptz,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  independent_confirmation_count int not null default 0,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (route_id, from_stage_id, to_stage_id)
);

create table transfer_points (
  park_id uuid not null references parks(id) on delete cascade,
  route_id uuid not null references routes(id) on delete cascade,
  stage_id uuid not null references route_stages(id),
  walk_distance_m int not null default 0,
  transfer_time_s int not null default 180,
  primary key (park_id, route_id)
);

create table graph_confirmations (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('route_stage','route_leg','route_through_fare','route','park')),
  target_id uuid not null,
  confirmer_profile_id uuid not null references profiles(id),
  confirmer_role text not null check (confirmer_role in ('rider','driver','field_agent','admin')),
  trust_weight numeric(4,3) not null,
  proposed_value jsonb not null,
  trip_id uuid,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  unique (target_type, target_id, confirmer_profile_id)
);
create index graph_confirmations_target on graph_confirmations(target_type, target_id);

create table graph_revisions (
  id bigserial primary key,
  target_type text not null,
  target_id uuid not null,
  before jsonb,
  after jsonb not null,
  changed_by uuid,
  source_id uuid references data_sources(id),
  reason text,
  created_at timestamptz not null default now()
);

create table fare_corrections (
  id uuid primary key default gen_random_uuid(),
  route_leg_id uuid references route_legs(id),
  route_through_fare_id uuid references route_through_fares(id),
  route_id uuid references routes(id),
  from_stage_id uuid references route_stages(id),
  to_stage_id uuid references route_stages(id),
  trip_id uuid,
  submitted_by uuid not null references profiles(id),
  submitter_role text not null check (submitter_role in ('rider','driver','system')),
  proposed_fare numeric(12,2) not null,
  currency char(3) not null,
  fare_shown numeric(12,2),
  status correction_status not null default 'pending',
  reviewed_by uuid references admin_users(id),
  reviewed_at timestamptz,
  review_note text,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  check (
    route_leg_id is not null
    or route_through_fare_id is not null
    or (route_id is not null and from_stage_id is not null and to_stage_id is not null)
  )
);
create index fare_corrections_queue on fare_corrections(status, created_at) where status = 'pending';

-- Adjacency / order validation
create or replace function route_legs_adjacent_check()
returns trigger
language plpgsql
as $$
declare
  from_seq int;
  to_seq int;
begin
  select rs.sequence into from_seq
  from route_stages rs
  where rs.id = new.from_stage_id and rs.route_id = new.route_id;

  select rs.sequence into to_seq
  from route_stages rs
  where rs.id = new.to_stage_id and rs.route_id = new.route_id;

  if from_seq is null or to_seq is null then
    raise exception 'route_legs stages must belong to route_id %', new.route_id
      using errcode = '23514';
  end if;

  if to_seq <> from_seq + 1 then
    raise exception 'route_legs must connect adjacent stages (from.sequence + 1 = to.sequence); got % -> %',
      from_seq, to_seq
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function route_through_fares_order_check()
returns trigger
language plpgsql
as $$
declare
  from_seq int;
  to_seq int;
begin
  select rs.sequence into from_seq
  from route_stages rs
  where rs.id = new.from_stage_id and rs.route_id = new.route_id;

  select rs.sequence into to_seq
  from route_stages rs
  where rs.id = new.to_stage_id and rs.route_id = new.route_id;

  if from_seq is null or to_seq is null then
    raise exception 'route_through_fares stages must belong to route_id %', new.route_id
      using errcode = '23514';
  end if;

  if from_seq >= to_seq then
    raise exception 'route_through_fares from_stage.sequence must be less than to_stage.sequence; got % >= %',
      from_seq, to_seq
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger route_legs_adjacent_check_trg
  before insert or update on route_legs
  for each row execute function route_legs_adjacent_check();

create trigger route_through_fares_order_check_trg
  before insert or update on route_through_fares
  for each row execute function route_through_fares_order_check();

-- graph_revisions writer (append-only audit trail on graph entity changes)
create or replace function write_graph_revision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into graph_revisions (target_type, target_id, before, after, changed_by, source_id)
    values (tg_table_name, new.id, null, to_jsonb(new), auth.uid(), new.source_id);
    return new;
  elsif tg_op = 'UPDATE' then
    insert into graph_revisions (target_type, target_id, before, after, changed_by, source_id)
    values (tg_table_name, new.id, to_jsonb(old), to_jsonb(new), auth.uid(), new.source_id);
    return new;
  end if;
  return null;
end;
$$;

create trigger parks_write_graph_revision
  after insert or update on parks
  for each row execute function write_graph_revision();
create trigger routes_write_graph_revision
  after insert or update on routes
  for each row execute function write_graph_revision();
create trigger route_stages_write_graph_revision
  after insert or update on route_stages
  for each row execute function write_graph_revision();
create trigger route_legs_write_graph_revision
  after insert or update on route_legs
  for each row execute function write_graph_revision();
create trigger route_through_fares_write_graph_revision
  after insert or update on route_through_fares
  for each row execute function write_graph_revision();

create trigger graph_revisions_ro
  before update or delete on graph_revisions
  for each row execute function forbid_mutation();

-- updated_at triggers
create trigger parks_set_updated_at before update on parks
  for each row execute function set_updated_at();
create trigger routes_set_updated_at before update on routes
  for each row execute function set_updated_at();
create trigger route_stages_set_updated_at before update on route_stages
  for each row execute function set_updated_at();
create trigger route_legs_set_updated_at before update on route_legs
  for each row execute function set_updated_at();
create trigger route_through_fares_set_updated_at before update on route_through_fares
  for each row execute function set_updated_at();

-- RLS policies inlined (Supabase CLI does not support \ir).
alter table data_sources enable row level security;
alter table parks enable row level security;
alter table routes enable row level security;
alter table route_stages enable row level security;
alter table route_legs enable row level security;
alter table route_through_fares enable row level security;
alter table transfer_points enable row level security;
alter table graph_confirmations enable row level security;
alter table graph_revisions enable row level security;
alter table fare_corrections enable row level security;

create policy data_sources_select_authenticated
  on data_sources for select to authenticated using (true);
create policy data_sources_write_admin
  on data_sources for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']));

create policy parks_select_authenticated
  on parks for select to authenticated using (true);
create policy parks_write_admin
  on parks for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy routes_select_authenticated
  on routes for select to authenticated using (true);
create policy routes_write_admin
  on routes for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy route_stages_select_authenticated
  on route_stages for select to authenticated using (true);
create policy route_stages_write_admin
  on route_stages for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );

create policy route_legs_select_authenticated
  on route_legs for select to authenticated using (true);
create policy route_legs_write_admin
  on route_legs for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );

create policy route_through_fares_select_authenticated
  on route_through_fares for select to authenticated using (true);
create policy route_through_fares_write_admin
  on route_through_fares for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );

create policy transfer_points_select_authenticated
  on transfer_points for select to authenticated using (true);
create policy transfer_points_write_admin
  on transfer_points for all to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select r.city_id from routes r where r.id = route_id))
  );

create policy graph_confirmations_select_admin
  on graph_confirmations for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'analyst']));

create policy graph_revisions_select_admin
  on graph_revisions for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'analyst']));

create policy fare_corrections_select_own
  on fare_corrections for select to authenticated
  using (submitted_by = auth.uid());
create policy fare_corrections_select_admin
  on fare_corrections for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']));

grant select on data_sources to authenticated;
grant select on parks to authenticated;
grant select on routes to authenticated;
grant select on route_stages to authenticated;
grant select on route_legs to authenticated;
grant select on route_through_fares to authenticated;
grant select on transfer_points to authenticated;
grant select on graph_confirmations to authenticated;
grant select on graph_revisions to authenticated;
grant select on fare_corrections to authenticated;
