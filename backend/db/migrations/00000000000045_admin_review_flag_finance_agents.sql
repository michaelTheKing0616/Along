-- P4-D-01: admin_review_flag (TS-INTEG-06), settlement agent admin RPCs (A-13)

-- ---------------------------------------------------------------------------
-- trip_reconciliation_flags — link actioned flags to standing transitions (FM13)
-- ---------------------------------------------------------------------------
alter table trip_reconciliation_flags
  add column if not exists standing_transition_id bigint
    references driver_standing_transitions(id);

-- ---------------------------------------------------------------------------
-- admin_review_flag — doc 03 §11; action requires standing_transition_id
-- ---------------------------------------------------------------------------
create or replace function admin_review_flag(
  p_flag_id uuid,
  p_action text,
  p_note text default null,
  p_standing_transition_id bigint default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_flag trip_reconciliation_flags%rowtype;
  v_transition driver_standing_transitions%rowtype;
  v_action text := lower(btrim(p_action));
begin
  if not has_admin_role(array['safety', 'ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_action not in ('clear', 'action') then
    raise exception using errcode = 'P0001', message = 'action must be clear or action';
  end if;

  select * into v_flag
  from trip_reconciliation_flags
  where id = p_flag_id
  for update;

  if v_flag.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = v_flag.driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_flag.status <> 'open' then
    raise exception using errcode = 'P0001', message = 'flag is not open';
  end if;

  if v_action = 'clear' then
    update trip_reconciliation_flags
    set
      status = 'cleared',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_note = nullif(btrim(p_note), '')
    where id = p_flag_id;

    return jsonb_build_object(
      'flag_id', p_flag_id,
      'status', 'cleared'
    );
  end if;

  if p_standing_transition_id is null then
    raise exception using errcode = 'P0001', message = 'standing transition id is required for action';
  end if;

  select * into v_transition
  from driver_standing_transitions
  where id = p_standing_transition_id;

  if v_transition.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'standing transition not found';
  end if;

  if v_transition.driver_id <> v_flag.driver_id then
    raise exception using errcode = 'P0001', message = 'standing transition driver mismatch';
  end if;

  update trip_reconciliation_flags
  set
    status = 'actioned',
    standing_transition_id = p_standing_transition_id,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_note = nullif(btrim(p_note), '')
  where id = p_flag_id;

  return jsonb_build_object(
    'flag_id', p_flag_id,
    'status', 'actioned',
    'standing_transition_id', p_standing_transition_id
  );
end;
$$;

grant execute on function admin_review_flag(uuid, text, text, bigint) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_upsert_settlement_agent — finance CRUD for A-13 (city-scoped)
-- ---------------------------------------------------------------------------
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

  perform private.audit_finance_action(
    case when p_id is null then 'create_settlement_agent' else 'update_settlement_agent' end,
    'settlement_agents',
    v_agent.id::text,
    null,
    jsonb_build_object(
      'business_name', v_agent.business_name,
      'city_id', v_agent.city_id,
      'active', v_agent.active
    )
  );

  return jsonb_build_object(
    'id', v_agent.id,
    'profile_id', v_agent.profile_id,
    'business_name', v_agent.business_name,
    'city_id', v_agent.city_id,
    'active', v_agent.active
  );
end;
$$;

grant execute on function admin_upsert_settlement_agent(uuid, text, uuid, text, double precision, double precision, boolean)
  to authenticated;

-- Integrity reviewers (safety) must call standing transition from the Action dialog (A-10 / FM13).
create or replace function admin_transition_standing(
  p_driver_id uuid,
  p_to text,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_to driver_standing;
  v_row driver_standing_transitions%rowtype;
begin
  if not has_admin_role(array['ops_lead', 'finance', 'safety']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = p_driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  begin
    v_to := p_to::driver_standing;
  exception
    when invalid_text_representation then
      raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid standing';
  end;

  v_row := transition_standing(p_driver_id, v_to, 'admin', auth.uid(), p_reason);

  return jsonb_build_object(
    'transition_id', v_row.id,
    'from_standing', v_row.from_standing,
    'to_standing', v_row.to_standing,
    'reason', v_row.reason
  );
end;
$$;

grant execute on function admin_transition_standing(uuid, text, text) to authenticated;
