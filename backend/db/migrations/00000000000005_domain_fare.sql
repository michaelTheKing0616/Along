-- P0-A-04: doc 04 §2 snap_stage, doc 04 §3 resolve_fare (Tier 1–2 only; Tier 0/3 deferred P1-A-03),
-- doc 02 §7 fare_quotes + RLS.

-- §1 geometry helper (doc 04 §1)
create or replace function distance_m(a geography, b geography)
returns double precision
language sql
immutable
parallel safe
as $$ select st_distance(a, b) $$;

-- §2 stage snapping (doc 04 §2)
create or replace function snap_stage(
  p geography,
  p_radius_m numeric default null,
  p_city_id uuid default null
)
returns uuid
language sql
stable
as $$
  with params as (
    select
      coalesce(p_radius_m, cfg_num('graph.snap_radius_m', coalesce(p_city_id, city_for_point(p)))) as radius,
      coalesce(p_city_id, city_for_point(p)) as city
  )
  select rs.id
  from route_stages rs
  join routes r on r.id = rs.route_id
  cross join params
  where r.city_id = params.city
    and r.active
    and st_dwithin(rs.location, p, params.radius)
  order by
    rs.verification_status desc,
    st_distance(rs.location, p)
  limit 1
$$;

-- §7 fare_quotes (doc 02 §7)
create table fare_quotes (
  id uuid primary key default gen_random_uuid(),
  rider_id uuid references riders(id),
  driver_id uuid references drivers(id),
  route_id uuid references routes(id),
  driver_route_profile_id uuid,
  from_stage_id uuid references route_stages(id),
  to_stage_id uuid references route_stages(id),
  from_location geography(Point,4326),
  to_location geography(Point,4326),
  mode_code text not null references mode_config(code),
  tier smallint not null check (tier between 0 and 3),
  amount numeric(12,2) not null,
  currency char(3) not null,
  components jsonb not null,
  confidence numeric(4,3) not null,
  negotiation_id uuid,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '10 minutes'
);

create index fare_quotes_route_pair_idx on fare_quotes(route_id, from_stage_id, to_stage_id);
create index fare_quotes_created_at_idx on fare_quotes(created_at);

-- Return type for resolve_fare (doc 04 §3)
create type fare_resolution as (
  quote_id uuid,
  amount numeric(12,2),
  currency char(3),
  tier smallint,
  confidence numeric(4,3),
  components jsonb,
  unconfirmed boolean
);

-- §3 fare resolution — Tier 1–2 only (Tier 0/3 deferred to P1-A-03)
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
  v_seq_from int;
  v_seq_to int;
  v_tf record;
  v_hop int;
  v_leg record;
  v_leg_count int;
  v_expected_legs int;
  v_resolved boolean := false;
begin
  if p_profile_id is not null then
    raise exception 'resolve_fare: tier 0 (driver profile) resolution deferred to P1-A-03'
      using errcode = '0A000';
  end if;

  if p_route_id is null or p_from_stage_id is null or p_to_stage_id is null then
    raise exception 'resolve_fare: route_id, from_stage_id, and to_stage_id are required for tier 1–2 resolution'
      using errcode = '22023';
  end if;

  if p_mode_code is null or p_city_id is null then
    raise exception 'resolve_fare: mode_code and city_id are required'
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

  -- Tier 1: verified through-fare for exactly this pair (doc 04 §3)
  select tf.id, tf.fare_amount, tf.confidence_score
  into v_tf
  from route_through_fares tf
  where tf.route_id = p_route_id
    and tf.from_stage_id = p_from_stage_id
    and tf.to_stage_id = p_to_stage_id
    and tf.verification_status <> 'candidate';

  if found then
    v_components := v_components || jsonb_build_array(
      jsonb_build_object('kind', 'through_fare', 'ref_id', v_tf.id, 'amount', v_tf.fare_amount)
    );
    v_tier := 1;
    v_confidence := v_tf.confidence_score;
    v_amount := v_tf.fare_amount;
    v_resolved := true;
  end if;

  if not v_resolved then
    -- Tier 2: sum adjacent legs covering every hop (doc 04 §3)
    v_expected_legs := v_seq_to - v_seq_from;
    v_leg_count := 0;
    v_amount := 0;
    v_confidence := 1.0;
    v_components := '[]'::jsonb;

    for v_hop in v_seq_from..v_seq_to - 1 loop
      select
        rl.id,
        rl.fare_amount,
        rl.confidence_score
      into v_leg
      from route_legs rl
      join route_stages fs on fs.id = rl.from_stage_id
      join route_stages ts on ts.id = rl.to_stage_id
      where rl.route_id = p_route_id
        and fs.sequence = v_hop
        and ts.sequence = v_hop + 1;

      if not found then
        raise exception 'resolve_fare: tier 3 resolution deferred to P1-A-03; insufficient fare data for stage pair (unconfirmed/unavailable)'
          using errcode = '0A000',
                hint = 'unconfirmed=true';
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
      raise exception 'resolve_fare: tier 3 resolution deferred to P1-A-03; insufficient fare data for stage pair (unconfirmed/unavailable)'
        using errcode = '0A000',
              hint = 'unconfirmed=true';
    end if;
  end if;

  insert into fare_quotes (
    rider_id,
    driver_id,
    route_id,
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
  v_result.unconfirmed := false;

  return v_result;
end;
$$;

-- RLS policies inlined (Supabase CLI does not support \ir).
alter table fare_quotes enable row level security;

create policy fare_quotes_select_rider
  on fare_quotes for select to authenticated
  using (rider_id = auth.uid());

create policy fare_quotes_select_driver
  on fare_quotes for select to authenticated
  using (driver_id = auth.uid());

create policy fare_quotes_select_admin
  on fare_quotes for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'finance', 'analyst']));

create policy fare_quotes_no_client_insert
  on fare_quotes for insert to authenticated
  with check (false);

create policy fare_quotes_no_client_update
  on fare_quotes for update to authenticated
  using (false);

create policy fare_quotes_no_client_delete
  on fare_quotes for delete to authenticated
  using (false);
