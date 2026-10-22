-- P6-A-01: Complete audit_admin_write coverage (doc 02 §15 attach list).

-- trip_reconciliation_flags — admin_review_flag
create trigger audit_trip_reconciliation_flags
  after insert or update or delete on trip_reconciliation_flags
  for each row execute function audit_admin_write();

-- driver_standing_transitions — append-only; admin_transition_standing / transition_standing
create trigger audit_driver_standing_transitions
  after insert on driver_standing_transitions
  for each row execute function audit_admin_write();

-- drivers — extend standing/verified col audit (doc 02 §15)
drop trigger if exists audit_drivers_verification on drivers;
create trigger audit_drivers_admin_cols
  after update on drivers
  for each row
  when (
    old.verified_status is distinct from new.verified_status
    or old.women_only_eligible is distinct from new.women_only_eligible
    or old.tenure_started_at is distinct from new.tenure_started_at
    or old.driver_code is distinct from new.driver_code
    or old.standing is distinct from new.standing
    or old.standing_since is distinct from new.standing_since
  )
  execute function audit_admin_write();

-- guarantors — admin_notify_guarantor updates last_notified_at
create trigger audit_guarantors_admin_notify
  after update on guarantors
  for each row
  when (old.last_notified_at is distinct from new.last_notified_at)
  execute function audit_admin_write();

-- settlement_agents — admin_upsert_settlement_agent
create trigger audit_settlement_agents
  after insert or update or delete on settlement_agents
  for each row execute function audit_admin_write();

-- driver_ledger_entries — manual adjustments only (doc 02 §15)
create trigger audit_driver_ledger_manual
  after insert on driver_ledger_entries
  for each row
  when (new.entry_type = 'manual_adjustment')
  execute function audit_admin_write();

-- settlement_agents RPC: table trigger replaces explicit audit_finance_action (no double-log)
create or replace function admin_upsert_settlement_agent(
  p_id uuid,
  p_business_name text,
  p_city_id uuid,
  p_agent_phone text,
  p_lat double precision default null,
  p_lng double precision default null,
  p_active boolean default true
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_agent settlement_agents%rowtype;
  v_profile_id uuid;
  v_location geography;
begin
  if not has_admin_role(array['finance']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_business_name is null or btrim(p_business_name) = '' then
    raise exception using errcode = 'P0001', message = 'business_name is required';
  end if;

  if p_agent_phone is null or btrim(p_agent_phone) = '' then
    raise exception using errcode = 'P0001', message = 'agent_phone is required';
  end if;

  if not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_lat is not null and p_lng is not null then
    v_location := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  else
    v_location := null;
  end if;

  if p_id is null then
    v_profile_id := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, phone, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at, confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_profile_id,
      'authenticated',
      'authenticated',
      btrim(p_agent_phone),
      '',
      now(),
      '{"provider":"phone","providers":["phone"]}'::jsonb,
      jsonb_build_object('display_name', btrim(p_business_name)),
      now(),
      now(),
      '', '', '', ''
    )
    on conflict (id) do update set phone = excluded.phone;

    insert into profiles (id, phone_e164, display_name)
    values (v_profile_id, btrim(p_agent_phone), btrim(p_business_name))
    on conflict (id) do update
      set display_name = excluded.display_name,
          phone_e164 = excluded.phone_e164;

    insert into settlement_agents (
      profile_id, city_id, business_name, location, active
    ) values (
      v_profile_id, p_city_id, btrim(p_business_name), v_location, coalesce(p_active, true)
    )
    returning * into v_agent;
  else
    select * into v_agent
    from settlement_agents
    where id = p_id
    for update;

    if v_agent.id is null then
      raise exception 'NOT_FOUND' using errcode = 'P0001';
    end if;

    if v_agent.city_id <> p_city_id then
      raise exception using errcode = 'P0001', message = 'cannot move agent to another city';
    end if;

    update profiles
    set
      display_name = btrim(p_business_name),
      phone_e164 = btrim(p_agent_phone),
      updated_at = now()
    where id = v_agent.profile_id;

    update settlement_agents
    set
      business_name = btrim(p_business_name),
      location = v_location,
      active = coalesce(p_active, true),
      updated_at = now()
    where id = p_id
    returning * into v_agent;
  end if;

  return jsonb_build_object(
    'id', v_agent.id,
    'profile_id', v_agent.profile_id,
    'business_name', v_agent.business_name,
    'city_id', v_agent.city_id,
    'active', v_agent.active
  );
end;
$$;

-- admin_set_config: enum + required-properties validation for object schemas
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
  v_elem jsonb;
  v_prop text;
  v_allowed jsonb;
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
      if v_schema ? 'enum' then
        v_allowed := v_schema->'enum';
        if not exists (
          select 1 from jsonb_array_elements_text(v_allowed) e
          where e = p_value #>> '{}'
        ) then
          raise exception 'VALIDATION: % value not in allowed enum', p_key using errcode = 'P0001';
        end if;
      end if;
    when 'object' then
      if jsonb_typeof(p_value) <> 'object' then
        raise exception 'VALIDATION: % expects a JSON object', p_key using errcode = 'P0001';
      end if;
      if v_schema ? 'required' then
        for v_elem in select value from jsonb_array_elements(v_schema->'required') loop
          v_prop := trim(both '"' from v_elem::text);
          if not (p_value ? v_prop) then
            raise exception 'VALIDATION: % missing required property %', p_key, v_prop
              using errcode = 'P0001';
          end if;
        end loop;
      end if;
    when 'array' then
      if jsonb_typeof(p_value) <> 'array' then
        raise exception 'VALIDATION: % expects a JSON array', p_key using errcode = 'P0001';
      end if;
      if v_schema ? 'minItems' then
        if jsonb_array_length(p_value) < (v_schema->>'minItems')::int then
          raise exception 'VALIDATION: % array below minItems %', p_key, v_schema->>'minItems'
            using errcode = 'P0001';
        end if;
      end if;
    else
      null;
  end case;
end;
$$;
