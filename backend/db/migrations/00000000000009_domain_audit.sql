-- P0-A-08: doc 02 §15 — audit_log, audit_admin_write() on Phase 0 admin-modifiable tables.

-- audit_log (append-only)
create table audit_log (
  id bigserial primary key,
  actor_id uuid,
  actor_role text,
  action text not null,
  target_type text not null,
  target_id text not null,
  before jsonb,
  after jsonb,
  ip inet,
  user_agent text,
  created_at timestamptz not null default now()
);

create trigger audit_log_ro
  before update or delete on audit_log
  for each row execute function forbid_mutation();

-- Resolve target_id for tables without a uuid `id` primary key.
create or replace function audit_row_target_id(p_row jsonb) returns text
language plpgsql immutable as $$
begin
  if p_row ? 'id' and p_row->>'id' is not null then
    return p_row->>'id';
  end if;
  if p_row ? 'key' then
    return p_row->>'key'
      || ':'
      || coalesce(p_row->>'scope_type', '')
      || ':'
      || coalesce(p_row->>'scope_id', '');
  end if;
  if p_row ? 'code' then
    return p_row->>'code';
  end if;
  return p_row::text;
end;
$$;

create or replace function audit_admin_write() returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_before jsonb;
  v_after jsonb;
  v_target_id text;
begin
  if tg_op = 'DELETE' then
    v_before := to_jsonb(old);
    v_after := null;
    v_target_id := audit_row_target_id(v_before);
  elsif tg_op = 'UPDATE' then
    v_before := to_jsonb(old);
    v_after := to_jsonb(new);
    v_target_id := audit_row_target_id(v_after);
  else
    v_before := null;
    v_after := to_jsonb(new);
    v_target_id := audit_row_target_id(v_after);
  end if;

  select a.role::text into v_actor_role
  from admin_users a
  where a.id = v_actor_id and a.disabled_at is null;

  insert into audit_log (
    actor_id, actor_role, action, target_type, target_id, before, after
  ) values (
    v_actor_id,
    v_actor_role,
    lower(tg_op),
    tg_table_name::text,
    v_target_id,
    v_before,
    v_after
  );

  return coalesce(new, old);
end;
$$;

-- Phase 0 admin-modifiable tables (doc 02 §15 trigger list; skip tables not yet created).
create trigger audit_app_config after insert or update or delete on app_config
  for each row execute function audit_admin_write();
create trigger audit_mode_config after insert or update or delete on mode_config
  for each row execute function audit_admin_write();
create trigger audit_deployments after insert or update or delete on deployments
  for each row execute function audit_admin_write();
create trigger audit_countries after insert or update or delete on countries
  for each row execute function audit_admin_write();
create trigger audit_cities after insert or update or delete on cities
  for each row execute function audit_admin_write();
create trigger audit_corridors after insert or update or delete on corridors
  for each row execute function audit_admin_write();
create trigger audit_parks after insert or update or delete on parks
  for each row execute function audit_admin_write();
create trigger audit_routes after insert or update or delete on routes
  for each row execute function audit_admin_write();
create trigger audit_route_stages after insert or update or delete on route_stages
  for each row execute function audit_admin_write();
create trigger audit_route_legs after insert or update or delete on route_legs
  for each row execute function audit_admin_write();
create trigger audit_route_through_fares after insert or update or delete on route_through_fares
  for each row execute function audit_admin_write();
create trigger audit_admin_users after insert or update or delete on admin_users
  for each row execute function audit_admin_write();
create trigger audit_field_agents after insert or update or delete on field_agents
  for each row execute function audit_admin_write();
create trigger audit_field_submissions after insert or update or delete on field_submissions
  for each row execute function audit_admin_write();
create trigger audit_field_reconciliations after insert or update or delete on field_reconciliations
  for each row execute function audit_admin_write();

-- RLS (doc 02 §16 matrix: ops_lead/finance select; superadmin all; append-only)
alter table audit_log enable row level security;

create policy audit_log_select_ops_lead
  on audit_log for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead']));

create policy audit_log_select_finance
  on audit_log for select to authenticated
  using (has_admin_role(array['finance']));

create policy audit_log_all_superadmin
  on audit_log for all to authenticated
  using (has_admin_role(array['superadmin']))
  with check (has_admin_role(array['superadmin']));

grant select on audit_log to authenticated;
