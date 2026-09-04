-- P0-A-01: doc 02 §1 — extensions, schemas, roles, helpers (admin_users stub + is_admin/has_admin_role;
-- admin_can_access_city deferred to 0002 because it references cities/countries).

create extension if not exists postgis;
create extension if not exists pgcrypto;
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists pg_trgm;
create extension if not exists btree_gist;

create schema if not exists private;
revoke all on schema private from anon, authenticated;

-- Generic helpers
create or replace function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

create or replace function forbid_mutation() returns trigger language plpgsql as $$
begin raise exception 'table % is append-only', tg_table_name using errcode = '42501'; end $$;

create or replace function current_profile_id() returns uuid language sql stable as $$ select auth.uid() $$;

-- STUB ONLY (P0-A-01): minimal admin_users so doc 02 §1 is_admin/has_admin_role compile.
-- P0-A-02 owns reconciliation: replace this stub with full doc 02 §3 admin_users DDL
-- (admin_role enum, profiles FK, deployment_id FK) via DROP+recreate or equivalent.
create table admin_users (
  id uuid primary key,
  role text not null,
  deployment_id uuid,
  city_scope uuid[],
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users a where a.id = auth.uid() and a.disabled_at is null) $$;

create or replace function has_admin_role(roles text[]) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users a where a.id = auth.uid() and a.disabled_at is null and (a.role = any(roles) or a.role = 'superadmin')) $$;
