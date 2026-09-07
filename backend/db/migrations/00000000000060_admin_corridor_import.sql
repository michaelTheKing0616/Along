-- P7-E-01: Extend admin_import_dry_run / admin_import_apply for corridor backbone bundles (doc 13 §4).

create or replace function _slugify_graph_name(p_name text)
returns text
language sql
immutable
as $$
  select regexp_replace(
    regexp_replace(lower(btrim(p_name)), '[^a-z0-9]+', '-', 'g'),
    '(^-+|-+$)',
    '',
    'g'
  );
$$;

create or replace function _corridor_route_label(
  p_origin text,
  p_destination text,
  p_mode text,
  p_name text
)
returns text
language sql
immutable
as $$
  select case
    when nullif(btrim(p_name), '') is not null then btrim(p_name)
    else format('%s → %s (%s)', btrim(p_origin), btrim(p_destination), btrim(p_mode))
  end;
$$;

create or replace function _corridor_import_dry_run(p_city_id uuid, p_bundle jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_diff jsonb := '[]'::jsonb;
  v_corridor_slug text := btrim(p_bundle->'corridor'->>'slug');
  v_corridor_name text := btrim(p_bundle->'corridor'->>'name');
  v_row jsonb;
  v_existing int;
  v_route_name text;
begin
  if v_corridor_slug = '' or v_corridor_name = '' then
    raise exception 'VALIDATION: corridor.name and corridor.slug are required' using errcode = 'P0001';
  end if;

  select count(*)::int into v_existing
  from corridors c
  where c.city_id = p_city_id
    and c.slug = v_corridor_slug;

  v_diff := v_diff || jsonb_build_array(jsonb_build_object(
    'entity', 'corridor',
    'name', v_corridor_name,
    'slug', v_corridor_slug,
    'action', case when v_existing > 0 then 'skip' else 'create' end,
    'reason', case when v_existing > 0 then 'Corridor slug already exists in city' else null end
  ));

  for v_row in
    select value
    from jsonb_array_elements(coalesce(p_bundle->'parks', '[]'::jsonb))
  loop
    select count(*)::int into v_existing
    from parks p
    where p.city_id = p_city_id
      and lower(btrim(p.name)) = lower(btrim(v_row->>'name'));

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'entity', 'park',
      'name', v_row->>'name',
      'lat', (v_row->>'lat')::double precision,
      'lng', (v_row->>'lng')::double precision,
      'name_aliases', coalesce(v_row->'name_aliases', '[]'::jsonb),
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Park name already exists in city' else null end
    ));
  end loop;

  for v_row in
    select value
    from jsonb_array_elements(coalesce(p_bundle->'routes', '[]'::jsonb))
  loop
    v_route_name := _corridor_route_label(
      v_row->>'origin_park',
      v_row->>'destination_park',
      v_row->>'mode',
      v_row->>'name'
    );

    select count(*)::int into v_existing
    from routes r
    join parks op on op.id = r.origin_park_id
    join parks dp on dp.id = r.destination_park_id
    where r.city_id = p_city_id
      and lower(op.name) = lower(btrim(v_row->>'origin_park'))
      and lower(dp.name) = lower(btrim(v_row->>'destination_park'))
      and r.mode_code = btrim(v_row->>'mode');

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'entity', 'route',
      'name', v_route_name,
      'origin_park', v_row->>'origin_park',
      'destination_park', v_row->>'destination_park',
      'mode', v_row->>'mode',
      'corridor_slug', v_corridor_slug,
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Route already exists for origin/destination/mode' else null end
    ));
  end loop;

  for v_row in
    select value
    from jsonb_array_elements(coalesce(p_bundle->'stages', '[]'::jsonb))
  loop
    v_route_name := btrim(v_row->>'route_name');

    select count(*)::int into v_existing
    from route_stages rs
    join routes r on r.id = rs.route_id
    where r.city_id = p_city_id
      and lower(coalesce(r.name, _corridor_route_label(
        (select p.name from parks p where p.id = r.origin_park_id),
        (select p.name from parks p where p.id = r.destination_park_id),
        r.mode_code,
        r.name
      ))) = lower(v_route_name)
      and rs.sequence = (v_row->>'sequence')::int;

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'entity', 'route_stage',
      'route_name', v_route_name,
      'sequence', (v_row->>'sequence')::int,
      'stage_name', v_row->>'stage_name',
      'lat', (v_row->>'lat')::double precision,
      'lng', (v_row->>'lng')::double precision,
      'is_official_park', coalesce((v_row->>'is_official_park')::boolean, false),
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Stage sequence already exists on route' else null end
    ));
  end loop;

  for v_row in
    select value
    from jsonb_array_elements(coalesce(p_bundle->'leg_fares', '[]'::jsonb))
  loop
    v_route_name := btrim(v_row->>'route_name');

    select count(*)::int into v_existing
    from route_legs rl
    join routes r on r.id = rl.route_id
    join route_stages fs on fs.id = rl.from_stage_id
    join route_stages ts on ts.id = rl.to_stage_id
    where r.city_id = p_city_id
      and lower(coalesce(r.name, _corridor_route_label(
        (select p.name from parks p where p.id = r.origin_park_id),
        (select p.name from parks p where p.id = r.destination_park_id),
        r.mode_code,
        r.name
      ))) = lower(v_route_name)
      and fs.sequence = (v_row->>'from_seq')::int
      and ts.sequence = (v_row->>'to_seq')::int;

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'entity', 'route_leg',
      'route_name', v_route_name,
      'from_seq', (v_row->>'from_seq')::int,
      'to_seq', (v_row->>'to_seq')::int,
      'fare', (v_row->>'fare')::numeric,
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Leg fare already exists' else null end
    ));
  end loop;

  for v_row in
    select value
    from jsonb_array_elements(coalesce(p_bundle->'through_fares', '[]'::jsonb))
  loop
    v_route_name := btrim(v_row->>'route_name');

    select count(*)::int into v_existing
    from route_through_fares tf
    join routes r on r.id = tf.route_id
    join route_stages fs on fs.id = tf.from_stage_id
    join route_stages ts on ts.id = tf.to_stage_id
    where r.city_id = p_city_id
      and lower(coalesce(r.name, _corridor_route_label(
        (select p.name from parks p where p.id = r.origin_park_id),
        (select p.name from parks p where p.id = r.destination_park_id),
        r.mode_code,
        r.name
      ))) = lower(v_route_name)
      and fs.sequence = (v_row->>'from_seq')::int
      and ts.sequence = (v_row->>'to_seq')::int;

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'entity', 'route_through_fare',
      'route_name', v_route_name,
      'from_seq', (v_row->>'from_seq')::int,
      'to_seq', (v_row->>'to_seq')::int,
      'fare', (v_row->>'fare')::numeric,
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Through-fare already exists' else null end
    ));
  end loop;

  return jsonb_build_object('kind', 'corridor', 'diff', v_diff);
end;
$$;

create or replace function _corridor_import_apply(p_city_id uuid, p_diff jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_row jsonb;
  v_source_id uuid;
  v_corridor_id uuid;
  v_park_id uuid;
  v_route_id uuid;
  v_stage_id uuid;
  v_created int := 0;
  v_currency char(3);
  v_route_name text;
  v_total_skipped int;
begin
  select c.currency_code into v_currency
  from cities ci
  join countries c on c.code = ci.country_code
  where ci.id = p_city_id;

  for v_row in
    select value
    from jsonb_array_elements(p_diff)
    where coalesce(value->>'action', '') = 'create'
    order by case value->>'entity'
      when 'corridor' then 1
      when 'park' then 2
      when 'route' then 3
      when 'route_stage' then 4
      when 'route_leg' then 5
      when 'route_through_fare' then 6
      else 99
    end,
    coalesce((value->>'sequence')::int, 0)
  loop
    v_source_id := _admin_graph_source(format(
      'admin_import_apply:%s:%s',
      v_row->>'entity',
      coalesce(v_row->>'slug', v_row->>'name', v_row->>'route_name')
    ));
    perform set_config('along.revision_reason', 'corridor_csv_import', true);

    case v_row->>'entity'
      when 'corridor' then
        insert into corridors (city_id, name, slug, status)
        values (p_city_id, v_row->>'name', v_row->>'slug', 'alpha')
        returning id into v_corridor_id;
        v_created := v_created + 1;

      when 'park' then
        insert into parks (
          city_id, name, name_aliases, location, source_id, verification_status, confidence_score
        ) values (
          p_city_id,
          v_row->>'name',
          coalesce(
            (select array_agg(x) from jsonb_array_elements_text(v_row->'name_aliases') as t(x)),
            '{}'::text[]
          ),
          st_setsrid(
            st_makepoint((v_row->>'lng')::double precision, (v_row->>'lat')::double precision),
            4326
          )::geography,
          v_source_id,
          'candidate',
          0.300
        );
        v_created := v_created + 1;

      when 'route' then
        select c.id into v_corridor_id
        from corridors c
        where c.city_id = p_city_id
          and c.slug = v_row->>'corridor_slug';

        if v_corridor_id is null then
          raise exception 'VALIDATION: corridor % not found for route %', v_row->>'corridor_slug', v_row->>'name'
            using errcode = 'P0001';
        end if;

        select p.id into v_park_id
        from parks p
        where p.city_id = p_city_id
          and lower(p.name) = lower(btrim(v_row->>'origin_park'));

        if v_park_id is null then
          raise exception 'VALIDATION: origin park % not found', v_row->>'origin_park' using errcode = 'P0001';
        end if;

        select p.id into v_stage_id
        from parks p
        where p.city_id = p_city_id
          and lower(p.name) = lower(btrim(v_row->>'destination_park'));

        if v_stage_id is null then
          raise exception 'VALIDATION: destination park % not found', v_row->>'destination_park'
            using errcode = 'P0001';
        end if;

        insert into routes (
          city_id, corridor_id, origin_park_id, destination_park_id, mode_code, name,
          source_id, verification_status, confidence_score
        ) values (
          p_city_id,
          v_corridor_id,
          v_park_id,
          v_stage_id,
          btrim(v_row->>'mode'),
          v_row->>'name',
          v_source_id,
          'candidate',
          0.300
        );
        v_created := v_created + 1;

      when 'route_stage' then
        v_route_name := btrim(v_row->>'route_name');

        select r.id into v_route_id
        from routes r
        where r.city_id = p_city_id
          and lower(coalesce(r.name, _corridor_route_label(
            (select p.name from parks p where p.id = r.origin_park_id),
            (select p.name from parks p where p.id = r.destination_park_id),
            r.mode_code,
            r.name
          ))) = lower(v_route_name)
        order by r.created_at desc
        limit 1;

        if v_route_id is null then
          raise exception 'VALIDATION: route % not found for stage', v_route_name using errcode = 'P0001';
        end if;

        v_park_id := null;
        if coalesce((v_row->>'is_official_park')::boolean, false) then
          select p.id into v_park_id
          from parks p
          where p.city_id = p_city_id
            and lower(p.name) = lower(btrim(v_row->>'stage_name'))
          limit 1;
        end if;

        insert into route_stages (
          route_id, sequence, park_id, location, name, is_official_park,
          source_id, verification_status, confidence_score
        ) values (
          v_route_id,
          (v_row->>'sequence')::int,
          v_park_id,
          st_setsrid(
            st_makepoint((v_row->>'lng')::double precision, (v_row->>'lat')::double precision),
            4326
          )::geography,
          v_row->>'stage_name',
          coalesce((v_row->>'is_official_park')::boolean, false),
          v_source_id,
          'candidate',
          0.300
        )
        returning id into v_stage_id;

        if v_park_id is not null then
          insert into transfer_points (park_id, route_id, stage_id, walk_distance_m, transfer_time_s)
          values (v_park_id, v_route_id, v_stage_id, 0, 120)
          on conflict (park_id, route_id) do update
            set stage_id = excluded.stage_id,
                walk_distance_m = excluded.walk_distance_m,
                transfer_time_s = excluded.transfer_time_s;
        end if;

        v_created := v_created + 1;

      when 'route_leg' then
        v_route_name := btrim(v_row->>'route_name');

        select r.id into v_route_id
        from routes r
        where r.city_id = p_city_id
          and lower(coalesce(r.name, _corridor_route_label(
            (select p.name from parks p where p.id = r.origin_park_id),
            (select p.name from parks p where p.id = r.destination_park_id),
            r.mode_code,
            r.name
          ))) = lower(v_route_name)
        order by r.created_at desc
        limit 1;

        insert into route_legs (
          route_id, from_stage_id, to_stage_id, mode_code,
          fare_amount, fare_currency, source_id, verification_status, confidence_score
        )
        select
          v_route_id,
          fs.id,
          ts.id,
          r.mode_code,
          (v_row->>'fare')::numeric,
          v_currency,
          v_source_id,
          'candidate',
          0.300
        from routes r
        join route_stages fs on fs.route_id = r.id and fs.sequence = (v_row->>'from_seq')::int
        join route_stages ts on ts.route_id = r.id and ts.sequence = (v_row->>'to_seq')::int
        where r.id = v_route_id;

        v_created := v_created + 1;

      when 'route_through_fare' then
        v_route_name := btrim(v_row->>'route_name');

        select r.id into v_route_id
        from routes r
        where r.city_id = p_city_id
          and lower(coalesce(r.name, _corridor_route_label(
            (select p.name from parks p where p.id = r.origin_park_id),
            (select p.name from parks p where p.id = r.destination_park_id),
            r.mode_code,
            r.name
          ))) = lower(v_route_name)
        order by r.created_at desc
        limit 1;

        insert into route_through_fares (
          route_id, from_stage_id, to_stage_id, mode_code,
          fare_amount, fare_currency, source_id, verification_status, confidence_score
        )
        select
          v_route_id,
          fs.id,
          ts.id,
          r.mode_code,
          (v_row->>'fare')::numeric,
          v_currency,
          v_source_id,
          'candidate',
          0.300
        from routes r
        join route_stages fs on fs.route_id = r.id and fs.sequence = (v_row->>'from_seq')::int
        join route_stages ts on ts.route_id = r.id and ts.sequence = (v_row->>'to_seq')::int
        where r.id = v_route_id;

        v_created := v_created + 1;

      else
        null;
    end case;

    perform set_config('along.revision_reason', '', true);
  end loop;

  select count(*)::int into v_total_skipped
  from jsonb_array_elements(p_diff) elem
  where coalesce(elem->>'action', '') <> 'create';

  return jsonb_build_object('kind', 'corridor', 'created', v_created, 'skipped', v_total_skipped);
end;
$$;

-- Extend admin_import_dry_run: parks CSV (legacy) or corridor JSON bundle.
create or replace function admin_import_dry_run(p_city_id uuid, p_csv text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_bundle jsonb;
  v_line text;
  v_lines text[];
  v_parts text[];
  v_name text;
  v_lat double precision;
  v_lng double precision;
  v_diff jsonb := '[]'::jsonb;
  v_existing int;
  v_i int;
begin
  if coalesce(current_setting('role', true), '') <> 'service_role'
     and current_user not in ('postgres', 'supabase_admin')
     and not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if coalesce(current_setting('role', true), '') <> 'service_role'
     and current_user not in ('postgres', 'supabase_admin')
     and not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if btrim(coalesce(p_csv, '')) like '{%' then
    v_bundle := p_csv::jsonb;
    if coalesce(v_bundle->>'kind', '') <> 'corridor' then
      raise exception 'VALIDATION: JSON import requires kind=corridor' using errcode = 'P0001';
    end if;
    return _corridor_import_dry_run(p_city_id, v_bundle);
  end if;

  v_lines := regexp_split_to_array(coalesce(p_csv, ''), E'\\r?\\n');

  for v_i in 1 .. coalesce(array_length(v_lines, 1), 0) loop
    v_line := btrim(v_lines[v_i]);
    if v_line = '' then continue; end if;
    if v_i = 1 and v_line ~* '^name\\s*,' then continue; end if;

    v_parts := string_to_array(v_line, ',');
    if coalesce(array_length(v_parts, 1), 0) < 3 then
      raise exception 'VALIDATION: line % expects name,lat,lng', v_i using errcode = 'P0001';
    end if;

    v_name := btrim(v_parts[1]);
    v_lat := btrim(v_parts[2])::double precision;
    v_lng := btrim(v_parts[3])::double precision;

    select count(*)::int into v_existing
    from parks p
    where p.city_id = p_city_id
      and lower(btrim(p.name)) = lower(v_name);

    v_diff := v_diff || jsonb_build_array(jsonb_build_object(
      'entity', 'park',
      'name', v_name,
      'lat', v_lat,
      'lng', v_lng,
      'action', case when v_existing > 0 then 'skip' else 'create' end,
      'reason', case when v_existing > 0 then 'Park name already exists in city' else null end
    ));
  end loop;

  return jsonb_build_object('kind', 'parks', 'diff', v_diff);
end;
$$;

create or replace function admin_import_apply(p_city_id uuid, p_diff jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_row jsonb;
  v_source_id uuid;
  v_created int := 0;
  v_skipped int := 0;
  v_is_corridor boolean := false;
begin
  if coalesce(current_setting('role', true), '') <> 'service_role'
     and current_user not in ('postgres', 'supabase_admin')
     and not has_admin_role(array['ops_agent', 'ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if coalesce(current_setting('role', true), '') <> 'service_role'
     and current_user not in ('postgres', 'supabase_admin')
     and not admin_can_access_city(p_city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if jsonb_typeof(p_diff) <> 'array' then
    raise exception 'VALIDATION: p_diff must be a JSON array' using errcode = 'P0001';
  end if;

  select exists (
    select 1
    from jsonb_array_elements(p_diff) elem
    where coalesce(elem->>'entity', 'park') <> 'park'
       or elem ? 'corridor_slug'
  ) into v_is_corridor;

  if v_is_corridor then
    return _corridor_import_apply(p_city_id, p_diff);
  end if;

  for v_row in select value from jsonb_array_elements(p_diff) loop
    if coalesce(v_row->>'action', '') <> 'create' then
      v_skipped := v_skipped + 1;
      continue;
    end if;

    v_source_id := _admin_graph_source(format('admin_import_apply:park:%s', v_row->>'name'));
    perform set_config('along.revision_reason', 'csv_import', true);

    insert into parks (
      city_id, name, location, source_id, verification_status, confidence_score
    ) values (
      p_city_id,
      v_row->>'name',
      st_setsrid(
        st_makepoint((v_row->>'lng')::double precision, (v_row->>'lat')::double precision),
        4326
      )::geography,
      v_source_id,
      'candidate',
      0.300
    );

    perform set_config('along.revision_reason', '', true);
    v_created := v_created + 1;
  end loop;

  return jsonb_build_object('kind', 'parks', 'created', v_created, 'skipped', v_skipped);
end;
$$;

grant execute on function _corridor_import_dry_run(uuid, jsonb) to authenticated;
grant execute on function _corridor_import_apply(uuid, jsonb) to authenticated;
grant execute on function admin_import_dry_run(uuid, text) to service_role;
grant execute on function admin_import_apply(uuid, jsonb) to service_role;
