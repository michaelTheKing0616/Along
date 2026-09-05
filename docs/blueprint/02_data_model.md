# 02 — Data Model (DDL-level)

Spec references: §4 (core data model + rules), §4.1–4.14. Decisions: ADR-0002 (mode as config table), ADR-0003 (journeys/trips/itineraries), ADR-0004 (tenant via city→deployment), ADR-0009 (location samples), ADR-0010 (ledger extensions).

This document is the source of truth for `backend/db/migrations`. Workers implement it *verbatim* in numbered migrations (one bounded context per migration file), then add pgTAP tests per doc 10. Any deviation is an ADR, not a judgment call.

Conventions: all tables have `created_at timestamptz not null default now()`; mutable tables also `updated_at` maintained by trigger `set_updated_at()`. `id uuid primary key default gen_random_uuid()` unless stated. Money `numeric(12,2)`. Geo `geography(Point,4326)`. `-- RLS:` lines summarize the policy; §7 has the full matrix.

---

## 1. Extensions, schemas, roles, helpers

```sql
create extension if not exists postgis;
create extension if not exists pgcrypto;
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists pg_trgm;
create extension if not exists btree_gist;

create schema if not exists private;   -- never exposed via PostgREST; service role + SQL functions only
revoke all on schema private from anon, authenticated;

-- Generic helpers
create or replace function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

create or replace function forbid_mutation() returns trigger language plpgsql as $$
begin raise exception 'table % is append-only', tg_table_name using errcode = '42501'; end $$;

create or replace function current_profile_id() returns uuid language sql stable as $$ select auth.uid() $$;

create or replace function is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users a where a.id = auth.uid() and a.disabled_at is null) $$;

create or replace function has_admin_role(roles text[]) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users a where a.id = auth.uid() and a.disabled_at is null and (a.role = any(roles) or a.role = 'superadmin')) $$;

-- City scoping for admins: null scope = all cities in their deployment; superadmin = everything
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
```

---

## 2. Geo & configuration

### 2.1 Deployments, countries, cities, corridors

```sql
create table deployments (                        -- §4.14 white-label / tenant boundary (ADR-0004)
  id uuid primary key default gen_random_uuid(),
  tenant_name text not null unique,
  branding_config jsonb not null default '{}'::jsonb,   -- logo urls, accent overrides (token names only)
  region_config jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table countries (
  code char(2) primary key,                       -- ISO 3166-1 alpha-2
  name text not null,
  currency_code char(3) not null,                 -- ISO 4217
  currency_minor_units smallint not null default 2 check (currency_minor_units between 0 and 3),
  currency_symbol text not null,                  -- '₦'
  phone_prefix text not null,                     -- '+234'
  default_locale text not null default 'en-NG',
  timezone text not null,                         -- IANA
  deployment_id uuid not null references deployments(id),
  verification_schema jsonb not null default '[]'::jsonb, -- §Phase 10: required document types per role, e.g. [{"type":"nin","label":"NIN","pattern":"^\\d{11}$","provider":"verifyme"}]
  regulatory_flags jsonb not null default '{}'::jsonb,   -- e.g. {"women_only_matching": true}
  active boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create type city_status as enum ('pre_seed','alpha','beta','live','paused');

create table cities (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code),
  name text not null,
  slug text not null unique,                      -- 'abuja'
  state_region text,                              -- 'FCT'
  centroid geography(Point,4326) not null,
  boundary geography(MultiPolygon,4326),
  timezone text,                                  -- overrides country if set
  status city_status not null default 'pre_seed',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index cities_boundary_gix on cities using gist (boundary);
create index cities_centroid_gix on cities using gist (centroid);

create table corridors (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  name text not null,                             -- 'Lugbe ↔ Area 1'
  slug text not null,
  geometry geography(LineString,4326),
  status city_status not null default 'pre_seed',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (city_id, slug)
);

-- Boundary match wins; otherwise nearest centroid within 60 km; null if nothing (caller treats as coverage gap)
create or replace function city_for_point(p geography) returns uuid language sql stable as $$
  select id from cities
  where status <> 'paused'
    and ((boundary is not null and st_intersects(boundary, p)) or st_dwithin(centroid, p, 60000))
  order by (boundary is not null and st_intersects(boundary, p)) desc, st_distance(centroid, p)
  limit 1 $$;
```
> RLS: `deployments`, `countries`, `cities`, `corridors` — select for all authenticated; write only `has_admin_role('{superadmin,ops_lead}')` (cities/corridors additionally `admin_can_access_city`).

### 2.2 Modes (ADR-0002 — a config table, never an enum)

```sql
create table mode_config (
  code text primary key,                          -- 'car','keke','okada','minibus' (seed); adding one is an INSERT
  label text not null,                            -- 'Along taxi'
  label_i18n jsonb not null default '{}'::jsonb,  -- {"ha":"...","yo":"..."}
  icon_key text not null,                         -- maps to along_design icon set
  color_token text not null,                      -- 'mode.car' — token name, never a hex (doc 05)
  comfort_weight numeric(4,2) not null check (comfort_weight between 0 and 10),  -- §4.2.2 mode_comfort_weights
  load_capacity text not null check (load_capacity in ('none','small','medium','large')), -- §4.13
  default_seat_capacity smallint not null check (default_seat_capacity between 1 and 60),
  default_dwell_s int not null default 120,       -- typical loading time at park, used by planner
  active boolean not null default true,
  sort_order smallint not null default 100,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
-- seed: car(4.0,'large',4) keke(6.0,'small',3) okada(8.0,'none',1) minibus(5.0,'medium',14). Comfort weight: higher = more strenuous.
```
> RLS: select all authenticated; write `has_admin_role('{superadmin,ops_lead}')`. Audited.

### 2.3 App configuration (every threshold in the spec lives here)

```sql
create type config_scope as enum ('global','country','city','corridor');

create table app_config (
  key text not null,
  scope_type config_scope not null default 'global',
  scope_id text not null default '*',             -- country code, city uuid, corridor uuid, or '*'
  value jsonb not null,
  description text,
  updated_by uuid,
  updated_at timestamptz not null default now(),
  primary key (key, scope_type, scope_id)
);

-- Resolution order: corridor → city → country → global. Returns jsonb; callers cast.
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

-- Config defaults are owned by MIGRATIONS, not seeds (ADR-0016): seed.sql only runs on local `db reset`,
-- never on `db push`, so a default that lives only in a seed never reaches staging or prod.
-- Defaults fill gaps only — never overwrite a value an admin has set through A-09.
create or replace function config_default(p_key text, p_value jsonb, p_scope_type config_scope default 'global', p_scope_id text default '*')
returns void language sql as $$
  insert into app_config (key, scope_type, scope_id, value) values (p_key, p_scope_type, p_scope_id, p_value)
  on conflict (key, scope_type, scope_id) do nothing $$;
```

**Required keys with defaults.** Every key below is registered by the migration that introduces the feature using it, via `select config_default('<key>', '<json>');` — one call per key, **`on conflict do nothing`**, never `do update` (a re-deployed default must not clobber an operator's live edit). `seed_core.sql` inserts **no** `app_config` rows; it may only add *scoped overrides* for seeded entities (e.g. the NG country `sos.emergency_number`), also via `config_default`. Changing a live value in any environment goes through A-09 → `admin_set_config`, audited. Test `TS-CFG-02` asserts every key in this table exists after migrations alone (seed not applied).

| key | default | used by (spec) |
|---|---|---|
| `commission.rate` | `0.075` | §4.4, Phase 4 (5–10% band) |
| `commission.applies_to_load_surcharge` | `true` | §4.13 |
| `ledger.block_threshold` | `-5000` (currency of city) | §4.4.1 threshold enforcement |
| `ledger.warn_threshold` | `-3000` | §4.4.3 `warned` |
| `ledger.grace_period_hours` | `48` | §4.4.3 |
| `ledger.deactivate_threshold` | `-15000` | §4.4.3 |
| `ledger.onboarding_deposit` | `0` (opt-in per city) | §4.4.1 |
| `dispatch.request_ttl_s` | `25` | driver response window |
| `dispatch.max_cascade` | `3` | roaming re-target |
| `planner.max_legs` | `3` | Phase 2 |
| `planner.max_candidates` | `12` | §4.2.2 bounded set |
| `planner.walk_radius_m` | `800` | origin→park search |
| `planner.dest_radius_m` | `600` | stage counts as "covering" destination |
| `planner.direct_viability_factor` | `1.5` | §4.2.1: direct is viable if `total_time ≤ factor × best_alt_time + slack` |
| `planner.direct_viability_slack_s` | `300` | §4.2.1 |
| `planner.recommended_weights` | `{"fare":0.4,"time":0.4,"strenuous":0.2}` | §4.2.2 explainable blend |
| `planner.strenuous_weights` | `{"transfer":1.0,"walk_per_100m":0.25,"mode":0.5}` | §4.2.2 |
| `planner.heading_tolerance_deg` | `45` | §4.1 plausibility |
| `planner.walk_speed_mps` | `1.25` | fallback |
| `graph.snap_radius_m` | `60` | §4.7 snapping, FM18 |
| `graph.stage_merge_radius_m` | `40` | dedupe |
| `promotion.threshold_weight` | `3.0` | §4.5 (default 3 trusted confirmations) |
| `promotion.min_distinct_accounts` | `3` | §4.5.1 |
| `promotion.fare_tolerance_pct` | `0.15` | §4.5 tolerance |
| `promotion.location_tolerance_m` | `50` | §4.5 |
| `promotion.outlier_mad_k` | `3.0` | §4.5.1 sharp deviation → review |
| `promotion.collusion_downweight` | `0.25` | doc 04 §6.2 — weight multiplier for confirmations from accounts sharing a device fingerprint / phone-prefix cluster (doc 12 §6) |
| `promotion.decay_window_days` | `90` | §4.5.1 re-validation |
| `promotion.decay_step` | `0.15` | confidence decrement per window |
| `trust.rider_base` | `0.2`; `trust.rider_per_trip` `0.05`; `trust.rider_cap` `1.0`; `trust.rider_min_age_days` `7` | §4.5.1 account_trust_weight |
| `trust.driver_verified` | `1.0`; `trust.driver_unverified` `0.0` | |
| `presence.ping_interval_moving_s` | `4`; `presence.ping_interval_still_s` `15`; `presence.stale_after_s` `45`; `presence.offline_after_s` `180` | §4.1 |
| `presence.history_full_res_hours` | `24`; `presence.history_downsampled_days` `30`; `presence.downsample_interval_s` `60` | §4.1 retention |
| `presence.ambient_cell_precision` | `6` (geohash) | §4.1.2 |
| `boarding.colocation_radius_m` | `25`; `boarding.colocation_duration_s` `20`; `boarding.min_speed_mps` `1.5` | §4.6 auto-confirm |
| `negotiation.park.round_cap` | `4`; `negotiation.park.round_timeout_s` `20` | §4.3.1 |
| `negotiation.roaming.eta_none_s` | `20`; `negotiation.roaming.eta_single_s` `60`; `negotiation.roaming.round_timeout_s` `12`; `negotiation.roaming.round_cap` `3`; `negotiation.pickup_radius_m` `150` | §4.3.1 ETA bands, FM37/38 |
| `negotiation.chip_steps` | `[-100,-50,50,100]` | §4.3.1 |
| `reconciliation.dest_radius_m` | `200`; `reconciliation.min_route_fraction` `0.7`; `reconciliation.extension_gap_m` `400` | §4.4.2, §4.12 |
| `clustering.eps_m` | `35`; `clustering.min_points` `12`; `clustering.min_distinct_drivers` `4`; `clustering.min_distinct_days` `3`; `clustering.window_days` `14` | §4.5.3, FM26 |
| `name.colors` | 8-entry list of token names; `name.shapes` 6-entry list | §4.8 Na Me (see doc 05 §6) |
| `sos.emergency_number` | `"112"` (country scope) | Phase 5 |
| `share.link_ttl_hours` | `12` | Phase 5 |
| `otp.rate_limit_per_hour` | `5` | doc 12 |
| `sms.providers` | `["termii","twilio"]` | doc 01 §9 |
| `sms.provider` | `"log"` (staging/local until Termii sender-ID is approved; then `"termii"`) | ADR-0012 |
| `public.origin` | `""` until a domain is purchased; intended prod `https://along.ng` | doc 14, W-01/W-04, share links. No trailing slash. QR stickers and App/Universal Links are not issued while empty. |
| `load.warn_capacities` | `{"small":["none"],"medium":["none","small"],"large":["none","small","medium"]}` | §4.13 FM36 |
| `fare.default_rate_per_km` | `{"car":120,"keke":90,"okada":110,"minibus":60}` (city currency) | doc 04 §3 Tier 3 fallback |
| `fare.min_fare` | `{"car":200,"keke":100,"okada":100,"minibus":100}` | doc 04 §3 |
| `planner.default_wait_s` | `300`; `planner.shared_vehicle_factor` `1.25` | doc 04 §4.4 |
| `dispatch.no_show_after_s` | `300` | doc 04 §10 |
| `decline.reasons` | `["too_far","wrong_direction","vehicle_full","no_room_for_load","other"]` | doc 03 §4 |
| `ledger.dual_control_threshold` | `20000`; `ledger.deactivate_after_days` `14` | doc 04 §12, doc 08 §5 |
| `export.k` | `10` | Phase 8 anonymisation |
| `geometry.min_supporting_traces` | `15`; `inference.min_trips` `20` | doc 04 §15 |
| `field.location_tol_m` | `50`; `field.fare_tol_pct` `0.15` | doc 13 §3 |
| `payments.digital_enabled` | `false` (flipped per country after P4-E-02 sign-off) | ADR-0010 |
| `payments.min_digital_amount` | `100`; `payments.fee_bearer` `'account'`; `payments.qr_resolve_rate_per_min` `30`; `payments.unattributed_lookback_hours` `24`; `payments.dynamic_qr_ttl_s` `600` | doc 14, ADR-0014 |
| `rating.tags` | `["safe_driving","fair_fare","clean_vehicle","polite","on_time","overcharged","unsafe","rude"]` | R-17 / D-18 |

> RLS: select all authenticated (values are not secret — secrets are never config); write `has_admin_role('{superadmin,ops_lead}')`. Audited.

---

## 3. Identity

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone_e164 text unique,
  display_name text,
  avatar_path text,                               -- storage path, private bucket
  locale text not null default 'en-NG',
  gender text check (gender in ('female','male','unspecified')) default 'unspecified',  -- only used for women-only eligibility, self-declared
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
-- trigger: on auth.users insert → profiles insert (phone from auth)

create table riders (
  id uuid primary key references profiles(id) on delete cascade,
  home_city_id uuid references cities(id),
  trip_count int not null default 0,
  account_trust_weight numeric(4,3) not null default 0.200,   -- §4.5.1; recomputed nightly by compute_trust_weights()
  wayfinding_mode text not null default 'text' check (wayfinding_mode in ('text','map','audio')),  -- §4.11
  saved_sort text check (saved_sort in ('recommended','cheapest','fastest','least_strenuous')),     -- post-MVP §4.2.2
  women_only_pref boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create type verified_status as enum ('unverified','pending','verified','rejected','suspended');
create type driver_standing as enum ('good_standing','warned','matching_paused','deactivated','guarantor_referred'); -- §4.4.3

create table drivers (
  id uuid primary key references profiles(id) on delete cascade,
  city_id uuid not null references cities(id),
  verified_status verified_status not null default 'unverified',
  standing driver_standing not null default 'good_standing',
  standing_since timestamptz not null default now(),
  rating numeric(3,2), rating_count int not null default 0,
  tenure_started_at timestamptz,                  -- first verified_at
  women_only_eligible boolean not null default false,  -- set by verifier, requires profiles.gender='female' + verified
  payout_subaccount_code text,                     -- Paystack subaccount (ADR-0010); presence = can accept digital payments
  payout_bank_last4 text,                          -- display only; full account number never stored
  driver_code text unique,                         -- 8-char Crockford base32, random; printed on the QR sticker (doc 14, ADR-0014); set at verification approval
  driver_code_rotated_at timestamptz,
  accepts_digital boolean not null default true,   -- driver may pause QR/digital acceptance; effective only with a subaccount
  home_park_id uuid,                               -- fk added after parks
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table vehicles (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code),
  mode_code text not null references mode_config(code),
  plate_number text not null,
  plate_normalized text generated always as (upper(regexp_replace(plate_number, '[^A-Za-z0-9]', '', 'g'))) stored,
  owner_profile_id uuid references profiles(id),  -- null when owner is not on platform (Constitution 1: never Along)
  owner_name text, owner_phone_e164 text,
  seat_capacity smallint not null,
  color text, make_model text,
  verification_status verified_status not null default 'unverified',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
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

create type admin_role as enum ('superadmin','ops_lead','ops_agent','verifier','safety','finance','analyst','city_admin','operator_viewer','corporate_admin');

create table admin_users (
  id uuid primary key references profiles(id) on delete cascade,
  role admin_role not null,
  deployment_id uuid references deployments(id),
  city_scope uuid[],                              -- null = all cities in deployment
  disabled_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create type doc_status as enum ('pending','approved','rejected','expired');

create table driver_verifications (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  vehicle_id uuid references vehicles(id),
  country_code char(2) not null references countries(code),
  document_type text not null,                    -- must exist in countries.verification_schema
  status doc_status not null default 'pending',
  storage_path text,                              -- private bucket 'verification'; signed URLs only
  provider text, provider_reference text,         -- external verification call reference; NEVER the id number
  ocr_extract jsonb,                              -- §5.3: assistive only; redacted of id numbers before storage
  face_match_score numeric(4,3),
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references admin_users(id), reviewed_at timestamptz, rejection_reason text,
  expires_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index driver_verifications_queue on driver_verifications(status, submitted_at) where status = 'pending';

-- Duplicate-identity detection without storing identifiers (spec §4 "hashed/never raw-stored")
create table private.identity_hashes (
  document_type text not null,
  id_hash bytea not null,                         -- hmac(sha256, normalized_id, pepper) ; pepper in Vault, never in repo
  driver_id uuid not null references drivers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (document_type, id_hash)
);

create table device_tokens (
  profile_id uuid not null references profiles(id) on delete cascade,
  platform text not null check (platform in ('android','ios')),
  token text not null,
  app text not null check (app in ('rider','driver')),
  updated_at timestamptz not null default now(),
  primary key (profile_id, token)
);

alter table drivers add constraint drivers_home_park_fk foreign key (home_park_id) references parks(id) deferrable initially deferred; -- after §4
```
> RLS: `profiles/riders/drivers` — owner select/update own row (drivers cannot update `verified_status`, `standing`, `rating*`, `women_only_eligible` — column-level via trigger `protect_driver_columns()`); admins select in scope; `verifier` updates verification columns via RPC only. `vehicles` — driver with active `driver_vehicles` link can select; insert via `rpc.register_vehicle`; owner_profile can select. `driver_verifications` — driver select own (status, rejection_reason only via view `my_verifications`); insert via RPC; `verifier/ops_lead` select+update in scope. `private.*` — no policies; service role only. `device_tokens` — owner all.

---

## 4. The along-graph (Constitution 2 — changes need an ADR)

```sql
create type graph_verification as enum ('candidate','crowd_verified','field_verified');
create type source_type as enum ('field_agent','driver_declared','rider_correction','driver_correction','presence_cluster','trace_inference','pricing_negotiation','admin','import');

create table data_sources (                      -- provenance for every graph write (§4, FM4)
  id uuid primary key default gen_random_uuid(),
  source_type source_type not null,
  actor_profile_id uuid references profiles(id),
  field_submission_id uuid,                       -- fk after §14
  job_run_id uuid,                                -- fk after §12
  trip_id uuid,                                   -- fk after §8
  notes text,
  created_at timestamptz not null default now()
);

create table parks (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  name text not null,
  name_aliases text[] not null default '{}',
  location geography(Point,4326) not null,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  source_id uuid not null references data_sources(id),
  verified_by uuid references admin_users(id), verified_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index parks_location_gix on parks using gist (location);
create index parks_name_trgm on parks using gin (name gin_trgm_ops);

create table routes (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  corridor_id uuid references corridors(id),
  origin_park_id uuid not null references parks(id),
  destination_park_id uuid not null references parks(id),
  mode_code text not null references mode_config(code),
  is_direct boolean not null default true,
  name text,                                      -- 'Lugbe → Area 1 (keke)'
  path geography(LineString,4326),                -- from GPX (field) or matched traces
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  source_id uuid not null references data_sources(id),
  active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (origin_park_id <> destination_park_id)
);
create index routes_city_mode on routes(city_id, mode_code) where active;
create index routes_path_gix on routes using gist (path);

create table route_stages (                       -- ordered stops on a route (§4.3)
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references routes(id) on delete cascade,
  sequence int not null,
  park_id uuid references parks(id),              -- set when this stage IS a park
  location geography(Point,4326) not null,
  name text,
  is_official_park boolean not null default false,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  independent_confirmation_count int not null default 0,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (route_id, sequence)
);
create index route_stages_location_gix on route_stages using gist (location);

create table route_legs (                         -- adjacent stage-hop with its own fare (§4.3 Tier 2)
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references routes(id) on delete cascade,
  from_stage_id uuid not null references route_stages(id),
  to_stage_id uuid not null references route_stages(id),
  mode_code text not null references mode_config(code),
  fare_amount numeric(12,2) not null check (fare_amount >= 0),
  fare_currency char(3) not null,
  fare_last_verified_at timestamptz,
  frequency_estimate_per_hour numeric(6,2),
  operating_hours jsonb,                          -- [{"dow":[1,2,3,4,5],"from":"05:30","to":"22:00"}]
  avg_wait_time_estimate_s int,
  in_vehicle_time_estimate_s int,
  distance_m int,
  boarding_walk_distance_m int not null default 0,
  verification_status graph_verification not null default 'candidate',
  confidence_score numeric(4,3) not null default 0.300,
  independent_confirmation_count int not null default 0,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (route_id, from_stage_id, to_stage_id)
);
-- trigger route_legs_adjacent_check(): from_stage.sequence + 1 = to_stage.sequence and both belong to route_id

create table route_through_fares (                -- non-additive known pair price (§4.3 Tier 1)
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
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (route_id, from_stage_id, to_stage_id)
);
-- trigger: from_stage.sequence < to_stage.sequence, same route

create table transfer_points (                    -- a park where a route can be joined/left for another (§4)
  park_id uuid not null references parks(id) on delete cascade,
  route_id uuid not null references routes(id) on delete cascade,
  stage_id uuid not null references route_stages(id),
  walk_distance_m int not null default 0,         -- within-park walk between bays
  transfer_time_s int not null default 180,
  primary key (park_id, route_id)
);

create table graph_confirmations (                -- one independent confirmation per account per target (§4.5.1)
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('route_stage','route_leg','route_through_fare','route','park')),
  target_id uuid not null,
  confirmer_profile_id uuid not null references profiles(id),
  confirmer_role text not null check (confirmer_role in ('rider','driver','field_agent','admin')),
  trust_weight numeric(4,3) not null,             -- snapshot at confirmation time
  proposed_value jsonb not null,                  -- {"fare":450} or {"lat":..,"lng":..}
  trip_id uuid,                                   -- fk after §8; confirmations tied to a real trip weigh more
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  unique (target_type, target_id, confirmer_profile_id)
);
create index graph_confirmations_target on graph_confirmations(target_type, target_id);

create table graph_revisions (                    -- versioning (§4 rules, business plan 5.2.1) — append-only
  id bigserial primary key,
  target_type text not null, target_id uuid not null,
  before jsonb, after jsonb not null,
  changed_by uuid, source_id uuid references data_sources(id), reason text,
  created_at timestamptz not null default now()
);
create trigger graph_revisions_ro before update or delete on graph_revisions for each row execute function forbid_mutation();
-- triggers on parks/routes/route_stages/route_legs/route_through_fares write graph_revisions on insert/update

create type correction_status as enum ('pending','approved','rejected','auto_merged');

create table fare_corrections (                   -- §4.5 pipeline input (post-trip mismatch, negotiation outcomes, driver corrections)
  id uuid primary key default gen_random_uuid(),
  route_leg_id uuid references route_legs(id),
  route_through_fare_id uuid references route_through_fares(id),
  route_id uuid references routes(id),            -- when target pair doesn't exist yet: create candidate through-fare on approval
  from_stage_id uuid references route_stages(id), to_stage_id uuid references route_stages(id),
  trip_id uuid,                                   -- fk after §8
  submitted_by uuid not null references profiles(id),
  submitter_role text not null check (submitter_role in ('rider','driver','system')),
  proposed_fare numeric(12,2) not null, currency char(3) not null,
  fare_shown numeric(12,2),                       -- what the app showed, for delta analysis
  status correction_status not null default 'pending',
  reviewed_by uuid references admin_users(id), reviewed_at timestamptz, review_note text,
  source_id uuid not null references data_sources(id),
  created_at timestamptz not null default now(),
  check (route_leg_id is not null or route_through_fare_id is not null or (route_id is not null and from_stage_id is not null and to_stage_id is not null))
);
create index fare_corrections_queue on fare_corrections(status, created_at) where status = 'pending';
```
> RLS: all graph tables — select for authenticated (they *are* the product's public data; candidate rows included but flagged). Writes only through `security definer` RPCs (`submit_correction`, `confirm_graph_value`, `publish_field_entity`, admin RPCs). Direct insert/update/delete policies exist only for `has_admin_role('{superadmin,ops_lead,ops_agent}')` and are audited. `graph_confirmations` — insert via RPC (sets trust weight server-side), select admin only.

---

## 5. Driver self-service routes (§4.7)

```sql
create table driver_route_profiles (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  route_id uuid references routes(id),            -- nullable until reconciled to canonical route
  mode_code text not null references mode_config(code),
  name text,
  active boolean not null default true,
  load_surcharge_amount numeric(12,2) check (load_surcharge_amount >= 0),   -- §4.13 optional standard surcharge
  load_surcharge_currency char(3),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index driver_route_profiles_active on driver_route_profiles(driver_id) where active;

create table driver_route_stops (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references driver_route_profiles(id) on delete cascade,
  sequence int not null,
  route_stage_id uuid references route_stages(id), -- snapped canonical stage (FM18)
  custom_location geography(Point,4326),          -- until snapped
  custom_label text,
  price_to_end numeric(12,2) not null check (price_to_end >= 0),   -- §4.7: fare from this stop to the END of the route
  currency char(3) not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (profile_id, sequence),
  check (route_stage_id is not null or custom_location is not null)
);
create index driver_route_stops_loc_gix on driver_route_stops using gist (custom_location);
-- trigger: price_to_end must be non-increasing with sequence; last stop price_to_end = 0
-- view driver_route_stop_location: coalesce(route_stages.location, custom_location)
```
> RLS: driver select/insert/update/delete own (`driver_id = auth.uid()` via join); riders none (they read via planner RPC); admins select in scope.

---

## 6. Presence (§4.1)

```sql
create type presence_status as enum ('offline','at_park','roaming_available','roaming_full');

create table driver_presence (                    -- exactly one live row per opted-in driver; deleted on offline (FM10)
  driver_id uuid primary key references drivers(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id),
  session_id uuid not null default gen_random_uuid(),
  status presence_status not null check (status <> 'offline'),
  current_location geography(Point,4326) not null,
  heading smallint check (heading between 0 and 359),
  speed_mps numeric(5,2),
  accuracy_m numeric(6,1),
  park_id uuid references parks(id),              -- required when at_park
  declared_route_leg_id uuid references route_legs(id),
  declared_route_profile_id uuid references driver_route_profiles(id),
  nearest_stage_id uuid references route_stages(id),   -- inferred by presence_ping (≤ graph.snap_radius_m×2)
  seats_available smallint not null check (seats_available >= 0),
  last_ping_at timestamptz not null default now(),
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'at_park' or park_id is not null)
);
create index driver_presence_loc_gix on driver_presence using gist (current_location);
create index driver_presence_ping on driver_presence(last_ping_at);

create table driver_presence_history (            -- retention per app_config presence.history_* (§4.1)
  id bigserial,
  driver_id uuid not null,
  session_id uuid not null,
  ts timestamptz not null,
  location geography(Point,4326) not null,
  heading smallint, speed_mps numeric(5,2), status presence_status not null,
  downsampled boolean not null default false,
  primary key (ts, id)
) partition by range (ts);
-- monthly partitions created by job ensure_partitions(); index (driver_id, ts); gist(location)
```
> RLS: `driver_presence` — driver select own row only; **no rider select** (ambient via `ambient_vehicles()`; committed via trip view); admins `safety/ops_*` select in scope. Writes only via `set_presence()`/`presence_ping()`. `driver_presence_history` — no client policies; admin analysts via aggregated views only.

---

## 7. Planner support

```sql
create table fare_quotes (                        -- every fare ever shown, with its tier and components (dispute trail)
  id uuid primary key default gen_random_uuid(),
  rider_id uuid references riders(id),
  driver_id uuid references drivers(id),
  route_id uuid references routes(id),
  driver_route_profile_id uuid references driver_route_profiles(id),
  from_stage_id uuid references route_stages(id), to_stage_id uuid references route_stages(id),
  from_location geography(Point,4326), to_location geography(Point,4326),
  mode_code text not null references mode_config(code),
  tier smallint not null check (tier between 0 and 3),
  amount numeric(12,2) not null, currency char(3) not null,
  components jsonb not null,                      -- [{"kind":"leg","leg_id":..,"amount":150},{"kind":"load_surcharge","amount":100}]
  confidence numeric(4,3) not null,
  negotiation_id uuid,                            -- fk after §8 (Tier 3 agreed)
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '10 minutes'
);

create table planner_queries (                    -- analytics for ranking tuning + conversion (§4.1.2 diagnostic)
  id uuid primary key default gen_random_uuid(),
  rider_id uuid references riders(id),
  city_id uuid references cities(id),
  origin geography(Point,4326) not null, destination geography(Point,4326) not null,
  filters jsonb not null default '{}'::jsonb,
  candidate_count smallint not null, direct_count smallint not null,
  degraded boolean not null default false,
  latency_ms int,
  chosen_candidate_id uuid,                       -- set by request_trip
  created_at timestamptz not null default now()
);

create table coverage_gap_reports (               -- §4.9
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
```
> RLS: `fare_quotes` — rider/driver select where own id matches; insert only via functions. `planner_queries`, `coverage_gap_reports` — insert via functions; select admin `analyst+`.

---

## 8. Journeys, trips, negotiations, extensions (ADR-0003)

**Model:** a *journey* is one rider going to one destination; it contains 1..N *trips*, one per vehicle boarded (a transfer = journey moves from trip k to trip k+1). A single trip may traverse many adjacent `route_legs` (hence `route_leg_ids[]`). A day-planner *itinerary* is a sequence of *stops*, each fulfilled by one journey.

```sql
create type journey_status as enum ('planning','active','transfer','completed','abandoned');
create type trip_status as enum ('requested','accepted','boarded','in_transit','completed','declined','expired','cancelled_by_rider','cancelled_by_driver','no_show');
create type load_size as enum ('small','medium','large');
create type payment_method as enum ('cash','digital');

create table journeys (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id),
  city_id uuid not null references cities(id),
  status journey_status not null default 'planning',
  origin geography(Point,4326) not null,
  destination geography(Point,4326) not null,
  destination_label text,
  plan_snapshot jsonb not null,                   -- the chosen candidate incl. metrics, legs, quotes — immutable evidence
  planner_query_id uuid references planner_queries(id),
  itinerary_stop_id uuid,                         -- fk after §11
  load_flagged boolean not null default false, load_size load_size, load_note text check (char_length(load_note) <= 140),
  women_only boolean not null default false,
  current_trip_sequence smallint not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), completed_at timestamptz
);

create table trips (
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references journeys(id),
  journey_sequence smallint not null default 1,
  rider_id uuid not null references riders(id),
  driver_id uuid references drivers(id),          -- null only transiently during roaming dispatch cascade
  vehicle_id uuid references vehicles(id),
  mode_code text not null references mode_config(code),
  route_id uuid references routes(id),
  driver_route_profile_id uuid references driver_route_profiles(id),
  route_leg_ids uuid[] not null default '{}',     -- ordered adjacent legs traversed
  boarding_stage_id uuid references route_stages(id),
  alighting_stage_id uuid references route_stages(id),
  boarding_location geography(Point,4326),        -- actual/expected pickup point (roaming or off-stage)
  alighting_location geography(Point,4326),
  fare_quote_id uuid not null references fare_quotes(id),
  fare_shown numeric(12,2) not null, fare_currency char(3) not null,
  fare_tier smallint not null check (fare_tier between 0 and 3),
  load_surcharge_amount numeric(12,2) not null default 0,
  commission_rate numeric(5,4) not null,          -- snapshot of cfg('commission.rate') at request
  commission_amount numeric(12,2),                -- set at completion = round((fare_shown + load_surcharge) * rate)
  fare_reported_paid numeric(12,2),               -- rider post-trip
  payment_method payment_method not null default 'cash',
  status trip_status not null default 'requested',
  requested_at timestamptz not null default now(),
  expires_at timestamptz not null,                -- requested_at + cfg dispatch.request_ttl_s
  accepted_at timestamptz, boarded_at timestamptz, started_at timestamptz, ended_at timestamptz, cancelled_at timestamptz,
  boarded_via text check (boarded_via in ('auto_colocation','manual_rider','manual_driver')),
  cancel_reason text, decline_reason text,        -- decline_reason includes 'no_room_for_load' (§4.13)
  id_signal_color text not null, id_signal_shape text not null,   -- §4.8 Na Me pairing, generated at insert
  load_flagged boolean not null default false, load_size load_size, load_note text,
  women_only boolean not null default false,
  dispatch_attempt smallint not null default 1,
  driver_live_path geography(LineString,4326),    -- materialized at completion from trip_location_samples
  rider_live_path geography(LineString,4326),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (journey_id, journey_sequence)
);
create index trips_driver_status on trips(driver_id, status);
create index trips_rider_created on trips(rider_id, created_at desc);
create index trips_open_requests on trips(expires_at) where status = 'requested';
-- multi-rider corroboration window (btree_gist); null upper bound = still open. Index expressions must be immutable: no now() here.
create index trips_driver_window on trips using gist (driver_id, tstzrange(coalesce(boarded_at, accepted_at), coalesce(ended_at, cancelled_at)));
-- guard trigger: only trip_transition() may change status (checks current_setting('along.in_transition') = 'on')

create type actor_type as enum ('rider','driver','system','admin');

create table trip_events (                        -- append-only transition log
  id bigserial primary key,
  trip_id uuid not null references trips(id),
  from_status trip_status, to_status trip_status not null,
  actor_type actor_type not null, actor_id uuid,
  reason text, meta jsonb,
  created_at timestamptz not null default now()
);
create index trip_events_trip on trip_events(trip_id, created_at);
create trigger trip_events_ro before update or delete on trip_events for each row execute function forbid_mutation();

create table trip_location_samples (              -- ADR-0009: raw points; paths materialized on completion
  id bigserial,
  trip_id uuid not null,
  actor_type actor_type not null check (actor_type in ('rider','driver')),
  ts timestamptz not null,
  location geography(Point,4326) not null,
  accuracy_m numeric(6,1), speed_mps numeric(5,2), heading smallint,
  primary key (ts, id)
) partition by range (ts);
-- monthly partitions; index (trip_id, actor_type, ts)

create table trip_extensions (                    -- §4.12 append-only
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  previous_alighting_stage_id uuid references route_stages(id),
  previous_alighting_location geography(Point,4326),
  new_alighting_stage_id uuid references route_stages(id),
  new_alighting_location geography(Point,4326),
  proposed_by actor_type not null check (proposed_by in ('rider','driver')),
  status text not null default 'proposed' check (status in ('proposed','accepted','declined','expired')),
  fare_quote_id uuid references fare_quotes(id),  -- re-run of resolve_fare against new endpoint
  fare_delta numeric(12,2) not null, currency char(3) not null,
  commission_delta numeric(12,2),
  ledger_entry_id bigint,                         -- fk after §9
  proposed_at timestamptz not null default now(), responded_at timestamptz, expires_at timestamptz not null
);
create trigger trip_extensions_no_delete before delete on trip_extensions for each row execute function forbid_mutation();
-- update allowed only on status/responded_at/ledger_entry_id via function (trigger protect_extension_columns)

create type negotiation_context as enum ('park','roaming','extension','load_surcharge');
create type negotiation_status as enum ('open','agreed','lapsed','declined');
create type eta_band as enum ('none','single','full');

create table price_negotiations (                 -- §4.3.1
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id),
  driver_id uuid not null references drivers(id),
  context negotiation_context not null,
  candidate_ref jsonb not null,                   -- {"route_id"|"profile_id"|"presence_session_id", "from_stage_id","to_stage_id","from_location","to_location"}
  anchor_amount numeric(12,2) not null, currency char(3) not null,
  anchor_quote_id uuid references fare_quotes(id),
  status negotiation_status not null default 'open',
  agreed_amount numeric(12,2),
  round_cap smallint not null, round_timeout_s smallint not null,
  eta_band eta_band,                              -- roaming only
  pickup_radius_m int,                            -- roaming only (FM38)
  expires_at timestamptz not null,
  resulting_trip_id uuid references trips(id),
  created_at timestamptz not null default now(), resolved_at timestamptz
);
create index price_negotiations_open on price_negotiations(expires_at) where status = 'open';

create table price_negotiation_rounds (           -- append-only
  id uuid primary key default gen_random_uuid(),
  negotiation_id uuid not null references price_negotiations(id) on delete cascade,
  round_number smallint not null,
  proposed_by actor_type not null check (proposed_by in ('rider','driver','system')),  -- system = split-the-difference
  amount numeric(12,2) not null,
  proposed_at timestamptz not null default now(),
  responded_at timestamptz,
  response text check (response in ('accept','counter','decline','lapse')),
  unique (negotiation_id, round_number)
);
create trigger pnr_ro before delete on price_negotiation_rounds for each row execute function forbid_mutation();

alter table fare_quotes add constraint fare_quotes_negotiation_fk foreign key (negotiation_id) references price_negotiations(id);
alter table data_sources add constraint data_sources_trip_fk foreign key (trip_id) references trips(id);
alter table graph_confirmations add constraint gc_trip_fk foreign key (trip_id) references trips(id);
alter table fare_corrections add constraint fc_trip_fk foreign key (trip_id) references trips(id);
```
> RLS: `journeys` — rider own. `trips` — rider where `rider_id = auth.uid()`; driver where `driver_id = auth.uid()` **and** status ≠ `requested`-for-another-attempt (view `driver_trip_view` hides rider phone; exposes rider display name + rating + pickup); admins in scope. Column-level: clients never see `id_signal_*` of trips they aren't party to (implicit via row policy). All writes via RPC. `trip_events` — party to trip select; admins. `trip_location_samples` — insert via RPC only; select admin `safety/ops_lead/finance`. `trip_extensions`, `price_negotiations`, `*_rounds` — party select; writes via RPC.

---

## 9. Ledger, settlements, payments, standing, guarantors (§4.4)

```sql
create type ledger_entry_type as enum (
  'cash_commission_debit',        -- negative amount at cash trip completion / extension
  'digital_settlement_credit',    -- positive: self-service or agent settlement confirmed; also digital-trip driver earnings (fare − commission)
  'onboarding_deposit',           -- positive, refundable
  'deposit_drawdown',             -- negative: consumes deposit against debt after grace
  'payout_debit',                 -- negative: Along paid a positive balance out to driver bank (ADR-0010 extension)
  'manual_adjustment'             -- signed; admin only, reason required
);
create type ledger_actor as enum ('system','admin','agent','payment_webhook');

create table driver_ledger_entries (              -- APPEND-ONLY. Balance = sum(amount). (§4.4.1, FM12)
  id bigserial primary key,
  driver_id uuid not null references drivers(id),
  trip_id uuid references trips(id),
  trip_extension_id uuid references trip_extensions(id),
  settlement_id uuid,                             -- fk below
  entry_type ledger_entry_type not null,
  amount numeric(12,2) not null,                  -- sign convention: + credits driver (reduces debt), − debits (increases debt)
  currency char(3) not null,
  balance_after numeric(12,2) not null,           -- running total computed under advisory lock; immutable snapshot, never mutated
  created_by_type ledger_actor not null, created_by_id uuid,
  idempotency_key text not null unique,           -- e.g. 'trip:{id}:commission', 'paystack:{ref}', 'ext:{id}'
  memo text,
  created_at timestamptz not null default now(),
  check ((entry_type in ('cash_commission_debit','deposit_drawdown','payout_debit') and amount < 0)
      or (entry_type in ('digital_settlement_credit','onboarding_deposit') and amount > 0)
      or (entry_type = 'manual_adjustment' and amount <> 0 and memo is not null))
);
create index dle_driver_created on driver_ledger_entries(driver_id, created_at desc);
create trigger dle_ro before update or delete on driver_ledger_entries for each row execute function forbid_mutation();

create or replace view driver_balances as
  select driver_id, currency, sum(amount) as balance, max(created_at) as as_of
  from driver_ledger_entries group by driver_id, currency;

create table settlement_agents (                  -- POS / mobile-money agents (§4.4.1)
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id),
  city_id uuid not null references cities(id),
  business_name text not null,
  location geography(Point,4326),
  active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create type settlement_channel as enum ('paystack_transfer','paystack_ussd','paystack_card','agent_cash','bank_manual');
create type settlement_status as enum ('pending','confirmed','failed','expired');

create table settlements (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  amount numeric(12,2) not null check (amount > 0), currency char(3) not null,
  channel settlement_channel not null,
  status settlement_status not null default 'pending',
  provider_reference text unique,                 -- Paystack reference
  agent_id uuid references settlement_agents(id),
  agent_code text unique,                         -- 6-char code shown by driver to agent; expires
  ledger_entry_id bigint references driver_ledger_entries(id),
  created_at timestamptz not null default now(), confirmed_at timestamptz, expires_at timestamptz
);
alter table driver_ledger_entries add constraint dle_settlement_fk foreign key (settlement_id) references settlements(id);
alter table trip_extensions add constraint te_ledger_fk foreign key (ledger_entry_id) references driver_ledger_entries(id);

create table payments (                           -- digital payments to a driver, split at source (ADR-0010/0014); driver-centric, trip/rider optional (QR + web)
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  trip_id uuid references trips(id),              -- null for unattributed QR / web payments
  rider_id uuid references riders(id),            -- null for anonymous web payers
  source text not null check (source in ('app_trip','qr_static','qr_dynamic','web_anonymous')),
  channel text not null check (channel in ('app','web')),
  amount numeric(12,2) not null, currency char(3) not null,
  commission_amount numeric(12,2) not null, driver_amount numeric(12,2) not null, -- driver_amount = amount − commission, to the minor unit
  fee_bearer text not null check (fee_bearer in ('account','subaccount')),
  provider_fee numeric(12,2),                     -- from webhook
  provider text not null, provider_reference text not null unique,
  method text not null,                           -- 'card','bank_transfer','ussd','wallet'
  status text not null check (status in ('initiated','pending','succeeded','failed','expired','refunded')),
  payer_phone_e164 text,                          -- anonymous web receipt, consented, optional
  created_at timestamptz not null default now(), confirmed_at timestamptz
);
create index payments_driver_created on payments(driver_id, created_at desc);
create unique index payments_one_success_per_trip on payments(trip_id) where trip_id is not null and status = 'succeeded';

create table rider_payment_methods (              -- saved provider authorisations; tokens only, never card data (doc 14 §5)
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id) on delete cascade,
  provider text not null default 'paystack',
  authorization_code text not null,               -- never exposed to clients; view returns brand/last4 only
  brand text, last4 text, exp_month smallint, exp_year smallint, bank text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (rider_id, authorization_code)
);
create unique index rider_payment_methods_default on rider_payment_methods(rider_id) where is_default;
create table private.payment_webhook_raw (id bigserial primary key, provider text, received_at timestamptz default now(), signature_ok boolean, body jsonb);

create table driver_standing_transitions (        -- §4.4.3 append-only
  id bigserial primary key,
  driver_id uuid not null references drivers(id),
  from_standing driver_standing, to_standing driver_standing not null,
  actor_type actor_type not null, actor_id uuid,
  reason text not null,
  balance_at numeric(12,2),
  created_at timestamptz not null default now()
);
create trigger dst_ro before update or delete on driver_standing_transitions for each row execute function forbid_mutation();

create type guarantor_type as enum ('fellow_driver','vehicle_owner');

create table guarantors (                         -- §4.4.4 notification only; no automatic deduction
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id),
  guarantor_type guarantor_type not null,
  guarantor_profile_id uuid references profiles(id),
  guarantor_name text not null, guarantor_phone_e164 text not null,
  acknowledged_at timestamptz,                    -- guarantor confirmed via OTP link
  last_notified_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
```
> RLS: `driver_ledger_entries` — driver select own; `finance/ops_lead` select in scope; **no client insert** (only `ledger_post()` security definer). `settlements` — driver select/insert-via-RPC own; agents select rows with their `agent_id`; finance all. `payments` — rider own select, driver own select (`driver_id`); writes by Edge functions/webhook only (doc 14). `rider_payment_methods` — rider select own via a view that omits `authorization_code`; writes by Edge only. `driver_standing_transitions` — driver own select; admins. `guarantors` — driver own; admins.

---

## 10. Integrity (fraud/anomaly) — §4.4.2

```sql
create type flag_type as enum ('premature_conversion','undeclared_extension','route_deviation','profile_price_mismatch');
create type flag_status as enum ('open','cleared','actioned');
create type trace_quality as enum ('none','partial','good');

create table trip_reconciliation_flags (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  driver_id uuid not null references drivers(id),
  flag_type flag_type not null,
  score numeric(5,4) not null,                    -- 0..1 explainable heuristic score
  evidence jsonb not null,                        -- {"driver_trace":{"quality":"good","reached_dest_m":45,"route_fraction":0.93},"rider_trace":{...},"corroborating_rider_count":2,"distance_beyond_alighting_m":0}
  rider_trace_quality trace_quality not null,
  corroborating_rider_count smallint not null default 0,
  status flag_status not null default 'open',
  reviewed_by uuid references admin_users(id), reviewed_at timestamptz, review_note text,
  created_at timestamptz not null default now(),
  unique (trip_id, flag_type)
);
create index trf_queue on trip_reconciliation_flags(status, score desc) where status = 'open';

create table driver_risk_scores (
  driver_id uuid not null references drivers(id),
  window_start date not null, window_end date not null,
  trips_matched int not null, cancels_after_match int not null, cash_cancels_after_match int not null,
  cancel_after_match_rate numeric(5,4) not null,
  open_flags int not null, actioned_flags int not null,
  computed_at timestamptz not null default now(),
  primary key (driver_id, window_start)
);
```
> RLS: admins `safety/ops_lead/finance` only. Never wired to automatic status change (FM13) — `transition_standing()` requires `actor_type in ('admin','system-grace')` and the only `system` transitions are threshold-based on ledger balance, never on flags.

---

## 11. Safety & day planner

```sql
create table ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id),
  rater_profile_id uuid not null references profiles(id),
  ratee_profile_id uuid not null references profiles(id),
  rater_role text not null check (rater_role in ('rider','driver')),
  score smallint not null check (score between 1 and 5),
  tags text[] not null default '{}',              -- config-driven vocab: 'safe_driving','fair_fare','clean_vehicle',...
  comment text check (char_length(comment) <= 280),
  created_at timestamptz not null default now(),
  unique (trip_id, rater_profile_id)
);

create table trip_shares (                        -- Phase 5 link-based sharing
  id uuid primary key default gen_random_uuid(),
  journey_id uuid not null references journeys(id),
  rider_id uuid not null references riders(id),
  token_hash bytea not null unique,               -- sha256(token); token only ever returned once
  contact_name text, contact_phone_e164 text,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create type sos_status as enum ('open','acknowledged','resolved','false_alarm');

create table sos_alerts (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references trips(id), journey_id uuid references journeys(id),
  raised_by uuid not null references profiles(id), raised_role text not null check (raised_role in ('rider','driver')),
  location geography(Point,4326) not null, accuracy_m numeric(6,1),
  status sos_status not null default 'open',
  acknowledged_by uuid references admin_users(id), acknowledged_at timestamptz,
  resolved_at timestamptz, resolution_note text,
  created_at timestamptz not null default now()
);
create index sos_open on sos_alerts(created_at) where status in ('open','acknowledged');

create type incident_type as enum ('safety','fare_dispute','vehicle_quality','driver_behavior','rider_behavior','lost_item','other');
create type incident_status as enum ('open','triaged','resolved','dismissed');

create table incidents (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references trips(id),
  type incident_type not null, severity smallint not null default 2 check (severity between 1 and 4),
  status incident_status not null default 'open',
  reported_by uuid not null references profiles(id), reported_role text not null,
  description text check (char_length(description) <= 2000),
  attachment_paths text[] not null default '{}',  -- private bucket 'incidents'
  assigned_to uuid references admin_users(id),
  reported_at timestamptz not null default now(), resolved_at timestamptz, resolution_note text,
  updated_at timestamptz not null default now()
);

create type itinerary_status as enum ('active','completed','abandoned');
create type stop_status as enum ('pending','in_progress','completed','skipped');

create table itineraries (                        -- §4.10
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id),
  status itinerary_status not null default 'active',
  plan_date date not null default current_date,
  load_flagged boolean not null default false, load_size load_size, load_note text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table itinerary_stops (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references itineraries(id) on delete cascade,
  sequence int not null,
  destination_description text not null,
  destination_location geography(Point,4326),     -- null until resolved (NL entry)
  target_time timestamptz,                        -- informational; never a booking (FM23)
  status stop_status not null default 'pending',
  linked_journey_id uuid references journeys(id), -- spec's linked_trip_id, generalized (ADR-0003)
  prepared_plan jsonb,                            -- next-stage candidates precomputed when previous stop nears completion
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (itinerary_id, sequence)
);
alter table journeys add constraint journeys_stop_fk foreign key (itinerary_stop_id) references itinerary_stops(id);
```
> RLS: `ratings` — rater insert via RPC, party select. `trip_shares` — rider own; public read only via `shared_trip_view(token)` security definer RPC. `sos_alerts` — raiser select own; `safety/ops_lead` all in scope. `incidents` — reporter select own; `safety/ops_*` in scope. `itineraries/itinerary_stops` — rider own.

---

## 12. Intelligence (§4.5.3, §4.5.4)

```sql
create table job_runs (
  id uuid primary key default gen_random_uuid(),
  job_name text not null, started_at timestamptz not null default now(), finished_at timestamptz,
  status text not null default 'running' check (status in ('running','succeeded','failed')),
  params jsonb, stats jsonb, error text
);
alter table data_sources add constraint data_sources_job_fk foreign key (job_run_id) references job_runs(id);

create table candidate_park_clusters (            -- output of cluster_candidate_parks() (ST_ClusterDBSCAN)
  id uuid primary key default gen_random_uuid(),
  job_run_id uuid not null references job_runs(id),
  city_id uuid not null references cities(id),
  centroid geography(Point,4326) not null,
  distinct_driver_count int not null, distinct_day_count int not null, sample_count int not null,
  first_seen timestamptz not null, last_seen timestamptz not null,
  status text not null default 'new' check (status in ('new','promoted_to_stage','dismissed')),
  route_stage_id uuid references route_stages(id),
  reviewed_by uuid references admin_users(id), reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table matched_traces (                     -- map-matched (OSRM Match) versions of trip paths (FM27)
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references trips(id), actor_type actor_type not null,
  geometry geography(LineString,4326) not null,
  confidence numeric(4,3) not null,
  osm_way_ids bigint[] not null default '{}',
  match_meta jsonb,
  created_at timestamptz not null default now(),
  unique (trip_id, actor_type)
);

create table road_geometry_corrections (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  geometry geography(LineString,4326) not null,
  supporting_trace_count int not null,
  status text not null default 'candidate' check (status in ('candidate','internal_applied','reviewed_for_osm','submitted_osm','rejected')),
  reviewed_by uuid references admin_users(id), reviewed_at timestamptz, osm_changeset_id text,
  created_at timestamptz not null default now()
);

create table route_inference_candidates (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  mode_code text references mode_config(code),
  geometry geography(LineString,4326) not null,
  origin_cluster geography(Point,4326), destination_cluster geography(Point,4326),
  supporting_trip_count int not null,
  status text not null default 'new' check (status in ('new','promoted_to_route','dismissed')),
  route_id uuid references routes(id),
  reviewed_by uuid references admin_users(id), reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table segment_speed_profiles (             -- historical baseline for ETA calibration (§4.5.4 output 3)
  segment_key text not null,                      -- '{osm_way_id}:{direction}'
  city_id uuid not null references cities(id),
  dow_bucket smallint not null check (dow_bucket in (0,1)),   -- 0 weekday, 1 weekend
  hour_bucket smallint not null check (hour_bucket between 0 and 23),
  median_speed_mps numeric(5,2) not null, p85_speed_mps numeric(5,2), sample_count int not null,
  updated_at timestamptz not null default now(),
  primary key (segment_key, dow_bucket, hour_bucket)
);
```
> RLS: admins only (`ops_lead`, `analyst`, `superadmin`); writes by jobs (service role).

---

## 13. B2B / B2G / revenue hooks (§4.14, Phase 8+) — create in Phase 8 migrations, listed here so nothing is retrofitted

```sql
create table corporate_accounts (id, deployment_id, name, billing_email, billing_address, status ('active','suspended'), monthly_budget numeric, currency, created_at, updated_at);
create table corporate_members (corporate_account_id, rider_id, employee_ref, department, active, since, pk(corporate_account_id, rider_id));
create table corporate_trip_policies (id, corporate_account_id, name, subsidy_pct numeric(5,4), max_per_trip numeric, allowed_hours jsonb, allowed_zones geography(MultiPolygon), active);
create table corporate_trip_allocations (id, trip_id unique, corporate_account_id, policy_id, subsidized_amount, created_at);   -- reconciles against trips
create table corporate_invoices (id, corporate_account_id, period_start, period_end, total, currency, status, generated_at);
create table invoice_lines (id, invoice_id, allocation_id, amount);
create table operator_accounts (id, deployment_id, type ('park','union','vehicle_owner','corporate'), name, subscription_tier, billing_status, created_at);
create table operator_members (operator_account_id, driver_id, role, since, pk);
create table sponsored_placements (id, deployment_id, context_type ('destination','park','corridor'), target_reference uuid, advertiser, content jsonb, active_from, active_to, created_at);   -- FM39: no rider_id anywhere
create table placement_counters (placement_id, day date, impressions int, taps int, pk(placement_id, day));                     -- aggregate only
create table api_keys (id, owner_organization, key_hash bytea unique, scope text[], rate_limit_per_min int, created_at, revoked_at);
create table api_usage (api_key_id, day date, calls int, pk);
```
> RLS: `corporate_admin` scoped to own account; `operator_viewer` scoped to own operator; all others admin-only. Placements/API expose only aggregates (FM39/FM40).

---

## 14. Field data (Phase 0, doc 13)

```sql
create table field_submissions (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id), corridor_id uuid references corridors(id),
  scout_profile_id uuid not null references profiles(id),
  form_id text not null, form_version text not null,     -- ODK form identity
  submission_uid text not null unique,                    -- ODK instanceID
  payload jsonb not null,                                 -- raw
  gpx_storage_path text,
  entity_type text not null check (entity_type in ('park','route','stage','leg_fare','through_fare')),
  entity_key text not null,                               -- deterministic key for matching scout A vs B, e.g. 'route:lugbe-area1:keke:stage:3'
  submitted_at timestamptz not null,
  status text not null default 'received' check (status in ('received','reconciled','published','rejected')),
  created_at timestamptz not null default now()
);
create index field_submissions_key on field_submissions(entity_key, status);

create table field_reconciliations (              -- two-scout reconciliation (Phase 0 gate)
  id uuid primary key default gen_random_uuid(),
  entity_type text not null, entity_key text not null,
  submission_a uuid not null references field_submissions(id),
  submission_b uuid references field_submissions(id),
  submission_c uuid references field_submissions(id),      -- third check on discrepancy
  variance jsonb,                                          -- {"location_m":145,"fare_pct":0.2}
  status text not null default 'awaiting_second' check (status in ('awaiting_second','matched','discrepant','resolved','rejected')),
  resolved_by uuid references admin_users(id), resolved_at timestamptz, resolution jsonb,
  published_target_type text, published_target_id uuid,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table data_sources add constraint data_sources_field_fk foreign key (field_submission_id) references field_submissions(id);
```
> RLS: scouts (a `profiles` flag `is_field_agent` via `field_agents` table: id, city_id, active) insert own; `ops_*` select/update in scope.

---

## 15. Audit & notifications

```sql
create table audit_log (                          -- Phase 6 gate: every admin write logged; append-only
  id bigserial primary key,
  actor_id uuid, actor_role text,
  action text not null,                           -- 'update','insert','delete','rpc:approve_verification'
  target_type text not null, target_id text,
  before jsonb, after jsonb,
  ip inet, user_agent text,
  created_at timestamptz not null default now()
);
create trigger audit_log_ro before update or delete on audit_log for each row execute function forbid_mutation();
-- trigger audit_admin_write() attached to: app_config, mode_config, cities, corridors, parks, routes, route_stages, route_legs, route_through_fares, drivers (standing/verified cols), driver_verifications, fare_corrections, trip_reconciliation_flags, incidents, sos_alerts, settlements, driver_ledger_entries(manual), admin_users, deployments, countries, sponsored_placements, api_keys

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  type text not null,                             -- 'trip_request','trip_accepted','trip_declined','na_me_pairing','settlement_confirmed','standing_changed','guarantor_referral', ...
  payload jsonb not null,
  channels text[] not null default '{push}',      -- push | sms | inapp
  sent_at timestamptz, read_at timestamptz,
  created_at timestamptz not null default now()
);
```

---

## 16. RLS policy matrix (summary — policies are defined inline in migrations; `backend/db/policies/*.sql` is the generated per-table snapshot (ADR-0015); tested in pgTAP)

Legend: **O** own rows · **P** party to trip/journey · **S** admin in city scope · **R** specific admin roles · **F** function/RPC only · **—** none · **T** Tier-A aggregate view only

| Table | anon | rider | driver | agent | verifier | safety | ops_agent | ops_lead | finance | analyst | superadmin |
|---|---|---|---|---|---|---|---|---|---|---|---|
| countries/cities/corridors/mode_config/app_config | — | sel | sel | sel | sel | sel | sel | sel+wr(S) | sel | sel | all |
| profiles | — | O | O | O | S | S | S | S | S | — | all |
| riders | — | O | — | — | — | S | S | S | S | agg | all |
| drivers | — | — | O (limited cols) | — | S (verif cols via F) | S | S | S+standing via F | S | agg | all |
| vehicles | — | — | O-linked | — | S | S | S | S | — | — | all |
| driver_verifications | — | — | O (view) | — | S all | — | S sel | S all | — | — | all |
| private.* | — | — | — | — | — | — | — | — | — | — | service |
| parks/routes/stages/legs/through_fares/transfer_points | — | sel | sel | — | — | sel | S wr(F) | S wr | sel | sel | all |
| graph_confirmations / fare_corrections | — | F ins, O sel | F ins, O sel | — | — | — | S | S | — | agg | all |
| driver_route_profiles/stops | — | — | O all | — | — | — | S sel | S sel | — | — | all |
| driver_presence | — | **T** | O sel | — | — | S sel | S sel | S sel | — | — | all |
| driver_presence_history | — | — | — | — | — | — | — | agg | — | agg | all |
| fare_quotes | — | O | O | — | — | — | S | S | S | — | all |
| planner_queries / coverage_gap_reports | — | F | — | — | — | — | — | S | — | S | all |
| journeys | — | O | — | — | — | S | S | S | — | agg | all |
| trips | — | O | O (view) | — | — | S | S | S | S | agg | all |
| trip_events | — | P | P | — | — | S | S | S | S | — | all |
| trip_location_samples | — | F ins | F ins | — | — | S | — | S | S | — | all |
| trip_extensions / negotiations / rounds | — | P | P | — | — | S | S | S | S | — | all |
| driver_ledger_entries | — | — | O sel | — | — | — | — | S sel | S sel | agg | all |
| settlements | — | — | O | O(agent rows) | — | — | — | S | S all | — | all |
| payments | — | O sel | O sel (driver_id) | — | — | — | — | S | S | agg | all |
| rider_payment_methods | — | O (view: brand/last4 only) | — | — | — | — | — | — | — | — | service |
| driver_standing_transitions | — | — | O sel | — | — | S | S | S | S | — | all |
| guarantors | — | — | O | — | — | — | S | S | — | — | all |
| trip_reconciliation_flags / driver_risk_scores | — | — | — | — | — | S | — | S | S | — | all |
| ratings | — | P | P | — | — | S | S | S | — | agg | all |
| trip_shares | tokenF | O | — | — | — | S | S | S | — | — | all |
| sos_alerts | — | O | O | — | — | S all | — | S | — | — | all |
| incidents | — | O | O | — | — | S all | S | S | — | — | all |
| itineraries/stops | — | O | — | — | — | — | — | S | — | — | all |
| intelligence tables | — | — | — | — | — | — | — | S | — | S | all |
| field_submissions/reconciliations | — | — | — | — | — | — | S | S | — | — | all |
| audit_log | — | — | — | — | — | — | — | S sel | S sel | — | all |
| notifications / device_tokens | — | O | O | O | — | — | — | — | — | — | all |

**Non-negotiables enforced by pgTAP (doc 10, TS-RLS-*)**: every table has RLS enabled; no table grants `insert/update/delete` to `authenticated` without a policy; `driver_presence` has zero rider-readable policies; `driver_ledger_entries`/`trip_events`/`graph_revisions`/`audit_log`/`driver_standing_transitions` reject `update`/`delete` even for superadmin; `private` schema has no grants to `anon`/`authenticated`.

---

## 17. Seed data requirements

- `seed_core.sql`: `deployments` (Along NG), `countries` (NG: NGN, 2 minor units, ₦, +234, Africa/Lagos, verification_schema for nin/drivers_license/vehicle_particulars, `regulatory_flags = {"women_only_matching": true}` — **enabled at launch, product-owner decision 2026-09-04**), `mode_config` (4 rows), Na Me palettes. **No global `app_config` rows** — defaults are registered by migrations via `config_default()` (ADR-0016); the seed may add only scoped overrides for seeded entities (NG `sos.emergency_number`), also via `config_default()`. `commission.rate = 0.075` (**confirmed by product owner**) is therefore a migration default, editable only through A-09 → `admin_set_config`, audited, scoped per city if ever needed.
- `seed_abuja_pilot/`: `cities` (abuja), `corridors` (lugbe-area1, nyanya-cbd, kubwa-wuse), backbone `parks`, `routes` per mode where field data exists, `route_stages`, `route_legs`, `route_through_fares`, `transfer_points` — all with `source_type='field_agent'` and `field_verified` only when a reconciliation record exists (Phase 0 gate).
- `seed_testcity_fixture/`: fictional city **"Zaria-Test"** (real coordinates, fictional parks) with one corridor, 2 modes, 5 stages, deliberately different `app_config` overrides (`commission.rate`, `graph.snap_radius_m`) — exists to prove FM5 in CI. Never deployed to prod.
- `seed_test_scenarios/`: fixtures for every TS-* scenario in doc 10 (mid-route boarding, direct-vs-multileg, collusion, negotiation ETA bands, threshold block, premature conversion with/without rider trace, multi-rider corroboration, cluster false positive).
