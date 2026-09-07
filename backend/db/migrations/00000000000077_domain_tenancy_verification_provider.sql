-- P10-A-01: deployment tenant isolation RLS, verification provider helpers, regulatory/currency metadata.

-- ---------------------------------------------------------------------------
-- Tenant scoping helpers (ADR-0004: city → country → deployment)
-- ---------------------------------------------------------------------------
create or replace function auth_user_deployment_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select a.deployment_id
      from admin_users a
      where a.id = auth.uid()
        and a.disabled_at is null
    ),
    (
      select k.deployment_id
      from riders r
      join cities c on c.id = r.home_city_id
      join countries k on k.code = c.country_code
      where r.id = auth.uid()
    ),
    (
      select k.deployment_id
      from drivers d
      join cities c on c.id = d.city_id
      join countries k on k.code = c.country_code
      where d.id = auth.uid()
    )
  );
$$;

revoke all on function auth_user_deployment_id() from public;
grant execute on function auth_user_deployment_id() to authenticated, service_role;

create or replace function city_in_user_deployment(p_city_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auth_user_deployment_id() is null
    or exists (
      select 1
      from cities c
      join countries k on k.code = c.country_code
      where c.id = p_city_id
        and k.deployment_id = auth_user_deployment_id()
    );
$$;

revoke all on function city_in_user_deployment(uuid) from public;
grant execute on function city_in_user_deployment(uuid) to authenticated, service_role;

create or replace function app_config_visible_to_user(
  p_scope_type config_scope,
  p_scope_id text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when auth_user_deployment_id() is null then true
    when p_scope_type = 'global' then true
    when p_scope_type = 'country' then exists (
      select 1
      from countries k
      where k.code = p_scope_id
        and k.deployment_id = auth_user_deployment_id()
    )
    when p_scope_type = 'city' then city_in_user_deployment(p_scope_id::uuid)
    when p_scope_type = 'corridor' then exists (
      select 1
      from corridors cor
      where cor.id = p_scope_id::uuid
        and city_in_user_deployment(cor.city_id)
    )
    else false
  end;
$$;

revoke all on function app_config_visible_to_user(config_scope, text) from public;
grant execute on function app_config_visible_to_user(config_scope, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Verification provider resolution (countries.verification_schema[].provider)
-- ---------------------------------------------------------------------------
create or replace function verification_doc_provider(
  p_country_code char(2),
  p_document_type text
)
returns text
language sql
stable
as $$
  select elem->>'provider'
  from countries c,
       lateral jsonb_array_elements(c.verification_schema) elem
  where c.code = p_country_code
    and elem->>'type' = p_document_type
  limit 1;
$$;

revoke all on function verification_doc_provider(char(2), text) from public;
grant execute on function verification_doc_provider(char(2), text) to authenticated, service_role;

create or replace function country_currency_meta(p_country_code char(2))
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'currency_code', c.currency_code,
    'currency_symbol', c.currency_symbol,
    'currency_minor_units', c.currency_minor_units
  )
  from countries c
  where c.code = p_country_code;
$$;

revoke all on function country_currency_meta(char(2)) from public;
grant execute on function country_currency_meta(char(2)) to authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- Verification provider stub config (no live VerifyMe API in CI)
-- ---------------------------------------------------------------------------
select config_default('verification.provider.verifyme.stub_mode', 'true');
select config_default('verification.provider.verifyme.base_url', 'null');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'verification.provider.verifyme.stub_mode',
    '{"type":"boolean"}',
    'When true, verification-ocr uses the in-process VerifyMe stub adapter (never calls live API)',
    array['global']::config_scope[],
    false
  ),
  (
    'verification.provider.verifyme.base_url',
    '{"type":["string","null"]}',
    'Optional VerifyMe API base URL; null keeps stub mode regardless of environment',
    array['global']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Tenant isolation RLS (cross-tenant SELECT returns 0 once user has deployment)
-- ---------------------------------------------------------------------------
drop policy if exists deployments_select_authenticated on deployments;
create policy deployments_select_authenticated
  on deployments for select to authenticated
  using (
    auth_user_deployment_id() is null
    or id = auth_user_deployment_id()
  );

drop policy if exists countries_select_authenticated on countries;
create policy countries_select_authenticated
  on countries for select to authenticated
  using (
    auth_user_deployment_id() is null
    or deployment_id = auth_user_deployment_id()
  );

drop policy if exists cities_select_authenticated on cities;
create policy cities_select_authenticated
  on cities for select to authenticated
  using (city_in_user_deployment(id));

drop policy if exists corridors_select_authenticated on corridors;
create policy corridors_select_authenticated
  on corridors for select to authenticated
  using (city_in_user_deployment(city_id));

drop policy if exists app_config_select_authenticated on app_config;
create policy app_config_select_authenticated
  on app_config for select to authenticated
  using (app_config_visible_to_user(scope_type, scope_id));
