-- P4-A-05: trip extensions — propose_extension, respond_extension, completion commission (doc 04 §17)

select config_default('extension.proposal_ttl_s', '120');

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function _extension_parse_endpoint(p_value jsonb)
returns table (stage_id uuid, point geography)
language plpgsql
immutable
set search_path = public, extensions
as $$
begin
  if p_value is null then
    return;
  end if;

  if p_value ? 'stage_id' then
    stage_id := nullif(p_value->>'stage_id', '')::uuid;
  end if;

  if p_value ? 'lat' and p_value ? 'lng' then
    point := st_setsrid(
      st_makepoint((p_value->>'lng')::double precision, (p_value->>'lat')::double precision),
      4326
    )::geography;
  end if;

  if stage_id is not null or point is not null then
    return next;
    return;
  end if;

  raise exception 'VALIDATION' using errcode = 'P0001';
end;
$$;

create or replace function _extension_trip_actor(p_trip_id uuid, p_uid uuid)
returns actor_type
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_t trips%rowtype;
begin
  select * into v_t from trips where id = p_trip_id;

  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.rider_id = p_uid then
    return 'rider';
  end if;

  if v_t.driver_id = p_uid then
    return 'driver';
  end if;

  raise exception 'FORBIDDEN' using errcode = 'P0001';
end;
$$;

-- ---------------------------------------------------------------------------
-- propose_extension — doc 03 §5, doc 04 §17
-- ---------------------------------------------------------------------------
create or replace function propose_extension(
  p_trip_id uuid,
  p_new_alight jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_actor actor_type;
  v_t trips%rowtype;
  v_city_id uuid;
  v_new record;
  v_from_stage uuid;
  v_from_point geography;
  v_to_stage uuid;
  v_to_point geography;
  v_snap_radius numeric;
  v_seq_from int;
  v_seq_to int;
  v_fare fare_resolution;
  v_fare_delta numeric(12,2);
  v_commission_delta numeric(12,2);
  v_new_total numeric(12,2);
  v_accepted_delta numeric(12,2);
  v_ext_id uuid;
  v_ttl_s int;
  v_expires timestamptz;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_actor := _extension_trip_actor(p_trip_id, v_uid);

  if v_t.status not in ('boarded', 'in_transit') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from trip_extensions te
    where te.trip_id = p_trip_id
      and te.status = 'proposed'
      and te.expires_at > now()
  ) then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select j.city_id into v_city_id
  from journeys j
  where j.id = v_t.journey_id;

  select * into v_new from _extension_parse_endpoint(p_new_alight);
  v_to_stage := v_new.stage_id;
  v_to_point := v_new.point;
  v_snap_radius := cfg_num('graph.snap_radius_m', v_city_id);

  v_from_stage := v_t.alighting_stage_id;
  v_from_point := v_t.alighting_location;

  if v_from_stage is null and v_from_point is not null then
    v_from_stage := snap_stage(v_from_point, v_snap_radius, v_city_id);
  end if;

  if v_to_stage is null and v_to_point is not null then
    v_to_stage := snap_stage(v_to_point, v_snap_radius, v_city_id);
  elsif v_to_stage is not null and v_to_point is null then
    select rs.location into v_to_point
    from route_stages rs
    where rs.id = v_to_stage;
  end if;

  if v_from_stage is null or v_to_stage is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if v_from_stage = v_to_stage then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if v_t.driver_route_profile_id is not null then
    select drs_from.sequence, drs_to.sequence
    into v_seq_from, v_seq_to
    from driver_route_stops drs_from
    join driver_route_stops drs_to on drs_to.profile_id = drs_from.profile_id
    where drs_from.profile_id = v_t.driver_route_profile_id
      and drs_from.route_stage_id = v_from_stage
      and drs_to.route_stage_id = v_to_stage;

    if v_seq_from is null or v_seq_from >= v_seq_to then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    v_fare := resolve_fare(
      p_profile_id := v_t.driver_route_profile_id,
      p_from_stage_id := v_from_stage,
      p_to_stage_id := v_to_stage,
      p_mode_code := v_t.mode_code,
      p_city_id := v_city_id,
      p_rider_id := v_t.rider_id,
      p_driver_id := v_t.driver_id
    );
  elsif v_t.route_id is not null then
    select rs_from.sequence, rs_to.sequence
    into v_seq_from, v_seq_to
    from route_stages rs_from
    join route_stages rs_to on rs_to.route_id = rs_from.route_id
    where rs_from.id = v_from_stage
      and rs_to.id = v_to_stage
      and rs_from.route_id = v_t.route_id;

    if v_seq_from is null or v_seq_from >= v_seq_to then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;

    v_fare := resolve_fare(
      p_route_id := v_t.route_id,
      p_from_stage_id := v_from_stage,
      p_to_stage_id := v_to_stage,
      p_mode_code := v_t.mode_code,
      p_city_id := v_city_id,
      p_rider_id := v_t.rider_id,
      p_driver_id := v_t.driver_id
    );
  else
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  v_fare_delta := v_fare.amount;
  v_commission_delta := round(v_fare_delta * v_t.commission_rate, 2);

  select coalesce(sum(te.fare_delta), 0)
  into v_accepted_delta
  from trip_extensions te
  where te.trip_id = p_trip_id
    and te.status = 'accepted';

  v_new_total := v_t.fare_shown + v_accepted_delta + v_fare_delta;
  v_ttl_s := cfg_num('extension.proposal_ttl_s', v_city_id)::int;
  v_expires := now() + make_interval(secs => v_ttl_s);

  insert into trip_extensions (
    trip_id,
    previous_alighting_stage_id,
    previous_alighting_location,
    new_alighting_stage_id,
    new_alighting_location,
    proposed_by,
    status,
    fare_quote_id,
    fare_delta,
    currency,
    commission_delta,
    expires_at
  ) values (
    p_trip_id,
    v_from_stage,
    v_from_point,
    v_to_stage,
    v_to_point,
    v_actor,
    'proposed',
    v_fare.quote_id,
    v_fare_delta,
    v_fare.currency,
    v_commission_delta,
    v_expires
  )
  returning id into v_ext_id;

  return jsonb_build_object(
    'extension_id', v_ext_id,
    'fare_delta', v_fare_delta,
    'new_total', v_new_total,
    'tier', v_fare.tier,
    'unconfirmed', v_fare.unconfirmed
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- respond_extension — doc 03 §5, doc 04 §17
-- ---------------------------------------------------------------------------
create or replace function respond_extension(
  p_extension_id uuid,
  p_response text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_ext trip_extensions%rowtype;
  v_t trips%rowtype;
  v_actor actor_type;
  v_responder actor_type;
begin
  if v_uid is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_response not in ('accept', 'decline') then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select * into v_ext
  from trip_extensions
  where id = p_extension_id
  for update;

  if v_ext.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_ext.status <> 'proposed' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if v_ext.expires_at <= now() then
    perform set_config('along.in_extension_update', 'on', true);
    update trip_extensions
    set status = 'expired', responded_at = now()
    where id = p_extension_id;
    perform set_config('along.in_extension_update', '', true);
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = v_ext.trip_id for update;

  if v_t.status not in ('boarded', 'in_transit') then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  v_actor := _extension_trip_actor(v_ext.trip_id, v_uid);

  v_responder := case v_ext.proposed_by
    when 'rider' then 'driver'
    when 'driver' then 'rider'
  end;

  if v_actor <> v_responder then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  perform set_config('along.in_extension_update', 'on', true);

  if p_response = 'decline' then
    update trip_extensions
    set status = 'declined', responded_at = now()
    where id = p_extension_id;

    perform set_config('along.in_extension_update', '', true);

    return jsonb_build_object(
      'extension_id', p_extension_id,
      'status', 'declined'
    );
  end if;

  update trip_extensions
  set status = 'accepted', responded_at = now()
  where id = p_extension_id;

  update trips
  set
    alighting_stage_id = v_ext.new_alighting_stage_id,
    alighting_location = coalesce(
      v_ext.new_alighting_location,
      (select rs.location from route_stages rs where rs.id = v_ext.new_alighting_stage_id)
    )
  where id = v_ext.trip_id;

  perform set_config('along.in_extension_update', '', true);

  return jsonb_build_object(
    'extension_id', p_extension_id,
    'status', 'accepted',
    'trip', build_trip_view(v_ext.trip_id, v_uid)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- complete_trip — base + accepted extension commission deltas at completion
-- ---------------------------------------------------------------------------
create or replace function complete_trip(
  p_trip_id uuid,
  p_alighting jsonb default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver_id uuid := auth.uid();
  v_t trips%rowtype;
  v_commission numeric;
  v_fare numeric;
  v_surcharge numeric;
  v_total numeric;
  v_ledger_entry driver_ledger_entries%rowtype;
  v_ext trip_extensions%rowtype;
  v_ext_ledger driver_ledger_entries%rowtype;
  v_ext_commission_total numeric := 0;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  select * into v_t from trips where id = p_trip_id for update;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_t.driver_id is distinct from v_driver_id then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_t.status <> 'in_transit' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if p_alighting is not null then
    update trips
    set
      alighting_location = st_setsrid(
        st_makepoint(
          (p_alighting->>'lng')::double precision,
          (p_alighting->>'lat')::double precision
        ),
        4326
      )::geography,
      alighting_stage_id = nullif(p_alighting->>'stage_id', '')::uuid
    where id = p_trip_id;
  end if;

  perform trip_transition(p_trip_id, 'completed', 'driver', v_driver_id);

  select * into v_t from trips where id = p_trip_id;
  v_fare := v_t.fare_shown;
  v_surcharge := coalesce(v_t.load_surcharge_amount, 0);
  v_total := v_fare + v_surcharge;
  v_commission := coalesce(v_t.commission_amount, round(v_total * v_t.commission_rate, 2));

  if v_t.payment_method = 'cash' and v_commission > 0 then
    v_ledger_entry := ledger_post(
      v_t.driver_id,
      'cash_commission_debit',
      -v_commission,
      v_t.fare_currency,
      jsonb_build_object('trip_id', p_trip_id),
      format('trip:%s:commission', p_trip_id),
      'system',
      null,
      null
    );
  end if;

  if v_t.payment_method = 'cash' then
    for v_ext in
      select *
      from trip_extensions
      where trip_id = p_trip_id
        and status = 'accepted'
        and coalesce(commission_delta, 0) > 0
      order by proposed_at
    loop
      v_ext_ledger := ledger_post(
        v_t.driver_id,
        'cash_commission_debit',
        -v_ext.commission_delta,
        v_ext.currency,
        jsonb_build_object(
          'trip_id', p_trip_id,
          'trip_extension_id', v_ext.id
        ),
        format('ext:%s', v_ext.id),
        'system',
        null,
        null
      );

      perform set_config('along.in_extension_update', 'on', true);
      update trip_extensions
      set ledger_entry_id = v_ext_ledger.id
      where id = v_ext.id;
      perform set_config('along.in_extension_update', '', true);

      v_ext_commission_total := v_ext_commission_total + v_ext.commission_delta;
    end loop;
  end if;

  return jsonb_build_object(
    'trip', build_trip_view(p_trip_id, v_driver_id),
    'fare', jsonb_build_object('amount', v_fare, 'currency', v_t.fare_currency),
    'surcharge', case
      when v_surcharge > 0 then jsonb_build_object('amount', v_surcharge, 'currency', v_t.fare_currency)
      else null
    end,
    'total', jsonb_build_object('amount', v_total, 'currency', v_t.fare_currency),
    'commission', jsonb_build_object(
      'amount', v_commission + v_ext_commission_total,
      'currency', v_t.fare_currency,
      'base', v_commission,
      'extension', v_ext_commission_total
    ),
    'ledger_entry_id', v_ledger_entry.id
  );
end;
$$;

revoke all on function propose_extension(uuid, jsonb) from public;
grant execute on function propose_extension(uuid, jsonb) to authenticated;

revoke all on function respond_extension(uuid, text) from public;
grant execute on function respond_extension(uuid, text) to authenticated;

grant execute on function complete_trip(uuid, jsonb) to authenticated;
