-- Na Me handshake (doc 05 §6, doc 07 §9): a per-trip colour+shape pairing that is
-- unique among live trips at the same boarding stage (or route), a per-trip
-- secret only the trip's rider and accepted driver can read, and
-- confirm_na_me_match() which boards the rider through the same gate as
-- verify_trip_pin().

create table trip_handshakes (
  trip_id uuid primary key references trips(id) on delete cascade,
  secret text not null default encode(extensions.gen_random_bytes(20), 'hex'),
  attempts integer not null default 0,
  tap_locked boolean not null default false,
  last_attempt_at timestamptz,
  matched_at timestamptz,
  matched_method text check (matched_method in ('tap', 'optical')),
  created_at timestamptz not null default now()
);

alter table trip_handshakes enable row level security;

create policy trip_handshakes_select_party
  on trip_handshakes for select to authenticated
  using (
    exists (
      select 1 from trips t
      where t.id = trip_handshakes.trip_id
        and t.status in ('accepted', 'boarded')
        and (t.rider_id = (select auth.uid()) or t.driver_id = (select auth.uid()))
    )
  );

revoke all on trip_handshakes from anon;
revoke insert, update, delete on trip_handshakes from authenticated;
grant select on trip_handshakes to authenticated;

-- Pairing scope: same boarding stage, else same route, else same driver.
create or replace function _na_me_scope_matches(a trips, b trips)
returns boolean
language sql
immutable
as $$
  select case
    when a.boarding_stage_id is not null then a.boarding_stage_id = b.boarding_stage_id
    when a.route_id is not null then a.route_id = b.route_id
    else a.driver_id = b.driver_id
  end;
$$;

-- Live pairs in a trip's scope, excluding the trip itself.
create or replace function _na_me_pairs_in_use(p_t trips)
returns text[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(t.id_signal_color || ':' || t.id_signal_shape), '{}'::text[])
  from trips t
  where t.id <> p_t.id
    and t.status in ('requested', 'accepted', 'boarded', 'in_transit')
    and _na_me_scope_matches(p_t, t);
$$;

-- At accept: keep the pairing if it is free in scope, else retry random free pairs.
create or replace function trips_na_me_unique_on_accept()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_used text[];
  v_city uuid;
  v_pair text;
  v_try int := 0;
  v_free text[];
begin
  perform pg_advisory_xact_lock(
    hashtext('na_me:' || coalesce(new.boarding_stage_id::text, new.route_id::text, new.driver_id::text, ''))
  );
  v_used := _na_me_pairs_in_use(new);
  if not ((new.id_signal_color || ':' || new.id_signal_shape) = any (v_used)) then
    return new;
  end if;

  select r.city_id into v_city from routes r where r.id = new.route_id;
  select array_agg(c || ':' || s)
  into v_free
  from jsonb_array_elements_text(cfg('name.colors', v_city)) c,
       jsonb_array_elements_text(cfg('name.shapes', v_city)) s
  where not ((c || ':' || s) = any (v_used));

  if v_free is null or cardinality(v_free) = 0 then
    raise exception 'Na Me palette exhausted at stage' using errcode = 'P0001';
  end if;
  -- Retry on collision: random draws, re-checked against the scope each time.
  loop
    v_try := v_try + 1;
    v_pair := v_free[1 + floor(random() * cardinality(v_free))::int];
    exit when not (v_pair = any (_na_me_pairs_in_use(new))) or v_try >= 8;
  end loop;
  new.id_signal_color := split_part(v_pair, ':', 1);
  new.id_signal_shape := split_part(v_pair, ':', 2);
  return new;
end;
$$;

create trigger trips_na_me_unique_on_accept
  before update of status on trips
  for each row
  when (new.status = 'accepted' and old.status is distinct from 'accepted')
  execute function trips_na_me_unique_on_accept();

create or replace function trips_na_me_handshake_on_accept()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into trip_handshakes (trip_id) values (new.id) on conflict (trip_id) do nothing;
  return null;
end;
$$;

create trigger trips_na_me_handshake_on_accept
  after insert or update of status on trips
  for each row
  when (new.status = 'accepted')
  execute function trips_na_me_handshake_on_accept();

-- 16-bit optical code for a 10 s step: HMAC-SHA256(secret, step), first two bytes.
create or replace function _na_me_optical_code(p_secret text, p_step bigint)
returns int
language sql
immutable
set search_path = public
as $$
  select (get_byte(h, 0) << 8) | get_byte(h, 1)
  from (select extensions.hmac(p_step::text, p_secret, 'sha256') as h) x;
$$;

-- The tap-match choices: the real pairing plus 3 decoys from palette pairs that
-- no live trip in scope holds. Order and decoys are stable per trip (seeded by
-- the secret), so refetching cannot narrow the answer down.
create or replace function na_me_tap_options(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_h trip_handshakes%rowtype;
  v_city uuid;
  v_real text;
  v_used text[];
  v_opts jsonb;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_t.driver_id is distinct from v_uid then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_t.status <> 'accepted' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;
  select * into v_h from trip_handshakes where trip_id = p_trip_id;
  if v_h.trip_id is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select r.city_id into v_city from routes r where r.id = v_t.route_id;
  v_real := v_t.id_signal_color || ':' || v_t.id_signal_shape;
  v_used := _na_me_pairs_in_use(v_t);

  with decoys as (
    select c || ':' || s as pair
    from jsonb_array_elements_text(cfg('name.colors', v_city)) c,
         jsonb_array_elements_text(cfg('name.shapes', v_city)) s
    where (c || ':' || s) <> v_real
      and not ((c || ':' || s) = any (v_used))
      and c <> v_t.id_signal_color
    order by md5(v_h.secret || 'decoy' || c || ':' || s)
    limit 3
  ), opts as (
    select pair from decoys union all select v_real
  )
  select jsonb_agg(
    jsonb_build_object(
      'color_token', split_part(pair, ':', 1),
      'shape', split_part(pair, ':', 2),
      'label', _na_me_label(split_part(pair, ':', 1), split_part(pair, ':', 2))
    ) order by md5(v_h.secret || 'order' || pair)
  ) into v_opts from opts;

  return jsonb_build_object(
    'options', v_opts,
    'tap_locked', v_h.tap_locked,
    'attempts_left', greatest(0, 3 - v_h.attempts)
  );
end;
$$;

-- p_proof: {"method":"tap","color_token":..,"shape":..}
--       or {"method":"optical","code":<0..65535>,"step":<unix/10>}.
-- Cap: 3 wrong attempts in total; one wrong tap also locks tap-match (with 4
-- choices a second tap would make elimination too easy). Wrong answers never
-- reveal the right pairing.
create or replace function confirm_na_me_match(p_trip_id uuid, p_proof jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_t trips%rowtype;
  v_h trip_handshakes%rowtype;
  v_max int := 3;
  v_method text := p_proof ->> 'method';
  v_ok boolean := false;
  v_now_step bigint := floor(extract(epoch from now()) / 10)::bigint;
  v_step bigint;
  v_code int;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;
  if v_method is null or v_method not in ('tap', 'optical') then
    raise exception 'VALIDATION_FAILED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_t.driver_id is distinct from v_uid then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_h from trip_handshakes where trip_id = p_trip_id for update;
  if v_h.trip_id is not null and v_h.matched_at is not null then
    return jsonb_build_object('matched', true, 'attempts_left', greatest(0, v_max - v_h.attempts));
  end if;
  if v_t.status <> 'accepted' or v_h.trip_id is null then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_h.attempts >= v_max then
    return jsonb_build_object('matched', false, 'attempts_left', 0, 'locked', true);
  end if;
  if v_method = 'tap' and v_h.tap_locked then
    return jsonb_build_object('matched', false, 'attempts_left', v_max - v_h.attempts, 'tap_locked', true);
  end if;
  if v_h.last_attempt_at > now() - interval '1 second' then
    return jsonb_build_object('matched', false, 'attempts_left', v_max - v_h.attempts, 'rate_limited', true);
  end if;

  if v_method = 'tap' then
    v_ok := (p_proof ->> 'color_token') = v_t.id_signal_color
        and (p_proof ->> 'shape') = v_t.id_signal_shape;
  else
    begin
      v_step := (p_proof ->> 'step')::bigint;
      v_code := (p_proof ->> 'code')::int;
    exception when others then
      raise exception 'VALIDATION_FAILED' using errcode = 'P0001';
    end;
    -- Clock skew: up to 30 s ahead; up to 10 min behind (offline-queued proofs).
    if v_step between v_now_step - 60 and v_now_step + 3 then
      v_ok := _na_me_optical_code(v_h.secret, v_step) = v_code;
    end if;
  end if;

  if not v_ok then
    update trip_handshakes
    set attempts = attempts + 1,
        last_attempt_at = now(),
        tap_locked = tap_locked or v_method = 'tap'
    where trip_id = p_trip_id;
    return jsonb_build_object(
      'matched', false,
      'attempts_left', v_max - v_h.attempts - 1,
      'locked', v_h.attempts + 1 >= v_max,
      'tap_locked', v_h.tap_locked or v_method = 'tap'
    );
  end if;

  update trip_handshakes
  set matched_at = now(), matched_method = v_method, last_attempt_at = now()
  where trip_id = p_trip_id;
  -- Same gate as verify_trip_pin: the PIN is satisfied, the rider is boarded.
  update trip_pins
  set verified_at = now(), verified_by = 'driver'
  where trip_id = p_trip_id and verified_at is null;
  perform trip_transition(p_trip_id, 'boarded', 'driver', v_uid);

  insert into audit_log (actor_id, actor_role, action, target_type, target_id, after)
  values (v_uid, 'driver', 'na_me_match', 'trips', p_trip_id::text,
          jsonb_build_object('method', v_method, 'attempts', v_h.attempts));

  return jsonb_build_object('matched', true, 'attempts_left', v_max - v_h.attempts);
end;
$$;

revoke execute on function confirm_na_me_match(uuid, jsonb) from public, anon;
grant execute on function confirm_na_me_match(uuid, jsonb) to authenticated;
revoke execute on function na_me_tap_options(uuid) from public, anon;
grant execute on function na_me_tap_options(uuid) to authenticated;
revoke execute on function _na_me_optical_code(text, bigint) from public, anon, authenticated;
revoke execute on function _na_me_pairs_in_use(trips) from public, anon, authenticated;
revoke execute on function trips_na_me_unique_on_accept() from public, anon, authenticated;
revoke execute on function trips_na_me_handshake_on_accept() from public, anon, authenticated;

-- Backfill: trips already accepted get a secret too.
insert into trip_handshakes (trip_id)
select id from trips where status = 'accepted'
on conflict do nothing;
