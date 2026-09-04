-- P1-A-09: doc 03 §1, §11; doc 02 §3; doc 12 §5 — verification RPCs, storage bucket,
-- identity hash on approval, OCR enqueue.

-- ---------------------------------------------------------------------------
-- Storage bucket (private verification uploads)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'verification',
  'verification',
  false,
  52428800,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy verification_objects_insert_own
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy verification_objects_select_own
  on storage.objects for select to authenticated
  using (
    bucket_id = 'verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy verification_objects_update_own
  on storage.objects for update to authenticated
  using (
    bucket_id = 'verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'verification'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy verification_objects_select_verifier
  on storage.objects for select to authenticated
  using (
    bucket_id = 'verification'
    and has_admin_role(array['verifier', 'ops_lead', 'ops_agent', 'superadmin'])
  );

-- ---------------------------------------------------------------------------
-- Identity hash helpers (doc 12 §5 — pepper from Vault via runtime setting)
-- ---------------------------------------------------------------------------
create or replace function identity_hash_pepper()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return nullif(current_setting('app.settings.identity_hash_pepper', true), '');
exception
  when others then
    return null;
end;
$$;

revoke all on function identity_hash_pepper() from public;
grant execute on function identity_hash_pepper() to service_role;

create or replace function normalize_identity_id(p_document_type text, p_raw text)
returns text
language plpgsql
immutable
as $$
declare
  v_norm text;
begin
  if p_raw is null or btrim(p_raw) = '' then
    return null;
  end if;

  if p_document_type = 'nin' then
    v_norm := regexp_replace(p_raw, '[^0-9]', '', 'g');
    if length(v_norm) <> 11 then
      return null;
    end if;
    return v_norm;
  end if;

  if p_document_type = 'drivers_license' then
    v_norm := upper(regexp_replace(p_raw, '[^A-Za-z0-9]', '', 'g'));
    if length(v_norm) < 5 then
      return null;
    end if;
    return v_norm;
  end if;

  return null;
end;
$$;

create or replace function compute_identity_hash(p_document_type text, p_normalized_id text)
returns bytea
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_pepper text;
begin
  if p_normalized_id is null then
    return null;
  end if;

  v_pepper := identity_hash_pepper();
  if v_pepper is null then
    raise exception 'IDENTITY_PEPPER_MISSING' using errcode = 'P0001';
  end if;

  return extensions.hmac(p_normalized_id::bytea, v_pepper::bytea, 'sha256');
end;
$$;

revoke all on function compute_identity_hash(text, text) from public;
grant execute on function compute_identity_hash(text, text) to service_role;

create or replace function verification_doc_type_allowed(p_country_code char(2), p_document_type text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from countries c,
         lateral jsonb_array_elements(c.verification_schema) elem
    where c.code = p_country_code
      and elem->>'type' = p_document_type
  );
$$;

create or replace function verification_required_doc_types(p_country_code char(2))
returns text[]
language sql
stable
as $$
  select coalesce(
    array_agg(elem->>'type' order by ordinality),
    '{}'::text[]
  )
  from countries c,
       lateral jsonb_array_elements(c.verification_schema) with ordinality as t(elem, ordinality)
  where c.code = p_country_code;
$$;

create or replace function verification_storage_path_valid(p_storage_path text, p_user_id uuid)
returns boolean
language sql
immutable
as $$
  select p_storage_path is not null
    and p_storage_path ~ ('^' || p_user_id::text || '/[A-Za-z0-9._/-]+$')
    and p_storage_path !~ '\.\.';
$$;

create or replace function generate_driver_code()
returns text
language plpgsql
volatile
as $$
declare
  v_chars constant text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_code text := '';
  v_i int;
  v_attempt int := 0;
begin
  loop
    v_code := '';
    for v_i in 1..8 loop
      v_code := v_code || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
    end loop;

    exit when not exists (select 1 from drivers d where d.driver_code = v_code);

    v_attempt := v_attempt + 1;
    if v_attempt > 20 then
      raise exception 'generate_driver_code: exhausted retries' using errcode = 'P0001';
    end if;
  end loop;

  return v_code;
end;
$$;

create or replace function private.driver_all_required_docs_approved(p_driver_id uuid, p_country_code char(2))
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select not exists (
    select 1
    from unnest(verification_required_doc_types(p_country_code)) req(doc_type)
    where not exists (
      select 1
      from driver_verifications dv
      where dv.driver_id = p_driver_id
        and dv.document_type = req.doc_type
        and dv.status = 'approved'
    )
  );
$$;

revoke all on function private.driver_all_required_docs_approved(uuid, char(2)) from public;
grant execute on function private.driver_all_required_docs_approved(uuid, char(2)) to service_role;

create or replace function private.record_identity_hash(
  p_document_type text,
  p_id_hash bytea,
  p_driver_id uuid,
  p_allow_duplicate boolean default false
)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_existing_driver uuid;
begin
  if p_id_hash is null then
    return;
  end if;

  select ih.driver_id
  into v_existing_driver
  from private.identity_hashes ih
  where ih.document_type = p_document_type
    and ih.id_hash = p_id_hash;

  if found and v_existing_driver <> p_driver_id then
    if not p_allow_duplicate then
      raise exception 'DUPLICATE_IDENTITY' using errcode = 'P0001';
    end if;
  end if;

  insert into private.identity_hashes (document_type, id_hash, driver_id)
  values (p_document_type, p_id_hash, p_driver_id)
  on conflict (document_type, id_hash) do nothing;
end;
$$;

revoke all on function private.record_identity_hash(text, bytea, uuid, boolean) from public;
grant execute on function private.record_identity_hash(text, bytea, uuid, boolean) to service_role;

create or replace function private.enqueue_verification_ocr(p_verification_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_url text;
  v_key text;
begin
  begin
    v_url := nullif(current_setting('app.settings.api_external_url', true), '');
    v_key := nullif(current_setting('app.settings.service_role_key', true), '');
  exception
    when others then
      return;
  end;

  if v_url is null or v_key is null then
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/verification-ocr',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    body := jsonb_build_object(
      'verification_id', p_verification_id
    )
  );
exception
  when others then
    null;
end;
$$;

revoke all on function private.enqueue_verification_ocr(uuid) from public;
grant execute on function private.enqueue_verification_ocr(uuid) to service_role;

-- Limited driver-facing view (doc 02 §3 RLS note)
create or replace view my_verifications_v as
select
  dv.document_type,
  dv.status,
  dv.rejection_reason,
  dv.submitted_at
from driver_verifications dv
where dv.driver_id = auth.uid();

grant select on my_verifications_v to authenticated;

-- Audit admin writes on verification tables (doc 02 §15)
create trigger audit_driver_verifications
  after insert or update or delete on driver_verifications
  for each row execute function audit_admin_write();

create trigger audit_drivers_verification
  after update on drivers
  for each row
  when (
    old.verified_status is distinct from new.verified_status
    or old.women_only_eligible is distinct from new.women_only_eligible
    or old.tenure_started_at is distinct from new.tenure_started_at
    or old.driver_code is distinct from new.driver_code
  )
  execute function audit_admin_write();

-- Admin update policy for verifier queue (doc 02 §3)
create policy driver_verifications_update_admin
  on driver_verifications for update to authenticated
  using (has_admin_role(array['verifier', 'ops_lead', 'superadmin']))
  with check (has_admin_role(array['verifier', 'ops_lead', 'superadmin']));

grant update on driver_verifications to authenticated;

-- ---------------------------------------------------------------------------
-- register_vehicle (doc 03 §1)
-- ---------------------------------------------------------------------------
create or replace function register_vehicle(
  p_mode_code text,
  p_plate_number text,
  p_seat_capacity smallint,
  p_owner_is_me boolean,
  p_color text default null,
  p_make_model text default null,
  p_owner_name text default null,
  p_owner_phone text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_country_code char(2);
  v_vehicle_id uuid;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_mode_code is null or p_plate_number is null or p_seat_capacity is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_seat_capacity < 1 then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if not exists (select 1 from mode_config m where m.code = p_mode_code) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select ci.country_code
  into v_country_code
  from drivers d
  join cities ci on ci.id = d.city_id
  where d.id = v_driver_id;

  if v_country_code is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not p_owner_is_me and (p_owner_name is null or p_owner_phone is null) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  begin
    insert into vehicles (
      country_code,
      mode_code,
      plate_number,
      owner_profile_id,
      owner_name,
      owner_phone_e164,
      seat_capacity,
      color,
      make_model
    ) values (
      v_country_code,
      p_mode_code,
      btrim(p_plate_number),
      case when p_owner_is_me then v_driver_id else null end,
      case when p_owner_is_me then null else btrim(p_owner_name) end,
      case when p_owner_is_me then null else btrim(p_owner_phone) end,
      p_seat_capacity,
      nullif(btrim(p_color), ''),
      nullif(btrim(p_make_model), '')
    )
    returning id into v_vehicle_id;
  exception
    when unique_violation then
      raise exception 'CONFLICT' using errcode = 'P0001';
  end;

  update driver_vehicles
  set active = false
  where driver_id = v_driver_id
    and active;

  insert into driver_vehicles (driver_id, vehicle_id, active)
  values (v_driver_id, v_vehicle_id, true)
  on conflict (driver_id, vehicle_id) do update
    set active = true,
        since = now();

  return jsonb_build_object('vehicle_id', v_vehicle_id);
end;
$$;

grant execute on function register_vehicle(text, text, smallint, boolean, text, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- submit_verification (doc 03 §1 — never accepts raw ID numbers)
-- ---------------------------------------------------------------------------
create or replace function submit_verification(
  p_document_type text,
  p_storage_path text,
  p_vehicle_id uuid default null,
  p_client_ocr_hint text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_driver_id uuid := auth.uid();
  v_country_code char(2);
  v_verification_id uuid;
  v_hint jsonb;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_document_type is null or p_storage_path is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if not verification_storage_path_valid(p_storage_path, v_driver_id) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select ci.country_code
  into v_country_code
  from drivers d
  join cities ci on ci.id = d.city_id
  where d.id = v_driver_id;

  if v_country_code is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if not verification_doc_type_allowed(v_country_code, p_document_type) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_document_type = 'vehicle_particulars' and p_vehicle_id is null then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_vehicle_id is not null and not exists (
    select 1
    from driver_vehicles dv
    where dv.driver_id = v_driver_id
      and dv.vehicle_id = p_vehicle_id
  ) then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  if p_client_ocr_hint is not null then
    begin
      v_hint := p_client_ocr_hint::jsonb;
    exception
      when others then
        raise exception 'VALIDATION' using errcode = 'P0001';
    end;

    if v_hint ? 'id_number' or v_hint ? 'nin' or v_hint ? 'license_number' then
      raise exception 'VALIDATION' using errcode = 'P0001';
    end if;
  end if;

  insert into driver_verifications (
    driver_id,
    vehicle_id,
    country_code,
    document_type,
    status,
    storage_path,
    submitted_at
  ) values (
    v_driver_id,
    p_vehicle_id,
    v_country_code,
    p_document_type,
    'pending',
    p_storage_path,
    now()
  )
  returning id into v_verification_id;

  update drivers
  set verified_status = case
        when verified_status = 'verified' then verified_status
        else 'pending'
      end,
      updated_at = now()
  where id = v_driver_id
    and verified_status = 'unverified';

  perform private.enqueue_verification_ocr(v_verification_id);

  return jsonb_build_object('verification_id', v_verification_id);
end;
$$;

grant execute on function submit_verification(text, text, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- my_verifications (doc 03 §1)
-- ---------------------------------------------------------------------------
create or replace function my_verifications()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'document_type', dv.document_type,
        'status', dv.status,
        'rejection_reason', dv.rejection_reason,
        'submitted_at', dv.submitted_at
      )
      order by dv.submitted_at desc
    ),
    '[]'::jsonb
  )
  from driver_verifications dv
  where dv.driver_id = auth.uid();
$$;

grant execute on function my_verifications() to authenticated;

-- ---------------------------------------------------------------------------
-- admin_approve_verification / admin_reject_verification (doc 03 §11)
-- ---------------------------------------------------------------------------
create or replace function admin_approve_verification(
  p_verification_id uuid,
  p_women_only_eligible boolean default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, private
as $$
declare
  v_verification driver_verifications%rowtype;
  v_id_hash bytea;
  v_allow_duplicate boolean := false;
  v_admin_role admin_role;
begin
  if not has_admin_role(array['verifier', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  select * into v_verification
  from driver_verifications
  where id = p_verification_id
  for update;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_verification.status <> 'pending' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = v_verification.driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if v_verification.ocr_extract ? 'id_hash' then
    v_id_hash := decode(v_verification.ocr_extract->>'id_hash', 'base64');
  end if;

  select a.role into v_admin_role
  from admin_users a
  where a.id = auth.uid() and a.disabled_at is null;

  v_allow_duplicate := v_admin_role in ('ops_lead', 'superadmin');

  perform private.record_identity_hash(
    v_verification.document_type,
    v_id_hash,
    v_verification.driver_id,
    v_allow_duplicate
  );

  update driver_verifications
  set status = 'approved',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = null,
      updated_at = now()
  where id = p_verification_id;

  if p_women_only_eligible is true then
    update drivers d
    set women_only_eligible = true,
        updated_at = now()
    from profiles p
    where d.id = v_verification.driver_id
      and p.id = d.id
      and p.gender = 'female';
  end if;

  if private.driver_all_required_docs_approved(v_verification.driver_id, v_verification.country_code) then
    update drivers
    set verified_status = 'verified',
        tenure_started_at = coalesce(tenure_started_at, now()),
        driver_code = coalesce(driver_code, generate_driver_code()),
        updated_at = now()
    where id = v_verification.driver_id;
  end if;

  return jsonb_build_object(
    'verification_id', p_verification_id,
    'status', 'approved'
  );
end;
$$;

create or replace function admin_reject_verification(
  p_verification_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_verification driver_verifications%rowtype;
begin
  if not has_admin_role(array['verifier', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'VALIDATION' using errcode = 'P0001';
  end if;

  select * into v_verification
  from driver_verifications
  where id = p_verification_id
  for update;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_verification.status <> 'pending' then
    raise exception 'STATE_INVALID' using errcode = 'P0001';
  end if;

  if not admin_can_access_city((
    select d.city_id from drivers d where d.id = v_verification.driver_id
  )) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  update driver_verifications
  set status = 'rejected',
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      rejection_reason = btrim(p_reason),
      updated_at = now()
  where id = p_verification_id;

  update drivers
  set verified_status = case
        when verified_status = 'verified' then verified_status
        else 'rejected'
      end,
      updated_at = now()
  where id = v_verification.driver_id
    and verified_status in ('pending', 'unverified');

  return jsonb_build_object(
    'verification_id', p_verification_id,
    'status', 'rejected'
  );
end;
$$;

grant execute on function admin_approve_verification(uuid, boolean) to authenticated;
grant execute on function admin_reject_verification(uuid, text) to authenticated;
