-- Phase C extensions of the driver-authored rules system.
-- Luggage is a seat role. Whole-row and whole-vehicle booking, walk-time
-- holds, shift hours, a home label, and a conductor code are data the
-- driver turns on. The engine does not invent a product for each one.

-- ---------------------------------------------------------------------------
-- Luggage seats count toward the layout, not toward bookable passengers.
-- ---------------------------------------------------------------------------
create or replace function private.seat_layout_stats(p_layout jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_body text;
  v_rows jsonb;
  v_row jsonb;
  v_seat jsonb;
  v_row_count int;
  v_seat_count int;
  v_passengers int := 0;
  v_drivers int := 0;
  v_total int := 0;
  v_ids text[] := '{}';
  v_row_ids text[] := '{}';
  v_id text;
  v_role text;
  v_label text;
  v_pass_ids jsonb := '[]'::jsonb;
begin
  if p_layout is null or jsonb_typeof(p_layout) <> 'object' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if (p_layout->>'version') is distinct from '1' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_body := p_layout->>'body';
  if v_body is null or v_body not in ('cabin', 'bench', 'bike', 'coach') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_rows := p_layout->'rows';
  if v_rows is null or jsonb_typeof(v_rows) <> 'array' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_row_count := jsonb_array_length(v_rows);
  if v_row_count < 1 or v_row_count > 24 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  for v_row in select value from jsonb_array_elements(v_rows)
  loop
    v_id := v_row->>'id';
    if v_id is null or char_length(v_id) < 1 or char_length(v_id) > 40 or v_id = any(v_row_ids) then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
    v_row_ids := v_row_ids || v_id;
    if v_row->'seats' is null or jsonb_typeof(v_row->'seats') <> 'array' then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
    v_seat_count := jsonb_array_length(v_row->'seats');
    if v_seat_count < 1 or v_seat_count > 6 then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
    for v_seat in select value from jsonb_array_elements(v_row->'seats')
    loop
      v_id := v_seat->>'id';
      v_role := v_seat->>'role';
      v_label := v_seat->>'label';
      if v_id is null or char_length(v_id) < 1 or char_length(v_id) > 40 or v_id = any(v_ids) then
        raise exception 'VALIDATION' using errcode = 'P0001';
      end if;
      if v_label is null or char_length(btrim(v_label)) < 1 or char_length(v_label) > 40 then
        raise exception 'VALIDATION' using errcode = 'P0001';
      end if;
      if v_role is null or v_role not in ('driver', 'passenger', 'cargo') then
        raise exception 'VALIDATION' using errcode = 'P0001';
      end if;
      v_ids := v_ids || v_id;
      v_total := v_total + 1;
      if v_role = 'driver' then
        v_drivers := v_drivers + 1;
      elsif v_role = 'passenger' then
        v_passengers := v_passengers + 1;
        v_pass_ids := v_pass_ids || jsonb_build_array(v_id);
      end if;
    end loop;
  end loop;

  if v_total > 80 or v_drivers <> 1 or v_passengers < 1 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'passenger_seats', v_passengers,
    'passenger_ids', v_pass_ids
  );
end;
$$;

revoke all on function private.seat_layout_stats(jsonb) from public;

-- ---------------------------------------------------------------------------
-- Bundle is another effect. Definitions stay in preset rows.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select con.conname, rel.relname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'public'
      and rel.relname in ('driver_ride_rules', 'ride_rule_presets')
      and con.contype = 'c'
      and pg_get_constraintdef(con.oid) like '%hold_minutes%'
  loop
    execute format('alter table %I drop constraint %I', r.relname, r.conname);
  end loop;
end $$;

alter table driver_ride_rules
  add constraint driver_ride_rules_effect_check
  check (effect in ('badge', 'hold_minutes', 'cap_seats', 'acknowledge', 'bundle'));

alter table ride_rule_presets
  add constraint ride_rule_presets_effect_check
  check (effect in ('badge', 'hold_minutes', 'cap_seats', 'acknowledge', 'bundle'));

insert into ride_rule_presets (id, title, body, effect, target_scope, default_params, sort_order)
values
  (
    'book_row',
    'Book a whole row',
    'Riders can take every free seat in the row you choose.',
    'bundle',
    'row',
    '{}'::jsonb,
    50
  ),
  (
    'book_vehicle',
    'Book the whole vehicle',
    'Riders can take every free passenger seat.',
    'bundle',
    'vehicle',
    '{}'::jsonb,
    60
  )
on conflict (id) do nothing;

update ride_rule_presets
set default_params = coalesce(default_params, '{}'::jsonb)
  || '{"walk_extension_minutes":0}'::jsonb
where id = 'seat_hold';

-- ---------------------------------------------------------------------------
-- Shift hours and a home label are optional day fields the driver writes.
-- ---------------------------------------------------------------------------
alter table driver_day_plans
  add column shift_start time,
  add column shift_end time,
  add column home_label text,
  add constraint driver_day_plans_home_label_len
    check (home_label is null or char_length(btrim(home_label)) between 1 and 80);

drop function start_driver_day(uuid, uuid, uuid, uuid);

create function start_driver_day(
  p_vehicle_id uuid,
  p_layout_id uuid,
  p_corridor_id uuid,
  p_route_id uuid default null,
  p_shift_start time default null,
  p_shift_end time default null,
  p_home_label text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_city uuid;
  v_id uuid;
  v_home text := nullif(btrim(p_home_label), '');
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not private.owns_vehicle(v_user, p_vehicle_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from vehicle_layouts
    where id = p_layout_id
      and vehicle_id = p_vehicle_id
      and driver_id = v_user
  ) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_home is not null and char_length(v_home) > 80 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select city_id into v_city from drivers where id = v_user;
  if v_city is null or not exists (
    select 1 from corridors c where c.id = p_corridor_id and c.city_id = v_city
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if p_route_id is not null and not exists (
    select 1 from routes r
    where r.id = p_route_id
      and r.city_id = v_city
      and r.corridor_id = p_corridor_id
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  update vehicle_layouts
  set is_active = false
  where vehicle_id = p_vehicle_id and is_active and id <> p_layout_id;
  update vehicle_layouts set is_active = true where id = p_layout_id;

  update driver_day_plans set active = false where driver_id = v_user and active;
  insert into driver_day_plans (
    driver_id, vehicle_id, layout_id, corridor_id, route_id, active,
    shift_start, shift_end, home_label
  )
  values (
    v_user, p_vehicle_id, p_layout_id, p_corridor_id, p_route_id, true,
    p_shift_start, p_shift_end, v_home
  )
  returning id into v_id;

  perform private.touch_presence_seats(v_user, p_layout_id);

  return jsonb_build_object(
    'id', v_id,
    'layout_id', p_layout_id,
    'shift_start', p_shift_start,
    'shift_end', p_shift_end,
    'home_label', v_home
  );
end;
$$;

revoke all on function start_driver_day(uuid, uuid, uuid, uuid, time, time, text) from public;
grant execute on function start_driver_day(uuid, uuid, uuid, uuid, time, time, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Walk-time hold. Duration and the walk cap come from the driver's hold rule.
-- ---------------------------------------------------------------------------
create or replace function private.hold_walk_cap(p_layout_id uuid, p_seat_id text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((r.params->>'walk_extension_minutes')::int, 0)
  from vehicle_layouts l
  join driver_ride_rules r
    on r.driver_id = l.driver_id
   and r.vehicle_id = l.vehicle_id
   and r.enabled
   and r.effect = 'hold_minutes'
  where l.id = p_layout_id
    and (
      (r.target_scope = 'seat' and r.target_ref = p_seat_id)
      or (r.target_scope = 'row' and r.target_ref = private.seat_row_id(l.layout, p_seat_id))
      or r.target_scope = 'vehicle'
    )
  order by case r.target_scope
    when 'seat' then 1
    when 'row' then 2
    else 3
  end
  limit 1;
$$;

revoke all on function private.hold_walk_cap(uuid, text) from public;

create function hold_seat(
  p_layout_id uuid,
  p_seat_id text,
  p_expected_version integer,
  p_walk_minutes integer default null,
  p_ack_rule_ids uuid[] default '{}'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout vehicle_layouts%rowtype;
  v_row text;
  v_base int;
  v_cap int;
  v_walk int;
  v_version int;
  v_updated timestamptz;
  v_free int;
  v_until timestamptz;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_layout from vehicle_layouts where id = p_layout_id;
  if v_layout.id is null or not v_layout.is_active then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from vehicle_seat_states
    where layout_id = p_layout_id and seat_id = p_seat_id
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_base := private.hold_minutes(p_layout_id, p_seat_id);
  if v_base is null or v_base < 1 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_cap := greatest(coalesce(private.hold_walk_cap(p_layout_id, p_seat_id), 0), 0);
  v_walk := least(greatest(coalesce(p_walk_minutes, 0), 0), v_cap);
  v_until := now() + make_interval(mins => v_base + v_walk);
  v_row := private.seat_row_id(v_layout.layout, p_seat_id);

  if exists (
    select 1 from driver_ride_rules r
    where r.driver_id = v_layout.driver_id
      and r.vehicle_id = v_layout.vehicle_id
      and r.enabled
      and r.effect = 'acknowledge'
      and (
        r.target_scope = 'vehicle'
        or (r.target_scope = 'row' and r.target_ref = v_row)
        or (r.target_scope = 'seat' and r.target_ref = p_seat_id)
      )
      and not (r.id = any(coalesce(p_ack_rule_ids, '{}')))
  ) then
    raise exception 'RULE_ACK' using errcode = 'P0001';
  end if;

  update vehicle_seat_states
  set status = 'free',
      holder_profile_id = null,
      hold_until = null,
      updated_at = now()
  where layout_id = p_layout_id
    and seat_id = p_seat_id
    and status = 'held'
    and hold_until is not null
    and hold_until < now();

  update vehicle_seat_states
  set status = 'held',
      holder_profile_id = v_user,
      hold_until = v_until,
      version = version + 1,
      updated_at = now()
  where layout_id = p_layout_id
    and seat_id = p_seat_id
    and status = 'free'
    and version = p_expected_version
  returning version, updated_at into v_version, v_updated;

  if v_version is null then
    raise exception 'CONFLICT' using errcode = 'P0001';
  end if;

  perform private.touch_presence_seats(v_layout.driver_id, p_layout_id);
  v_free := private.layout_free_count(p_layout_id);

  return jsonb_build_object(
    'seat_id', p_seat_id,
    'status', 'held',
    'version', v_version,
    'free', v_free,
    'hold_until', v_until,
    'updated_at', v_updated
  );
end;
$$;

revoke all on function hold_seat(uuid, text, integer, integer, uuid[]) from public;
grant execute on function hold_seat(uuid, text, integer, integer, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- Book every free passenger seat covered by one bundle rule, or none.
-- ---------------------------------------------------------------------------
create function claim_bundle(
  p_layout_id uuid,
  p_rule_id uuid,
  p_ack_rule_ids uuid[] default '{}'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout vehicle_layouts%rowtype;
  v_rule driver_ride_rules%rowtype;
  v_ids text[] := '{}';
  v_seat text;
  v_row text;
  v_taken int;
  v_free int;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_layout from vehicle_layouts where id = p_layout_id;
  if v_layout.id is null or not v_layout.is_active then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_rule
  from driver_ride_rules
  where id = p_rule_id
    and driver_id = v_layout.driver_id
    and vehicle_id = v_layout.vehicle_id
    and enabled
    and effect = 'bundle';
  if v_rule.id is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select coalesce(array_agg(seat->>'id' order by seat->>'id'), '{}')
  into v_ids
  from jsonb_array_elements(v_layout.layout->'rows') rowj
  cross join lateral jsonb_array_elements(rowj->'seats') seat
  where seat->>'role' = 'passenger'
    and (
      v_rule.target_scope = 'vehicle'
      or (v_rule.target_scope = 'row' and rowj->>'id' = v_rule.target_ref)
      or (v_rule.target_scope = 'seat' and seat->>'id' = v_rule.target_ref)
    );

  if coalesce(array_length(v_ids, 1), 0) < 1 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from driver_ride_rules cap
    where cap.driver_id = v_layout.driver_id
      and cap.vehicle_id = v_layout.vehicle_id
      and cap.enabled
      and cap.effect = 'cap_seats'
      and (cap.params->>'max')::int < array_length(v_ids, 1)
      and (
        cap.target_scope = 'vehicle'
        or cap.target_scope = v_rule.target_scope and cap.target_ref is not distinct from v_rule.target_ref
      )
  ) then
    raise exception 'RULE_CAP' using errcode = 'P0001';
  end if;

  foreach v_seat in array v_ids loop
    v_row := private.seat_row_id(v_layout.layout, v_seat);
    if exists (
      select 1 from driver_ride_rules r
      where r.driver_id = v_layout.driver_id
        and r.vehicle_id = v_layout.vehicle_id
        and r.enabled
        and r.effect = 'acknowledge'
        and (
          r.target_scope = 'vehicle'
          or (r.target_scope = 'row' and r.target_ref = v_row)
          or (r.target_scope = 'seat' and r.target_ref = v_seat)
        )
        and not (r.id = any(coalesce(p_ack_rule_ids, '{}')))
    ) then
      raise exception 'RULE_ACK' using errcode = 'P0001';
    end if;
  end loop;

  update vehicle_seat_states
  set status = 'free', holder_profile_id = null, hold_until = null, updated_at = now()
  where layout_id = p_layout_id
    and seat_id = any(v_ids)
    and status = 'held'
    and hold_until is not null
    and hold_until < now();

  update vehicle_seat_states
  set status = 'occupied',
      holder_profile_id = v_user,
      hold_until = null,
      version = version + 1,
      updated_at = now()
  where layout_id = p_layout_id
    and seat_id = any(v_ids)
    and status = 'free';

  get diagnostics v_taken = row_count;
  if v_taken is distinct from array_length(v_ids, 1) then
    raise exception 'CONFLICT' using errcode = 'P0001';
  end if;

  perform private.touch_presence_seats(v_layout.driver_id, p_layout_id);
  v_free := private.layout_free_count(p_layout_id);
  return jsonb_build_object(
    'status', 'occupied',
    'seats', to_jsonb(v_ids),
    'free', v_free,
    'updated_at', now()
  );
end;
$$;

revoke all on function claim_bundle(uuid, uuid, uuid[]) from public;
grant execute on function claim_bundle(uuid, uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- Conductor code for a second phone. It can mark seats and nothing else.
-- ---------------------------------------------------------------------------
create table conductor_sessions (
  id uuid primary key default gen_random_uuid(),
  day_plan_id uuid not null references driver_day_plans(id) on delete cascade,
  layout_id uuid not null references vehicle_layouts(id),
  code text not null unique check (char_length(code) = 8),
  created_by uuid not null references profiles(id),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index conductor_sessions_plan on conductor_sessions (day_plan_id);

alter table conductor_sessions enable row level security;

create policy conductor_sessions_read
  on conductor_sessions for select to authenticated
  using (
    created_by = auth.uid()
    or is_admin()
    or exists (
      select 1 from driver_day_plans p
      where p.id = day_plan_id and p.driver_id = auth.uid()
    )
  );

grant select on conductor_sessions to authenticated;
revoke insert, update, delete on conductor_sessions from authenticated, anon;

create function open_conductor_session()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_plan driver_day_plans%rowtype;
  v_code text;
  v_until timestamptz;
  v_shift timestamptz;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_plan
  from driver_day_plans
  where driver_id = v_user and active
  order by created_at desc
  limit 1;
  if v_plan.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_until := now() + interval '12 hours';
  if v_plan.shift_end is not null then
    v_shift := current_date + v_plan.shift_end;
    if v_plan.shift_start is not null and v_plan.shift_end <= v_plan.shift_start then
      v_shift := v_shift + interval '1 day';
    end if;
    if v_shift <= now() then
      v_shift := v_shift + interval '1 day';
    end if;
    v_until := least(v_until, v_shift);
  end if;

  v_code := substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  insert into conductor_sessions (day_plan_id, layout_id, code, created_by, expires_at)
  values (v_plan.id, v_plan.layout_id, v_code, v_user, v_until);

  return jsonb_build_object(
    'code', v_code,
    'layout_id', v_plan.layout_id,
    'expires_at', v_until
  );
end;
$$;

revoke all on function open_conductor_session() from public;
grant execute on function open_conductor_session() to authenticated;

create function conductor_board(p_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select layout_id into v_layout
  from conductor_sessions
  where code = lower(btrim(p_code))
    and expires_at > now();
  if v_layout is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  return seat_board(v_layout);
end;
$$;

revoke all on function conductor_board(text) from public;
grant execute on function conductor_board(text) to authenticated;

create function conductor_set_seat(
  p_code text,
  p_seat_id text,
  p_status text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout_id uuid;
  v_driver uuid;
  v_minutes int;
  v_hold timestamptz;
  v_version int;
  v_updated timestamptz;
  v_free int;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_status is null or p_status not in ('free', 'occupied', 'held') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select s.layout_id, p.driver_id
  into v_layout_id, v_driver
  from conductor_sessions s
  join driver_day_plans p on p.id = s.day_plan_id
  where s.code = lower(btrim(p_code))
    and s.expires_at > now();
  if v_layout_id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from vehicle_seat_states
    where layout_id = v_layout_id and seat_id = p_seat_id
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_status = 'held' then
    v_minutes := private.hold_minutes(v_layout_id, p_seat_id);
    if v_minutes is not null then
      v_hold := now() + make_interval(mins => v_minutes);
    end if;
  end if;

  update vehicle_seat_states set
    status = p_status,
    holder_profile_id = null,
    hold_until = v_hold,
    version = version + 1,
    updated_at = now()
  where layout_id = v_layout_id and seat_id = p_seat_id
  returning version, updated_at into v_version, v_updated;

  perform private.touch_presence_seats(v_driver, v_layout_id);
  v_free := private.layout_free_count(v_layout_id);
  return jsonb_strip_nulls(jsonb_build_object(
    'seat_id', p_seat_id,
    'status', p_status,
    'version', v_version,
    'free', v_free,
    'updated_at', v_updated
  ));
end;
$$;

revoke all on function conductor_set_seat(text, text, text) from public;
grant execute on function conductor_set_seat(text, text, text) to authenticated;
