-- P9-E-01: Generic city onboarding RPC (no bespoke city branches in application code).

create or replace function admin_create_city(
  p_name text,
  p_slug text,
  p_country_code char(2),
  p_centroid_lat double precision,
  p_centroid_lng double precision,
  p_state_region text default null,
  p_status city_status default 'pre_seed',
  p_config_overrides jsonb default '{}'::jsonb,
  p_dry_run boolean default false
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_name text := btrim(p_name);
  v_slug text := btrim(p_slug);
  v_existing cities%rowtype;
  v_row cities%rowtype;
  v_key text;
  v_value jsonb;
  v_meta app_config_keys%rowtype;
  v_applied jsonb := '[]'::jsonb;
begin
  if coalesce(current_setting('role', true), '') <> 'service_role'
     and not has_admin_role(array['ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if v_name = '' or v_slug = '' then
    raise exception 'VALIDATION: name and slug are required' using errcode = 'P0001';
  end if;

  if p_centroid_lat is null or p_centroid_lng is null
     or p_centroid_lat < -90 or p_centroid_lat > 90
     or p_centroid_lng < -180 or p_centroid_lng > 180 then
    raise exception 'VALIDATION: centroid lat/lng must be valid WGS84 coordinates' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from countries k
    where k.code = p_country_code and k.active
  ) then
    raise exception 'VALIDATION: country % is missing or inactive', p_country_code using errcode = 'P0001';
  end if;

  select c.* into v_existing
  from cities c
  where c.slug = v_slug;

  if found then
    return jsonb_build_object(
      'dry_run', p_dry_run,
      'action', 'skip',
      'reason', 'City slug already exists',
      'city_id', v_existing.id,
      'slug', v_existing.slug,
      'name', v_existing.name
    );
  end if;

  if p_dry_run then
    return jsonb_build_object(
      'dry_run', true,
      'action', 'create',
      'city', jsonb_build_object(
        'name', v_name,
        'slug', v_slug,
        'country_code', p_country_code,
        'state_region', p_state_region,
        'status', p_status,
        'centroid', jsonb_build_object('lat', p_centroid_lat, 'lng', p_centroid_lng)
      ),
      'config_overrides', coalesce(p_config_overrides, '{}'::jsonb)
    );
  end if;

  insert into cities (
    country_code,
    name,
    slug,
    state_region,
    centroid,
    status
  ) values (
    p_country_code,
    v_name,
    v_slug,
    nullif(btrim(p_state_region), ''),
    st_setsrid(st_makepoint(p_centroid_lng, p_centroid_lat), 4326)::geography,
    coalesce(p_status, 'pre_seed'::city_status)
  )
  returning * into v_row;

  for v_key, v_value in
    select e.key, e.value
    from jsonb_each(coalesce(p_config_overrides, '{}'::jsonb)) e
  loop
    select k.* into v_meta from app_config_keys k where k.key = v_key;
    if not found then
      raise exception 'VALIDATION: unknown config key %', v_key using errcode = 'P0001';
    end if;

    if v_meta.read_only then
      raise exception 'VALIDATION: config key % is read-only', v_key using errcode = 'P0001';
    end if;

    if not ('city' = any (v_meta.allowed_scopes)) then
      raise exception 'VALIDATION: scope city not allowed for key %', v_key using errcode = 'P0001';
    end if;

    perform _validate_config_value(v_key, v_value);

    insert into app_config (key, scope_type, scope_id, value)
    values (v_key, 'city', v_row.id::text, v_value)
    on conflict (key, scope_type, scope_id) do update
      set value = excluded.value,
          updated_at = now();

    v_applied := v_applied || jsonb_build_array(
      jsonb_build_object('key', v_key, 'value', v_value)
    );
  end loop;

  return jsonb_build_object(
    'dry_run', false,
    'action', 'create',
    'city_id', v_row.id,
    'slug', v_row.slug,
    'name', v_row.name,
    'status', v_row.status,
    'config_overrides_applied', v_applied
  );
end;
$$;

revoke all on function admin_create_city(text, text, char, double precision, double precision, text, city_status, jsonb, boolean) from public;
grant execute on function admin_create_city(text, text, char, double precision, double precision, text, city_status, jsonb, boolean) to authenticated, service_role;
