-- P8-D-01: SECURITY DEFINER RPCs for corporate / operator / revenue admin-console portals

-- ---------------------------------------------------------------------------
-- C-02 roster: per-member default policy assignment
-- ---------------------------------------------------------------------------
alter table corporate_members
  add column if not exists default_policy_id uuid
  references corporate_trip_policies(id) on delete set null;

create index if not exists corporate_members_default_policy
  on corporate_members (default_policy_id)
  where default_policy_id is not null;

-- Prefer member default policy when set and applicable
create or replace function corporate_allocate_trip(p_trip_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_t trips%rowtype;
  v_member corporate_members%rowtype;
  v_account corporate_accounts%rowtype;
  v_policy corporate_trip_policies%rowtype;
  v_best_policy corporate_trip_policies%rowtype;
  v_best_amount numeric := -1;
  v_amount numeric;
  v_total numeric;
  v_allocation_id uuid;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null or v_t.status <> 'completed' then
    return null;
  end if;

  select a.id into v_allocation_id
  from corporate_trip_allocations a
  where a.trip_id = p_trip_id;
  if v_allocation_id is not null then
    return v_allocation_id;
  end if;

  select cm.* into v_member
  from corporate_members cm
  join corporate_accounts ca on ca.id = cm.corporate_account_id
  where cm.rider_id = v_t.rider_id
    and cm.active
    and ca.status = 'active'
  order by cm.since desc
  limit 1;

  if v_member.corporate_account_id is null then
    return null;
  end if;

  select * into v_account
  from corporate_accounts
  where id = v_member.corporate_account_id;

  v_total := v_t.fare_shown + coalesce(v_t.load_surcharge_amount, 0);

  if v_member.default_policy_id is not null then
    select * into v_policy
    from corporate_trip_policies
    where id = v_member.default_policy_id
      and corporate_account_id = v_member.corporate_account_id
      and active;

    if v_policy.id is not null and private.corporate_policy_applies(v_policy, v_t) then
      v_amount := private.corporate_compute_subsidy(v_policy, v_total);
      if v_amount >= 0 then
        insert into corporate_trip_allocations (
          trip_id,
          corporate_account_id,
          policy_id,
          subsidized_amount
        ) values (
          p_trip_id,
          v_member.corporate_account_id,
          v_policy.id,
          v_amount
        )
        on conflict (trip_id) do nothing
        returning id into v_allocation_id;

        return v_allocation_id;
      end if;
    end if;
  end if;

  for v_policy in
    select *
    from corporate_trip_policies
    where corporate_account_id = v_member.corporate_account_id
      and active
  loop
    if private.corporate_policy_applies(v_policy, v_t) then
      v_amount := private.corporate_compute_subsidy(v_policy, v_total);
      if v_amount > v_best_amount then
        v_best_amount := v_amount;
        v_best_policy := v_policy;
      end if;
    end if;
  end loop;

  if v_best_amount < 0 then
    return null;
  end if;

  insert into corporate_trip_allocations (
    trip_id,
    corporate_account_id,
    policy_id,
    subsidized_amount
  ) values (
    p_trip_id,
    v_member.corporate_account_id,
    v_best_policy.id,
    v_best_amount
  )
  on conflict (trip_id) do nothing
  returning id into v_allocation_id;

  return v_allocation_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function private.corporate_caller_account_id(p_account_id uuid default null)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_scoped uuid;
begin
  v_scoped := admin_corporate_account_id();
  if v_scoped is not null then
    if p_account_id is not null and p_account_id <> v_scoped then
      raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
    end if;
    return v_scoped;
  end if;

  if not has_admin_role(array['superadmin', 'finance']) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_account_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  return p_account_id;
end;
$$;

revoke all on function private.corporate_caller_account_id(uuid) from public;

create or replace function private.revenue_admin_roles()
returns text[]
language sql
immutable
as $$
  select array['superadmin', 'finance']::text[]
$$;

-- ---------------------------------------------------------------------------
-- C-01 corporate overview
-- ---------------------------------------------------------------------------
create or replace function corporate_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_account_id uuid;
  v_account corporate_accounts%rowtype;
  v_mtd_start timestamptz := date_trunc('month', now() at time zone 'UTC') at time zone 'UTC';
  v_subsidy_mtd numeric := 0;
  v_enrolled int := 0;
  v_active_trips int := 0;
  v_live_trips jsonb := '[]'::jsonb;
begin
  v_account_id := admin_corporate_account_id();
  if v_account_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  select * into v_account from corporate_accounts where id = v_account_id;

  select coalesce(sum(a.subsidized_amount), 0)
  into v_subsidy_mtd
  from corporate_trip_allocations a
  where a.corporate_account_id = v_account_id
    and a.created_at >= v_mtd_start;

  select count(*)::int into v_enrolled
  from corporate_members cm
  where cm.corporate_account_id = v_account_id
    and cm.active;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'trip_id', t.id,
        'employee_ref', cm.employee_ref,
        'department', cm.department,
        'status', t.status,
        'mode_code', t.mode_code,
        'fare_shown', t.fare_shown,
        'requested_at', t.requested_at
      )
      order by t.requested_at desc
    ),
    '[]'::jsonb
  )
  into v_live_trips
  from trips t
  join corporate_members cm
    on cm.rider_id = t.rider_id
   and cm.corporate_account_id = v_account_id
   and cm.active
  where t.status in ('accepted', 'boarded', 'in_transit');

  v_active_trips := jsonb_array_length(v_live_trips);

  return jsonb_build_object(
    'corporate_account_id', v_account_id,
    'account_name', v_account.name,
    'currency', v_account.currency,
    'monthly_budget', v_account.monthly_budget,
    'subsidy_used_mtd', v_subsidy_mtd,
    'enrolled_staff', v_enrolled,
    'active_staff_trips', v_active_trips,
    'live_trips', v_live_trips
  );
end;
$$;

revoke all on function corporate_overview() from public;
grant execute on function corporate_overview() to authenticated;

-- ---------------------------------------------------------------------------
-- C-02 roster writes
-- ---------------------------------------------------------------------------
create or replace function corporate_invite_member(
  p_phone_e164 text,
  p_department text default null,
  p_employee_ref text default null,
  p_default_policy_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account_id uuid;
  v_rider_id uuid;
  v_policy corporate_trip_policies%rowtype;
begin
  v_account_id := admin_corporate_account_id();
  if v_account_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_phone_e164 is null or btrim(p_phone_e164) = '' then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  select r.id into v_rider_id
  from profiles p
  join riders r on r.id = p.id
  where p.phone_e164 = btrim(p_phone_e164)
  limit 1;

  if v_rider_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
  end if;

  if p_default_policy_id is not null then
    select * into v_policy
    from corporate_trip_policies
    where id = p_default_policy_id
      and corporate_account_id = v_account_id
      and active;
    if v_policy.id is null then
      raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
    end if;
  end if;

  insert into corporate_members (
    corporate_account_id,
    rider_id,
    employee_ref,
    department,
    default_policy_id,
    active
  ) values (
    v_account_id,
    v_rider_id,
    nullif(btrim(p_employee_ref), ''),
    nullif(btrim(p_department), ''),
    p_default_policy_id,
    true
  )
  on conflict (corporate_account_id, rider_id)
  do update set
    employee_ref = coalesce(excluded.employee_ref, corporate_members.employee_ref),
    department = coalesce(excluded.department, corporate_members.department),
    default_policy_id = coalesce(excluded.default_policy_id, corporate_members.default_policy_id),
    active = true
  returning rider_id into v_rider_id;

  return jsonb_build_object(
    'corporate_account_id', v_account_id,
    'rider_id', v_rider_id,
    'status', 'active'
  );
end;
$$;

revoke all on function corporate_invite_member(text, text, text, uuid) from public;
grant execute on function corporate_invite_member(text, text, text, uuid) to authenticated;

create or replace function corporate_update_member(
  p_rider_id uuid,
  p_department text default null,
  p_employee_ref text default null,
  p_default_policy_id uuid default null,
  p_active boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account_id uuid;
  v_member corporate_members%rowtype;
  v_policy corporate_trip_policies%rowtype;
begin
  v_account_id := admin_corporate_account_id();
  if v_account_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_rider_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if p_default_policy_id is not null then
    select * into v_policy
    from corporate_trip_policies
    where id = p_default_policy_id
      and corporate_account_id = v_account_id;
    if v_policy.id is null then
      raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
    end if;
  end if;

  update corporate_members cm
  set
    department = coalesce(nullif(btrim(p_department), ''), cm.department),
    employee_ref = coalesce(nullif(btrim(p_employee_ref), ''), cm.employee_ref),
    default_policy_id = coalesce(p_default_policy_id, cm.default_policy_id),
    active = coalesce(p_active, cm.active)
  where cm.corporate_account_id = v_account_id
    and cm.rider_id = p_rider_id
  returning cm.* into v_member;

  if v_member.rider_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
  end if;

  return jsonb_build_object(
    'rider_id', v_member.rider_id,
    'department', v_member.department,
    'employee_ref', v_member.employee_ref,
    'default_policy_id', v_member.default_policy_id,
    'active', v_member.active
  );
end;
$$;

revoke all on function corporate_update_member(uuid, text, text, uuid, boolean) from public;
grant execute on function corporate_update_member(uuid, text, text, uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- C-03 policy writes
-- ---------------------------------------------------------------------------
create or replace function corporate_upsert_policy(
  p_name text,
  p_subsidy_pct numeric,
  p_id uuid default null,
  p_max_per_trip numeric default null,
  p_allowed_hours jsonb default null,
  p_active boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account_id uuid;
  v_policy corporate_trip_policies%rowtype;
begin
  v_account_id := admin_corporate_account_id();
  if v_account_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_name is null or btrim(p_name) = '' or p_subsidy_pct is null then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if p_subsidy_pct <= 0 or p_subsidy_pct > 1 then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  if p_id is null then
    insert into corporate_trip_policies (
      corporate_account_id,
      name,
      subsidy_pct,
      max_per_trip,
      allowed_hours,
      active
    ) values (
      v_account_id,
      btrim(p_name),
      p_subsidy_pct,
      p_max_per_trip,
      p_allowed_hours,
      coalesce(p_active, true)
    )
    returning * into v_policy;
  else
    update corporate_trip_policies ctp
    set
      name = btrim(p_name),
      subsidy_pct = p_subsidy_pct,
      max_per_trip = p_max_per_trip,
      allowed_hours = coalesce(p_allowed_hours, ctp.allowed_hours),
      active = coalesce(p_active, ctp.active)
    where ctp.id = p_id
      and ctp.corporate_account_id = v_account_id
    returning ctp.* into v_policy;

    if v_policy.id is null then
      raise exception using errcode = 'P0001', message = 'ALONG:NOT_FOUND';
    end if;
  end if;

  return jsonb_build_object(
    'id', v_policy.id,
    'name', v_policy.name,
    'subsidy_pct', v_policy.subsidy_pct,
    'max_per_trip', v_policy.max_per_trip,
    'allowed_hours', v_policy.allowed_hours,
    'active', v_policy.active
  );
end;
$$;

revoke all on function corporate_upsert_policy(text, numeric, uuid, numeric, jsonb, boolean) from public;
grant execute on function corporate_upsert_policy(text, numeric, uuid, numeric, jsonb, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- O-01 operator overview (FM39: aggregate only — no rider identity)
-- ---------------------------------------------------------------------------
create or replace function operator_overview(
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
  v_stale_s numeric;
  v_aggregates jsonb;
  v_online_total int := 0;
  v_online_at_park int := 0;
  v_online_roaming int := 0;
begin
  if p_from is null or p_to is null or p_to <= p_from then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  v_operator_id := admin_operator_account_id();
  if v_operator_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  v_aggregates := operator_driver_aggregates(p_from, p_to);
  v_stale_s := cfg_num('presence.stale_after_s');

  select
    count(*) filter (
      where dp.status <> 'offline'
        and dp.last_ping_at > now() - make_interval(secs => v_stale_s::int)
    )::int,
    count(*) filter (
      where dp.status = 'at_park'
        and dp.last_ping_at > now() - make_interval(secs => v_stale_s::int)
    )::int,
    count(*) filter (
      where dp.status like 'roaming%'
        and dp.last_ping_at > now() - make_interval(secs => v_stale_s::int)
    )::int
  into v_online_total, v_online_at_park, v_online_roaming
  from operator_members om
  join driver_presence dp on dp.driver_id = om.driver_id
  where om.operator_account_id = v_operator_id;

  return v_aggregates || jsonb_build_object(
    'online_total', v_online_total,
    'online_at_park', v_online_at_park,
    'online_roaming', v_online_roaming,
    'trips_per_day',
      case when p_to > p_from
        then round((v_aggregates->>'trips_completed')::numeric
          / greatest(extract(epoch from (p_to - p_from)) / 86400.0, 1), 2)
        else null end,
    'aggregate_only', true
  );
end;
$$;

revoke all on function operator_overview(timestamptz, timestamptz) from public;
grant execute on function operator_overview(timestamptz, timestamptz) to authenticated;

-- ---------------------------------------------------------------------------
-- A-19 revenue admin writes
-- ---------------------------------------------------------------------------
create or replace function admin_create_corporate_account(
  p_deployment_id uuid,
  p_name text,
  p_billing_email text,
  p_monthly_budget numeric default null,
  p_currency char(3) default 'NGN'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row corporate_accounts%rowtype;
begin
  if not has_admin_role(private.revenue_admin_roles()) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_deployment_id is null or p_name is null or btrim(p_name) = ''
     or p_billing_email is null or btrim(p_billing_email) = '' then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  insert into corporate_accounts (
    deployment_id,
    name,
    billing_email,
    monthly_budget,
    currency
  ) values (
    p_deployment_id,
    btrim(p_name),
    btrim(p_billing_email),
    p_monthly_budget,
    coalesce(p_currency, 'NGN')
  )
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'name', v_row.name,
    'billing_email', v_row.billing_email,
    'monthly_budget', v_row.monthly_budget,
    'currency', v_row.currency,
    'status', v_row.status
  );
end;
$$;

revoke all on function admin_create_corporate_account(uuid, text, text, numeric, char) from public;
grant execute on function admin_create_corporate_account(uuid, text, text, numeric, char) to authenticated;

create or replace function admin_create_operator_account(
  p_deployment_id uuid,
  p_type operator_account_type,
  p_name text,
  p_subscription_tier text default 'basic'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row operator_accounts%rowtype;
begin
  if not has_admin_role(private.revenue_admin_roles()) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_deployment_id is null or p_type is null or p_name is null or btrim(p_name) = '' then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  insert into operator_accounts (
    deployment_id,
    type,
    name,
    subscription_tier
  ) values (
    p_deployment_id,
    p_type,
    btrim(p_name),
    coalesce(nullif(btrim(p_subscription_tier), ''), 'basic')
  )
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'type', v_row.type,
    'name', v_row.name,
    'subscription_tier', v_row.subscription_tier,
    'billing_status', v_row.billing_status
  );
end;
$$;

revoke all on function admin_create_operator_account(uuid, operator_account_type, text, text) from public;
grant execute on function admin_create_operator_account(uuid, operator_account_type, text, text) to authenticated;

create or replace function admin_create_sponsored_placement(
  p_deployment_id uuid,
  p_context_type placement_context_type,
  p_target_reference uuid,
  p_advertiser text,
  p_content jsonb,
  p_active_from timestamptz,
  p_active_to timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row sponsored_placements%rowtype;
begin
  if not has_admin_role(private.revenue_admin_roles()) then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  if p_deployment_id is null or p_context_type is null or p_target_reference is null
     or p_advertiser is null or btrim(p_advertiser) = ''
     or p_active_from is null or p_active_to is null or p_active_to <= p_active_from then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  insert into sponsored_placements (
    deployment_id,
    context_type,
    target_reference,
    advertiser,
    content,
    active_from,
    active_to
  ) values (
    p_deployment_id,
    p_context_type,
    p_target_reference,
    btrim(p_advertiser),
    coalesce(p_content, '{}'::jsonb),
    p_active_from,
    p_active_to
  )
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'context_type', v_row.context_type,
    'target_reference', v_row.target_reference,
    'advertiser', v_row.advertiser,
    'content', v_row.content,
    'active_from', v_row.active_from,
    'active_to', v_row.active_to
  );
end;
$$;

revoke all on function admin_create_sponsored_placement(uuid, placement_context_type, uuid, text, jsonb, timestamptz, timestamptz) from public;
grant execute on function admin_create_sponsored_placement(uuid, placement_context_type, uuid, text, jsonb, timestamptz, timestamptz) to authenticated;

-- Finance role on A-19 revenue reads/writes (extend P8-A-03 admin RPCs)
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
  if not has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst']) then
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

create or replace function admin_revoke_api_key(p_api_key_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key api_keys%rowtype;
begin
  if not has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst']) then
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

-- ---------------------------------------------------------------------------
-- RLS: finance read access for A-19 revenue console
-- ---------------------------------------------------------------------------
drop policy if exists sponsored_placements_select_admin on sponsored_placements;
create policy sponsored_placements_select_admin
  on sponsored_placements for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst'])
    and (
      has_admin_role(array['superadmin'])
      or deployment_id = (
        select a.deployment_id from admin_users a
        where a.id = auth.uid() and a.disabled_at is null
      )
    )
  );

drop policy if exists placement_counters_select_admin on placement_counters;
create policy placement_counters_select_admin
  on placement_counters for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst'])
    and exists (
      select 1
      from sponsored_placements sp
      join admin_users au on au.id = auth.uid() and au.disabled_at is null
      where sp.id = placement_counters.placement_id
        and sp.deployment_id = au.deployment_id
    )
  );

drop policy if exists api_keys_select_admin on api_keys;
create policy api_keys_select_admin
  on api_keys for select to authenticated
  using (has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst']));

drop policy if exists api_usage_select_admin on api_usage;
create policy api_usage_select_admin
  on api_usage for select to authenticated
  using (has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst']));

drop policy if exists anonymized_od_exports_select_admin on anonymized_od_exports;
create policy anonymized_od_exports_select_admin
  on anonymized_od_exports for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );

drop policy if exists anonymized_od_cells_select_admin on anonymized_od_cells;
create policy anonymized_od_cells_select_admin
  on anonymized_od_cells for select to authenticated
  using (
    has_admin_role(array['superadmin', 'finance', 'ops_lead', 'analyst'])
    and admin_can_access_city(city_id)
  );
