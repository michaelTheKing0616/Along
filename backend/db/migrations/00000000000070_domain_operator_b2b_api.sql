-- P8-A-03: operator accounts, sponsored placements, api keys + aggregate endpoints (doc 02 §13, FM39/FM40)

select config_default('api.default_rate_limit_per_min', '60');
select config_default('api.max_page_size', '50');
select config_default('placements.enabled', 'false');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'api.default_rate_limit_per_min',
    '{"type":"integer","minimum":1,"maximum":10000}',
    'Default per-minute call cap for data API keys when not overridden on the key row',
    array['global']::config_scope[],
    false
  ),
  (
    'api.max_page_size',
    '{"type":"integer","minimum":1,"maximum":200}',
    'Maximum page size for aggregate API product responses',
    array['global']::config_scope[],
    false
  ),
  (
    'placements.enabled',
    '{"type":"boolean"}',
    'Master switch for contextual sponsored placements (P8-B-01 UI reads this; FM39 boundary unchanged)',
    array['global','city']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Types + tables (doc 02 §13)
-- ---------------------------------------------------------------------------
create type operator_account_type as enum ('park', 'union', 'vehicle_owner', 'corporate');
create type operator_billing_status as enum ('active', 'suspended');
create type placement_context_type as enum ('destination', 'park', 'corridor');

create table operator_accounts (
  id uuid primary key default gen_random_uuid(),
  deployment_id uuid not null references deployments(id),
  type operator_account_type not null,
  name text not null check (char_length(btrim(name)) between 1 and 200),
  subscription_tier text not null default 'basic'
    check (subscription_tier in ('basic', 'standard', 'premium')),
  billing_status operator_billing_status not null default 'active',
  created_at timestamptz not null default now()
);

create index operator_accounts_deployment on operator_accounts(deployment_id);

create table operator_members (
  operator_account_id uuid not null references operator_accounts(id) on delete cascade,
  driver_id uuid not null references drivers(id) on delete cascade,
  role text not null default 'member' check (char_length(btrim(role)) between 1 and 50),
  since timestamptz not null default now(),
  primary key (operator_account_id, driver_id)
);

create index operator_members_driver on operator_members(driver_id);

create table sponsored_placements (
  id uuid primary key default gen_random_uuid(),
  deployment_id uuid not null references deployments(id),
  context_type placement_context_type not null,
  target_reference uuid not null,
  advertiser text not null check (char_length(btrim(advertiser)) between 1 and 200),
  content jsonb not null default '{}'::jsonb,
  active_from timestamptz not null,
  active_to timestamptz not null check (active_to > active_from),
  created_at timestamptz not null default now()
);

create index sponsored_placements_context
  on sponsored_placements(deployment_id, context_type, target_reference, active_from, active_to);

create table placement_counters (
  placement_id uuid not null references sponsored_placements(id) on delete cascade,
  day date not null,
  impressions int not null default 0 check (impressions >= 0),
  taps int not null default 0 check (taps >= 0),
  primary key (placement_id, day)
);

create table api_keys (
  id uuid primary key default gen_random_uuid(),
  owner_organization text not null check (char_length(btrim(owner_organization)) between 1 and 200),
  key_hash bytea not null unique,
  scope text[] not null check (array_length(scope, 1) >= 1),
  rate_limit_per_min int not null check (rate_limit_per_min >= 1),
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  check (scope <@ array['od_cells', 'placement_stats']::text[])
);

create index api_keys_active on api_keys(id) where revoked_at is null;

create table api_usage (
  api_key_id uuid not null references api_keys(id) on delete cascade,
  day date not null,
  calls int not null default 0 check (calls >= 0),
  primary key (api_key_id, day)
);

create table private.api_rate_windows (
  api_key_id uuid not null references public.api_keys(id) on delete cascade,
  window_start timestamptz not null,
  call_count int not null default 0 check (call_count >= 0),
  primary key (api_key_id, window_start)
);

revoke all on private.api_rate_windows from anon, authenticated;
alter table private.api_rate_windows enable row level security;

-- operator_viewer scoping (doc 02 §13 RLS)
alter table admin_users
  add column if not exists operator_account_id uuid references operator_accounts(id);

create index admin_users_operator_account
  on admin_users(operator_account_id)
  where operator_account_id is not null;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function admin_operator_account_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.operator_account_id
  from admin_users a
  where a.id = auth.uid()
    and a.disabled_at is null
    and a.role = 'operator_viewer'
$$;

create or replace function private.hash_api_key(p_raw_key text)
returns bytea
language sql
immutable
set search_path = public, extensions
as $$
  select digest(btrim(p_raw_key), 'sha256')
$$;

revoke all on function private.hash_api_key(text) from public;
grant execute on function private.hash_api_key(text) to service_role;

create or replace function private.verify_api_key(p_raw_key text)
returns api_keys
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_key api_keys%rowtype;
begin
  if p_raw_key is null or btrim(p_raw_key) = '' then
    raise exception using errcode = 'P0001', message = 'ALONG:UNAUTHENTICATED';
  end if;

  select * into v_key
  from api_keys k
  where k.key_hash = private.hash_api_key(p_raw_key)
    and k.revoked_at is null;

  if v_key.id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  return v_key;
end;
$$;

revoke all on function private.verify_api_key(text) from public;
grant execute on function private.verify_api_key(text) to service_role;

create or replace function private.api_enforce_rate_limit(p_key api_keys)
returns void
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_window timestamptz := date_trunc('minute', now());
  v_limit int := coalesce(p_key.rate_limit_per_min, cfg_num('api.default_rate_limit_per_min')::int);
  v_count int;
begin
  insert into private.api_rate_windows as w (api_key_id, window_start, call_count)
  values (p_key.id, v_window, 1)
  on conflict (api_key_id, window_start)
  do update set call_count = w.call_count + 1
  returning call_count into v_count;

  if v_count > v_limit then
    raise exception using errcode = 'P0001', message = 'ALONG:RATE_LIMITED';
  end if;

  insert into api_usage as u (api_key_id, day, calls)
  values (p_key.id, current_date, 1)
  on conflict (api_key_id, day)
  do update set calls = u.calls + 1;
end;
$$;

revoke all on function private.api_enforce_rate_limit(api_keys) from public;
grant execute on function private.api_enforce_rate_limit(api_keys) to service_role;

-- FM39: contextual placement resolution — no rider/trip/journey dependency
create or replace function resolve_sponsored_placements(
  p_context_type placement_context_type,
  p_target_reference uuid,
  p_deployment_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_deployment uuid := p_deployment_id;
begin
  if p_target_reference is null then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if v_deployment is null then
    select d.id into v_deployment
    from deployments d
    order by d.created_at
    limit 1;
  end if;

  if coalesce((cfg('placements.enabled'))::text = 'true', false) is not true then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', sp.id,
          'context_type', sp.context_type,
          'target_reference', sp.target_reference,
          'advertiser', sp.advertiser,
          'content', sp.content,
          'active_from', sp.active_from,
          'active_to', sp.active_to
        )
        order by sp.active_from desc
      )
      from sponsored_placements sp
      where sp.deployment_id = v_deployment
        and sp.context_type = p_context_type
        and sp.target_reference = p_target_reference
        and sp.active_from <= now()
        and sp.active_to > now()
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function resolve_sponsored_placements(placement_context_type, uuid, uuid) from public;
grant execute on function resolve_sponsored_placements(placement_context_type, uuid, uuid) to anon, authenticated, service_role;

create or replace function record_placement_counter(
  p_placement_id uuid,
  p_metric text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_metric not in ('impression', 'tap') then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if not exists (select 1 from sponsored_placements sp where sp.id = p_placement_id) then
    raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
  end if;

  insert into placement_counters as pc (placement_id, day, impressions, taps)
  values (
    p_placement_id,
    current_date,
    case when p_metric = 'impression' then 1 else 0 end,
    case when p_metric = 'tap' then 1 else 0 end
  )
  on conflict (placement_id, day)
  do update set
    impressions = pc.impressions + case when p_metric = 'impression' then 1 else 0 end,
    taps = pc.taps + case when p_metric = 'tap' then 1 else 0 end;
end;
$$;

revoke all on function record_placement_counter(uuid, text) from public;
grant execute on function record_placement_counter(uuid, text) to service_role;

-- Operator-scoped aggregates (no rider identity)
create or replace function operator_driver_aggregates(
  p_from timestamptz,
  p_to timestamptz
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_operator_id uuid;
  v_max_window_days numeric;
  v_fare_tol_pct numeric;
  v_driver_count int;
  v_trips_completed int;
  v_fare_discrepancies int;
  v_fare_confirmations int;
begin
  if p_from is null or p_to is null or p_to <= p_from then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  v_operator_id := admin_operator_account_id();

  if v_operator_id is null and not has_admin_role(array['superadmin', 'ops_lead', 'analyst']) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if v_operator_id is null and has_admin_role(array['superadmin', 'ops_lead', 'analyst']) then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  v_max_window_days := cfg_num('analytics.max_window_days');
  if p_to - p_from > make_interval(days => v_max_window_days::int) then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  v_fare_tol_pct := cfg_num('promotion.fare_tolerance_pct');

  select count(*)::int into v_driver_count
  from operator_members om
  where om.operator_account_id = v_operator_id;

  select
    count(*) filter (where t.status = 'completed')::int,
    count(*) filter (
      where t.fare_reported_paid is not null
        and t.fare_shown > 0
        and abs(t.fare_reported_paid - t.fare_shown) / t.fare_shown * 100.0 > v_fare_tol_pct
    )::int,
    count(*) filter (
      where t.fare_reported_paid is not null and t.fare_shown > 0
    )::int
  into v_trips_completed, v_fare_discrepancies, v_fare_confirmations
  from trips t
  join operator_members om on om.driver_id = t.driver_id
  where om.operator_account_id = v_operator_id
    and t.requested_at >= p_from
    and t.requested_at < p_to;

  return jsonb_build_object(
    'operator_account_id', v_operator_id,
    'from', p_from,
    'to', p_to,
    'driver_count', v_driver_count,
    'trips_completed', v_trips_completed,
    'fare_discrepancy_rate',
      case when v_fare_confirmations > 0
        then round(v_fare_discrepancies::numeric / v_fare_confirmations, 4)
        else null end,
    'aggregate_only', true
  );
end;
$$;

revoke all on function operator_driver_aggregates(timestamptz, timestamptz) from public;
grant execute on function operator_driver_aggregates(timestamptz, timestamptz) to authenticated;

-- Admin RPCs (audited via table triggers)
create or replace function admin_create_api_key(
  p_owner_organization text,
  p_scope text[],
  p_rate_limit_per_min int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_key api_keys%rowtype;
  v_raw text;
  v_limit int;
begin
  if not has_admin_role(array['superadmin', 'ops_lead', 'analyst']) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_owner_organization is null or btrim(p_owner_organization) = '' then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if p_scope is null or array_length(p_scope, 1) is null then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if not (p_scope <@ array['od_cells', 'placement_stats']::text[]) then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  v_limit := coalesce(
    p_rate_limit_per_min,
    cfg_num('api.default_rate_limit_per_min')::int
  );

  v_raw := 'along_' || encode(gen_random_bytes(24), 'hex');

  insert into api_keys (owner_organization, key_hash, scope, rate_limit_per_min)
  values (
    btrim(p_owner_organization),
    private.hash_api_key(v_raw),
    p_scope,
    v_limit
  )
  returning * into v_key;

  return jsonb_build_object(
    'id', v_key.id,
    'owner_organization', v_key.owner_organization,
    'scope', v_key.scope,
    'rate_limit_per_min', v_key.rate_limit_per_min,
    'api_key', v_raw,
    'created_at', v_key.created_at,
    'warning', 'Store api_key now — it cannot be retrieved again.'
  );
end;
$$;

revoke all on function admin_create_api_key(text, text[], int) from public;
grant execute on function admin_create_api_key(text, text[], int) to authenticated;

create or replace function admin_revoke_api_key(p_api_key_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key api_keys%rowtype;
begin
  if not has_admin_role(array['superadmin', 'ops_lead', 'analyst']) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  update api_keys
  set revoked_at = now()
  where id = p_api_key_id
    and revoked_at is null
  returning * into v_key;

  if v_key.id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
  end if;

  return jsonb_build_object('id', v_key.id, 'revoked_at', v_key.revoked_at);
end;
$$;

revoke all on function admin_revoke_api_key(uuid) from public;
grant execute on function admin_revoke_api_key(uuid) to authenticated;

-- FM40: rate-limited aggregate API — anonymized OD cells only
create or replace function api_fetch_od_cells(
  p_api_key text,
  p_export_id uuid,
  p_limit int default null,
  p_cursor text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_key api_keys%rowtype;
  v_limit int;
  v_cursor_id uuid;
  v_cells jsonb;
  v_next_cursor text;
begin
  v_key := private.verify_api_key(p_api_key);

  if not ('od_cells' = any (v_key.scope)) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  perform private.api_enforce_rate_limit(v_key);

  if p_export_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if not exists (select 1 from anonymized_od_exports e where e.id = p_export_id) then
    raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
  end if;

  v_limit := least(
    greatest(coalesce(p_limit, cfg_num('api.max_page_size')::int), 1),
    cfg_num('api.max_page_size')::int
  );

  if p_cursor is not null and btrim(p_cursor) <> '' then
    begin
      v_cursor_id := p_cursor::uuid;
    exception
      when others then
        raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
    end;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'origin_geohash', c.origin_geohash,
        'destination_geohash', c.destination_geohash,
        'mode_code', c.mode_code,
        'dow_bucket', c.dow_bucket,
        'hour_bucket', c.hour_bucket,
        'trip_count', c.trip_count
      )
      order by c.id
    ),
    '[]'::jsonb
  )
  into v_cells
  from (
    select c.*
    from anonymized_od_cells c
    where c.export_id = p_export_id
      and (v_cursor_id is null or c.id > v_cursor_id)
    order by c.id
    limit v_limit
  ) c;

  if jsonb_array_length(v_cells) = v_limit then
    select c.id::text into v_next_cursor
    from anonymized_od_cells c
    where c.export_id = p_export_id
      and (v_cursor_id is null or c.id > v_cursor_id)
    order by c.id
    offset v_limit - 1
    limit 1;
  end if;

  return jsonb_build_object(
    'export_id', p_export_id,
    'cells', v_cells,
    'meta', jsonb_build_object(
      'aggregate_only', true,
      'next_cursor', v_next_cursor,
      'page_size', v_limit
    )
  );
end;
$$;

revoke all on function api_fetch_od_cells(text, uuid, int, text) from public;
grant execute on function api_fetch_od_cells(text, uuid, int, text) to anon, authenticated, service_role;

create or replace function api_fetch_placement_stats(
  p_api_key text,
  p_placement_id uuid,
  p_from date default null,
  p_to date default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_key api_keys%rowtype;
  v_from date := coalesce(p_from, current_date - 30);
  v_to date := coalesce(p_to, current_date);
begin
  v_key := private.verify_api_key(p_api_key);

  if not ('placement_stats' = any (v_key.scope)) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  perform private.api_enforce_rate_limit(v_key);

  if v_to < v_from then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if not exists (select 1 from sponsored_placements sp where sp.id = p_placement_id) then
    raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
  end if;

  return jsonb_build_object(
    'placement_id', p_placement_id,
    'from', v_from,
    'to', v_to,
    'days', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'day', pc.day,
            'impressions', pc.impressions,
            'taps', pc.taps
          )
          order by pc.day
        )
        from placement_counters pc
        where pc.placement_id = p_placement_id
          and pc.day >= v_from
          and pc.day <= v_to
      ),
      '[]'::jsonb
    ),
    'meta', jsonb_build_object('aggregate_only', true)
  );
end;
$$;

revoke all on function api_fetch_placement_stats(text, uuid, date, date) from public;
grant execute on function api_fetch_placement_stats(text, uuid, date, date) to anon, authenticated, service_role;

-- Guard: api keys must never expose raw key material after create
create or replace function private.forbid_api_key_plaintext()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and new.key_hash is distinct from old.key_hash then
    raise exception using errcode = 'P0001', message = 'ALONG:API_KEY_IMMUTABLE';
  end if;
  return new;
end;
$$;

create trigger api_keys_immutable_hash
  before update on api_keys
  for each row execute function private.forbid_api_key_plaintext();

-- ---------------------------------------------------------------------------
-- Audit — admin-writable tables (doc 02 §15)
-- ---------------------------------------------------------------------------
create trigger audit_operator_accounts
  after insert or update or delete on operator_accounts
  for each row execute function audit_admin_write();

create trigger audit_sponsored_placements
  after insert or update or delete on sponsored_placements
  for each row execute function audit_admin_write();

create trigger audit_api_keys
  after insert or update or delete on api_keys
  for each row execute function audit_admin_write();

-- ---------------------------------------------------------------------------
-- RLS (doc 02 §13)
-- ---------------------------------------------------------------------------
alter table operator_accounts enable row level security;
alter table operator_members enable row level security;
alter table sponsored_placements enable row level security;
alter table placement_counters enable row level security;
alter table api_keys enable row level security;
alter table api_usage enable row level security;

create policy operator_accounts_select_admin
  on operator_accounts for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and (
      has_admin_role(array['superadmin'])
      or deployment_id = (
        select a.deployment_id from admin_users a
        where a.id = auth.uid() and a.disabled_at is null
      )
    )
  );

create policy operator_accounts_select_operator_viewer
  on operator_accounts for select to authenticated
  using (id = admin_operator_account_id());

create policy operator_accounts_no_client_write
  on operator_accounts for all to authenticated
  using (false)
  with check (false);

create policy operator_members_select_admin
  on operator_members for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and exists (
      select 1 from operator_accounts oa
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where oa.id = operator_members.operator_account_id
        and oa.deployment_id = au.deployment_id
    )
  );

create policy operator_members_select_operator_viewer
  on operator_members for select to authenticated
  using (operator_account_id = admin_operator_account_id());

create policy operator_members_no_client_write
  on operator_members for all to authenticated
  using (false)
  with check (false);

create policy sponsored_placements_select_admin
  on sponsored_placements for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and (
      has_admin_role(array['superadmin'])
      or deployment_id = (
        select a.deployment_id from admin_users a
        where a.id = auth.uid() and a.disabled_at is null
      )
    )
  );

create policy sponsored_placements_no_client_write
  on sponsored_placements for all to authenticated
  using (false)
  with check (false);

create policy placement_counters_select_admin
  on placement_counters for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
    and exists (
      select 1
      from sponsored_placements sp
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where sp.id = placement_counters.placement_id
        and sp.deployment_id = au.deployment_id
    )
  );

create policy placement_counters_no_client_write
  on placement_counters for all to authenticated
  using (false)
  with check (false);

create policy api_keys_select_admin
  on api_keys for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'analyst']));

create policy api_keys_no_client_write
  on api_keys for all to authenticated
  using (false)
  with check (false);

create policy api_usage_select_admin
  on api_usage for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'analyst'])
  );

create policy api_usage_no_client_write
  on api_usage for all to authenticated
  using (false)
  with check (false);

grant select on operator_accounts to authenticated;
grant select on operator_members to authenticated;
grant select on sponsored_placements to authenticated;
grant select on placement_counters to authenticated;
grant select on api_keys to authenticated;
grant select on api_usage to authenticated;
