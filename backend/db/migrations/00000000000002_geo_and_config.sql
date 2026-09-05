-- P0-A-01: doc 02 §2 — geo & configuration (deployments, countries, cities, corridors,
-- mode_config, app_config, city_for_point, cfg, cfg_num) + RLS policies.

-- §2.1 Deployments, countries, cities, corridors
create table deployments (
  id uuid primary key default gen_random_uuid(),
  tenant_name text not null unique,
  branding_config jsonb not null default '{}'::jsonb,
  region_config jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table countries (
  code char(2) primary key,
  name text not null,
  currency_code char(3) not null,
  currency_minor_units smallint not null default 2 check (currency_minor_units between 0 and 3),
  currency_symbol text not null,
  phone_prefix text not null,
  default_locale text not null default 'en-NG',
  timezone text not null,
  deployment_id uuid not null references deployments(id),
  verification_schema jsonb not null default '[]'::jsonb,
  regulatory_flags jsonb not null default '{}'::jsonb,
  active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create type city_status as enum ('pre_seed','alpha','beta','live','paused');

create table cities (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code),
  name text not null,
  slug text not null unique,
  state_region text,
  centroid geography(Point,4326) not null,
  boundary geography(MultiPolygon,4326),
  timezone text,
  status city_status not null default 'pre_seed',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index cities_boundary_gix on cities using gist (boundary);
create index cities_centroid_gix on cities using gist (centroid);

create table corridors (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  name text not null,
  slug text not null,
  geometry geography(LineString,4326),
  status city_status not null default 'pre_seed',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (city_id, slug)
);

create or replace function city_for_point(p geography) returns uuid language sql stable as $$
  select id from cities
  where status <> 'paused'
    and ((boundary is not null and st_intersects(boundary, p)) or st_dwithin(centroid, p, 60000))
  order by (boundary is not null and st_intersects(boundary, p)) desc, st_distance(centroid, p)
  limit 1 $$;

-- §1 helper that references cities/countries (deferred from 0001).
create or replace function admin_can_access_city(p_city uuid) returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from admin_users a
    left join cities c on c.id = p_city
    left join countries k on k.code = c.country_code
    where a.id = auth.uid() and a.disabled_at is null
      and (a.role = 'superadmin'
           or (a.city_scope is null and a.deployment_id = k.deployment_id)
           or (p_city = any(a.city_scope)))
  ) $$;

alter table admin_users
  add constraint admin_users_deployment_id_fkey
  foreign key (deployment_id) references deployments(id);

-- §2.2 Modes
create table mode_config (
  code text primary key,
  label text not null,
  label_i18n jsonb not null default '{}'::jsonb,
  icon_key text not null,
  color_token text not null,
  comfort_weight numeric(4,2) not null check (comfort_weight between 0 and 10),
  load_capacity text not null check (load_capacity in ('none','small','medium','large')),
  default_seat_capacity smallint not null check (default_seat_capacity between 1 and 60),
  default_dwell_s int not null default 120,
  active boolean not null default true,
  sort_order smallint not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- §2.3 App configuration
create type config_scope as enum ('global','country','city','corridor');

create table app_config (
  key text not null,
  scope_type config_scope not null default 'global',
  scope_id text not null default '*',
  value jsonb not null,
  description text,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  primary key (key, scope_type, scope_id)
);

create or replace function cfg(p_key text, p_city uuid default null, p_corridor uuid default null) returns jsonb
language sql stable security definer set search_path = public as $$
  with s as (
    select value, 0 as pri from app_config where key = p_key and scope_type = 'corridor' and p_corridor is not null and scope_id = p_corridor::text
    union all
    select value, 1 from app_config where key = p_key and scope_type = 'city' and p_city is not null and scope_id = p_city::text
    union all
    select value, 2 from app_config a join cities c on c.id = p_city where a.key = p_key and a.scope_type = 'country' and a.scope_id = c.country_code
    union all
    select value, 3 from app_config where key = p_key and scope_type = 'global'
  ) select value from s order by pri limit 1 $$;

create or replace function cfg_num(p_key text, p_city uuid default null, p_corridor uuid default null) returns numeric
language sql stable as $$ select (cfg(p_key,p_city,p_corridor))::text::numeric $$;

-- Config defaults are owned by migrations, not seeds (ADR-0016).
create or replace function config_default(p_key text, p_value jsonb, p_scope_type config_scope default 'global', p_scope_id text default '*')
returns void language sql as $$
  insert into app_config (key, scope_type, scope_id, value) values (p_key, p_scope_type, p_scope_id, p_value)
  on conflict (key, scope_type, scope_id) do nothing $$;

-- updated_at triggers
create trigger deployments_set_updated_at before update on deployments
  for each row execute function set_updated_at();
create trigger countries_set_updated_at before update on countries
  for each row execute function set_updated_at();
create trigger cities_set_updated_at before update on cities
  for each row execute function set_updated_at();
create trigger corridors_set_updated_at before update on corridors
  for each row execute function set_updated_at();
create trigger mode_config_set_updated_at before update on mode_config
  for each row execute function set_updated_at();
create trigger admin_users_set_updated_at before update on admin_users
  for each row execute function set_updated_at();

-- RLS policies inlined here (Supabase CLI does not support \ir).
alter table deployments enable row level security;
alter table countries enable row level security;
alter table cities enable row level security;
alter table corridors enable row level security;
alter table mode_config enable row level security;
alter table app_config enable row level security;
alter table admin_users enable row level security;

create policy deployments_select_authenticated
  on deployments for select to authenticated using (true);
create policy deployments_write_admin
  on deployments for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));

create policy countries_select_authenticated
  on countries for select to authenticated using (true);
create policy countries_write_admin
  on countries for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));

create policy cities_select_authenticated
  on cities for select to authenticated using (true);
create policy cities_write_admin
  on cities for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(id))
  with check (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(id));

create policy corridors_select_authenticated
  on corridors for select to authenticated using (true);
create policy corridors_write_admin
  on corridors for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead']) and admin_can_access_city(city_id));

create policy mode_config_select_authenticated
  on mode_config for select to authenticated using (true);
create policy mode_config_write_admin
  on mode_config for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));

create policy app_config_select_authenticated
  on app_config for select to authenticated using (true);
create policy app_config_write_admin
  on app_config for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']))
  with check (has_admin_role(array['superadmin', 'ops_lead']));

create policy admin_users_no_client_access
  on admin_users for all to authenticated
  using (false)
  with check (false);
