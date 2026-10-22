-- P6-D-03: Graph editor RPCs (A-05) + admin_set_config (A-09) + app_config_keys registry.

-- ---------------------------------------------------------------------------
-- app_config_keys — JSON-schema metadata for A-09 validation
-- ---------------------------------------------------------------------------
create table app_config_keys (
  key text primary key,
  value_schema jsonb not null,
  description text,
  allowed_scopes config_scope[] not null default array['global','country','city','corridor']::config_scope[],
  read_only boolean not null default false
);

alter table app_config_keys enable row level security;

create policy app_config_keys_select_authenticated
  on app_config_keys for select to authenticated using (true);

create policy app_config_keys_write_superadmin
  on app_config_keys for all to authenticated
  using (has_admin_role(array['superadmin']))
  with check (has_admin_role(array['superadmin']));

grant select on app_config_keys to authenticated;

-- Populate keys (schemas mirror shared/contracts/config-schemas/).
insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  ('commission.rate', '{"type":"number","minimum":0.05,"maximum":0.10}', 'Platform commission rate', array['global','city']::config_scope[], false),
  ('graph.snap_radius_m', '{"type":"number","minimum":10,"maximum":200}', 'Driver route stop snap radius (m)', array['global','city']::config_scope[], false),
  ('graph.stage_merge_radius_m', '{"type":"number","minimum":10,"maximum":200}', 'Stage dedupe radius (m)', array['global','city']::config_scope[], false),
  ('ops.live_map_poll_s', '{"type":"number","minimum":3,"maximum":60}', 'Admin live map poll interval (seconds)', array['global','city']::config_scope[], false),
  ('ledger.dual_control_threshold', '{"type":"number","minimum":0}', 'Finance dual-control threshold', array['global','city']::config_scope[], false),
  ('payments.digital_enabled', '{"type":"boolean"}', 'Digital payments master switch (country/city)', array['global','country','city']::config_scope[], true),
  ('dispatch.request_ttl_s', '{"type":"number","minimum":10,"maximum":120}', 'Driver request TTL (seconds)', array['global','city']::config_scope[], false),
  ('planner.max_legs', '{"type":"number","minimum":1,"maximum":6}', 'Max planner legs', array['global']::config_scope[], false),
  ('sos.ack_sla_s', '{"type":"number","minimum":30,"maximum":600}', 'SOS acknowledge SLA (seconds)', array['global','city']::config_scope[], false),
  ('sos.escalate_sla_s', '{"type":"number","minimum":60,"maximum":1800}', 'SOS escalate SLA (seconds)', array['global','city']::config_scope[], false)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- audit_admin_write — attach optional reason from session (A-09)
-- ---------------------------------------------------------------------------
create or replace function audit_admin_write() returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role text;
  v_before jsonb;
  v_after jsonb;
  v_target_id text;
  v_reason text;
begin
  v_reason := nullif(current_setting('along.audit_reason', true), '');

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

  if v_reason is not null and v_after is not null then
    v_after := v_after || jsonb_build_object('reason', v_reason);
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

-- ---------------------------------------------------------------------------
-- Config validation + admin_set_config
-- ---------------------------------------------------------------------------
create or replace function _validate_config_value(p_key text, p_value jsonb)
returns void
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_schema jsonb;
  v_type text;
  v_num numeric;
begin
  select k.value_schema into v_schema
  from app_config_keys k
  where k.key = p_key;

  if not found then
    raise exception 'VALIDATION: unknown config key %', p_key using errcode = 'P0001';
  end if;

  v_type := v_schema->>'type';

  case v_type
    when 'number' then
      if jsonb_typeof(p_value) <> 'number' then
        raise exception 'VALIDATION: % expects a JSON number', p_key using errcode = 'P0001';
      end if;
      v_num := (p_value #>> '{}')::numeric;
      if v_schema ? 'minimum' and v_num < (v_schema->>'minimum')::numeric then
        raise exception 'VALIDATION: % below minimum %', p_key, v_schema->>'minimum' using errcode = 'P0001';
      end if;
      if v_schema ? 'maximum' and v_num > (v_schema->>'maximum')::numeric then
        raise exception 'VALIDATION: % above maximum %', p_key, v_schema->>'maximum' using errcode = 'P0001';
      end if;
    when 'boolean' then
      if jsonb_typeof(p_value) <> 'boolean' then
        raise exception 'VALIDATION: % expects a JSON boolean', p_key using errcode = 'P0001';
      end if;
    when 'string' then
      if jsonb_typeof(p_value) <> 'string' then
        raise exception 'VALIDATION: % expects a JSON string', p_key using errcode = 'P0001';
      end if;
    when 'object' then
      if jsonb_typeof(p_value) <> 'object' then
        raise exception 'VALIDATION: % expects a JSON object', p_key using errcode = 'P0001';
      end if;
    when 'array' then
      if jsonb_typeof(p_value) <> 'array' then
        raise exception 'VALIDATION: % expects a JSON array', p_key using errcode = 'P0001';
      end if;
    else
      null;
  end case;
end;
$$;

create or replace function admin_set_config(
  p_key text,
  p_scope_type config_scope,
  p_scope_id text,
  p_value jsonb,
  p_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_meta app_config_keys%rowtype;
  v_before jsonb;
  v_scope_id text := coalesce(nullif(btrim(p_scope_id), ''), '*');
  v_reason text := nullif(btrim(p_reason), '');
begin
  if not has_admin_role(array['superadmin', 'ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if v_reason is null then
    raise exception 'VALIDATION: reason is required' using errcode = 'P0001';
  end if;

  select * into v_meta from app_config_keys k where k.key = p_key;
  if not found then
    raise exception 'VALIDATION: unknown config key %', p_key using errcode = 'P0001';
  end if;

  if v_meta.read_only then
    raise exception 'VALIDATION: config key % is read-only in admin console', p_key
      using errcode = 'P0001';
  end if;

  if not (p_scope_type = any (v_meta.allowed_scopes)) then
    raise exception 'VALIDATION: scope % not allowed for key %', p_scope_type, p_key
      using errcode = 'P0001';
  end if;

  perform _validate_config_value(p_key, p_value);

  if p_scope_type = 'city' and not admin_can_access_city(v_scope_id::uuid) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  select ac.value into v_before
  from app_config ac
  where ac.key = p_key
    and ac.scope_type = p_scope_type
    and ac.scope_id = v_scope_id;

  perform set_config('along.audit_reason', v_reason, true);

  insert into app_config (key, scope_type, scope_id, value, updated_by)
  values (p_key, p_scope_type, v_scope_id, p_value, auth.uid())
  on conflict (key, scope_type, scope_id) do update
    set value = excluded.value,
        updated_by = auth.uid(),
        updated_at = now();

  perform set_config('along.audit_reason', '', true);

  return jsonb_build_object(
    'key', p_key,
    'scope_type', p_scope_type,
    'scope_id', v_scope_id,
    'before', v_before,
    'after', p_value,
    'reason', v_reason
  );
end;
$$;

grant execute on function admin_set_config(text, config_scope, text, jsonb, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Graph admin helpers
-- ---------------------------------------------------------------------------
create or replace function _admin_graph_source(p_note text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
begin
  insert into data_sources (source_type, actor_profile_id, notes)
  values ('admin', auth.uid(), p_note)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function _graph_revision_target_table(p_type text)
returns text
language sql
immutable
as $$
  select case p_type
    when 'park' then 'parks'
    when 'route' then 'routes'
    when 'route_stage' then 'route_stages'
    when 'route_leg' then 'route_legs'
    when 'route_through_fare' then 'route_through_fares'
    else null
  end;
$$;

create or replace function admin_update_graph_entity(p_type text, p_payload jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
  v_city_id uuid;
  v_source_id uuid;
  v_revision_id bigint;
  v_table text;
  v_rows int := 0;
  v_reason text := coalesce(nullif(p_payload->>'reason', ''), 'admin_edit');
begin
  if not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_table := _graph_revision_target_table(p_type);
  if v_table is null then
    raise exception 'VALIDATION: unsupported graph entity type %', p_type using errcode = 'P0001';
  end if;

  v_id := (p_payload->>'id')::uuid;
  if v_id is null then
    raise exception 'VALIDATION: payload.id is required' using errcode = 'P0001';
  end if;

  v_city_id := graph_target_city_id(p_type, v_id);
  if v_city_id is null or not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_source_id := _admin_graph_source(format('admin_update_graph_entity:%s:%s', p_type, v_id));
  perform set_config('along.revision_reason', v_reason, true);

  case p_type
    when 'park' then
      update parks p set
        name = coalesce(p_payload->>'name', p.name),
        name_aliases = case
          when p_payload ? 'name_aliases' then
            coalesce(
              (select array_agg(x) from jsonb_array_elements_text(p_payload->'name_aliases') as t(x)),
              p.name_aliases
            )
          else p.name_aliases
        end,
        location = case
          when p_payload ? 'lat' and p_payload ? 'lng' then
            st_setsrid(
              st_makepoint((p_payload->>'lng')::double precision, (p_payload->>'lat')::double precision),
              4326
            )::geography
          else p.location
        end,
        source_id = v_source_id
      where p.id = v_id;
      get diagnostics v_rows = row_count;
    when 'route' then
      update routes r set
        name = case when p_payload ? 'name' then p_payload->>'name' else r.name end,
        active = case when p_payload ? 'active' then (p_payload->>'active')::boolean else r.active end,
        source_id = v_source_id
      where r.id = v_id;
      get diagnostics v_rows = row_count;
    when 'route_stage' then
      if p_payload ? 'sequence' then
        if exists (
          select 1 from route_stages rs
          where rs.route_id = (select route_id from route_stages where id = v_id)
            and rs.sequence = (p_payload->>'sequence')::int
            and rs.id <> v_id
        ) then
          raise exception 'VALIDATION: duplicate stage sequence on route' using errcode = 'P0001';
        end if;
      end if;
      update route_stages rs set
        name = case when p_payload ? 'name' then p_payload->>'name' else rs.name end,
        sequence = case when p_payload ? 'sequence' then (p_payload->>'sequence')::int else rs.sequence end,
        location = case
          when p_payload ? 'lat' and p_payload ? 'lng' then
            st_setsrid(
              st_makepoint((p_payload->>'lng')::double precision, (p_payload->>'lat')::double precision),
              4326
            )::geography
          else rs.location
        end,
        source_id = v_source_id
      where rs.id = v_id;
      get diagnostics v_rows = row_count;
    when 'route_leg' then
      update route_legs rl set
        fare_amount = case when p_payload ? 'fare_amount' then (p_payload->>'fare_amount')::numeric else rl.fare_amount end,
        source_id = v_source_id
      where rl.id = v_id;
      get diagnostics v_rows = row_count;
    when 'route_through_fare' then
      update route_through_fares tf set
        fare_amount = case when p_payload ? 'fare_amount' then (p_payload->>'fare_amount')::numeric else tf.fare_amount end,
        source_id = v_source_id
      where tf.id = v_id;
      get diagnostics v_rows = row_count;
  end case;

  if v_rows = 0 then
    perform set_config('along.revision_reason', '', true);
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  perform set_config('along.revision_reason', '', true);

  select gr.id into v_revision_id
  from graph_revisions gr
  where gr.target_type = v_table
    and gr.target_id = v_id
  order by gr.created_at desc, gr.id desc
  limit 1;

  return jsonb_build_object(
    'id', v_id,
    'type', p_type,
    'revision_id', v_revision_id,
    'source_id', v_source_id
  );
end;
$$;

grant execute on function admin_update_graph_entity(text, jsonb) to authenticated;

create or replace function admin_deactivate_graph_entity(
  p_type text,
  p_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_city_id uuid;
  v_source_id uuid;
  v_revision_id bigint;
begin
  if not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if p_type <> 'route' then
    raise exception 'VALIDATION: deactivate supported for routes only' using errcode = 'P0001';
  end if;

  v_city_id := graph_target_city_id('route', p_id);
  if v_city_id is null or not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_source_id := _admin_graph_source(format('admin_deactivate_graph_entity:route:%s', p_id));
  perform set_config('along.revision_reason', coalesce(nullif(p_reason, ''), 'admin_deactivate'), true);

  update routes r
  set active = false,
      source_id = v_source_id
  where r.id = p_id and r.active = true;

  if not found then
    perform set_config('along.revision_reason', '', true);
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  perform set_config('along.revision_reason', '', true);

  select gr.id into v_revision_id
  from graph_revisions gr
  where gr.target_type = 'routes' and gr.target_id = p_id
  order by gr.created_at desc, gr.id desc
  limit 1;

  return jsonb_build_object('id', p_id, 'type', p_type, 'revision_id', v_revision_id, 'active', false);
end;
$$;

grant execute on function admin_deactivate_graph_entity(text, uuid, text) to authenticated;

create or replace function admin_publish_graph_entity(p_type text, p_payload jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_city_id uuid;
  v_source_id uuid;
  v_id uuid;
  v_currency char(3);
begin
  if not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_city_id := (p_payload->>'city_id')::uuid;
  if v_city_id is null or not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_source_id := _admin_graph_source(format('admin_publish_graph_entity:%s', p_type));
  perform set_config('along.revision_reason', coalesce(nullif(p_payload->>'reason', ''), 'admin_publish'), true);

  select c.currency_code into v_currency
  from cities ci
  join countries c on c.code = ci.country_code
  where ci.id = v_city_id;

  case p_type
    when 'park' then
      if not (p_payload ? 'name' and p_payload ? 'lat' and p_payload ? 'lng') then
        raise exception 'VALIDATION: park payload requires name, lat, lng' using errcode = 'P0001';
      end if;
      insert into parks (
        city_id, name, name_aliases, location, source_id, verification_status, confidence_score
      ) values (
        v_city_id,
        p_payload->>'name',
        coalesce(
          (select array_agg(x) from jsonb_array_elements_text(p_payload->'name_aliases') as t(x)),
          '{}'::text[]
        ),
        st_setsrid(
          st_makepoint((p_payload->>'lng')::double precision, (p_payload->>'lat')::double precision),
          4326
        )::geography,
        v_source_id,
        'candidate',
        0.300
      )
      returning id into v_id;
    else
      raise exception 'VALIDATION: publish for type % not supported — use field reconciliation for field_verified', p_type
        using errcode = 'P0001';
  end case;

  perform set_config('along.revision_reason', '', true);

  return jsonb_build_object('id', v_id, 'type', p_type, 'verification_status', 'candidate');
end;
$$;

grant execute on function admin_publish_graph_entity(text, jsonb) to authenticated;

-- CSV bulk import (parks) — dry-run diff then apply
create or replace function admin_import_dry_run(p_city_id uuid, p_csv text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_line text;
  v_lines text[];
  v_parts text[];
  v_name text;
  v_lat double precision;
  v_lng double precision;
  v_diff jsonb := '[]'::jsonb;
  v_existing int;
  v_i int;
begin
  if not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_lines := regexp_split_to_array(coalesce(p_csv, ''), E'\\r?\\n');

  for v_i in 1 .. coalesce(array_length(v_lines, 1), 0) loop
    v_line := btrim(v_lines[v_i]);
    if v_line = '' then continue; end if;
    if v_i = 1 and v_line ~* '^name\\s*,' then continue; end if;

    v_parts := string_to_array(v_line, ',');
    if coalesce(array_length(v_parts, 1), 0) < 3 then
      raise exception 'VALIDATION: line % expects name,lat,lng', v_i using errcode = 'P0001';
    end if;

    v_name := btrim(v_parts[1]);
    v_lat := btrim(v_parts[2])::double precision;
    v_lng := btrim(v_parts[3])::double precision;

    select count(*)::int into v_existing
    from parks p
    where p.city_id = p_city_id
      and lower(btrim(p.name)) = lower(v_name);

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'name', v_name,
      'lat', v_lat,
      'lng', v_lng,
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Park name already exists in city' else null end
    ));
  end loop;

  return jsonb_build_object('diff', v_diff);
end;
$$;

grant execute on function admin_import_dry_run(uuid, text) to authenticated;

create or replace function admin_import_apply(p_city_id uuid, p_diff jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_row jsonb;
  v_source_id uuid;
  v_created int := 0;
  v_skipped int := 0;
begin
  if not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if jsonb_typeof(p_diff) <> 'array' then
    raise exception 'VALIDATION: p_diff must be a JSON array' using errcode = 'P0001';
  end if;

  for v_row in select value from jsonb_array_elements(p_diff) loop
    if coalesce(v_row->>'action', '') <> 'create' then
      v_skipped := v_skipped + 1;
      continue;
    end if;

    v_source_id := _admin_graph_source(format('admin_import_apply:park:%s', v_row->>'name'));
    perform set_config('along.revision_reason', 'csv_import', true);

    insert into parks (
      city_id, name, location, source_id, verification_status, confidence_score
    ) values (
      p_city_id,
      v_row->>'name',
      st_setsrid(
        st_makepoint((v_row->>'lng')::double precision, (v_row->>'lat')::double precision),
        4326
      )::geography,
      v_source_id,
      'candidate',
      0.300
    );

    perform set_config('along.revision_reason', '', true);
    v_created := v_created + 1;
  end loop;

  return jsonb_build_object('created', v_created, 'skipped', v_skipped);
end;
$$;

grant execute on function admin_import_apply(uuid, jsonb) to authenticated;
