-- P10-D-01: A-18 Markets & portability — country upsert + verification schema RPCs.

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only)
values (
  'payments.provider',
  '{"type":"string","enum":["paystack","flutterwave","none"]}'::jsonb,
  'Payment provider for digital payments in this country (Phase 4 gate still applies)',
  array['country']::config_scope[],
  false
)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- admin_upsert_country — create or update country row + country-scoped payment provider
-- ---------------------------------------------------------------------------
create or replace function admin_upsert_country(
  p_code char(2),
  p_name text,
  p_currency_code char(3),
  p_currency_symbol text,
  p_phone_prefix text,
  p_default_locale text,
  p_timezone text,
  p_deployment_id uuid,
  p_currency_minor_units smallint default 2,
  p_regulatory_flags jsonb default '{}'::jsonb,
  p_active boolean default false,
  p_payment_provider text default 'paystack'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_code char(2) := upper(btrim(p_code));
  v_name text := btrim(p_name);
  v_provider text := lower(btrim(coalesce(p_payment_provider, 'paystack')));
  v_row countries%rowtype;
begin
  if not has_admin_role(array['superadmin', 'ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if v_code is null or v_code = '' or length(v_code) <> 2 then
    raise exception 'VALIDATION: country code must be ISO 3166-1 alpha-2' using errcode = 'P0001';
  end if;

  if v_name = '' then
    raise exception 'VALIDATION: name is required' using errcode = 'P0001';
  end if;

  if p_currency_code is null or btrim(p_currency_code) = '' then
    raise exception 'VALIDATION: currency_code is required' using errcode = 'P0001';
  end if;

  if p_currency_symbol is null or btrim(p_currency_symbol) = '' then
    raise exception 'VALIDATION: currency_symbol is required' using errcode = 'P0001';
  end if;

  if p_phone_prefix is null or btrim(p_phone_prefix) = '' then
    raise exception 'VALIDATION: phone_prefix is required' using errcode = 'P0001';
  end if;

  if p_default_locale is null or btrim(p_default_locale) = '' then
    raise exception 'VALIDATION: default_locale is required' using errcode = 'P0001';
  end if;

  if p_timezone is null or btrim(p_timezone) = '' then
    raise exception 'VALIDATION: timezone is required' using errcode = 'P0001';
  end if;

  if not exists (select 1 from deployments d where d.id = p_deployment_id and d.active) then
    raise exception 'VALIDATION: deployment % is missing or inactive', p_deployment_id using errcode = 'P0001';
  end if;

  if v_provider not in ('paystack', 'flutterwave', 'none') then
    raise exception 'VALIDATION: payment_provider must be paystack, flutterwave, or none' using errcode = 'P0001';
  end if;

  insert into countries (
    code,
    name,
    currency_code,
    currency_minor_units,
    currency_symbol,
    phone_prefix,
    default_locale,
    timezone,
    deployment_id,
    regulatory_flags,
    active
  ) values (
    v_code,
    v_name,
    upper(btrim(p_currency_code)),
    coalesce(p_currency_minor_units, 2),
    btrim(p_currency_symbol),
    btrim(p_phone_prefix),
    btrim(p_default_locale),
    btrim(p_timezone),
    p_deployment_id,
    coalesce(p_regulatory_flags, '{}'::jsonb),
    coalesce(p_active, false)
  )
  on conflict (code) do update set
    name = excluded.name,
    currency_code = excluded.currency_code,
    currency_minor_units = excluded.currency_minor_units,
    currency_symbol = excluded.currency_symbol,
    phone_prefix = excluded.phone_prefix,
    default_locale = excluded.default_locale,
    timezone = excluded.timezone,
    deployment_id = excluded.deployment_id,
    regulatory_flags = excluded.regulatory_flags,
    active = excluded.active,
    updated_at = now()
  returning * into v_row;

  perform admin_set_config(
    'payments.provider',
    'country'::config_scope,
    v_row.code::text,
    to_jsonb(v_provider),
    'markets portability console'
  );

  return jsonb_build_object(
    'code', v_row.code,
    'name', v_row.name,
    'currency_code', v_row.currency_code,
    'currency_symbol', v_row.currency_symbol,
    'phone_prefix', v_row.phone_prefix,
    'default_locale', v_row.default_locale,
    'timezone', v_row.timezone,
    'deployment_id', v_row.deployment_id,
    'regulatory_flags', v_row.regulatory_flags,
    'active', v_row.active,
    'payment_provider', v_provider
  );
end;
$$;

grant execute on function admin_upsert_country(
  char(2), text, char(3), text, text, text, text, uuid, smallint, jsonb, boolean, text
) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_set_country_schema — verification_schema editor (document types/patterns/providers)
-- ---------------------------------------------------------------------------
create or replace function admin_set_country_schema(
  p_code char(2),
  p_verification_schema jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_code char(2) := upper(btrim(p_code));
  v_row countries%rowtype;
  v_elem jsonb;
begin
  if not has_admin_role(array['superadmin', 'ops_lead']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if v_code is null or v_code = '' then
    raise exception 'VALIDATION: country code is required' using errcode = 'P0001';
  end if;

  if p_verification_schema is null or jsonb_typeof(p_verification_schema) <> 'array' then
    raise exception 'VALIDATION: verification_schema must be a JSON array' using errcode = 'P0001';
  end if;

  for v_elem in select value from jsonb_array_elements(p_verification_schema) value loop
    if jsonb_typeof(v_elem) <> 'object' then
      raise exception 'VALIDATION: each verification_schema entry must be an object' using errcode = 'P0001';
    end if;
    if coalesce(v_elem->>'type', '') = '' then
      raise exception 'VALIDATION: verification_schema entry missing type' using errcode = 'P0001';
    end if;
    if coalesce(v_elem->>'label', '') = '' then
      raise exception 'VALIDATION: verification_schema entry missing label' using errcode = 'P0001';
    end if;
    if coalesce(v_elem->>'pattern', '') = '' then
      raise exception 'VALIDATION: verification_schema entry missing pattern' using errcode = 'P0001';
    end if;
    if coalesce(v_elem->>'provider', '') = '' then
      raise exception 'VALIDATION: verification_schema entry missing provider' using errcode = 'P0001';
    end if;
  end loop;

  update countries
  set verification_schema = p_verification_schema,
      updated_at = now()
  where code = v_code
  returning * into v_row;

  if v_row.code is null then
    raise exception 'NOT_FOUND: country %', v_code using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'code', v_row.code,
    'verification_schema', v_row.verification_schema
  );
end;
$$;

grant execute on function admin_set_country_schema(char(2), jsonb) to authenticated;
