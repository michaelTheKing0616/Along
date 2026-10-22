-- Phase B: driver-built seat layouts and driver-authored ride rules.
-- Vehicle classes and rule presets are data. The app does not hardcode
-- women-only, front-seat, or hold policy; it interprets effect + params.

alter table mode_config
  add column layout_preset jsonb,
  add column review_seat_max smallint;

alter table mode_config
  add constraint mode_config_review_seat_max_check
  check (review_seat_max is null or (review_seat_max between 1 and 80));

-- ---------------------------------------------------------------------------
-- Starting layouts. Presets only — drivers edit and save their own.
-- ---------------------------------------------------------------------------
create or replace function private.mode_layout_preset(p_code text)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_rows jsonb := '[]'::jsonb;
  v_seats jsonb;
  v_r int;
  v_s int;
  v_per int;
  v_count int;
begin
  if p_code = 'car' then
    return '{"version":1,"body":"cabin","rows":[{"id":"front","seats":[{"id":"fp","role":"passenger","label":"Front"},{"id":"drv","role":"driver","label":"Driver"}]},{"id":"back","seats":[{"id":"bl","role":"passenger","label":"Back left"},{"id":"bm","role":"passenger","label":"Back middle"},{"id":"br","role":"passenger","label":"Back right"}]}]}'::jsonb;
  elsif p_code = 'along' then
    return '{"version":1,"body":"cabin","rows":[{"id":"front","seats":[{"id":"fl","role":"passenger","label":"Front left"},{"id":"fr","role":"passenger","label":"Front right"},{"id":"drv","role":"driver","label":"Driver"}]},{"id":"back","seats":[{"id":"b1","role":"passenger","label":"Back left"},{"id":"b2","role":"passenger","label":"Back middle left"},{"id":"b3","role":"passenger","label":"Back middle right"},{"id":"b4","role":"passenger","label":"Back right"}]}]}'::jsonb;
  elsif p_code = 'keke' then
    return '{"version":1,"body":"bench","rows":[{"id":"cab","seats":[{"id":"drv","role":"driver","label":"Driver"}]},{"id":"bench","seats":[{"id":"k1","role":"passenger","label":"Left"},{"id":"k2","role":"passenger","label":"Middle"},{"id":"k3","role":"passenger","label":"Right"}]}]}'::jsonb;
  elsif p_code = 'okada' then
    return '{"version":1,"body":"bike","rows":[{"id":"bike","seats":[{"id":"drv","role":"driver","label":"Rider"},{"id":"p1","role":"passenger","label":"Pillion"}]}]}'::jsonb;
  elsif p_code in ('minibus', 'danfo', 'bus') then
    v_rows := jsonb_build_array(jsonb_build_object(
      'id', 'cab',
      'seats', jsonb_build_array(jsonb_build_object(
        'id', 'drv', 'role', 'driver', 'label', 'Driver'
      ))
    ));
    if p_code = 'bus' then
      v_count := 10;
      v_per := 4;
    else
      v_count := 4;
      v_per := 3;
    end if;
    for v_r in 1..v_count loop
      v_seats := '[]'::jsonb;
      for v_s in 1..v_per loop
        v_seats := v_seats || jsonb_build_array(jsonb_build_object(
          'id', 'r' || v_r || 's' || v_s,
          'role', 'passenger',
          'label', 'Row ' || v_r || ' seat ' || v_s
        ));
      end loop;
      v_rows := v_rows || jsonb_build_array(jsonb_build_object(
        'id', 'r' || v_r,
        'seats', v_seats
      ));
    end loop;
    if p_code in ('minibus', 'danfo') then
      v_rows := v_rows || jsonb_build_array(jsonb_build_object(
        'id', 'r5',
        'seats', jsonb_build_array(
          jsonb_build_object('id', 'r5s1', 'role', 'passenger', 'label', 'Row 5 seat 1'),
          jsonb_build_object('id', 'r5s2', 'role', 'passenger', 'label', 'Row 5 seat 2')
        )
      ));
    end if;
    return jsonb_build_object('version', 1, 'body', 'coach', 'rows', v_rows);
  end if;
  return null;
end;
$$;

revoke all on function private.mode_layout_preset(text) from public;

insert into mode_config (
  code, label, icon_key, color_token, comfort_weight, load_capacity,
  default_seat_capacity, sort_order, layout_preset, review_seat_max
) values
  ('car', 'Along taxi', 'mode.car', 'mode.car', 4.0, 'large', 4, 10, private.mode_layout_preset('car'), 4),
  ('along', 'Along car', 'mode.car', 'mode.car', 4.0, 'large', 6, 15, private.mode_layout_preset('along'), 6),
  ('keke', 'Keke', 'mode.keke', 'mode.keke', 6.0, 'small', 3, 20, private.mode_layout_preset('keke'), 4),
  ('okada', 'Okada', 'mode.okada', 'mode.okada', 8.0, 'none', 1, 30, private.mode_layout_preset('okada'), 2),
  ('minibus', 'Minibus', 'mode.minibus', 'mode.minibus', 5.0, 'medium', 14, 40, private.mode_layout_preset('minibus'), 18),
  ('danfo', 'Danfo', 'mode.minibus', 'mode.minibus', 5.0, 'medium', 14, 45, private.mode_layout_preset('danfo'), 18),
  ('bus', 'Bus', 'mode.minibus', 'mode.minibus', 5.0, 'large', 40, 50, private.mode_layout_preset('bus'), 60)
on conflict (code) do update set
  layout_preset = excluded.layout_preset,
  review_seat_max = excluded.review_seat_max,
  updated_at = now();

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table ride_rule_presets (
  id text primary key,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  body text check (body is null or char_length(body) <= 280),
  effect text not null check (effect in ('badge', 'hold_minutes', 'cap_seats', 'acknowledge')),
  target_scope text not null check (target_scope in ('vehicle', 'row', 'seat')),
  default_params jsonb not null default '{}'::jsonb,
  sort_order smallint not null default 100,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into ride_rule_presets (id, title, body, effect, target_scope, default_params, sort_order) values
  (
    'seat_hold',
    'Hold a seat',
    'Hold a seat for the number of minutes you set.',
    'hold_minutes',
    'vehicle',
    '{"duration_minutes":3}'::jsonb,
    10
  ),
  (
    'max_front_passengers',
    'Passenger cap',
    'Cap how many passengers sit in the row you choose.',
    'cap_seats',
    'row',
    '{"max":1}'::jsonb,
    20
  ),
  (
    'women_only_row',
    'Women-only row',
    'Riders acknowledge this row before they take a seat in it.',
    'acknowledge',
    'row',
    '{}'::jsonb,
    30
  ),
  (
    'front_seat_offered',
    'Front seat offered',
    'You are offering a front passenger seat.',
    'badge',
    'vehicle',
    '{}'::jsonb,
    40
  );

create table vehicle_layouts (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  driver_id uuid not null references drivers(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 60),
  layout jsonb not null,
  passenger_seats smallint not null check (passenger_seats >= 1),
  over_capacity boolean not null default false,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (vehicle_id, name)
);

create unique index vehicle_layouts_one_active
  on vehicle_layouts (vehicle_id) where is_active;

create index vehicle_layouts_driver on vehicle_layouts (driver_id, vehicle_id);

create trigger vehicle_layouts_set_updated_at before update on vehicle_layouts
  for each row execute function set_updated_at();

create table vehicle_seat_states (
  layout_id uuid not null references vehicle_layouts(id) on delete cascade,
  seat_id text not null,
  status text not null default 'free' check (status in ('free', 'occupied', 'held', 'blocked')),
  holder_profile_id uuid references profiles(id),
  version integer not null default 1 check (version >= 1),
  hold_until timestamptz,
  updated_at timestamptz not null default now(),
  primary key (layout_id, seat_id)
);

create index vehicle_seat_states_updated on vehicle_seat_states (layout_id, updated_at);

create table driver_ride_rules (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id) on delete cascade,
  preset_id text references ride_rule_presets(id),
  effect text not null check (effect in ('badge', 'hold_minutes', 'cap_seats', 'acknowledge')),
  target_scope text not null check (target_scope in ('vehicle', 'row', 'seat')),
  target_ref text,
  title text not null check (char_length(btrim(title)) between 1 and 80),
  body text check (body is null or char_length(body) <= 280),
  params jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (preset_id is not null or effect = 'badge'),
  check (target_scope = 'vehicle' or target_ref is not null)
);

create index driver_ride_rules_vehicle
  on driver_ride_rules (driver_id, vehicle_id) where enabled;

create trigger driver_ride_rules_set_updated_at before update on driver_ride_rules
  for each row execute function set_updated_at();

create table driver_day_plans (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  vehicle_id uuid not null references vehicles(id),
  layout_id uuid not null references vehicle_layouts(id),
  corridor_id uuid not null references corridors(id),
  route_id uuid references routes(id),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index driver_day_plans_one_active
  on driver_day_plans (driver_id) where active;

-- ---------------------------------------------------------------------------
-- Layout helpers
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
      if v_role is null or v_role not in ('driver', 'passenger') then
        raise exception 'VALIDATION' using errcode = 'P0001';
      end if;
      v_ids := v_ids || v_id;
      v_total := v_total + 1;
      if v_role = 'driver' then
        v_drivers := v_drivers + 1;
      else
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

create or replace function private.seat_row_id(p_layout jsonb, p_seat_id text)
returns text
language sql
immutable
as $$
  select rowj->>'id'
  from jsonb_array_elements(p_layout->'rows') rowj,
       jsonb_array_elements(rowj->'seats') seat
  where seat->>'id' = p_seat_id
  limit 1;
$$;

revoke all on function private.seat_row_id(jsonb, text) from public;

create or replace function private.seat_state_is_free(p_status text, p_hold_until timestamptz)
returns boolean
language sql
stable
as $$
  select p_status is null
    or p_status = 'free'
    or (
      p_status = 'held'
      and p_hold_until is not null
      and p_hold_until < now()
    );
$$;

revoke all on function private.seat_state_is_free(text, timestamptz) from public;

create or replace function private.sync_layout_seats(p_layout_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ids jsonb;
begin
  v_ids := private.seat_layout_stats(
    (select layout from vehicle_layouts where id = p_layout_id)
  )->'passenger_ids';

  delete from vehicle_seat_states
  where layout_id = p_layout_id
    and seat_id <> all (select jsonb_array_elements_text(v_ids));

  insert into vehicle_seat_states (layout_id, seat_id, status)
  select p_layout_id, sid, 'free'
  from jsonb_array_elements_text(v_ids) as sid
  on conflict (layout_id, seat_id) do nothing;
end;
$$;

revoke all on function private.sync_layout_seats(uuid) from public;

create or replace function private.layout_free_count(p_layout_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  with stats as (
    select private.seat_layout_stats(l.layout)->'passenger_ids' as ids
    from vehicle_layouts l
    where l.id = p_layout_id
  )
  select count(*)::int
  from stats
  cross join lateral jsonb_array_elements_text(stats.ids) as sid(seat_id)
  left join vehicle_seat_states s
    on s.layout_id = p_layout_id
   and s.seat_id = sid.seat_id
  where private.seat_state_is_free(s.status, s.hold_until);
$$;

revoke all on function private.layout_free_count(uuid) from public;

create or replace function private.touch_presence_seats(p_driver_id uuid, p_layout_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update driver_presence
  set seats_available = private.layout_free_count(p_layout_id),
      updated_at = now()
  where driver_id = p_driver_id;
end;
$$;

revoke all on function private.touch_presence_seats(uuid, uuid) from public;

create or replace function private.hold_minutes(p_layout_id uuid, p_seat_id text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select (r.params->>'duration_minutes')::int
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

revoke all on function private.hold_minutes(uuid, text) from public;

create or replace function private.rule_json(r driver_ride_rules)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'id', r.id,
    'preset_id', r.preset_id,
    'effect', r.effect,
    'target_scope', r.target_scope,
    'target_ref', r.target_ref,
    'title', r.title,
    'body', r.body,
    'params', r.params,
    'enabled', r.enabled
  );
$$;

revoke all on function private.rule_json(driver_ride_rules) from public;

create or replace function private.owns_vehicle(p_driver_id uuid, p_vehicle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from driver_vehicles dv
    where dv.driver_id = p_driver_id
      and dv.vehicle_id = p_vehicle_id
  );
$$;

revoke all on function private.owns_vehicle(uuid, uuid) from public;

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------
create or replace function save_vehicle_layout(
  p_vehicle_id uuid,
  p_name text,
  p_layout jsonb,
  p_activate boolean default true
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_stats jsonb;
  v_passengers int;
  v_review int;
  v_over boolean;
  v_id uuid;
  v_name text := btrim(p_name);
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not private.owns_vehicle(v_user, p_vehicle_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_name is null or char_length(v_name) < 1 or char_length(v_name) > 60 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_stats := private.seat_layout_stats(p_layout);
  v_passengers := (v_stats->>'passenger_seats')::int;

  select coalesce(m.review_seat_max, m.default_seat_capacity)
  into v_review
  from vehicles v
  join mode_config m on m.code = v.mode_code
  where v.id = p_vehicle_id;

  v_over := v_review is not null and v_passengers > v_review;

  if coalesce(p_activate, true) then
    update vehicle_layouts
    set is_active = false
    where vehicle_id = p_vehicle_id
      and is_active
      and name <> v_name;
  end if;

  insert into vehicle_layouts (
    vehicle_id, driver_id, name, layout, passenger_seats, over_capacity, is_active
  ) values (
    p_vehicle_id, v_user, v_name, p_layout, v_passengers, v_over, coalesce(p_activate, true)
  )
  on conflict (vehicle_id, name) do update set
    driver_id = excluded.driver_id,
    layout = excluded.layout,
    passenger_seats = excluded.passenger_seats,
    over_capacity = excluded.over_capacity,
    is_active = case when coalesce(p_activate, true) then true else vehicle_layouts.is_active end
  returning id into v_id;

  perform private.sync_layout_seats(v_id);
  update vehicles set seat_capacity = v_passengers, updated_at = now()
  where id = p_vehicle_id;
  perform private.touch_presence_seats(v_user, v_id);

  return jsonb_build_object(
    'id', v_id,
    'passenger_seats', v_passengers,
    'over_capacity', v_over
  );
end;
$$;

create or replace function save_ride_rule(
  p_vehicle_id uuid,
  p_preset_id text default null,
  p_title text default null,
  p_body text default null,
  p_params jsonb default '{}'::jsonb,
  p_target_ref text default null,
  p_enabled boolean default true,
  p_rule_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_preset ride_rule_presets%rowtype;
  v_effect text;
  v_scope text;
  v_title text;
  v_body text;
  v_params jsonb;
  v_ref text;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not private.owns_vehicle(v_user, p_vehicle_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_rule_id is not null and not exists (
    select 1 from driver_ride_rules
    where id = p_rule_id and driver_id = v_user
  ) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_params := coalesce(p_params, '{}'::jsonb);
  if jsonb_typeof(v_params) <> 'object' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_preset_id is not null then
    select * into v_preset from ride_rule_presets where id = p_preset_id and active;
    if not found then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
    v_effect := v_preset.effect;
    v_scope := v_preset.target_scope;
    v_params := v_preset.default_params || v_params;
    v_title := coalesce(nullif(btrim(p_title), ''), v_preset.title);
    v_body := coalesce(p_body, v_preset.body);
  else
    v_effect := 'badge';
    v_scope := 'vehicle';
    v_title := btrim(p_title);
    v_body := p_body;
    v_params := '{}'::jsonb;
  end if;

  if v_title is null or char_length(v_title) < 1 or char_length(v_title) > 80 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_body is not null and char_length(v_body) > 280 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if v_scope = 'vehicle' then
    v_ref := null;
  else
    v_ref := nullif(btrim(p_target_ref), '');
    if v_ref is null or char_length(v_ref) > 40 then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
  end if;

  if v_effect = 'cap_seats' and (v_params->>'max') is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_effect = 'hold_minutes' and (v_params->>'duration_minutes') is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_effect = 'cap_seats' and ((v_params->>'max')::int < 0 or (v_params->>'max')::int > 80) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_effect = 'hold_minutes'
     and ((v_params->>'duration_minutes')::int < 1 or (v_params->>'duration_minutes')::int > 180) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_rule_id is null then
    insert into driver_ride_rules (
      driver_id, vehicle_id, preset_id, effect, target_scope, target_ref,
      title, body, params, enabled
    ) values (
      v_user, p_vehicle_id, p_preset_id, v_effect, v_scope, v_ref,
      v_title, v_body, v_params, coalesce(p_enabled, true)
    )
    returning id into v_id;
  else
    update driver_ride_rules set
      vehicle_id = p_vehicle_id,
      preset_id = p_preset_id,
      effect = v_effect,
      target_scope = v_scope,
      target_ref = v_ref,
      title = v_title,
      body = v_body,
      params = v_params,
      enabled = coalesce(p_enabled, true)
    where id = p_rule_id and driver_id = v_user
    returning id into v_id;
  end if;

  return (
    select private.rule_json(r) from driver_ride_rules r where r.id = v_id
  );
end;
$$;

create or replace function delete_ride_rule(p_rule_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_owner uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select driver_id into v_owner from driver_ride_rules where id = p_rule_id;
  if v_owner is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_owner <> v_user then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  delete from driver_ride_rules where id = p_rule_id;
  return jsonb_build_object('id', p_rule_id);
end;
$$;

create or replace function start_driver_day(
  p_vehicle_id uuid,
  p_layout_id uuid,
  p_corridor_id uuid,
  p_route_id uuid default null
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
  insert into driver_day_plans (driver_id, vehicle_id, layout_id, corridor_id, route_id, active)
  values (v_user, p_vehicle_id, p_layout_id, p_corridor_id, p_route_id, true)
  returning id into v_id;

  perform private.touch_presence_seats(v_user, p_layout_id);

  return jsonb_build_object('id', v_id, 'layout_id', p_layout_id);
end;
$$;

create or replace function my_day_setup()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_city uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select city_id into v_city from drivers where id = v_user;
  if v_city is null then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'vehicles', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', v.id,
        'mode_code', v.mode_code,
        'plate_number', v.plate_number,
        'seat_capacity', v.seat_capacity,
        'color', v.color,
        'make_model', v.make_model,
        'review_seat_max', coalesce(m.review_seat_max, m.default_seat_capacity),
        'layout_preset', m.layout_preset
      ) order by v.created_at)
      from driver_vehicles dv
      join vehicles v on v.id = dv.vehicle_id
      join mode_config m on m.code = v.mode_code
      where dv.driver_id = v_user
    ), '[]'::jsonb),
    'layouts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', l.id,
        'vehicle_id', l.vehicle_id,
        'name', l.name,
        'layout', l.layout,
        'passenger_seats', l.passenger_seats,
        'over_capacity', l.over_capacity,
        'is_active', l.is_active
      ) order by l.name)
      from vehicle_layouts l
      where l.driver_id = v_user
    ), '[]'::jsonb),
    'corridors', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', c.id, 'name', c.name, 'slug', c.slug
      ) order by c.name)
      from corridors c
      where c.city_id = v_city and c.status = 'live'
    ), '[]'::jsonb),
    'routes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', r.id,
        'name', r.name,
        'corridor_id', r.corridor_id,
        'mode_code', r.mode_code
      ) order by r.name)
      from (
        select id, name, corridor_id, mode_code
        from routes
        where city_id = v_city and active
        order by name
        limit 80
      ) r
    ), '[]'::jsonb),
    'rules', coalesce((
      select jsonb_agg(private.rule_json(rr) order by rr.created_at)
      from driver_ride_rules rr
      where rr.driver_id = v_user
    ), '[]'::jsonb),
    'presets', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'title', p.title,
        'body', p.body,
        'effect', p.effect,
        'target_scope', p.target_scope,
        'default_params', p.default_params
      ) order by p.sort_order)
      from ride_rule_presets p
      where p.active
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function seat_board(p_layout_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout vehicle_layouts%rowtype;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_layout_id is null then
    select l.* into v_layout
    from driver_day_plans p
    join vehicle_layouts l on l.id = p.layout_id
    where p.driver_id = v_user and p.active
    limit 1;
  else
    select * into v_layout from vehicle_layouts where id = p_layout_id;
  end if;

  if v_layout.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_layout.driver_id <> v_user and not v_layout.is_active then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'layout_id', v_layout.id,
    'vehicle_id', v_layout.vehicle_id,
    'name', v_layout.name,
    'body', v_layout.layout->>'body',
    'layout', v_layout.layout,
    'passenger_seats', v_layout.passenger_seats,
    'over_capacity', v_layout.over_capacity,
    'free', private.layout_free_count(v_layout.id),
    'seat_updated_at', (
      select max(s.updated_at) from vehicle_seat_states s where s.layout_id = v_layout.id
    ),
    'seats', coalesce((
      select jsonb_agg(jsonb_build_object(
        'seat_id', s.seat_id,
        'status', s.status,
        'version', s.version,
        'hold_until', s.hold_until,
        'updated_at', s.updated_at
      ) order by s.seat_id)
      from vehicle_seat_states s
      where s.layout_id = v_layout.id
    ), '[]'::jsonb),
    'rules', coalesce((
      select jsonb_agg(private.rule_json(r) order by r.created_at)
      from driver_ride_rules r
      where r.driver_id = v_layout.driver_id
        and r.vehicle_id = v_layout.vehicle_id
        and r.enabled
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function set_seat_status(
  p_layout_id uuid,
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
  v_layout vehicle_layouts%rowtype;
  v_minutes int;
  v_hold timestamptz;
  v_version int;
  v_updated timestamptz;
  v_free int;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_status is null or p_status not in ('free', 'occupied', 'held', 'blocked') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select * into v_layout from vehicle_layouts where id = p_layout_id;
  if v_layout.id is null or v_layout.driver_id <> v_user then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from vehicle_seat_states
    where layout_id = p_layout_id and seat_id = p_seat_id
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_status = 'held' then
    v_minutes := private.hold_minutes(p_layout_id, p_seat_id);
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
  where layout_id = p_layout_id and seat_id = p_seat_id
  returning version, updated_at into v_version, v_updated;

  perform private.touch_presence_seats(v_user, p_layout_id);
  v_free := private.layout_free_count(p_layout_id);

  return jsonb_strip_nulls(jsonb_build_object(
    'seat_id', p_seat_id,
    'status', p_status,
    'version', v_version,
    'free', v_free,
    'updated_at', v_updated,
    'hold_until', v_hold
  ));
end;
$$;

create or replace function set_all_seats(p_layout_id uuid, p_status text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout vehicle_layouts%rowtype;
  v_free int;
  v_updated timestamptz;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_status is null or p_status not in ('free', 'occupied') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  select * into v_layout from vehicle_layouts where id = p_layout_id;
  if v_layout.id is null or v_layout.driver_id <> v_user then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  update vehicle_seat_states set
    status = p_status,
    holder_profile_id = null,
    hold_until = null,
    version = version + 1,
    updated_at = now()
  where layout_id = p_layout_id;

  perform private.touch_presence_seats(v_user, p_layout_id);
  v_free := private.layout_free_count(p_layout_id);
  select max(updated_at) into v_updated
  from vehicle_seat_states where layout_id = p_layout_id;

  return jsonb_build_object(
    'status', p_status,
    'free', v_free,
    'updated_at', v_updated
  );
end;
$$;

create or replace function claim_seat(
  p_layout_id uuid,
  p_seat_id text,
  p_expected_version integer,
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
  v_version int;
  v_updated timestamptz;
  v_free int;
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

  if exists (
    select 1
    from driver_ride_rules r
    where r.driver_id = v_layout.driver_id
      and r.vehicle_id = v_layout.vehicle_id
      and r.enabled
      and r.effect = 'cap_seats'
      and (
        r.target_scope = 'vehicle'
        or (r.target_scope = 'row' and r.target_ref = v_row)
        or (r.target_scope = 'seat' and r.target_ref = p_seat_id)
      )
      and (
        select count(*)
        from jsonb_array_elements(v_layout.layout->'rows') rowj
        cross join lateral jsonb_array_elements(rowj->'seats') seat
        left join vehicle_seat_states s
          on s.layout_id = p_layout_id
         and s.seat_id = seat->>'id'
        where seat->>'role' = 'passenger'
          and (
            r.target_scope = 'vehicle'
            or (r.target_scope = 'row' and rowj->>'id' = r.target_ref)
            or (r.target_scope = 'seat' and seat->>'id' = r.target_ref)
          )
          and not private.seat_state_is_free(s.status, s.hold_until)
      ) >= (r.params->>'max')::int
  ) then
    raise exception 'RULE_CAP' using errcode = 'P0001';
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
  set status = 'occupied',
      holder_profile_id = v_user,
      hold_until = null,
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
    'status', 'occupied',
    'version', v_version,
    'free', v_free,
    'updated_at', v_updated
  );
end;
$$;

create or replace function release_seat(p_layout_id uuid, p_seat_id text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_layout vehicle_layouts%rowtype;
  v_holder uuid;
  v_version int;
  v_updated timestamptz;
  v_free int;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_layout from vehicle_layouts where id = p_layout_id;
  if v_layout.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  select holder_profile_id into v_holder
  from vehicle_seat_states
  where layout_id = p_layout_id and seat_id = p_seat_id;
  if not found then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  if v_user <> v_layout.driver_id and v_user is distinct from v_holder then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  update vehicle_seat_states set
    status = 'free',
    holder_profile_id = null,
    hold_until = null,
    version = version + 1,
    updated_at = now()
  where layout_id = p_layout_id and seat_id = p_seat_id
  returning version, updated_at into v_version, v_updated;

  perform private.touch_presence_seats(v_layout.driver_id, p_layout_id);
  v_free := private.layout_free_count(p_layout_id);

  return jsonb_build_object(
    'seat_id', p_seat_id,
    'status', 'free',
    'version', v_version,
    'free', v_free,
    'updated_at', v_updated
  );
end;
$$;

create or replace function private.vehicle_card(p_layout_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_layout vehicle_layouts%rowtype;
  v_vehicle vehicles%rowtype;
begin
  select * into v_layout from vehicle_layouts where id = p_layout_id;
  if v_layout.id is null then
    return '{}'::jsonb;
  end if;
  select * into v_vehicle from vehicles where id = v_layout.vehicle_id;
  return jsonb_build_object(
    'driver_id', v_layout.driver_id,
    'vehicle_id', v_layout.vehicle_id,
    'layout_id', v_layout.id,
    'plate_number', v_vehicle.plate_number,
    'mode_code', v_vehicle.mode_code,
    'color', v_vehicle.color,
    'make_model', v_vehicle.make_model,
    'body', v_layout.layout->>'body',
    'layout', v_layout.layout,
    'free_count', private.layout_free_count(v_layout.id),
    'seat_updated_at', coalesce(
      (select max(s.updated_at) from vehicle_seat_states s where s.layout_id = v_layout.id),
      v_layout.updated_at
    ),
    'seats', coalesce((
      select jsonb_agg(jsonb_build_object(
        'seat_id', s.seat_id,
        'status', s.status,
        'version', s.version,
        'hold_until', s.hold_until,
        'updated_at', s.updated_at
      ) order by s.seat_id)
      from vehicle_seat_states s
      where s.layout_id = v_layout.id
    ), '[]'::jsonb),
    'rules', coalesce((
      select jsonb_agg(private.rule_json(r) order by r.created_at)
      from driver_ride_rules r
      where r.driver_id = v_layout.driver_id
        and r.vehicle_id = v_layout.vehicle_id
        and r.enabled
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function private.vehicle_card(uuid) from public;

create or replace function online_vehicle_cards(
  p_city_id uuid,
  p_preset_ids text[] default '{}',
  p_query text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_query text := nullif(lower(btrim(coalesce(p_query, ''))), '');
  v_cards jsonb;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select coalesce(jsonb_agg(private.vehicle_card(p.layout_id) order by dp.last_ping_at desc), '[]'::jsonb)
  into v_cards
  from driver_day_plans p
  join driver_presence dp on dp.driver_id = p.driver_id and dp.vehicle_id = p.vehicle_id
  join drivers d on d.id = p.driver_id
  where p.active
    and d.city_id = p_city_id
    and dp.status::text <> 'offline'
    and (
      p_preset_ids is null
      or cardinality(p_preset_ids) = 0
      or (
        select count(distinct r.preset_id)
        from driver_ride_rules r
        where r.driver_id = p.driver_id
          and r.vehicle_id = p.vehicle_id
          and r.enabled
          and r.preset_id = any(p_preset_ids)
      ) = cardinality(p_preset_ids)
    )
    and (
      v_query is null
      or exists (
        select 1 from driver_ride_rules r
        where r.driver_id = p.driver_id
          and r.vehicle_id = p.vehicle_id
          and r.enabled
          and (
            position(v_query in lower(r.title)) > 0
            or position(v_query in lower(coalesce(r.body, ''))) > 0
          )
      )
    );

  return jsonb_build_object(
    'presets', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', pr.id,
        'title', pr.title,
        'body', pr.body,
        'effect', pr.effect,
        'target_scope', pr.target_scope,
        'default_params', pr.default_params
      ) order by pr.sort_order)
      from ride_rule_presets pr
      where pr.active
    ), '[]'::jsonb),
    'cards', coalesce(v_cards, '[]'::jsonb)
  );
end;
$$;

create or replace function vehicle_card_for_trip(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_rider uuid;
  v_driver uuid;
  v_vehicle uuid;
  v_layout uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select rider_id, driver_id, vehicle_id
  into v_rider, v_driver, v_vehicle
  from trips where id = p_trip_id;
  if v_rider is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_user <> v_rider and v_user is distinct from v_driver then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select l.id into v_layout
  from vehicle_layouts l
  where l.vehicle_id = v_vehicle
    and (
      l.is_active
      or l.id = (
        select p.layout_id from driver_day_plans p
        where p.driver_id = v_driver and p.active
        limit 1
      )
    )
  order by l.is_active desc
  limit 1;

  if v_layout is null then
    return '{}'::jsonb;
  end if;
  return private.vehicle_card(v_layout);
end;
$$;

revoke all on function save_vehicle_layout(uuid, text, jsonb, boolean) from public;
grant execute on function save_vehicle_layout(uuid, text, jsonb, boolean) to authenticated;

revoke all on function save_ride_rule(uuid, text, text, text, jsonb, text, boolean, uuid) from public;
grant execute on function save_ride_rule(uuid, text, text, text, jsonb, text, boolean, uuid) to authenticated;

revoke all on function delete_ride_rule(uuid) from public;
grant execute on function delete_ride_rule(uuid) to authenticated;

revoke all on function start_driver_day(uuid, uuid, uuid, uuid) from public;
grant execute on function start_driver_day(uuid, uuid, uuid, uuid) to authenticated;

revoke all on function my_day_setup() from public;
grant execute on function my_day_setup() to authenticated;

revoke all on function seat_board(uuid) from public;
grant execute on function seat_board(uuid) to authenticated;

revoke all on function set_seat_status(uuid, text, text) from public;
grant execute on function set_seat_status(uuid, text, text) to authenticated;

revoke all on function set_all_seats(uuid, text) from public;
grant execute on function set_all_seats(uuid, text) to authenticated;

revoke all on function claim_seat(uuid, text, integer, uuid[]) from public;
grant execute on function claim_seat(uuid, text, integer, uuid[]) to authenticated;

revoke all on function release_seat(uuid, text) from public;
grant execute on function release_seat(uuid, text) to authenticated;

revoke all on function online_vehicle_cards(uuid, text[], text) from public;
grant execute on function online_vehicle_cards(uuid, text[], text) to authenticated;

revoke all on function vehicle_card_for_trip(uuid) from public;
grant execute on function vehicle_card_for_trip(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS. Writes go through the RPCs above.
-- ---------------------------------------------------------------------------
alter table ride_rule_presets enable row level security;
alter table vehicle_layouts enable row level security;
alter table vehicle_seat_states enable row level security;
alter table driver_ride_rules enable row level security;
alter table driver_day_plans enable row level security;

create policy ride_rule_presets_read
  on ride_rule_presets for select to authenticated
  using (active or is_admin());

create policy vehicle_layouts_read
  on vehicle_layouts for select to authenticated
  using (is_active or driver_id = auth.uid() or is_admin());

create policy vehicle_seat_states_read
  on vehicle_seat_states for select to authenticated
  using (
    exists (
      select 1 from vehicle_layouts l
      where l.id = vehicle_seat_states.layout_id
        and (l.is_active or l.driver_id = auth.uid() or is_admin())
    )
  );

create policy driver_ride_rules_read
  on driver_ride_rules for select to authenticated
  using (enabled or driver_id = auth.uid() or is_admin());

create policy driver_day_plans_read
  on driver_day_plans for select to authenticated
  using (driver_id = auth.uid() or is_admin());

grant select on ride_rule_presets to authenticated;
grant select on vehicle_layouts to authenticated;
grant select on vehicle_seat_states to authenticated;
grant select on driver_ride_rules to authenticated;
grant select on driver_day_plans to authenticated;

do $$
begin
  execute 'alter publication supabase_realtime add table public.vehicle_seat_states';
exception
  when undefined_object or duplicate_object then
    null;
end $$;
