-- claim_seat: report a stale seat version as CONFLICT before ride-rule checks
-- (RULE_CAP / RULE_ACK). Body otherwise identical to 00000000000084.

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

  -- A stale client view answers CONFLICT before any rule check, so the client
  -- refreshes and re-evaluates rules against current seat state. The guarded
  -- update below still enforces the version atomically.
  if exists (
    select 1 from vehicle_seat_states s
    where s.layout_id = p_layout_id
      and s.seat_id = p_seat_id
      and s.version <> p_expected_version
  ) then
    raise exception 'CONFLICT' using errcode = 'P0001';
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

