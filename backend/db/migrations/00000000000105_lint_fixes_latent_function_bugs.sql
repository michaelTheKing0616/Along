-- Fix latent bugs surfaced by `supabase db lint` (db CI job):
--  * private.osrm_foot_duration_s: CREATE EXTENSION inside a STABLE function
--    (not allowed) -> create once here, function only checks availability.
--  * transfer_prefetch_context: wayfinding_mode lives on riders, not profiles.
--  * driver_ledger: destination_label lives on journeys, not trips.
--  * operator_overview: LIKE on presence_status enum needs ::text.

do $do$
begin
  create extension if not exists http with schema extensions;
exception
  when others then
    raise notice 'http extension unavailable: %', sqlerrm;
end;
$do$;

create or replace function private.osrm_foot_duration_s(
  p_from geography,
  p_to geography,
  p_city_id uuid default null
)
returns int
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_override text;
  v_url text;
  v_from_lng double precision;
  v_from_lat double precision;
  v_to_lng double precision;
  v_to_lat double precision;
  v_response record;
  v_body jsonb;
  v_duration numeric;
begin
  v_override := nullif(current_setting('along.test.osrm_foot_duration_s', true), '');
  if v_override is not null then
    return v_override::int;
  end if;

  v_url := nullif(current_setting('app.settings.osrm_foot_url', true), '');
  if v_url is null then
    return null;
  end if;

  v_from_lng := st_x(p_from::geometry);
  v_from_lat := st_y(p_from::geometry);
  v_to_lng := st_x(p_to::geometry);
  v_to_lat := st_y(p_to::geometry);

  -- DDL is not allowed in a stable function; the extension is created by the
  -- migration. Degrade to null (caller falls back) when it is unavailable.
  if not exists (select 1 from pg_extension where extname = 'http') then
    return null;
  end if;

  begin
    select * into v_response
    from extensions.http((
      'GET',
      format(
        '%s/route/v1/foot/%s,%s;%s,%s?overview=false',
        rtrim(v_url, '/'),
        v_from_lng, v_from_lat,
        v_to_lng, v_to_lat
      ),
      null::text[],
      null::text,
      null::text
    )::extensions.http_request);

    if v_response.status <> 200 then
      return null;
    end if;

    v_body := v_response.content::jsonb;
    v_duration := (v_body->'routes'->0->>'duration')::numeric;
    if v_duration is null then
      return null;
    end if;

    return greatest(0, round(v_duration)::int);
  exception
    when others then
      return null;
  end;
end;
$$;

create or replace function transfer_prefetch_context(p_trip_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_t trips%rowtype;
  v_j journeys%rowtype;
  v_leg_count int;
  v_current_leg jsonb;
  v_next_leg jsonb;
  v_from geography;
  v_to geography;
  v_remaining_s int;
  v_prefetch_eta_s int;
  v_wayfinding text;
begin
  select * into v_t from trips where id = p_trip_id;
  if v_t.id is null then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  select * into v_j from journeys where id = v_t.journey_id;
  v_leg_count := _journey_planned_leg_count(v_j.id);

  if v_t.status <> 'in_transit'
     or v_t.journey_sequence >= v_leg_count then
    return jsonb_build_object('eligible', false);
  end if;

  v_prefetch_eta_s := cfg_num('journey.transfer_prefetch_eta_s', v_j.city_id)::int;
  v_remaining_s := coalesce(
    _trip_planned_in_vehicle_s(v_t.id),
    0
  ) - extract(epoch from (now() - coalesce(v_t.started_at, v_t.boarded_at, v_t.accepted_at, now())))::int;

  if v_remaining_s > v_prefetch_eta_s then
    return jsonb_build_object('eligible', false, 'remaining_s', v_remaining_s);
  end if;

  v_current_leg := _journey_plan_leg(v_j.id, v_t.journey_sequence - 1);
  v_next_leg := _journey_plan_leg(v_j.id, v_t.journey_sequence);

  if v_current_leg is null or v_next_leg is null then
    return jsonb_build_object('eligible', false);
  end if;

  v_from := coalesce(
    v_t.alighting_location,
    case when v_current_leg->'alight' ? 'location'
      then _point_from_json(v_current_leg->'alight'->'location') else null end
  );
  v_to := case when v_next_leg->'board' ? 'location'
    then _point_from_json(v_next_leg->'board'->'location') else null end;

  if v_from is null or v_to is null then
    return jsonb_build_object('eligible', false);
  end if;

  select p.wayfinding_mode into v_wayfinding
  from riders p
  where p.id = v_j.rider_id;

  return jsonb_build_object(
    'eligible', true,
    'journey_id', v_j.id,
    'after_trip_sequence', v_t.journey_sequence,
    'city_id', v_j.city_id,
    'wayfinding_mode', coalesce(v_wayfinding, 'text'),
    'from', jsonb_build_object(
      'lat', st_y(v_from::geometry),
      'lng', st_x(v_from::geometry)
    ),
    'to', jsonb_build_object(
      'lat', st_y(v_to::geometry),
      'lng', st_x(v_to::geometry)
    )
  );
end;
$$;

create or replace function driver_ledger(p_cursor text default null, p_limit int default 50)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_limit int;
  v_cursor_id bigint;
  v_entries jsonb;
  v_next_cursor text;
  v_last_id bigint;
  v_has_more boolean;
begin
  if v_driver_id is null then
    raise exception 'UNAUTHENTICATED' using errcode = 'P0001';
  end if;

  v_limit := least(greatest(coalesce(p_limit, 50), 1), 50);

  if p_cursor is not null and btrim(p_cursor) <> '' then
    begin
      v_cursor_id := p_cursor::bigint;
    exception
      when others then
        raise exception 'VALIDATION' using errcode = 'P0001', message = 'invalid cursor';
    end;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', e.id::text,
        'entry_type', e.entry_type::text,
        'amount', jsonb_build_object(
          'amount', to_char(e.amount, 'FM999999990.00'),
          'currency', e.currency
        ),
        'balance_after', jsonb_build_object(
          'amount', to_char(e.balance_after, 'FM999999990.00'),
          'currency', e.currency
        ),
        'created_at', e.created_at,
        'memo', e.memo,
        'trip_id', e.trip_id,
        'destination_label', coalesce(rs.name, j.destination_label)
      )
      order by e.id desc
    ),
    '[]'::jsonb
  )
  into v_entries
  from (
    select dle.*
    from driver_ledger_entries dle
    where dle.driver_id = v_driver_id
      and (v_cursor_id is null or dle.id < v_cursor_id)
    order by dle.id desc
    limit v_limit
  ) e
  left join trips t on t.id = e.trip_id
  left join journeys j on j.id = t.journey_id
  left join route_stages rs on rs.id = t.alighting_stage_id;

  select min((entry->>'id')::bigint)
  into v_last_id
  from jsonb_array_elements(v_entries) entry;

  if v_last_id is not null then
    select exists (
      select 1
      from driver_ledger_entries dle
      where dle.driver_id = v_driver_id
        and dle.id < v_last_id
    )
    into v_has_more;

    if v_has_more then
      v_next_cursor := v_last_id::text;
    end if;
  end if;

  return jsonb_build_object(
    'entries', v_entries,
    'meta', jsonb_build_object('next_cursor', v_next_cursor)
  );
end;
$$;

create or replace function operator_overview(
  p_from timestamptz,
  p_to timestamptz
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_operator_id uuid;
  v_stale_s numeric;
  v_aggregates jsonb;
  v_online_total int := 0;
  v_online_at_park int := 0;
  v_online_roaming int := 0;
begin
  if p_from is null or p_to is null or p_to <= p_from then
    raise exception using errcode = 'P0001', message = 'ALONG:VALIDATION';
  end if;

  v_operator_id := admin_operator_account_id();
  if v_operator_id is null then
    raise exception using errcode = 'P0001', message = 'ALONG:FORBIDDEN';
  end if;

  v_aggregates := operator_driver_aggregates(p_from, p_to);
  v_stale_s := cfg_num('presence.stale_after_s');

  select
    count(*) filter (
      where dp.status <> 'offline'
        and dp.last_ping_at > now() - make_interval(secs => v_stale_s::int)
    )::int,
    count(*) filter (
      where dp.status = 'at_park'
        and dp.last_ping_at > now() - make_interval(secs => v_stale_s::int)
    )::int,
    count(*) filter (
      where dp.status::text like 'roaming%'
        and dp.last_ping_at > now() - make_interval(secs => v_stale_s::int)
    )::int
  into v_online_total, v_online_at_park, v_online_roaming
  from operator_members om
  join driver_presence dp on dp.driver_id = om.driver_id
  where om.operator_account_id = v_operator_id;

  return v_aggregates || jsonb_build_object(
    'online_total', v_online_total,
    'online_at_park', v_online_at_park,
    'online_roaming', v_online_roaming,
    'trips_per_day',
      case when p_to > p_from
        then round((v_aggregates->>'trips_completed')::numeric
          / greatest(extract(epoch from (p_to - p_from)) / 86400.0, 1), 2)
        else null end,
    'aggregate_only', true
  );
end;
$$;
