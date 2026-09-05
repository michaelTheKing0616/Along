-- P1-D-01: A-04 document view audit + duplicate identity lookup for verifier queue.

create or replace function admin_log_view_document(p_verification_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_verification driver_verifications%rowtype;
  v_actor_role text;
begin
  if not has_admin_role(array['verifier', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  select * into v_verification
  from driver_verifications
  where id = p_verification_id;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = v_verification.driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  select a.role::text into v_actor_role
  from admin_users a
  where a.id = auth.uid() and a.disabled_at is null;

  insert into audit_log (
    actor_id, actor_role, action, target_type, target_id, before, after
  ) values (
    auth.uid(),
    v_actor_role,
    'view_document',
    'driver_verifications',
    p_verification_id::text,
    null,
    jsonb_build_object(
      'document_type', v_verification.document_type,
      'driver_id', v_verification.driver_id,
      'storage_path', v_verification.storage_path
    )
  );

  return jsonb_build_object(
    'verification_id', p_verification_id,
    'storage_path', v_verification.storage_path,
    'logged', true
  );
end;
$$;

create or replace function admin_check_identity_duplicate(p_verification_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_verification driver_verifications%rowtype;
  v_id_hash bytea;
  v_other_driver uuid;
begin
  if not has_admin_role(array['verifier', 'ops_lead', 'ops_agent', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  select * into v_verification
  from driver_verifications
  where id = p_verification_id;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = v_verification.driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if not (v_verification.ocr_extract ? 'id_hash') then
    return jsonb_build_object('duplicate', false);
  end if;

  v_id_hash := decode(v_verification.ocr_extract->>'id_hash', 'base64');

  select ih.driver_id
  into v_other_driver
  from private.identity_hashes ih
  where ih.document_type = v_verification.document_type
    and ih.id_hash = v_id_hash
    and ih.driver_id <> v_verification.driver_id;

  if not found then
    return jsonb_build_object('duplicate', false);
  end if;

  return jsonb_build_object(
    'duplicate', true,
    'other_driver_id', v_other_driver,
    'other_driver_masked',
      left(v_other_driver::text, 8) || '…' || right(v_other_driver::text, 4)
  );
end;
$$;

grant execute on function admin_log_view_document(uuid) to authenticated;
grant execute on function admin_check_identity_duplicate(uuid) to authenticated;
