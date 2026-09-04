-- P1-A-03: doc 04 §3 resolve_fare Tier 0 + Tier 3 + load surcharge;
-- doc 03 §6 route/profile RPCs.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function round_to_minor(p_amount numeric, p_city_id uuid)
returns numeric
language sql
stable
as $$
  select round(
    p_amount,
    coalesce(
      (select k.currency_minor_units
       from cities c
       join countries k on k.code = c.country_code
       where c.id = p_city_id),
      2
    )
  )
$$;

do $do$
begin
  alter type fare_resolution add attribute load_surcharge_pending boolean;
exception
  when duplicate_column then null;
end $do$;

-- ---------------------------------------------------------------------------
-- resolve_fare — Tier 0–3 + load surcharge (extends P0-A-04 Tier 1–2)
-- ---------------------------------------------------------------------------
create or replace function resolve_fare(
  p_route_id uuid default null,
  p_profile_id uuid default null,
  p_from_stage_id uuid default null,
  p_to_stage_id uuid default null,
  p_from_point geography default null,
  p_to_point geography default null,
  p_mode_code text default null,
  p_city_id uuid default null,
  p_load jsonb default null,
  p_rider_id uuid default null,
  p_driver_id uuid default null
)
returns fare_resolution
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_result fare_resolution;
  v_components jsonb := '[]'::jsonb;
  v_tier smallint;
  v_confidence numeric(4,3);
  v_amount numeric(12,2);
  v_currency char(3);
  v_unconfirmed boolean := false;
  v_load_pending boolean := false;
  v_resolved boolean := false;
  v_seq_from int;
  v_seq_to int;
  v_tf record;
  v_tfc record;
  v_hop int;
  v_leg record;
  v_leg_count int;
  v_expected_legs int;
  v_profile record;
  v_board record;
  v_alight record;
  v_snap_radius numeric;
  v_distance_m double precision;
  v_rate_per_km numeric;
  v_min_fare numeric;
  v_anchor numeric;
  v_midpoint geography;
  v_load_flagged boolean := coalesce((p_load->>'flagged')::boolean, false);
begin
  if p_mode_code is null or p_city_id is null then
    raise exception 'resolve_fare: mode_code and city_id are required'
      using errcode = '22023';
  end if;

  if (
    (p_profile_id is not null)::int
    + (p_route_id is not null and p_from_stage_id is not null and p_to_stage_id is not null)::int
    + (p_from_point is not null and p_to_point is not null and p_route_id is null and p_profile_id is null)::int
  ) <> 1 then
    raise exception 'resolve_fare: exactly one resolution context is required'
      using errcode = '22023';
  end if;

  select k.currency_code
  into v_currency
  from cities c
  join countries k on k.code = c.country_code
  where c.id = p_city_id;

  if v_currency is null then
    raise exception 'resolve_fare: unknown city_id %', p_city_id;
  end if;

  v_snap_radius := cfg_num('graph.snap_radius_m', p_city_id);

  -- Tier 0: driver-declared profile prices (doc 04 §3)
  if p_profile_id is not null then
    select drp.id, drp.load_surcharge_amount
    into v_profile
    from driver_route_profiles drp
    where drp.id = p_profile_id
      and drp.active;

    if not found then
      raise exception 'resolve_fare: unknown or inactive profile_id %', p_profile_id
        using errcode = '22023';
    end if;

    if p_from_stage_id is not null then
      select s.*
      into v_board
      from driver_route_stops s
      where s.profile_id = p_profile_id
        and s.route_stage_id = p_from_stage_id
      order by s.sequence
      limit 1;
    elsif p_from_point is not null then
      select s.*
      into v_board
      from driver_route_stops s
      left join route_stages rs on rs.id = s.route_stage_id
      cross join lateral (
        select coalesce(rs.location, s.custom_location) as loc
      ) locs
      where s.profile_id = p_profile_id
        and locs.loc is not null
        and st_dwithin(locs.loc, p_from_point, v_snap_radius)
      order by st_distance(locs.loc, p_from_point), s.sequence
      limit 1;
    end if;

    if p_to_stage_id is not null then
      select s.*
      into v_alight
      from driver_route_stops s
      where s.profile_id = p_profile_id
        and s.route_stage_id = p_to_stage_id
      order by s.sequence desc
      limit 1;
    elsif p_to_point is not null then
      select s.*
      into v_alight
      from driver_route_stops s
      left join route_stages rs on rs.id = s.route_stage_id
      cross join lateral (
        select coalesce(rs.location, s.custom_location) as loc
      ) locs
      where s.profile_id = p_profile_id
        and locs.loc is not null
        and st_dwithin(locs.loc, p_to_point, v_snap_radius)
      order by st_distance(locs.loc, p_to_point), s.sequence desc
      limit 1;
    end if;

    if v_board.id is null or v_alight.id is null then
      raise exception 'resolve_fare: could not match profile stops for boarding/alighting'
        using errcode = '22023';
    end if;

    if v_board.sequence >= v_alight.sequence then
      raise exception 'resolve_fare: boarding stop must precede alighting stop on profile (direction matters)'
        using errcode = '22023';
    end if;

    v_amount := v_board.price_to_end - v_alight.price_to_end;
    v_components := jsonb_build_array(
      jsonb_build_object('kind', 'profile', 'ref_id', p_profile_id, 'amount', v_amount)
    );
    v_tier := 0;
    v_confidence := 1.0;
    v_resolved := true;

  elsif p_route_id is not null and p_from_stage_id is not null and p_to_stage_id is not null then
    select rs_from.sequence, rs_to.sequence
    into v_seq_from, v_seq_to
    from route_stages rs_from
    join route_stages rs_to on rs_to.route_id = rs_from.route_id
    where rs_from.id = p_from_stage_id
      and rs_to.id = p_to_stage_id
      and rs_from.route_id = p_route_id;

    if v_seq_from is null then
      raise exception 'resolve_fare: invalid stage pair for route %', p_route_id;
    end if;

    if v_seq_from >= v_seq_to then
      raise exception 'resolve_fare: from_stage must precede to_stage on route (direction matters)'
        using errcode = '22023';
    end if;

    select tf.id, tf.fare_amount, tf.confidence_score
    into v_tf
    from route_through_fares tf
    where tf.route_id = p_route_id
      and tf.from_stage_id = p_from_stage_id
      and tf.to_stage_id = p_to_stage_id
      and tf.verification_status <> 'candidate';

    if found then
      v_components := jsonb_build_array(
        jsonb_build_object('kind', 'through_fare', 'ref_id', v_tf.id, 'amount', v_tf.fare_amount)
      );
      v_tier := 1;
      v_confidence := v_tf.confidence_score;
      v_amount := v_tf.fare_amount;
      v_resolved := true;
    else
      v_expected_legs := v_seq_to - v_seq_from;
      v_leg_count := 0;
      v_amount := 0;
      v_confidence := 1.0;
      v_components := '[]'::jsonb;

      for v_hop in v_seq_from..v_seq_to - 1 loop
        select rl.id, rl.fare_amount, rl.confidence_score
        into v_leg
        from route_legs rl
        join route_stages fs on fs.id = rl.from_stage_id
        join route_stages ts on ts.id = rl.to_stage_id
        where rl.route_id = p_route_id
          and fs.sequence = v_hop
          and ts.sequence = v_hop + 1;

        if not found then
          exit;
        end if;

        v_leg_count := v_leg_count + 1;
        v_amount := v_amount + v_leg.fare_amount;
        v_confidence := least(v_confidence, v_leg.confidence_score);
        v_components := v_components || jsonb_build_array(
          jsonb_build_object('kind', 'leg', 'ref_id', v_leg.id, 'amount', v_leg.fare_amount)
        );
      end loop;

      if v_leg_count = v_expected_legs then
        v_tier := 2;
        v_resolved := true;
      else
        select tf.id, tf.fare_amount
        into v_tfc
        from route_through_fares tf
        where tf.route_id = p_route_id
          and tf.from_stage_id = p_from_stage_id
          and tf.to_stage_id = p_to_stage_id
          and tf.verification_status = 'candidate'
        limit 1;
      end if;
    end if;
  end if;

  if not v_resolved then
    if p_route_id is not null and p_from_stage_id is not null and p_to_stage_id is not null then
      select
        case
          when r.path is not null then
            st_length(
              st_linesubstring(
                r.path::geometry,
                least(
                  st_linelocatepoint(r.path::geometry, rs_from.location::geometry),
                  st_linelocatepoint(r.path::geometry, rs_to.location::geometry)
                ),
                greatest(
                  st_linelocatepoint(r.path::geometry, rs_from.location::geometry),
                  st_linelocatepoint(r.path::geometry, rs_to.location::geometry)
                )
              )::geography
            )
          else distance_m(rs_from.location, rs_to.location) * 1.3
        end,
        st_centroid(st_collect(array[rs_from.location::geometry, rs_to.location::geometry]))::geography
      into v_distance_m, v_midpoint
      from routes r
      join route_stages rs_from on rs_from.id = p_from_stage_id
      join route_stages rs_to on rs_to.id = p_to_stage_id
      where r.id = p_route_id;
    else
      v_distance_m := distance_m(p_from_point, p_to_point) * 1.3;
      v_midpoint := st_centroid(st_collect(array[p_from_point::geometry, p_to_point::geometry]))::geography;
    end if;

    select percentile_cont(0.5) within group (order by rl.fare_amount / nullif(rl.distance_m / 1000.0, 0))
    into v_rate_per_km
    from route_legs rl
    join routes r on r.id = rl.route_id
    join route_stages fs on fs.id = rl.from_stage_id
    join route_stages ts on ts.id = rl.to_stage_id
    where r.city_id = p_city_id
      and rl.mode_code = p_mode_code
      and rl.verification_status <> 'candidate'
      and rl.distance_m > 0
      and st_dwithin(
        st_centroid(st_collect(array[fs.location::geometry, ts.location::geometry]))::geography,
        v_midpoint,
        3000
      )
    limit 20;

    if v_rate_per_km is null then
      v_rate_per_km := (cfg('fare.default_rate_per_km', p_city_id)->>p_mode_code)::numeric;
    end if;

    v_min_fare := (cfg('fare.min_fare', p_city_id)->>p_mode_code)::numeric;
    v_anchor := round_to_minor(
      greatest(v_min_fare, v_rate_per_km * (v_distance_m / 1000.0))::numeric,
      p_city_id
    );

    if v_tfc.id is not null then
      v_anchor := v_tfc.fare_amount;
    end if;

    v_components := jsonb_build_array(
      jsonb_build_object('kind', 'estimate', 'amount', v_anchor)
    );
    v_amount := v_anchor;
    v_tier := 3;
    v_confidence := 0.3;
    v_unconfirmed := true;
    v_resolved := true;
  end if;

  if not v_resolved then
    raise exception 'resolve_fare: unable to resolve fare'
      using errcode = '22023';
  end if;

  if v_load_flagged then
    if p_profile_id is not null and v_profile.load_surcharge_amount is not null then
      v_components := v_components || jsonb_build_array(
        jsonb_build_object('kind', 'load_surcharge', 'amount', v_profile.load_surcharge_amount)
      );
      v_amount := v_amount + v_profile.load_surcharge_amount;
    else
      v_load_pending := true;
    end if;
  end if;

  v_amount := (
    select coalesce(sum((c->>'amount')::numeric), 0)
    from jsonb_array_elements(v_components) c
  );

  insert into fare_quotes (
    rider_id,
    driver_id,
    route_id,
    driver_route_profile_id,
    from_stage_id,
    to_stage_id,
    from_location,
    to_location,
    mode_code,
    tier,
    amount,
    currency,
    components,
    confidence
  ) values (
    p_rider_id,
    p_driver_id,
    p_route_id,
    p_profile_id,
    p_from_stage_id,
    p_to_stage_id,
    p_from_point,
    p_to_point,
    p_mode_code,
    v_tier,
    v_amount,
    v_currency,
    v_components,
    v_confidence
  )
  returning id into v_result.quote_id;

  v_result.amount := v_amount;
  v_result.currency := v_currency;
  v_result.tier := v_tier;
  v_result.confidence := v_confidence;
  v_result.components := v_components;
  v_result.unconfirmed := v_unconfirmed;
  v_result.load_surcharge_pending := v_load_pending;

  return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- Route profile RPCs (doc 03 §6)
-- ---------------------------------------------------------------------------
create or replace function _driver_declared_source(p_driver_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  select id into v_id
  from data_sources
  where source_type = 'driver_declared'
    and actor_profile_id = p_driver_id
  order by created_at desc
  limit 1;

  if v_id is null then
    insert into data_sources (source_type, actor_profile_id)
    values ('driver_declared', p_driver_id)
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

create or replace function _point_from_json(p_loc jsonb)
returns geography
language sql
immutable
as $$
  select st_setsrid(
    st_makepoint((p_loc->>'lng')::double precision, (p_loc->>'lat')::double precision),
    4326
  )::geography
$$;

create or replace function upsert_route_profile(p_profile jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_profile_id uuid;
  v_mode_code text := p_profile->>'mode_code';
  v_name text := p_profile->>'name';
  v_route_id uuid;
  v_city_id uuid;
  v_currency char(3);
  v_source_id uuid;
  v_stop jsonb;
  v_seq int;
  v_stage_id uuid;
  v_location geography;
  v_label text;
  v_price numeric(12,2);
  v_load_amount numeric(12,2);
  v_load_currency char(3);
  v_snapped uuid;
  v_max_seq int;
begin
  if v_driver_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select d.city_id, k.currency_code
  into v_city_id, v_currency
  from drivers d
  join cities c on c.id = d.city_id
  join countries k on k.code = c.country_code
  where d.id = v_driver_id;

  if v_city_id is null then
    raise exception 'driver not found' using errcode = '42501';
  end if;

  if v_mode_code is null or jsonb_array_length(p_profile->'stops') is null then
    raise exception 'mode_code and stops are required' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_profile->'stops') s1
    join jsonb_array_elements(p_profile->'stops') s2
      on (s2->>'sequence')::int = (s1->>'sequence')::int + 1
    where (s1->>'price_to_end')::numeric < (s2->>'price_to_end')::numeric
  ) then
    raise exception 'driver_route_stop price_to_end must be non-increasing with sequence'
      using errcode = '23514';
  end if;

  if coalesce((
    select (s->>'price_to_end')::numeric
    from jsonb_array_elements(p_profile->'stops') s
    order by (s->>'sequence')::int desc
    limit 1
  ), -1) <> 0 then
    raise exception 'last driver_route_stop price_to_end must be 0'
      using errcode = '23514';
  end if;

  v_profile_id := coalesce((p_profile->>'id')::uuid, gen_random_uuid());

  if (p_profile->>'id') is not null
     and not exists (
       select 1 from driver_route_profiles
       where id = v_profile_id and driver_id = v_driver_id
     ) then
    raise exception 'profile not found' using errcode = '42501';
  end if;

  v_source_id := _driver_declared_source(v_driver_id);

  if p_profile ? 'load_surcharge' then
    v_load_amount := (p_profile->'load_surcharge'->>'amount')::numeric;
    v_load_currency := coalesce(p_profile->'load_surcharge'->>'currency', v_currency::text)::char(3);
  end if;

  -- Infer canonical route from provided stage ids
  select rs.route_id
  into v_route_id
  from jsonb_array_elements(p_profile->'stops') stop
  join route_stages rs on rs.id = (stop->>'route_stage_id')::uuid
  join routes r on r.id = rs.route_id and r.city_id = v_city_id
  group by rs.route_id
  order by count(*) desc
  limit 1;

  if v_route_id is null then
    select r.id
    into v_route_id
    from drivers d
    join routes r on r.origin_park_id = d.home_park_id and r.city_id = d.city_id and r.active
    where d.id = v_driver_id
      and d.home_park_id is not null
    order by r.confidence_score desc nulls last
    limit 1;
  end if;

  insert into driver_route_profiles (
    id, driver_id, route_id, mode_code, name, active,
    load_surcharge_amount, load_surcharge_currency
  ) values (
    v_profile_id, v_driver_id, v_route_id, v_mode_code, v_name, true,
    v_load_amount, v_load_currency
  )
  on conflict (id) do update set
    route_id = excluded.route_id,
    mode_code = excluded.mode_code,
    name = excluded.name,
    active = true,
    load_surcharge_amount = excluded.load_surcharge_amount,
    load_surcharge_currency = excluded.load_surcharge_currency,
    updated_at = now();

  delete from driver_route_stops where profile_id = v_profile_id;

  for v_stop in select value from jsonb_array_elements(p_profile->'stops') loop
    v_seq := (v_stop->>'sequence')::int;
    v_stage_id := nullif(v_stop->>'route_stage_id', '')::uuid;
    v_label := v_stop->>'custom_label';
    v_price := (v_stop->>'price_to_end')::numeric;

    if v_stop ? 'location' then
      v_location := _point_from_json(v_stop->'location');
    else
      v_location := null;
    end if;

    if v_stage_id is null and v_location is not null then
      v_snapped := snap_stage(v_location, null, v_city_id);
      if v_snapped is not null then
        v_stage_id := v_snapped;
        if v_route_id is null then
          select route_id into v_route_id from route_stages where id = v_stage_id;
        end if;
      elsif v_route_id is not null then
        select coalesce(max(sequence), 0) + 1
        into v_max_seq
        from route_stages
        where route_id = v_route_id;

        insert into route_stages (
          route_id, sequence, location, name, source_id,
          verification_status, confidence_score
        ) values (
          v_route_id, v_max_seq, v_location, coalesce(v_label, 'Driver stop'),
          v_source_id, 'candidate', 0.300
        )
        returning id into v_stage_id;
      else
        raise exception 'cannot place unmatched stop without a route context'
          using errcode = '22023';
      end if;
    end if;

    if v_stage_id is null and v_location is null then
      raise exception 'each stop requires route_stage_id or location'
        using errcode = '22023';
    end if;

    insert into driver_route_stops (
      profile_id, sequence, route_stage_id, custom_location, custom_label,
      price_to_end, currency
    ) values (
      v_profile_id, v_seq, v_stage_id, v_location, v_label,
      v_price, v_currency
    );
  end loop;

  update driver_route_profiles
  set route_id = coalesce(v_route_id, route_id)
  where id = v_profile_id;

  return jsonb_build_object(
    'id', v_profile_id,
    'active', true,
    'route_id', v_route_id
  );
end;
$$;

create or replace function my_route_profiles()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'route_id', p.route_id,
        'mode_code', p.mode_code,
        'name', p.name,
        'active', p.active,
        'load_surcharge_amount', p.load_surcharge_amount,
        'load_surcharge_currency', p.load_surcharge_currency,
        'stops', (
          select coalesce(jsonb_agg(
            jsonb_build_object(
              'sequence', s.sequence,
              'route_stage_id', s.route_stage_id,
              'custom_label', s.custom_label,
              'price_to_end', s.price_to_end,
              'currency', s.currency
            ) order by s.sequence
          ), '[]'::jsonb)
          from driver_route_stops s
          where s.profile_id = p.id
        )
      ) order by p.created_at desc
    ),
    '[]'::jsonb
  )
  from driver_route_profiles p
  where p.driver_id = auth.uid()
$$;

create or replace function deactivate_route_profile(p_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  update driver_route_profiles
  set active = false, updated_at = now()
  where id = p_id
    and driver_id = auth.uid();

  if not found then
    raise exception 'profile not found' using errcode = '42501';
  end if;
end;
$$;

create or replace function suggested_stop_price(
  p_profile_id uuid,
  p_sequence int,
  p_location jsonb
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_city_id uuid;
  v_mode text;
  v_point geography := _point_from_json(p_location);
  v_interp numeric;
  v_consensus numeric;
  v_prev record;
  v_next record;
  v_dist_total double precision;
  v_dist_from_prev double precision;
begin
  select drp.mode_code, d.city_id
  into v_mode, v_city_id
  from driver_route_profiles drp
  join drivers d on d.id = drp.driver_id
  where drp.id = p_profile_id
    and drp.driver_id = v_driver_id;

  if v_city_id is null then
    raise exception 'profile not found' using errcode = '42501';
  end if;

  select s.sequence, s.price_to_end, coalesce(rs.location, s.custom_location) as loc
  into v_prev
  from driver_route_stops s
  left join route_stages rs on rs.id = s.route_stage_id
  where s.profile_id = p_profile_id
    and s.sequence < p_sequence
  order by s.sequence desc
  limit 1;

  select s.sequence, s.price_to_end, coalesce(rs.location, s.custom_location) as loc
  into v_next
  from driver_route_stops s
  left join route_stages rs on rs.id = s.route_stage_id
  where s.profile_id = p_profile_id
    and s.sequence > p_sequence
  order by s.sequence
  limit 1;

  if v_prev.loc is not null and v_next.loc is not null then
    v_dist_total := greatest(distance_m(v_prev.loc, v_next.loc), 1);
    v_dist_from_prev := distance_m(v_prev.loc, v_point);
    v_interp := v_prev.price_to_end
      - ((v_prev.price_to_end - v_next.price_to_end) * (v_dist_from_prev / v_dist_total));
  elsif v_prev.loc is not null then
    v_interp := greatest(v_prev.price_to_end - 50, 0);
  elsif v_next.loc is not null then
    v_interp := v_next.price_to_end + 50;
  else
    v_interp := (cfg('fare.min_fare', v_city_id)->>v_mode)::numeric;
  end if;

  select percentile_cont(0.5) within group (order by s.price_to_end)
  into v_consensus
  from driver_route_stops s
  join driver_route_profiles p on p.id = s.profile_id
  left join route_stages rs on rs.id = s.route_stage_id
  cross join lateral (select coalesce(rs.location, s.custom_location) as loc) locs
  where p.active
    and p.mode_code = v_mode
    and locs.loc is not null
    and st_dwithin(locs.loc, v_point, cfg_num('graph.snap_radius_m', v_city_id) * 2);

  return round_to_minor(
    case
      when v_interp is not null and v_consensus is not null then (v_interp + v_consensus) / 2.0
      else coalesce(v_interp, v_consensus, (cfg('fare.min_fare', v_city_id)->>v_mode)::numeric)
    end,
    v_city_id
  );
end;
$$;

create or replace function suggest_known_route()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_driver_id uuid := auth.uid();
  v_home_park uuid;
  v_city_id uuid;
  v_route record;
  v_stages jsonb;
begin
  if v_driver_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select d.home_park_id, d.city_id
  into v_home_park, v_city_id
  from drivers d
  where d.id = v_driver_id;

  if v_home_park is null then
    return null;
  end if;

  select
    r.id as route_id,
    r.mode_code,
    count(distinct h.id) as history_hits
  into v_route
  from routes r
  join route_stages rs on rs.route_id = r.id
  left join driver_presence_history h
    on h.driver_id = v_driver_id
   and h.ts > now() - interval '14 days'
   and st_dwithin(h.location, rs.location, cfg_num('graph.snap_radius_m', v_city_id))
  where r.origin_park_id = v_home_park
    and r.city_id = v_city_id
    and r.active
  group by r.id, r.mode_code
  order by count(distinct h.id) desc, r.confidence_score desc nulls last
  limit 1;

  if v_route.route_id is null then
    return null;
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'stage', jsonb_build_object(
        'id', rs.id,
        'sequence', rs.sequence,
        'name', rs.name
      ),
      'default_price_to_end', coalesce((
        select sum(rl.fare_amount)
        from route_legs rl
        join route_stages fs on fs.id = rl.from_stage_id
        where rl.route_id = rs.route_id
          and fs.sequence >= rs.sequence
      ), 0)
    ) order by rs.sequence
  ), '[]'::jsonb)
  into v_stages
  from route_stages rs
  where rs.route_id = v_route.route_id;

  return jsonb_build_object(
    'route', jsonb_build_object(
      'id', v_route.route_id,
      'mode_code', v_route.mode_code
    ),
    'stages', v_stages
  );
end;
$$;

grant execute on function round_to_minor(numeric, uuid) to authenticated, anon;
grant execute on function resolve_fare(uuid, uuid, uuid, uuid, geography, geography, text, uuid, jsonb, uuid, uuid) to authenticated, anon;
grant execute on function upsert_route_profile(jsonb) to authenticated;
grant execute on function my_route_profiles() to authenticated;
grant execute on function deactivate_route_profile(uuid) to authenticated;
grant execute on function suggested_stop_price(uuid, int, jsonb) to authenticated;
grant execute on function suggest_known_route() to authenticated;
