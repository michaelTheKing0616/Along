-- P8-A-02: k-anonymised OD export tables + aggregation (doc 02 §13, 12 §1 T9, FM39/40).

select config_default('export.geohash_precision', '5');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'export.k',
    '{"type":"integer","minimum":2,"maximum":1000}',
    'Minimum trip count per OD export cell (k-anonymity threshold)',
    array['global','city']::config_scope[],
    false
  ),
  (
    'export.geohash_precision',
    '{"type":"integer","minimum":3,"maximum":8}',
    'Geohash precision for anonymised origin/destination export cells',
    array['global','city']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Export batch + aggregate cells (no rider_id, phone, plate, or raw coordinates)
-- ---------------------------------------------------------------------------
create table anonymized_od_exports (
  id uuid primary key default gen_random_uuid(),
  job_run_id uuid not null references job_runs(id),
  city_id uuid not null references cities(id),
  period_start timestamptz not null,
  period_end timestamptz not null,
  k_threshold int not null check (k_threshold >= 2),
  geohash_precision smallint not null check (geohash_precision between 3 and 8),
  trips_examined int not null default 0 check (trips_examined >= 0),
  cells_emitted int not null default 0 check (cells_emitted >= 0),
  cells_suppressed int not null default 0 check (cells_suppressed >= 0),
  created_at timestamptz not null default now()
);

create index anonymized_od_exports_city_created on anonymized_od_exports (city_id, created_at desc);
create index anonymized_od_exports_job_run on anonymized_od_exports (job_run_id);

create table anonymized_od_cells (
  id uuid primary key default gen_random_uuid(),
  export_id uuid not null references anonymized_od_exports(id) on delete cascade,
  city_id uuid not null references cities(id),
  origin_geohash text not null check (char_length(origin_geohash) between 3 and 8),
  destination_geohash text not null check (char_length(destination_geohash) between 3 and 8),
  mode_code text not null references mode_config(code),
  dow_bucket smallint not null check (dow_bucket in (0, 1)),
  hour_bucket smallint not null check (hour_bucket between 0 and 23),
  trip_count int not null check (trip_count >= 1),
  unique (export_id, origin_geohash, destination_geohash, mode_code, dow_bucket, hour_bucket)
);

create index anonymized_od_cells_export on anonymized_od_cells (export_id);
create index anonymized_od_cells_city on anonymized_od_cells (city_id);

alter table anonymized_od_exports enable row level security;
alter table anonymized_od_cells enable row level security;

create policy anonymized_od_exports_select_admin
  on anonymized_od_exports for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

create policy anonymized_od_exports_no_client_write
  on anonymized_od_exports for all to authenticated
  using (false)
  with check (false);

create policy anonymized_od_cells_select_admin
  on anonymized_od_cells for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

create policy anonymized_od_cells_no_client_write
  on anonymized_od_cells for all to authenticated
  using (false)
  with check (false);

grant select on anonymized_od_exports to authenticated;
grant select on anonymized_od_cells to authenticated;

create or replace function private.enforce_anonymized_od_cell_k()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_k int;
begin
  select e.k_threshold into v_k
  from anonymized_od_exports e
  where e.id = new.export_id;

  if v_k is null then
    raise exception using errcode = 'P0001', message = 'ALONG:EXPORT_PARENT_MISSING';
  end if;

  if new.trip_count < v_k then
    raise exception using errcode = 'P0001', message = 'ALONG:EXPORT_K_ANONYMITY_VIOLATION';
  end if;

  return new;
end;
$$;

create trigger anonymized_od_cells_k_anonymity
  before insert or update on anonymized_od_cells
  for each row execute function private.enforce_anonymized_od_cell_k();

-- Aggregate completed trips into geohash OD cells; suppress cells below cfg export.k.
create or replace function private.aggregate_anonymized_od_cells(
  p_city_id uuid,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_k int default null,
  p_geohash_precision smallint default null
)
returns table (
  origin_geohash text,
  destination_geohash text,
  mode_code text,
  dow_bucket smallint,
  hour_bucket smallint,
  trip_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with cfg as (
    select
      coalesce(p_k, cfg_num('export.k', p_city_id)::int) as k,
      coalesce(p_geohash_precision, cfg_num('export.geohash_precision', p_city_id)::smallint) as precision
  ),
  observations as (
    select
      along_geohash(coalesce(t.boarding_location, j.origin), (select precision from cfg)) as origin_geohash,
      along_geohash(coalesce(t.alighting_location, j.destination), (select precision from cfg)) as destination_geohash,
      t.mode_code,
      case
        when extract(isodow from coalesce(t.ended_at, t.started_at, t.requested_at)) in (6, 7)
        then 1
        else 0
      end::smallint as dow_bucket,
      extract(hour from coalesce(t.ended_at, t.started_at, t.requested_at))::smallint as hour_bucket
    from trips t
    join journeys j on j.id = t.journey_id
    where j.city_id = p_city_id
      and t.status = 'completed'
      and coalesce(t.ended_at, t.started_at, t.requested_at) >= p_period_start
      and coalesce(t.ended_at, t.started_at, t.requested_at) < p_period_end
  ),
  grouped as (
    select
      o.origin_geohash,
      o.destination_geohash,
      o.mode_code,
      o.dow_bucket,
      o.hour_bucket,
      count(*)::bigint as trip_count
    from observations o
    group by 1, 2, 3, 4, 5
  )
  select
    g.origin_geohash,
    g.destination_geohash,
    g.mode_code,
    g.dow_bucket,
    g.hour_bucket,
    g.trip_count
  from grouped g
  cross join cfg
  where g.trip_count >= cfg.k
$$;

create or replace function private.count_suppressed_od_cells(
  p_city_id uuid,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_k int default null,
  p_geohash_precision smallint default null
)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  with cfg as (
    select
      coalesce(p_k, cfg_num('export.k', p_city_id)::int) as k,
      coalesce(p_geohash_precision, cfg_num('export.geohash_precision', p_city_id)::smallint) as precision
  ),
  observations as (
    select
      along_geohash(coalesce(t.boarding_location, j.origin), (select precision from cfg)) as origin_geohash,
      along_geohash(coalesce(t.alighting_location, j.destination), (select precision from cfg)) as destination_geohash,
      t.mode_code,
      case
        when extract(isodow from coalesce(t.ended_at, t.started_at, t.requested_at)) in (6, 7)
        then 1
        else 0
      end::smallint as dow_bucket,
      extract(hour from coalesce(t.ended_at, t.started_at, t.requested_at))::smallint as hour_bucket
    from trips t
    join journeys j on j.id = t.journey_id
    where j.city_id = p_city_id
      and t.status = 'completed'
      and coalesce(t.ended_at, t.started_at, t.requested_at) >= p_period_start
      and coalesce(t.ended_at, t.started_at, t.requested_at) < p_period_end
  ),
  grouped as (
    select count(*)::bigint as trip_count
    from observations o
    group by
      o.origin_geohash,
      o.destination_geohash,
      o.mode_code,
      o.dow_bucket,
      o.hour_bucket
  )
  select count(*)::bigint
  from grouped g
  cross join cfg
  where g.trip_count < cfg.k
$$;

revoke all on function private.count_suppressed_od_cells(uuid, timestamptz, timestamptz, int, smallint) from public;
grant execute on function private.count_suppressed_od_cells(uuid, timestamptz, timestamptz, int, smallint) to service_role;

revoke all on function private.aggregate_anonymized_od_cells(uuid, timestamptz, timestamptz, int, smallint) from public;
grant execute on function private.aggregate_anonymized_od_cells(uuid, timestamptz, timestamptz, int, smallint) to service_role;
