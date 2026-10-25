-- P0-A-02: doc 02 §3 — identity (profiles, riders, drivers, vehicles, admin_users,
-- driver_verifications, private.identity_hashes, device_tokens) + triggers + RLS.

-- Enums
create type verified_status as enum ('unverified','pending','verified','rejected','suspended');
create type driver_standing as enum ('good_standing','warned','matching_paused','deactivated','guarantor_referred');
create type admin_role as enum (
  'superadmin','ops_lead','ops_agent','verifier','safety','finance','analyst',
  'city_admin','operator_viewer','corporate_admin'
);
create type doc_status as enum ('pending','approved','rejected','expired');

-- profiles
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone_e164 text unique,
  display_name text,
  avatar_path text,
  locale text not null default 'en-NG',
  gender text check (gender in ('female','male','unspecified')) default 'unspecified',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, phone_e164)
  values (new.id, new.phone);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Replace admin_users stub (P0-A-01) with full doc 02 §3 DDL.
drop policy if exists admin_users_no_client_access on admin_users;
drop trigger if exists admin_users_set_updated_at on admin_users;
alter table admin_users drop constraint if exists admin_users_deployment_id_fkey;
drop table admin_users;

create table admin_users (
  id uuid primary key references profiles(id) on delete cascade,
  role admin_role not null,
  deployment_id uuid references deployments(id),
  city_scope uuid[],
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger admin_users_set_updated_at before update on admin_users
  for each row execute function set_updated_at();

alter table admin_users enable row level security;

-- riders
create table riders (
  id uuid primary key references profiles(id) on delete cascade,
  home_city_id uuid references cities(id),
  trip_count int not null default 0,
  account_trust_weight numeric(4,3) not null default 0.200,
  wayfinding_mode text not null default 'text' check (wayfinding_mode in ('text','map','audio')),
  saved_sort text check (saved_sort in ('recommended','cheapest','fastest','least_strenuous')),
  women_only_pref boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- drivers (home_park_id FK deferred until parks exist — doc 02 §4)
create table drivers (
  id uuid primary key references profiles(id) on delete cascade,
  city_id uuid not null references cities(id),
  verified_status verified_status not null default 'unverified',
  standing driver_standing not null default 'good_standing',
  standing_since timestamptz not null default now(),
  rating numeric(3,2),
  rating_count int not null default 0,
  tenure_started_at timestamptz,
  women_only_eligible boolean not null default false,
  payout_subaccount_code text,
  payout_bank_last4 text,
  driver_code text unique,
  driver_code_rotated_at timestamptz,
  accepts_digital boolean not null default true,
  home_park_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function protect_driver_columns()
returns trigger
language plpgsql
as $$
begin
  if coalesce(current_setting('role', true), '') = 'service_role'
    -- nosemgrep: along-postgres-current-user-bypass -- reviewed: protect_* trigger, migration/service path only
     or current_user in ('postgres', 'supabase_admin') then
    return new;
  end if;

  if new.verified_status is distinct from old.verified_status then
    raise exception 'cannot update verified_status' using errcode = '42501';
  end if;
  if new.standing is distinct from old.standing then
    raise exception 'cannot update standing' using errcode = '42501';
  end if;
  if new.rating is distinct from old.rating then
    raise exception 'cannot update rating' using errcode = '42501';
  end if;
  if new.rating_count is distinct from old.rating_count then
    raise exception 'cannot update rating_count' using errcode = '42501';
  end if;
  if new.women_only_eligible is distinct from old.women_only_eligible then
    raise exception 'cannot update women_only_eligible' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger drivers_protect_columns before update on drivers
  for each row execute function protect_driver_columns();

-- vehicles
create table vehicles (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code),
  mode_code text not null references mode_config(code),
  plate_number text not null,
  plate_normalized text generated always as (upper(regexp_replace(plate_number, '[^A-Za-z0-9]', '', 'g'))) stored,
  owner_profile_id uuid references profiles(id),
  owner_name text,
  owner_phone_e164 text,
  seat_capacity smallint not null,
  color text,
  make_model text,
  verification_status verified_status not null default 'unverified',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (country_code, plate_normalized)
);

create table driver_vehicles (
  driver_id uuid not null references drivers(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  active boolean not null default true,
  since timestamptz not null default now(),
  primary key (driver_id, vehicle_id)
);
create unique index driver_vehicles_one_active on driver_vehicles(driver_id) where active;

-- driver_verifications
create table driver_verifications (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  vehicle_id uuid references vehicles(id),
  country_code char(2) not null references countries(code),
  document_type text not null,
  status doc_status not null default 'pending',
  storage_path text,
  provider text,
  provider_reference text,
  ocr_extract jsonb,
  face_match_score numeric(4,3),
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references admin_users(id),
  reviewed_at timestamptz,
  rejection_reason text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index driver_verifications_queue on driver_verifications(status, submitted_at) where status = 'pending';

-- private.identity_hashes — service role only; no client grants
create table private.identity_hashes (
  document_type text not null,
  id_hash bytea not null,
  driver_id uuid not null references drivers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (document_type, id_hash)
);
revoke all on private.identity_hashes from anon, authenticated;

create table device_tokens (
  profile_id uuid not null references profiles(id) on delete cascade,
  platform text not null check (platform in ('android','ios')),
  token text not null,
  app text not null check (app in ('rider','driver')),
  updated_at timestamptz not null default now(),
  primary key (profile_id, token)
);

-- updated_at triggers
create trigger profiles_set_updated_at before update on profiles
  for each row execute function set_updated_at();
create trigger riders_set_updated_at before update on riders
  for each row execute function set_updated_at();
create trigger drivers_set_updated_at before update on drivers
  for each row execute function set_updated_at();
create trigger vehicles_set_updated_at before update on vehicles
  for each row execute function set_updated_at();
create trigger driver_verifications_set_updated_at before update on driver_verifications
  for each row execute function set_updated_at();

-- RLS policies inlined (Supabase CLI does not support \ir).
alter table profiles enable row level security;
alter table riders enable row level security;
alter table drivers enable row level security;
alter table vehicles enable row level security;
alter table driver_vehicles enable row level security;
alter table driver_verifications enable row level security;
alter table device_tokens enable row level security;
alter table private.identity_hashes enable row level security;

create policy profiles_select_own
  on profiles for select to authenticated
  using (id = auth.uid());
create policy profiles_update_own
  on profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
create policy profiles_select_admin
  on profiles for select to authenticated
  using (is_admin());

create policy riders_select_own
  on riders for select to authenticated
  using (id = auth.uid());
create policy riders_insert_own
  on riders for insert to authenticated
  with check (id = auth.uid());
create policy riders_update_own
  on riders for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
create policy riders_select_admin
  on riders for select to authenticated
  using (is_admin());

create policy drivers_select_own
  on drivers for select to authenticated
  using (id = auth.uid());
create policy drivers_insert_own
  on drivers for insert to authenticated
  with check (id = auth.uid());
create policy drivers_update_own
  on drivers for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
create policy drivers_select_admin
  on drivers for select to authenticated
  using (is_admin() and admin_can_access_city(city_id));

create policy vehicles_select_owner
  on vehicles for select to authenticated
  using (owner_profile_id = auth.uid());
create policy vehicles_select_linked_driver
  on vehicles for select to authenticated
  using (
    exists (
      select 1 from driver_vehicles dv
      join drivers d on d.id = dv.driver_id
      where dv.vehicle_id = vehicles.id
        and dv.active
        and d.id = auth.uid()
    )
  );
create policy vehicles_select_admin
  on vehicles for select to authenticated
  using (is_admin());

create policy driver_vehicles_select_own
  on driver_vehicles for select to authenticated
  using (driver_id = auth.uid());
create policy driver_vehicles_write_own
  on driver_vehicles for all to authenticated
  using (driver_id = auth.uid())
  with check (driver_id = auth.uid());

create policy driver_verifications_select_own
  on driver_verifications for select to authenticated
  using (driver_id = auth.uid());
create policy driver_verifications_select_admin
  on driver_verifications for select to authenticated
  using (has_admin_role(array['verifier', 'ops_lead', 'ops_agent', 'superadmin']));

create policy device_tokens_all_own
  on device_tokens for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy admin_users_no_client_access
  on admin_users for all to authenticated
  using (false)
  with check (false);

-- Table grants: RLS policies gate row access; authenticated role needs base privileges.
grant select, insert, update, delete on profiles to authenticated;
grant select, insert, update, delete on riders to authenticated;
grant select, insert, update, delete on drivers to authenticated;
grant select on vehicles to authenticated;
grant select, insert, update, delete on driver_vehicles to authenticated;
grant select on driver_verifications to authenticated;
grant select, insert, update, delete on device_tokens to authenticated;
