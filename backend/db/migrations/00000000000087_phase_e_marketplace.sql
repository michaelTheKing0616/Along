-- Phase E. Marketplace numbers are city config or something a person wrote.
-- A missing config key leaves that check off. Disputes do not change a fare.
-- The board shows a name and a plate. It does not show a phone.

create table fare_observations (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references profiles(id) on delete cascade,
  corridor_label text not null check (char_length(btrim(corridor_label)) between 2 and 80),
  hour_of_day integer not null check (hour_of_day between 0 and 23),
  amount_minor integer not null check (amount_minor between 1 and 100000000),
  kind text not null check (kind in ('paid', 'dispute')),
  client_ref text not null check (char_length(client_ref) between 8 and 80),
  created_at timestamptz not null default now(),
  unique (rider_id, client_ref)
);

create index fare_observations_corridor
  on fare_observations (corridor_label, hour_of_day, kind);

alter table fare_observations enable row level security;

create policy fare_observations_owner
  on fare_observations for select to authenticated
  using (rider_id = auth.uid() or is_admin());

grant select on fare_observations to authenticated;
revoke insert, update, delete on fare_observations from authenticated, anon;

create table rider_favourites (
  rider_id uuid not null references profiles(id) on delete cascade,
  driver_id uuid not null references drivers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (rider_id, driver_id)
);

alter table rider_favourites enable row level security;

create policy rider_favourites_owner
  on rider_favourites for select to authenticated
  using (rider_id = auth.uid() or is_admin());

grant select on rider_favourites to authenticated;
revoke insert, update, delete on rider_favourites from authenticated, anon;

create table driver_earnings_goals (
  driver_id uuid primary key references drivers(id) on delete cascade,
  target_minor integer,
  updated_at timestamptz not null default now(),
  constraint driver_earnings_goals_target
    check (target_minor is null or target_minor between 100 and 100000000)
);

alter table driver_earnings_goals enable row level security;

create policy driver_earnings_goals_owner
  on driver_earnings_goals for select to authenticated
  using (driver_id = auth.uid() or is_admin());

grant select on driver_earnings_goals to authenticated;
revoke insert, update, delete on driver_earnings_goals from authenticated, anon;

create table fuel_notes (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references drivers(id) on delete cascade,
  label text not null check (char_length(btrim(label)) between 2 and 80),
  price_naira numeric(8,2) not null check (price_naira between 100 and 5000),
  lat double precision not null,
  lng double precision not null,
  client_ref text not null check (char_length(client_ref) between 8 and 80),
  created_at timestamptz not null default now(),
  unique (driver_id, client_ref)
);

alter table fuel_notes enable row level security;

create policy fuel_notes_read
  on fuel_notes for select to authenticated
  using (true);

grant select on fuel_notes to authenticated;
revoke insert, update, delete on fuel_notes from authenticated, anon;

create table route_requests (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references profiles(id) on delete cascade,
  corridor_label text not null check (char_length(btrim(corridor_label)) between 2 and 80),
  client_ref text not null check (char_length(client_ref) between 8 and 80),
  created_at timestamptz not null default now(),
  unique (rider_id, client_ref)
);

alter table route_requests enable row level security;

create policy route_requests_owner
  on route_requests for select to authenticated
  using (rider_id = auth.uid() or is_admin());

grant select on route_requests to authenticated;
revoke insert, update, delete on route_requests from authenticated, anon;

create table pickup_events (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 80),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  lat double precision not null,
  lng double precision not null,
  client_ref text not null check (char_length(client_ref) between 8 and 80),
  created_at timestamptz not null default now(),
  unique (author_id, client_ref),
  check (ends_at > starts_at),
  check (ends_at <= starts_at + interval '14 days')
);

alter table pickup_events enable row level security;

create policy pickup_events_read
  on pickup_events for select to authenticated
  using (true);

grant select on pickup_events to authenticated;
revoke insert, update, delete on pickup_events from authenticated, anon;

create function stage_board(p_park_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_stale numeric;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_park_id is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;
  v_stale := coalesce(cfg_num('presence.offline_after_s', null), 180);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'driver_id', s.driver_id,
      'name', s.name,
      'plate', s.plate,
      'seats_free', s.seats_free,
      'seats_total', s.seats_total,
      'started_at', s.started_at,
      'verified', s.verified
    ) order by s.seats_free, s.started_at)
    from (
      select
        dp.driver_id,
        coalesce(pr.display_name, '') as name,
        v.plate_number as plate,
        dp.seats_available as seats_free,
        v.seat_capacity as seats_total,
        dp.started_at,
        (d.verified_status = 'verified') as verified
      from driver_presence dp
      join drivers d on d.id = dp.driver_id
      join profiles pr on pr.id = dp.driver_id
      join vehicles v on v.id = dp.vehicle_id
      where dp.park_id = p_park_id
        and dp.last_ping_at >= now() - make_interval(secs => v_stale::integer)
    ) s
  ), '[]'::jsonb);
end;
$$;

revoke all on function stage_board(uuid) from public;
grant execute on function stage_board(uuid) to authenticated;

create function record_fare_observation(
  p_corridor text,
  p_hour integer,
  p_amount_minor integer,
  p_kind text,
  p_client_ref text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_kind not in ('paid', 'dispute') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  insert into fare_observations (
    rider_id, corridor_label, hour_of_day, amount_minor, kind, client_ref
  ) values (
    v_user, btrim(p_corridor), p_hour, p_amount_minor, p_kind, p_client_ref
  )
  on conflict (rider_id, client_ref) do nothing
  returning id into v_id;

  return jsonb_build_object(
    'id', v_id,
    'replayed', v_id is null,
    'fare_changed', false
  );
end;
$$;

revoke all on function record_fare_observation(text, integer, integer, text, text) from public;
grant execute on function record_fare_observation(text, integer, integer, text, text) to authenticated;

create function fare_shield(p_corridor text, p_hour integer)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_samples integer;
  v_median numeric;
  v_min numeric;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select count(*), percentile_cont(0.5) within group (order by amount_minor)
    into v_samples, v_median
  from fare_observations
  where corridor_label = btrim(p_corridor)
    and hour_of_day = p_hour
    and kind = 'paid'
    and created_at > now() - interval '28 days';

  v_min := cfg_num('marketplace.fare_min_samples', null);
  return jsonb_build_object(
    'samples', coalesce(v_samples, 0),
    'median_minor', case when v_samples > 0 then round(v_median)::integer else null end,
    'min_samples', v_min,
    'show_at', cfg_num('marketplace.fare_show_at', null)
  );
end;
$$;

revoke all on function fare_shield(text, integer) from public;
grant execute on function fare_shield(text, integer) to authenticated;

create function fare_history(p_corridor text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'hour', hour_of_day,
      'median_minor', median_minor
    ) order by hour_of_day)
    from (
      select
        hour_of_day,
        round(percentile_cont(0.5) within group (order by amount_minor))::integer as median_minor
      from fare_observations
      where corridor_label = btrim(p_corridor)
        and kind = 'paid'
        and created_at > now() - interval '28 days'
      group by hour_of_day
    ) s
  ), '[]'::jsonb);
end;
$$;

revoke all on function fare_history(text) from public;
grant execute on function fare_history(text) to authenticated;

create function save_favourite(p_driver_id uuid, p_on boolean)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_on then
    insert into rider_favourites (rider_id, driver_id)
    values (v_user, p_driver_id)
    on conflict do nothing;
  else
    delete from rider_favourites
    where rider_id = v_user and driver_id = p_driver_id;
  end if;
end;
$$;

revoke all on function save_favourite(uuid, boolean) from public;
grant execute on function save_favourite(uuid, boolean) to authenticated;

create function list_favourites()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  return coalesce((
    select jsonb_agg(driver_id)
    from rider_favourites
    where rider_id = v_user
  ), '[]'::jsonb);
end;
$$;

revoke all on function list_favourites() from public;
grant execute on function list_favourites() to authenticated;

create function save_earnings_goal(p_target_minor integer)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not exists (select 1 from drivers where id = v_user) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  insert into driver_earnings_goals (driver_id, target_minor)
  values (v_user, p_target_minor)
  on conflict (driver_id) do update
    set target_minor = excluded.target_minor, updated_at = now();
end;
$$;

revoke all on function save_earnings_goal(integer) from public;
grant execute on function save_earnings_goal(integer) to authenticated;

create function record_fuel_note(
  p_label text,
  p_price_naira numeric,
  p_lat double precision,
  p_lng double precision,
  p_client_ref text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if not exists (select 1 from drivers where id = v_user) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  insert into fuel_notes (driver_id, label, price_naira, lat, lng, client_ref)
  values (v_user, btrim(p_label), p_price_naira, p_lat, p_lng, p_client_ref)
  on conflict (driver_id, client_ref) do nothing
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'replayed', v_id is null);
end;
$$;

revoke all on function record_fuel_note(text, numeric, double precision, double precision, text) from public;
grant execute on function record_fuel_note(text, numeric, double precision, double precision, text) to authenticated;

create function nearby_fuel(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if p_radius_m is null or p_radius_m <= 0 then
    return '[]'::jsonb;
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'label', label,
      'price_naira', price_naira,
      'lat', lat,
      'lng', lng
    ) order by price_naira)
    from fuel_notes
    where st_dwithin(
      st_setsrid(st_makepoint(lng, lat), 4326)::geography,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
  ), '[]'::jsonb);
end;
$$;

revoke all on function nearby_fuel(double precision, double precision, integer) from public;
grant execute on function nearby_fuel(double precision, double precision, integer) to authenticated;

create function request_route(p_corridor text, p_client_ref text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_count integer;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  insert into route_requests (rider_id, corridor_label, client_ref)
  values (v_user, btrim(p_corridor), p_client_ref)
  on conflict (rider_id, client_ref) do nothing;

  select count(*) into v_count
  from route_requests
  where corridor_label = btrim(p_corridor)
    and created_at > now() - interval '7 days';

  return jsonb_build_object(
    'count', v_count,
    'threshold', cfg_num('marketplace.route_request_notify', null)
  );
end;
$$;

revoke all on function request_route(text, text) from public;
grant execute on function request_route(text, text) to authenticated;

create function open_pickup_event(
  p_name text,
  p_starts timestamptz,
  p_ends timestamptz,
  p_lat double precision,
  p_lng double precision,
  p_client_ref text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  insert into pickup_events (
    author_id, name, starts_at, ends_at, lat, lng, client_ref
  ) values (
    v_user, btrim(p_name), p_starts, p_ends, p_lat, p_lng, p_client_ref
  )
  on conflict (author_id, client_ref) do nothing
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'replayed', v_id is null);
end;
$$;

revoke all on function open_pickup_event(text, timestamptz, timestamptz, double precision, double precision, text) from public;
grant execute on function open_pickup_event(text, timestamptz, timestamptz, double precision, double precision, text) to authenticated;

create function list_pickup_events()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'name', name,
      'starts_at', starts_at,
      'ends_at', ends_at,
      'lat', lat,
      'lng', lng
    ) order by starts_at)
    from pickup_events
    where ends_at > now()
  ), '[]'::jsonb);
end;
$$;

revoke all on function list_pickup_events() from public;
grant execute on function list_pickup_events() to authenticated;
