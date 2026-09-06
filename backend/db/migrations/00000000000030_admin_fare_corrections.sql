-- P2-D-01: admin_review_fare_correction RPC (doc 03 §11) + fare_corrections audit trigger.

create or replace function _fare_correction_resolve_target(p_fc fare_corrections)
returns table (target_type text, target_id uuid)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_leg_id uuid;
  v_tf_id uuid;
  v_from_seq int;
  v_to_seq int;
begin
  if p_fc.route_leg_id is not null then
    return query select 'route_leg'::text, p_fc.route_leg_id;
    return;
  end if;

  if p_fc.route_through_fare_id is not null then
    return query select 'route_through_fare'::text, p_fc.route_through_fare_id;
    return;
  end if;

  if p_fc.route_id is null or p_fc.from_stage_id is null or p_fc.to_stage_id is null then
    raise exception 'NOT_FOUND: fare correction has no resolvable graph target'
      using errcode = 'P0001';
  end if;

  select tf.id into v_tf_id
  from route_through_fares tf
  where tf.route_id = p_fc.route_id
    and tf.from_stage_id = p_fc.from_stage_id
    and tf.to_stage_id = p_fc.to_stage_id
  limit 1;

  if v_tf_id is not null then
    return query select 'route_through_fare'::text, v_tf_id;
    return;
  end if;

  select fs.sequence, ts.sequence
  into v_from_seq, v_to_seq
  from route_stages fs
  join route_stages ts on ts.route_id = fs.route_id and ts.id = p_fc.to_stage_id
  where fs.id = p_fc.from_stage_id and fs.route_id = p_fc.route_id;

  if v_from_seq is not null and v_to_seq = v_from_seq + 1 then
    select rl.id into v_leg_id
    from route_legs rl
    where rl.route_id = p_fc.route_id
      and rl.from_stage_id = p_fc.from_stage_id
      and rl.to_stage_id = p_fc.to_stage_id
    limit 1;

    if v_leg_id is not null then
      return query select 'route_leg'::text, v_leg_id;
      return;
    end if;
  end if;

  raise exception 'NOT_FOUND: no graph entity for fare correction stage pair'
    using errcode = 'P0001';
end;
$$;

create or replace function admin_review_fare_correction(
  id uuid,
  action text,
  note text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_fc fare_corrections%rowtype;
  v_target_type text;
  v_target_id uuid;
  v_city_id uuid;
  v_conf_id uuid;
  v_promoted boolean := false;
begin
  if not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action not in ('approve', 'reject') then
    raise exception 'VALIDATION: action must be approve or reject' using errcode = 'P0001';
  end if;

  select * into v_fc
  from fare_corrections
  where fare_corrections.id = admin_review_fare_correction.id
  for update;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_fc.status <> 'pending' then
    raise exception 'STATE_INVALID: correction is not pending' using errcode = 'P0001';
  end if;

  v_city_id := graph_target_city_id(
    case
      when v_fc.route_leg_id is not null then 'route_leg'
      when v_fc.route_through_fare_id is not null then 'route_through_fare'
      else 'route'
    end,
    coalesce(v_fc.route_leg_id, v_fc.route_through_fare_id, v_fc.route_id)
  );

  if v_city_id is null and v_fc.route_id is not null then
    select r.city_id into v_city_id from routes r where r.id = v_fc.route_id;
  end if;

  if not admin_can_access_city(v_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action = 'reject' then
    update fare_corrections
    set status = 'rejected',
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        review_note = nullif(btrim(note), '')
    where fare_corrections.id = admin_review_fare_correction.id;

    return jsonb_build_object(
      'id', admin_review_fare_correction.id,
      'status', 'rejected',
      'confirmation_id', null,
      'promoted', false
    );
  end if;

  select t.target_type, t.target_id
  into v_target_type, v_target_id
  from _fare_correction_resolve_target(v_fc) t;

  v_conf_id := confirm_graph_value(
    v_target_type,
    v_target_id,
    jsonb_build_object('fare', v_fc.proposed_fare),
    v_fc.trip_id,
    auth.uid(),
    'admin'
  );

  update fare_corrections
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_note = nullif(btrim(note), '')
  where fare_corrections.id = admin_review_fare_correction.id;

  perform promote_candidates();

  select exists (
    select 1
    from route_legs rl
    where v_target_type = 'route_leg'
      and rl.id = v_target_id
      and rl.verification_status = 'crowd_verified'
  ) or exists (
    select 1
    from route_through_fares tf
    where v_target_type = 'route_through_fare'
      and tf.id = v_target_id
      and tf.verification_status = 'crowd_verified'
  )
  into v_promoted;

  return jsonb_build_object(
    'id', admin_review_fare_correction.id,
    'status', 'approved',
    'confirmation_id', v_conf_id,
    'target_type', v_target_type,
    'target_id', v_target_id,
    'promoted', v_promoted
  );
end;
$$;

grant execute on function admin_review_fare_correction(uuid, text, text) to authenticated;
grant execute on function fare_outlier_guard(uuid, uuid, numeric, uuid) to authenticated;

create trigger audit_fare_corrections
  after update on fare_corrections
  for each row execute function audit_admin_write();
