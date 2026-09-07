-- P6-D-04: Admin user management RPCs (A-17) + audit.page_size config (A-16 pagination).

select config_default('audit.page_size', '50');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  ('audit.page_size', '{"type":"number","minimum":10,"maximum":200}', 'Audit log page size (rows)', array['global']::config_scope[], false)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- admin_list_admins — superadmin roster with TOTP enrollment status
-- ---------------------------------------------------------------------------
create or replace function admin_list_admins(
  p_cursor uuid default null,
  p_limit int default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, auth, extensions
as $$
declare
  v_limit int := least(greatest(coalesce(p_limit, cfg_num('audit.page_size')), 1), 200);
  v_rows jsonb;
  v_next uuid;
begin
  if not has_admin_role(array['superadmin']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  with page as (
    select
      a.id,
      u.email,
      coalesce(p.display_name, u.raw_user_meta_data->>'display_name') as display_name,
      a.role,
      a.deployment_id,
      d.tenant_name as deployment_name,
      a.city_scope,
      a.disabled_at,
      a.created_at,
      exists (
        select 1
        from auth.mfa_factors mf
        where mf.user_id = a.id
          and mf.factor_type = 'totp'
          and mf.status = 'verified'
      ) as totp_enrolled
    from admin_users a
    join auth.users u on u.id = a.id
    left join profiles p on p.id = a.id
    left join deployments d on d.id = a.deployment_id
    where p_cursor is null
      or (a.created_at, a.id) < (
        select a2.created_at, a2.id
        from admin_users a2
        where a2.id = p_cursor
      )
    order by a.created_at desc, a.id desc
    limit v_limit + 1
  )
  select
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', pg.id,
          'email', pg.email,
          'display_name', pg.display_name,
          'role', pg.role,
          'deployment_id', pg.deployment_id,
          'deployment_name', pg.deployment_name,
          'city_scope', coalesce(pg.city_scope, array[]::uuid[]),
          'disabled_at', pg.disabled_at,
          'created_at', pg.created_at,
          'totp_enrolled', pg.totp_enrolled,
          'totp_required', pg.role in ('superadmin', 'finance', 'safety', 'ops_lead')
        )
        order by pg.created_at desc, pg.id desc
      )
      from (select * from page order by created_at desc, id desc limit v_limit) pg
    ), '[]'::jsonb),
    (select id from page order by created_at asc, id asc offset v_limit limit 1)
  into v_rows, v_next;

  return jsonb_build_object('rows', v_rows, 'next_cursor', v_next);
end;
$$;

grant execute on function admin_list_admins(uuid, int) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_invite_admin — create auth user + admin_users row (superadmin only)
-- ---------------------------------------------------------------------------
create or replace function admin_invite_admin(
  p_email text,
  p_role admin_role,
  p_deployment_id uuid default null,
  p_city_scope uuid[] default null,
  p_display_name text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, auth, extensions
as $$
declare
  v_email text := lower(btrim(p_email));
  v_user_id uuid := gen_random_uuid();
  v_password text;
  v_display text;
begin
  if not has_admin_role(array['superadmin']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_email is null or v_email !~ '^[^@]+@[^@]+\.[^@]+$' then
    raise exception using errcode = 'P0001', message = 'invalid email';
  end if;

  if exists (select 1 from auth.users u where lower(u.email) = v_email) then
    raise exception using errcode = 'P0001', message = 'email already registered';
  end if;

  if p_deployment_id is not null and not exists (
    select 1 from deployments d where d.id = p_deployment_id
  ) then
    raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'deployment not found';
  end if;

  v_display := nullif(btrim(coalesce(p_display_name, split_part(v_email, '@', 1))), '');
  v_password := encode(gen_random_bytes(12), 'base64');

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    v_email,
    crypt(v_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('display_name', v_display),
    now(),
    now(),
    '', '', '', ''
  );

  insert into auth.identities (
    provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_user_id::text,
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_email),
    'email',
    now(), now(), now()
  );

  update profiles
  set display_name = v_display, updated_at = now()
  where id = v_user_id;

  insert into admin_users (id, role, deployment_id, city_scope)
  values (v_user_id, p_role, p_deployment_id, p_city_scope);

  return jsonb_build_object(
    'user_id', v_user_id,
    'email', v_email,
    'role', p_role,
    'temporary_password', v_password
  );
end;
$$;

grant execute on function admin_invite_admin(text, admin_role, uuid, uuid[], text) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_update_admin — role, deployment, city scope (superadmin only)
-- ---------------------------------------------------------------------------
create or replace function admin_update_admin(
  p_user_id uuid,
  p_role admin_role default null,
  p_deployment_id uuid default null,
  p_city_scope uuid[] default null,
  p_clear_city_scope boolean default false
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_row admin_users%rowtype;
begin
  if not has_admin_role(array['superadmin']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  select * into v_row
  from admin_users
  where id = p_user_id
  for update;

  if v_row.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if p_deployment_id is not null and not exists (
    select 1 from deployments d where d.id = p_deployment_id
  ) then
    raise exception 'NOT_FOUND' using errcode = 'P0001', message = 'deployment not found';
  end if;

  update admin_users
  set
    role = coalesce(p_role, role),
    deployment_id = case when p_deployment_id is not null then p_deployment_id else deployment_id end,
    city_scope = case
      when p_clear_city_scope then null
      when p_city_scope is not null then p_city_scope
      else city_scope
    end,
    updated_at = now()
  where id = p_user_id
  returning * into v_row;

  return jsonb_build_object(
    'user_id', v_row.id,
    'role', v_row.role,
    'deployment_id', v_row.deployment_id,
    'city_scope', v_row.city_scope,
    'disabled_at', v_row.disabled_at
  );
end;
$$;

grant execute on function admin_update_admin(uuid, admin_role, uuid, uuid[], boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_disable_admin — soft-disable (superadmin only; cannot disable self)
-- ---------------------------------------------------------------------------
create or replace function admin_disable_admin(p_user_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_row admin_users%rowtype;
begin
  if not has_admin_role(array['superadmin']) then
    raise exception 'FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_user_id = auth.uid() then
    raise exception using errcode = 'P0001', message = 'cannot disable your own account';
  end if;

  select * into v_row
  from admin_users
  where id = p_user_id
  for update;

  if v_row.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_row.disabled_at is not null then
    return jsonb_build_object('user_id', p_user_id, 'disabled_at', v_row.disabled_at);
  end if;

  update admin_users
  set disabled_at = now(), updated_at = now()
  where id = p_user_id
  returning * into v_row;

  return jsonb_build_object('user_id', v_row.id, 'disabled_at', v_row.disabled_at);
end;
$$;

grant execute on function admin_disable_admin(uuid) to authenticated;
