-- P4-D-02: W-04 digital_enabled in resolver; admin rotate; finance sticker RLS

-- Extend resolve_qr_driver with digital_enabled for W-04 fail-closed UI (doc 14 §4.1)
create or replace function resolve_qr_driver(
  p_driver_code text,
  p_rider_id uuid default null,
  p_token text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, extensions
as $$
declare
  v_driver drivers%rowtype;
  v_first_name text;
  v_plate text;
  v_mode text;
  v_active boolean;
  v_accepts boolean;
  v_digital_enabled boolean;
  v_context jsonb;
  v_warning text;
  v_trip trips%rowtype;
  v_other_driver uuid;
  v_lookback interval;
  v_min_amount numeric;
  v_token_row record;
begin
  select * into v_driver
  from drivers d
  where d.driver_code = p_driver_code;

  if v_driver.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  v_active := private.driver_qr_active(v_driver);
  v_accepts := private.driver_accepts_digital_qr(v_driver);
  v_digital_enabled := coalesce((cfg('payments.digital_enabled', v_driver.city_id))::text = 'true', false);
  v_min_amount := cfg_num('payments.min_digital_amount', v_driver.city_id);

  if not v_active then
    return jsonb_build_object(
      'driver', jsonb_build_object('active', false, 'accepts_digital', false),
      'digital_enabled', v_digital_enabled,
      'suggested_amounts', qr_suggested_amounts(v_driver.id),
      'currency', 'NGN',
      'min_amount', jsonb_build_object('amount', v_min_amount, 'currency', 'NGN')
    );
  end if;

  select split_part(p.display_name, ' ', 1), v.plate_number, v.mode_code
  into v_first_name, v_plate, v_mode
  from profiles p
  left join driver_vehicles dv on dv.driver_id = v_driver.id and dv.active
  left join vehicles v on v.id = dv.vehicle_id
  where p.id = v_driver.id;

  v_context := null;
  v_warning := null;

  if p_rider_id is not null then
    v_lookback := make_interval(hours => cfg_num('payments.unattributed_lookback_hours', v_driver.city_id)::int);

    select t.* into v_trip
    from trips t
    where t.rider_id = p_rider_id
      and t.driver_id = v_driver.id
      and t.status in ('accepted', 'boarded', 'in_transit', 'completed')
      and (
        t.status <> 'completed'
        or coalesce(t.ended_at, t.updated_at) >= now() - v_lookback
      )
      and not exists (
        select 1 from payments pay
        where pay.trip_id = t.id and pay.status = 'succeeded'
      )
    order by
      case t.status
        when 'in_transit' then 1
        when 'boarded' then 2
        when 'accepted' then 3
        when 'completed' then 4
      end,
      t.requested_at desc
    limit 1;

    if v_trip.id is not null then
      v_context := jsonb_build_object(
        'trip_id', v_trip.id,
        'amount', jsonb_build_object(
          'amount', trip_payable_total(v_trip.id),
          'currency', v_trip.fare_currency
        ),
        'label', 'Trip fare',
        'locked', true
      );
    end if;

    select t.driver_id into v_other_driver
    from trips t
    where t.rider_id = p_rider_id
      and t.status in ('accepted', 'boarded', 'in_transit')
      and t.driver_id is distinct from v_driver.id
    order by t.requested_at desc
    limit 1;

    if v_other_driver is not null then
      v_warning := 'different_driver';
    end if;
  end if;

  if p_token is not null and btrim(p_token) <> '' then
    select * into v_token_row from verify_payment_token(p_token, v_driver.city_id);
    if v_token_row.driver_id is distinct from v_driver.id then
      raise exception 'FORBIDDEN' using errcode = 'P0001';
    end if;
    v_context := jsonb_build_object(
      'trip_id', v_token_row.trip_id,
      'amount', jsonb_build_object('amount', v_token_row.amount, 'currency', 'NGN'),
      'label', 'Payment request',
      'locked', true
    );
  end if;

  return jsonb_build_object(
    'driver', jsonb_build_object(
      'first_name', v_first_name,
      'plate', v_plate,
      'mode', v_mode,
      'accepts_digital', v_accepts,
      'active', true
    ),
    'digital_enabled', v_digital_enabled,
    'context', v_context,
    'suggested_amounts', qr_suggested_amounts(v_driver.id),
    'currency', 'NGN',
    'min_amount', jsonb_build_object('amount', v_min_amount, 'currency', 'NGN'),
    'warning', v_warning
  );
end;
$$;

-- admin_rotate_driver_code — ops rotate from A-11 (doc 14 §6)
create or replace function admin_rotate_driver_code(p_driver_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_driver drivers%rowtype;
  v_old_code text;
  v_new_code text;
  v_role text;
begin
  if not has_admin_role(array['superadmin', 'ops_lead', 'finance']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_driver from drivers where id = p_driver_id for update;
  if v_driver.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_driver.city_id) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  v_old_code := v_driver.driver_code;
  if v_old_code is null or btrim(v_old_code) = '' then
    raise exception 'STATE_INVALID' using errcode = 'P0001', message = 'no driver code';
  end if;

  v_new_code := generate_driver_code();

  update drivers
  set driver_code = v_new_code, driver_code_rotated_at = now()
  where id = p_driver_id;

  insert into qr_sticker_requests (driver_id, driver_code, reason)
  values (p_driver_id, v_new_code, 'rotation');

  select role into v_role from admin_users where id = auth.uid();

  insert into audit_log (actor_id, actor_role, action, target_type, target_id, after)
  values (
    auth.uid(),
    coalesce(v_role, 'admin'),
    'admin_rotate_driver_code',
    'drivers',
    p_driver_id::text,
    jsonb_build_object('old_code', v_old_code, 'new_code', v_new_code)
  );

  return jsonb_build_object(
    'driver_code', v_new_code,
    'rotated_at', now()
  );
end;
$$;

revoke all on function admin_rotate_driver_code(uuid) from public;
grant execute on function admin_rotate_driver_code(uuid) to authenticated;

-- Finance can read sticker requests for A-11 / A-13
drop policy if exists qr_sticker_requests_select_admin on qr_sticker_requests;
create policy qr_sticker_requests_select_admin
  on qr_sticker_requests for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'finance'])
    and admin_can_access_city((
      select d.city_id from drivers d where d.id = driver_id
    ))
  );

-- A-13 sticker batch PDF: finance joins driver_vehicles for plate labels
drop policy if exists driver_vehicles_select_admin on driver_vehicles;
create policy driver_vehicles_select_admin
  on driver_vehicles for select to authenticated
  using (
    is_admin()
    and exists (
      select 1 from drivers d
      where d.id = driver_vehicles.driver_id
        and admin_can_access_city(d.city_id)
    )
  );

-- A-13 sticker batch PDF: finance joins driver_vehicles for plate labels
drop policy if exists driver_vehicles_select_admin on driver_vehicles;
create policy driver_vehicles_select_admin
  on driver_vehicles for select to authenticated
  using (
    is_admin()
    and exists (
      select 1 from drivers d
      where d.id = driver_vehicles.driver_id
        and admin_can_access_city(d.city_id)
    )
  );
