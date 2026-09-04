-- P1-A-01: doc 02 §5–8 — driver routes, presence, planner support tables,
-- journeys/trips/negotiations, guard trigger, partitioned samples/history,
-- ensure_partitions() job.

-- ---------------------------------------------------------------------------
-- §5 Driver self-service routes
-- ---------------------------------------------------------------------------
create table driver_route_profiles (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  route_id uuid references routes(id),
  mode_code text not null references mode_config(code),
  name text,
  active boolean not null default true,
  load_surcharge_amount numeric(12,2) check (load_surcharge_amount >= 0),
  load_surcharge_currency char(3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index driver_route_profiles_active on driver_route_profiles(driver_id) where active;

create table driver_route_stops (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references driver_route_profiles(id) on delete cascade,
  sequence int not null,
  route_stage_id uuid references route_stages(id),
  custom_location geography(Point,4326),
  custom_label text,
  price_to_end numeric(12,2) not null check (price_to_end >= 0),
  currency char(3) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (profile_id, sequence),
  check (route_stage_id is not null or custom_location is not null)
);
create index driver_route_stops_loc_gix on driver_route_stops using gist (custom_location);

create or replace view driver_route_stop_location as
select
  s.id,
  s.profile_id,
  s.sequence,
  s.route_stage_id,
  coalesce(rs.location, s.custom_location) as location,
  s.custom_label,
  s.price_to_end,
  s.currency
from driver_route_stops s
left join route_stages rs on rs.id = s.route_stage_id;

create or replace function validate_driver_route_stop_prices()
returns trigger
language plpgsql
as $$
declare
  v_profile_id uuid;
  v_bad int;
begin
  v_profile_id := coalesce(new.profile_id, old.profile_id);

  if exists (
    select 1
    from driver_route_stops s
    where s.profile_id = v_profile_id
      and s.sequence = (
        select max(s2.sequence)
        from driver_route_stops s2
        where s2.profile_id = v_profile_id
      )
      and s.price_to_end <> 0
  ) then
    raise exception 'last driver_route_stop price_to_end must be 0'
      using errcode = '23514';
  end if;

  select count(*) into v_bad
  from driver_route_stops s1
  join driver_route_stops s2
    on s2.profile_id = s1.profile_id
   and s2.sequence = s1.sequence + 1
  where s1.profile_id = v_profile_id
    and s1.price_to_end < s2.price_to_end;

  if v_bad > 0 then
    raise exception 'driver_route_stop price_to_end must be non-increasing with sequence'
      using errcode = '23514';
  end if;

  return coalesce(new, old);
end;
$$;

create constraint trigger driver_route_stops_validate_prices
  after insert or update or delete on driver_route_stops
  deferrable initially deferred
  for each row execute function validate_driver_route_stop_prices();

create trigger driver_route_profiles_set_updated_at before update on driver_route_profiles
  for each row execute function set_updated_at();
create trigger driver_route_stops_set_updated_at before update on driver_route_stops
  for each row execute function set_updated_at();

alter table fare_quotes
  add constraint fare_quotes_driver_route_profile_fk
  foreign key (driver_route_profile_id) references driver_route_profiles(id);

-- ---------------------------------------------------------------------------
-- §6 Presence
-- ---------------------------------------------------------------------------
create type presence_status as enum ('offline','at_park','roaming_available','roaming_full');

create table driver_presence (
  driver_id uuid primary key references drivers(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id),
  session_id uuid not null default gen_random_uuid(),
  status presence_status not null check (status <> 'offline'),
  current_location geography(Point,4326) not null,
  heading smallint check (heading between 0 and 359),
  speed_mps numeric(5,2),
  accuracy_m numeric(6,1),
  park_id uuid references parks(id),
  declared_route_leg_id uuid references route_legs(id),
  declared_route_profile_id uuid references driver_route_profiles(id),
  nearest_stage_id uuid references route_stages(id),
  seats_available smallint not null check (seats_available >= 0),
  last_ping_at timestamptz not null default now(),
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'at_park' or park_id is not null)
);
create index driver_presence_loc_gix on driver_presence using gist (current_location);
create index driver_presence_ping on driver_presence(last_ping_at);

create trigger driver_presence_set_updated_at before update on driver_presence
  for each row execute function set_updated_at();

create table driver_presence_history (
  id bigserial,
  driver_id uuid not null,
  session_id uuid not null,
  ts timestamptz not null,
  location geography(Point,4326) not null,
  heading smallint,
  speed_mps numeric(5,2),
  status presence_status not null,
  downsampled boolean not null default false,
  primary key (ts, id)
) partition by range (ts);

create index driver_presence_history_driver_ts on driver_presence_history (driver_id, ts);
create index driver_presence_history_loc_gix on driver_presence_history using gist (location);

-- ---------------------------------------------------------------------------
-- §7 Planner support (fare_quotes exists from P0-A-04)
-- ---------------------------------------------------------------------------
create table planner_queries (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid references riders(id),
  city_id uuid references cities(id),
  origin geography(Point,4326) not null,
  destination geography(Point,4326) not null,
  filters jsonb not null default '{}'::jsonb,
  candidate_count smallint not null,
  direct_count smallint not null,
  degraded boolean not null default false,
  latency_ms int,
  chosen_candidate_id uuid,
  created_at timestamptz not null default now()
);

create table coverage_gap_reports (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid references riders(id),
  city_id uuid references cities(id),
  searched_location geography(Point,4326) not null,
  searched_destination geography(Point,4326),
  searched_at timestamptz not null default now(),
  nearest_known_stage_id uuid references route_stages(id),
  nearest_known_stage_distance_m int,
  ambient_vehicle_count smallint not null default 0
);
create index coverage_gap_loc_gix on coverage_gap_reports using gist (searched_location);

-- ---------------------------------------------------------------------------
-- §8 Journeys, trips, negotiations, extensions
-- ---------------------------------------------------------------------------
create type journey_status as enum ('planning','active','transfer','completed','abandoned');
create type trip_status as enum (
  'requested','accepted','boarded','in_transit','completed','declined','expired',
  'cancelled_by_rider','cancelled_by_driver','no_show'
);
create type load_size as enum ('small','medium','large');
create type payment_method as enum ('cash','digital');
create type actor_type as enum ('rider','driver','system','admin');
create type negotiation_context as enum ('park','roaming','extension','load_surcharge');
create type negotiation_status as enum ('open','agreed','lapsed','declined');
create type eta_band as enum ('none','single','full');

create table journeys (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id),
  city_id uuid not null references cities(id),
  status journey_status not null default 'planning',
  origin geography(Point,4326) not null,
  destination geography(Point,4326) not null,
  destination_label text,
  plan_snapshot jsonb not null,
  planner_query_id uuid references planner_queries(id),
  itinerary_stop_id uuid,
  load_flagged boolean not null default false,
  load_size load_size,
  load_note text check (char_length(load_note) <= 140),
  women_only boolean not null default false,
  current_trip_sequence smallint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create trigger journeys_set_updated_at before update on journeys
  for each row execute function set_updated_at();

create table trips (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references journeys(id),
  journey_sequence smallint not null default 1,
  rider_id uuid not null references riders(id),
  driver_id uuid references drivers(id),
  vehicle_id uuid references vehicles(id),
  mode_code text not null references mode_config(code),
  route_id uuid references routes(id),
  driver_route_profile_id uuid references driver_route_profiles(id),
  route_leg_ids uuid[] not null default '{}',
  boarding_stage_id uuid references route_stages(id),
  alighting_stage_id uuid references route_stages(id),
  boarding_location geography(Point,4326),
  alighting_location geography(Point,4326),
  fare_quote_id uuid not null references fare_quotes(id),
  fare_shown numeric(12,2) not null,
  fare_currency char(3) not null,
  fare_tier smallint not null check (fare_tier between 0 and 3),
  load_surcharge_amount numeric(12,2) not null default 0,
  commission_rate numeric(5,4) not null,
  commission_amount numeric(12,2),
  fare_reported_paid numeric(12,2),
  payment_method payment_method not null default 'cash',
  status trip_status not null default 'requested',
  requested_at timestamptz not null default now(),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  boarded_at timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  cancelled_at timestamptz,
  boarded_via text check (boarded_via in ('auto_colocation','manual_rider','manual_driver')),
  cancel_reason text,
  decline_reason text,
  id_signal_color text not null,
  id_signal_shape text not null,
  load_flagged boolean not null default false,
  load_size load_size,
  load_note text,
  women_only boolean not null default false,
  dispatch_attempt smallint not null default 1,
  driver_live_path geography(LineString,4326),
  rider_live_path geography(LineString,4326),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (journey_id, journey_sequence)
);
create index trips_driver_status on trips(driver_id, status);
create index trips_rider_created on trips(rider_id, created_at desc);
create index trips_open_requests on trips(expires_at) where status = 'requested';
create index trips_driver_window on trips using gist (
  driver_id,
  tstzrange(coalesce(boarded_at, accepted_at), coalesce(ended_at, cancelled_at))
);

create trigger trips_set_updated_at before update on trips
  for each row execute function set_updated_at();

create table trip_events (
  id bigserial primary key,
  trip_id uuid not null references trips(id),
  from_status trip_status,
  to_status trip_status not null,
  actor_type actor_type not null,
  actor_id uuid,
  reason text,
  meta jsonb,
  created_at timestamptz not null default now()
);
create index trip_events_trip on trip_events(trip_id, created_at);

create trigger trip_events_ro before update or delete on trip_events
  for each row execute function forbid_mutation();

create table trip_location_samples (
  id bigserial,
  trip_id uuid not null,
  actor_type actor_type not null check (actor_type in ('rider','driver')),
  ts timestamptz not null,
  location geography(Point,4326) not null,
  accuracy_m numeric(6,1),
  speed_mps numeric(5,2),
  heading smallint,
  primary key (ts, id)
) partition by range (ts);

create index trip_location_samples_trip_actor_ts on trip_location_samples (trip_id, actor_type, ts);

create table trip_extensions (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  previous_alighting_stage_id uuid references route_stages(id),
  previous_alighting_location geography(Point,4326),
  new_alighting_stage_id uuid references route_stages(id),
  new_alighting_location geography(Point,4326),
  proposed_by actor_type not null check (proposed_by in ('rider','driver')),
  status text not null default 'proposed' check (status in ('proposed','accepted','declined','expired')),
  fare_quote_id uuid references fare_quotes(id),
  fare_delta numeric(12,2) not null,
  currency char(3) not null,
  commission_delta numeric(12,2),
  ledger_entry_id bigint,
  proposed_at timestamptz not null default now(),
  responded_at timestamptz,
  expires_at timestamptz not null
);

create trigger trip_extensions_no_delete before delete on trip_extensions
  for each row execute function forbid_mutation();

create or replace function protect_extension_columns()
returns trigger
language plpgsql
as $$
begin
  if coalesce(current_setting('along.in_extension_update', true), '') = 'on' then
    if new.trip_id is distinct from old.trip_id
       or new.previous_alighting_stage_id is distinct from old.previous_alighting_stage_id
       or new.previous_alighting_location is distinct from old.previous_alighting_location
       or new.new_alighting_stage_id is distinct from old.new_alighting_stage_id
       or new.new_alighting_location is distinct from old.new_alighting_location
       or new.proposed_by is distinct from old.proposed_by
       or new.fare_quote_id is distinct from old.fare_quote_id
       or new.fare_delta is distinct from old.fare_delta
       or new.currency is distinct from old.currency
       or new.proposed_at is distinct from old.proposed_at
       or new.expires_at is distinct from old.expires_at then
      raise exception 'trip_extensions immutable columns cannot change outside RPC'
        using errcode = '42501';
    end if;
    return new;
  end if;

  raise exception 'trip_extensions may only be updated via RPC'
    using errcode = '42501';
end;
$$;

create trigger trip_extensions_protect_columns before update on trip_extensions
  for each row execute function protect_extension_columns();

create table price_negotiations (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id),
  driver_id uuid not null references drivers(id),
  context negotiation_context not null,
  candidate_ref jsonb not null,
  anchor_amount numeric(12,2) not null,
  currency char(3) not null,
  anchor_quote_id uuid references fare_quotes(id),
  status negotiation_status not null default 'open',
  agreed_amount numeric(12,2),
  round_cap smallint not null,
  round_timeout_s smallint not null,
  eta_band eta_band,
  pickup_radius_m int,
  expires_at timestamptz not null,
  resulting_trip_id uuid references trips(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
create index price_negotiations_open on price_negotiations(expires_at) where status = 'open';

create table price_negotiation_rounds (
  id uuid primary key default gen_random_uuid(),
  negotiation_id uuid not null references price_negotiations(id) on delete cascade,
  round_number smallint not null,
  proposed_by actor_type not null check (proposed_by in ('rider','driver','system')),
  amount numeric(12,2) not null,
  proposed_at timestamptz not null default now(),
  responded_at timestamptz,
  response text check (response in ('accept','counter','decline','lapse')),
  unique (negotiation_id, round_number)
);

create trigger pnr_ro before update or delete on price_negotiation_rounds
  for each row execute function forbid_mutation();

alter table fare_quotes
  add constraint fare_quotes_negotiation_fk
  foreign key (negotiation_id) references price_negotiations(id);

alter table data_sources
  add constraint data_sources_trip_fk
  foreign key (trip_id) references trips(id);

alter table graph_confirmations
  add constraint gc_trip_fk
  foreign key (trip_id) references trips(id);

alter table fare_corrections
  add constraint fc_trip_fk
  foreign key (trip_id) references trips(id);

-- Guard: only trip_transition() may change trips.status
create or replace function guard_trip_status_change()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status
     and coalesce(current_setting('along.in_transition', true), '') <> 'on' then
    raise exception 'trips.status may only be changed via trip_transition()'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger trips_guard_status before update of status on trips
  for each row execute function guard_trip_status_change();

-- ---------------------------------------------------------------------------
-- Partition maintenance (doc 02 §6/§8, doc 03 §12 ensure_partitions)
-- ---------------------------------------------------------------------------
create or replace function ensure_partitions()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_month date;
  v_end date;
  v_part text;
  i int;
begin
  for i in 0..2 loop
    v_month := date_trunc('month', current_date + (i || ' months')::interval)::date;
    v_end := (v_month + interval '1 month')::date;

    v_part := 'driver_presence_history_y' || to_char(v_month, 'YYYY') || '_m' || to_char(v_month, 'MM');
    if to_regclass('public.' || v_part) is null then
      execute format(
        'create table %I partition of driver_presence_history for values from (%L) to (%L)',
        v_part, v_month, v_end
      );
    end if;

    v_part := 'trip_location_samples_y' || to_char(v_month, 'YYYY') || '_m' || to_char(v_month, 'MM');
    if to_regclass('public.' || v_part) is null then
      execute format(
        'create table %I partition of trip_location_samples for values from (%L) to (%L)',
        v_part, v_month, v_end
      );
    end if;
  end loop;
end;
$$;

select ensure_partitions();

do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'ensure_partitions' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule(
    'ensure_partitions',
    '0 3 * * *',
    $cron$select ensure_partitions()$cron$
  );
end;
$$;

grant execute on function ensure_partitions() to authenticated;

-- ---------------------------------------------------------------------------
-- RLS (doc 02 §16 matrix)
-- ---------------------------------------------------------------------------
alter table driver_route_profiles enable row level security;
alter table driver_route_stops enable row level security;
alter table driver_presence enable row level security;
alter table driver_presence_history enable row level security;
alter table planner_queries enable row level security;
alter table coverage_gap_reports enable row level security;
alter table journeys enable row level security;
alter table trips enable row level security;
alter table trip_events enable row level security;
alter table trip_location_samples enable row level security;
alter table trip_extensions enable row level security;
alter table price_negotiations enable row level security;
alter table price_negotiation_rounds enable row level security;

create policy driver_route_profiles_select_own
  on driver_route_profiles for select to authenticated
  using (driver_id = auth.uid());
create policy driver_route_profiles_insert_own
  on driver_route_profiles for insert to authenticated
  with check (driver_id = auth.uid());
create policy driver_route_profiles_update_own
  on driver_route_profiles for update to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());
create policy driver_route_profiles_delete_own
  on driver_route_profiles for delete to authenticated
  using (driver_id = auth.uid());
create policy driver_route_profiles_select_admin
  on driver_route_profiles for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select d.city_id from drivers d where d.id = driver_id))
  );

create policy driver_route_stops_select_own
  on driver_route_stops for select to authenticated
  using (
    exists (
      select 1 from driver_route_profiles p
      where p.id = profile_id and p.driver_id = auth.uid()
    )
  );
create policy driver_route_stops_insert_own
  on driver_route_stops for insert to authenticated
  with check (
    exists (
      select 1 from driver_route_profiles p
      where p.id = profile_id and p.driver_id = auth.uid()
    )
  );
create policy driver_route_stops_update_own
  on driver_route_stops for update to authenticated
  using (
    exists (
      select 1 from driver_route_profiles p
      where p.id = profile_id and p.driver_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from driver_route_profiles p
      where p.id = profile_id and p.driver_id = auth.uid()
    )
  );
create policy driver_route_stops_delete_own
  on driver_route_stops for delete to authenticated
  using (
    exists (
      select 1 from driver_route_profiles p
      where p.id = profile_id and p.driver_id = auth.uid()
    )
  );
create policy driver_route_stops_select_admin
  on driver_route_stops for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select d.city_id
      from driver_route_profiles p
      join drivers d on d.id = p.driver_id
      where p.id = profile_id
    ))
  );

create policy driver_presence_select_own
  on driver_presence for select to authenticated
  using (driver_id = auth.uid());
create policy driver_presence_select_admin
  on driver_presence for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((select d.city_id from drivers d where d.id = driver_id))
  );
create policy driver_presence_no_client_write
  on driver_presence for all to authenticated
  using (false)
  with check (false);

create policy driver_presence_history_select_admin
  on driver_presence_history for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'analyst']));

create policy planner_queries_no_client_write
  on planner_queries for all to authenticated
  using (false)
  with check (false);
create policy planner_queries_select_admin
  on planner_queries for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'analyst']));

create policy coverage_gap_reports_no_client_write
  on coverage_gap_reports for all to authenticated
  using (false)
  with check (false);
create policy coverage_gap_reports_select_admin
  on coverage_gap_reports for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'analyst']));

create policy journeys_select_own
  on journeys for select to authenticated
  using (rider_id = auth.uid());
create policy journeys_select_admin
  on journeys for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance', 'analyst'])
    and admin_can_access_city(city_id)
  );
create policy journeys_no_client_write
  on journeys for all to authenticated
  using (false)
  with check (false);

create policy trips_select_rider
  on trips for select to authenticated
  using (rider_id = auth.uid());
create policy trips_select_driver
  on trips for select to authenticated
  using (driver_id = auth.uid());
create policy trips_select_admin
  on trips for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance', 'analyst'])
    and admin_can_access_city((
      select j.city_id from journeys j where j.id = journey_id
    ))
  );
create policy trips_no_client_write
  on trips for all to authenticated
  using (false)
  with check (false);

create policy trip_events_select_party
  on trip_events for select to authenticated
  using (
    exists (
      select 1 from trips t
      where t.id = trip_id
        and (t.rider_id = auth.uid() or t.driver_id = auth.uid())
    )
  );
create policy trip_events_select_admin
  on trip_events for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance'])
    and admin_can_access_city((
      select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = trip_id
    ))
  );
create policy trip_events_no_client_write
  on trip_events for all to authenticated
  using (false)
  with check (false);

create policy trip_location_samples_no_client_select
  on trip_location_samples for select to authenticated
  using (false);
create policy trip_location_samples_select_admin
  on trip_location_samples for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'finance'])
    and admin_can_access_city((
      select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = trip_id
    ))
  );
create policy trip_location_samples_no_client_write
  on trip_location_samples for all to authenticated
  using (false)
  with check (false);

create policy trip_extensions_select_party
  on trip_extensions for select to authenticated
  using (
    exists (
      select 1 from trips t
      where t.id = trip_id
        and (t.rider_id = auth.uid() or t.driver_id = auth.uid())
    )
  );
create policy trip_extensions_select_admin
  on trip_extensions for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance'])
    and admin_can_access_city((
      select j.city_id from trips t join journeys j on j.id = t.journey_id where t.id = trip_id
    ))
  );
create policy trip_extensions_no_client_write
  on trip_extensions for all to authenticated
  using (false)
  with check (false);

create policy price_negotiations_select_party
  on price_negotiations for select to authenticated
  using (rider_id = auth.uid() or driver_id = auth.uid());
create policy price_negotiations_select_admin
  on price_negotiations for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );
create policy price_negotiations_no_client_write
  on price_negotiations for all to authenticated
  using (false)
  with check (false);

create policy price_negotiation_rounds_select_party
  on price_negotiation_rounds for select to authenticated
  using (
    exists (
      select 1 from price_negotiations n
      where n.id = negotiation_id
        and (n.rider_id = auth.uid() or n.driver_id = auth.uid())
    )
  );
create policy price_negotiation_rounds_select_admin
  on price_negotiation_rounds for select to authenticated
  using (
    has_admin_role(array['superadmin', 'safety', 'ops_lead', 'ops_agent', 'finance'])
    and admin_can_access_city((
      select d.city_id
      from price_negotiations n
      join drivers d on d.id = n.driver_id
      where n.id = negotiation_id
    ))
  );
create policy price_negotiation_rounds_no_client_write
  on price_negotiation_rounds for all to authenticated
  using (false)
  with check (false);

grant select on driver_route_profiles to authenticated;
grant select, insert, update, delete on driver_route_profiles to authenticated;
grant select, insert, update, delete on driver_route_stops to authenticated;
grant select on driver_presence to authenticated;
grant select on driver_presence_history to authenticated;
grant select on planner_queries to authenticated;
grant select on coverage_gap_reports to authenticated;
grant select on journeys to authenticated;
grant select on trips to authenticated;
grant select on trip_events to authenticated;
grant select on trip_location_samples to authenticated;
grant select on trip_extensions to authenticated;
grant select on price_negotiations to authenticated;
grant select on price_negotiation_rounds to authenticated;
