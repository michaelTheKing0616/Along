-- P0-A-05: doc 04 §6 — promotion pipeline (compute_trust_weights, promote_candidates,
-- outlier MAD guard, decay_confidence, pg_cron schedules).

-- graph_confirmations.meta — outlier flag, collusion down-weight audit (doc 04 §6.2, §6.4)
alter table graph_confirmations
  add column if not exists meta jsonb not null default '{}'::jsonb;

-- doc 04 §6.2 collusion down-weight (algorithm parameter; seeded at global)
insert into app_config (key, scope_type, scope_id, value, description)
values (
  'promotion.collusion_downweight',
  'global',
  '*',
  '0.25',
  'Trust-weight multiplier when accounts share a device install id (doc 04 §6.2)'
)
on conflict (key, scope_type, scope_id) do nothing;

-- device install ids for Sybil / collusion detection (doc 04 §6.2, doc 12 §6)
create table device_installs (
  profile_id uuid not null references profiles(id) on delete cascade,
  install_id uuid not null,
  device_model text,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (profile_id, install_id)
);
create index device_installs_install_id_idx on device_installs(install_id);

alter table device_installs enable row level security;

create policy device_installs_select_own
  on device_installs for select to authenticated
  using (profile_id = auth.uid());

create policy device_installs_write_own
  on device_installs for insert to authenticated
  with check (profile_id = auth.uid());

create policy device_installs_update_own
  on device_installs for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy device_installs_select_admin
  on device_installs for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent', 'safety', 'analyst']));

grant select, insert, update on device_installs to authenticated;

-- Optional revision reason for promotion/decay jobs
create or replace function write_graph_revision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reason text;
begin
  v_reason := nullif(current_setting('along.revision_reason', true), '');

  if tg_op = 'INSERT' then
    insert into graph_revisions (target_type, target_id, before, after, changed_by, source_id, reason)
    values (tg_table_name, new.id, null, to_jsonb(new), auth.uid(), new.source_id, v_reason);
    return new;
  elsif tg_op = 'UPDATE' then
    insert into graph_revisions (target_type, target_id, before, after, changed_by, source_id, reason)
    values (tg_table_name, new.id, to_jsonb(old), to_jsonb(new), auth.uid(), new.source_id, v_reason);
    return new;
  end if;
  return null;
end;
$$;

-- §6.1 trust weight for a rider at confirmation time
create or replace function rider_trust_weight(p_rider_id uuid, p_city_id uuid default null)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_age_days numeric;
  v_trips int;
  v_min_age numeric;
  v_base numeric;
  v_per_trip numeric;
  v_cap numeric;
begin
  select
    extract(epoch from (now() - p.created_at)) / 86400.0,
    r.trip_count
  into v_age_days, v_trips
  from riders r
  join profiles p on p.id = r.id
  where r.id = p_rider_id;

  if not found then
    return 0;
  end if;

  v_min_age := cfg_num('trust.rider_min_age_days', p_city_id);
  v_base := cfg_num('trust.rider_base', p_city_id);
  v_per_trip := cfg_num('trust.rider_per_trip', p_city_id);
  v_cap := cfg_num('trust.rider_cap', p_city_id);

  if v_age_days < v_min_age then
    return 0;
  end if;

  return least(v_cap, v_base + v_per_trip * v_trips);
end;
$$;

create or replace function confirmer_trust_weight(
  p_profile_id uuid,
  p_role text,
  p_city_id uuid default null
)
returns numeric
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  case p_role
    when 'rider' then
      return coalesce(
        (select account_trust_weight from riders where id = p_profile_id),
        rider_trust_weight(p_profile_id, p_city_id)
      );
    when 'driver' then
      return case
        when exists (
          select 1 from drivers d
          where d.id = p_profile_id and d.verified_status = 'verified'
        ) then cfg_num('trust.driver_verified', p_city_id)
        else cfg_num('trust.driver_unverified', p_city_id)
      end;
    when 'field_agent' then
      return 3.0;
    when 'admin' then
      return 3.0;
    else
      return 0;
  end case;
end;
$$;

-- Nightly batch: refresh riders.account_trust_weight (doc 03 §12)
create or replace function compute_trust_weights()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update riders r
  set account_trust_weight = rider_trust_weight(r.id, r.home_city_id)
  where true;
end;
$$;

-- Shared install id → collusion down-weight via cfg (doc 04 §6.2)
drop function if exists fingerprint_collusion_factor(uuid);
create or replace function fingerprint_collusion_factor(
  p_profile_id uuid,
  p_city_id uuid default null
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select case
    when exists (
      select 1
      from device_installs di_self
      join device_installs di_other
        on di_other.install_id = di_self.install_id
       and di_other.profile_id <> di_self.profile_id
      where di_self.profile_id = p_profile_id
    ) then cfg_num('promotion.collusion_downweight', p_city_id)
    else 1.0
  end;
$$;

create or replace function weighted_median_fare(
  p_fares numeric[],
  p_weights numeric[]
)
returns numeric
language sql
immutable
as $$
  with rows as (
    select t.fare, t.weight
    from unnest(p_fares, p_weights) as t(fare, weight)
    order by fare
  ),
  totals as (
    select coalesce(sum(weight), 0) as total from rows
  ),
  running as (
    select
      fare,
      sum(weight) over (order by fare rows between unbounded preceding and current row) as cum
    from rows
  )
  select r.fare
  from running r
  cross join totals
  where totals.total <= 0 or r.cum >= totals.total / 2.0
  order by r.fare
  limit 1;
$$;

-- §6.4 MAD outlier guard for rider/driver fare confirmations
create or replace function fare_outlier_guard(
  p_route_id uuid,
  p_from_stage_id uuid,
  p_proposed_fare numeric,
  p_city_id uuid default null
)
returns table (is_outlier boolean, neighbour_median numeric, mad numeric)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_seq int;
  v_median numeric;
  v_mad numeric;
  v_k numeric;
  v_tol_pct numeric;
begin
  select rs.sequence into v_seq
  from route_stages rs
  where rs.id = p_from_stage_id and rs.route_id = p_route_id;

  if v_seq is null then
    return query select false, null::numeric, null::numeric;
    return;
  end if;

  select percentile_cont(0.5) within group (order by rl.fare_amount)
  into v_median
  from route_legs rl
  join route_stages fs on fs.id = rl.from_stage_id
  where rl.route_id = p_route_id
    and rl.verification_status <> 'candidate'
    and fs.sequence between v_seq - 2 and v_seq + 2;

  if v_median is null then
    return query select false, null::numeric, null::numeric;
    return;
  end if;

  select percentile_cont(0.5) within group (order by abs(rl.fare_amount - v_median))
  into v_mad
  from route_legs rl
  join route_stages fs on fs.id = rl.from_stage_id
  where rl.route_id = p_route_id
    and rl.verification_status <> 'candidate'
    and fs.sequence between v_seq - 2 and v_seq + 2;

  v_k := cfg_num('promotion.outlier_mad_k', p_city_id);
  v_tol_pct := cfg_num('promotion.fare_tolerance_pct', p_city_id);

  if v_mad is null or v_mad = 0 then
    return query
    select abs(p_proposed_fare - v_median) > v_tol_pct * v_median, v_median, coalesce(v_mad, 0);
    return;
  end if;

  return query
  select abs(p_proposed_fare - v_median) > v_k * v_mad, v_median, v_mad;
end;
$$;

create or replace function infer_confirmer_role(p_profile_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when exists (select 1 from admin_users a where a.id = p_profile_id and a.disabled_at is null) then 'admin'
    when exists (select 1 from drivers d where d.id = p_profile_id) then 'driver'
    when exists (select 1 from riders r where r.id = p_profile_id) then 'rider'
    else 'rider'
  end;
$$;

create or replace function graph_target_city_id(p_target_type text, p_target_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select case p_target_type
    when 'park' then (select city_id from parks where id = p_target_id)
    when 'route' then (select city_id from routes where id = p_target_id)
    when 'route_stage' then (
      select r.city_id from route_stages rs join routes r on r.id = rs.route_id where rs.id = p_target_id
    )
    when 'route_leg' then (
      select r.city_id from route_legs rl join routes r on r.id = rl.route_id where rl.id = p_target_id
    )
    when 'route_through_fare' then (
      select r.city_id from route_through_fares tf join routes r on r.id = tf.route_id where tf.id = p_target_id
    )
    else null
  end;
$$;

-- Insert confirmation with trust snapshot, collusion down-weight, outlier guard (doc 03 §11)
create or replace function confirm_graph_value(
  p_target_type text,
  p_target_id uuid,
  p_value jsonb,
  p_trip_id uuid default null,
  p_confirmer_profile_id uuid default auth.uid(),
  p_confirmer_role text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_city_id uuid;
  v_base_weight numeric;
  v_weight numeric;
  v_collusion numeric;
  v_meta jsonb := '{}'::jsonb;
  v_source_id uuid;
  v_conf_id uuid;
  v_proposed_fare numeric;
  v_route_id uuid;
  v_from_stage_id uuid;
  v_currency char(3);
  v_outlier record;
begin
  if p_confirmer_profile_id is null then
    raise exception 'confirm_graph_value: confirmer profile required'
      using errcode = '22023';
  end if;

  v_role := coalesce(p_confirmer_role, infer_confirmer_role(p_confirmer_profile_id));
  v_city_id := graph_target_city_id(p_target_type, p_target_id);

  v_base_weight := confirmer_trust_weight(p_confirmer_profile_id, v_role, v_city_id);
  v_collusion := fingerprint_collusion_factor(p_confirmer_profile_id, v_city_id);

  if v_collusion < 1.0 then
    v_meta := v_meta || jsonb_build_object('collusion_downweight', true, 'collusion_factor', v_collusion);
  end if;

  v_weight := v_base_weight * v_collusion;

  insert into data_sources (source_type, actor_profile_id, trip_id)
  values (
    case v_role
      when 'rider' then 'rider_correction'::source_type
      when 'driver' then 'driver_correction'::source_type
      when 'field_agent' then 'field_agent'::source_type
      else 'admin'::source_type
    end,
    p_confirmer_profile_id,
    p_trip_id
  )
  returning id into v_source_id;

  if p_target_type = 'route_leg'
     and v_role in ('rider', 'driver')
     and p_value ? 'fare' then
    v_proposed_fare := (p_value->>'fare')::numeric;

    select rl.route_id, rl.from_stage_id, rl.fare_currency
    into v_route_id, v_from_stage_id, v_currency
    from route_legs rl
    where rl.id = p_target_id;

    select * into v_outlier
    from fare_outlier_guard(v_route_id, v_from_stage_id, v_proposed_fare, v_city_id);

    if v_outlier.is_outlier then
      v_meta := v_meta || jsonb_build_object(
        'outlier', true,
        'neighbour_median', v_outlier.neighbour_median,
        'mad', v_outlier.mad
      );

      insert into fare_corrections (
        route_leg_id,
        trip_id,
        submitted_by,
        submitter_role,
        proposed_fare,
        currency,
        fare_shown,
        source_id
      ) values (
        p_target_id,
        p_trip_id,
        p_confirmer_profile_id,
        v_role,
        v_proposed_fare,
        v_currency,
        v_proposed_fare,
        v_source_id
      );
    end if;
  end if;

  insert into graph_confirmations (
    target_type,
    target_id,
    confirmer_profile_id,
    confirmer_role,
    trust_weight,
    proposed_value,
    trip_id,
    source_id,
    meta
  ) values (
    p_target_type,
    p_target_id,
    p_confirmer_profile_id,
    v_role,
    v_weight,
    p_value,
    p_trip_id,
    v_source_id,
    v_meta
  )
  returning id into v_conf_id;

  return v_conf_id;
end;
$$;

grant execute on function confirm_graph_value(text, uuid, jsonb, uuid, uuid, text) to authenticated;
grant execute on function compute_trust_weights() to authenticated;

-- §6.3 promote_candidates
create or replace function promote_candidates()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rec record;
  v_city_id uuid;
  v_tol_pct numeric;
  v_tol_loc numeric;
  v_thresh_w numeric;
  v_min_n int;
  v_canonical_fare numeric;
  v_canonical_loc geography;
  v_proposed_fare numeric;
  v_proposed_loc geography;
  v_w numeric;
  v_n int;
  v_dis_w numeric;
  v_new_conf numeric;
  v_fares numeric[];
  v_weights numeric[];
  v_median numeric;
  v_source_id uuid;
  v_system_submitter uuid;
begin
  for v_rec in
    select 'route_leg'::text as target_type, rl.id as target_id, rl.route_id, rl.from_stage_id,
           rl.fare_amount as canonical_fare, null::geography as canonical_loc,
           rl.verification_status, rl.confidence_score, rl.independent_confirmation_count,
           rl.fare_last_verified_at, r.city_id
    from route_legs rl
    join routes r on r.id = rl.route_id
    where rl.verification_status = 'candidate'
    union all
    select 'route_through_fare', tf.id, tf.route_id, tf.from_stage_id,
           tf.fare_amount, null, tf.verification_status, tf.confidence_score,
           tf.independent_confirmation_count, tf.fare_last_verified_at, r.city_id
    from route_through_fares tf
    join routes r on r.id = tf.route_id
    where tf.verification_status = 'candidate'
    union all
    select 'route_stage', rs.id, rs.route_id, rs.id,
           null, rs.location, rs.verification_status, rs.confidence_score,
           rs.independent_confirmation_count, null, r.city_id
    from route_stages rs
    join routes r on r.id = rs.route_id
    where rs.verification_status = 'candidate'
    union all
    select 'park', p.id, null, null,
           null, p.location, p.verification_status, p.confidence_score,
           0, null, p.city_id
    from parks p
    where p.verification_status = 'candidate'
  loop
    v_city_id := v_rec.city_id;
    v_tol_pct := cfg_num('promotion.fare_tolerance_pct', v_city_id);
    v_tol_loc := cfg_num('promotion.location_tolerance_m', v_city_id);
    v_thresh_w := cfg_num('promotion.threshold_weight', v_city_id);
    v_min_n := cfg_num('promotion.min_distinct_accounts', v_city_id)::int;

    with confs as (
      select gc.*
      from graph_confirmations gc
      where gc.target_type = v_rec.target_type
        and gc.target_id = v_rec.target_id
        and coalesce(gc.meta->>'outlier', 'false') <> 'true'
    ),
    agreeing as (
      select c.*
      from confs c
      where case v_rec.target_type
        when 'route_leg' then
          v_rec.canonical_fare is not null
          and c.proposed_value ? 'fare'
          and abs((c.proposed_value->>'fare')::numeric - v_rec.canonical_fare)
              <= v_tol_pct * v_rec.canonical_fare
        when 'route_through_fare' then
          v_rec.canonical_fare is not null
          and c.proposed_value ? 'fare'
          and abs((c.proposed_value->>'fare')::numeric - v_rec.canonical_fare)
              <= v_tol_pct * v_rec.canonical_fare
        when 'route_stage' then
          v_rec.canonical_loc is not null
          and c.proposed_value ? 'lat'
          and c.proposed_value ? 'lng'
          and st_dwithin(
            st_setsrid(st_makepoint(
              (c.proposed_value->>'lng')::double precision,
              (c.proposed_value->>'lat')::double precision
            ), 4326)::geography,
            v_rec.canonical_loc,
            v_tol_loc
          )
        when 'park' then
          v_rec.canonical_loc is not null
          and c.proposed_value ? 'lat'
          and c.proposed_value ? 'lng'
          and st_dwithin(
            st_setsrid(st_makepoint(
              (c.proposed_value->>'lng')::double precision,
              (c.proposed_value->>'lat')::double precision
            ), 4326)::geography,
            v_rec.canonical_loc,
            v_tol_loc
          )
        else false
      end
    )
    select coalesce(sum(trust_weight), 0), count(distinct confirmer_profile_id)
    into v_w, v_n
    from agreeing;

    if v_w >= v_thresh_w and v_n >= v_min_n then
      v_new_conf := least(0.9, 0.5 + 0.1 * v_n);

      perform set_config('along.revision_reason', 'promotion', true);

      case v_rec.target_type
        when 'route_leg' then
          update route_legs
          set verification_status = 'crowd_verified',
              confidence_score = v_new_conf,
              independent_confirmation_count = v_n,
              fare_last_verified_at = now()
          where id = v_rec.target_id;
        when 'route_through_fare' then
          update route_through_fares
          set verification_status = 'crowd_verified',
              confidence_score = v_new_conf,
              independent_confirmation_count = v_n,
              fare_last_verified_at = now()
          where id = v_rec.target_id;
        when 'route_stage' then
          update route_stages
          set verification_status = 'crowd_verified',
              confidence_score = v_new_conf,
              independent_confirmation_count = v_n
          where id = v_rec.target_id;
        when 'park' then
          update parks
          set verification_status = 'crowd_verified',
              confidence_score = v_new_conf
          where id = v_rec.target_id;
        else
          null;
      end case;

      perform set_config('along.revision_reason', '', true);
    else
      with confs as (
        select gc.*
        from graph_confirmations gc
        where gc.target_type = v_rec.target_type
          and gc.target_id = v_rec.target_id
      ),
      agreeing as (
        select c.*
        from confs c
        where case v_rec.target_type
          when 'route_leg' then
            v_rec.canonical_fare is not null
            and c.proposed_value ? 'fare'
            and abs((c.proposed_value->>'fare')::numeric - v_rec.canonical_fare)
                <= v_tol_pct * v_rec.canonical_fare
          when 'route_through_fare' then
            v_rec.canonical_fare is not null
            and c.proposed_value ? 'fare'
            and abs((c.proposed_value->>'fare')::numeric - v_rec.canonical_fare)
                <= v_tol_pct * v_rec.canonical_fare
          else false
        end
      ),
      disagreeing as (
        select c.*
        from confs c
        where not (
          case v_rec.target_type
            when 'route_leg' then
              v_rec.canonical_fare is not null
              and c.proposed_value ? 'fare'
              and abs((c.proposed_value->>'fare')::numeric - v_rec.canonical_fare)
                  <= v_tol_pct * v_rec.canonical_fare
            when 'route_through_fare' then
              v_rec.canonical_fare is not null
              and c.proposed_value ? 'fare'
              and abs((c.proposed_value->>'fare')::numeric - v_rec.canonical_fare)
                  <= v_tol_pct * v_rec.canonical_fare
            else false
          end
        )
      )
      select coalesce(sum(trust_weight), 0) into v_dis_w from disagreeing;

      if v_dis_w >= v_thresh_w and v_rec.target_type in ('route_leg', 'route_through_fare') then
        select array_agg((c.proposed_value->>'fare')::numeric order by (c.proposed_value->>'fare')::numeric),
               array_agg(c.trust_weight order by (c.proposed_value->>'fare')::numeric)
        into v_fares, v_weights
        from confs c
        where c.proposed_value ? 'fare';

        v_median := weighted_median_fare(v_fares, v_weights);

        select confirmer_profile_id
        into v_system_submitter
        from disagreeing
        order by trust_weight desc
        limit 1;

        insert into data_sources (source_type, notes)
        values ('admin', 'promotion sustained disagreement')
        returning id into v_source_id;

        if v_rec.target_type = 'route_leg' then
          insert into fare_corrections (
            route_leg_id, submitted_by, submitter_role, proposed_fare, currency, source_id
          )
          select v_rec.target_id, v_system_submitter, 'system', v_median, rl.fare_currency, v_source_id
          from route_legs rl where rl.id = v_rec.target_id;
        else
          insert into fare_corrections (
            route_through_fare_id, submitted_by, submitter_role, proposed_fare, currency, source_id
          )
          select v_rec.target_id, v_system_submitter, 'system', v_median, tf.fare_currency, v_source_id
          from route_through_fares tf where tf.id = v_rec.target_id;
        end if;
      end if;
    end if;
  end loop;
end;
$$;

-- §6.5 decay_confidence (daily)
create or replace function decay_confidence()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rec record;
  v_window_days numeric;
  v_step numeric;
  v_cutoff timestamptz;
  v_last_confirmed timestamptz;
  v_new_conf numeric;
begin
  v_window_days := cfg_num('promotion.decay_window_days');
  v_step := cfg_num('promotion.decay_step');
  v_cutoff := now() - (v_window_days || ' days')::interval;

  for v_rec in
    select 'route_leg'::text as target_type, rl.id as target_id, rl.confidence_score,
           rl.fare_last_verified_at, r.city_id
    from route_legs rl
    join routes r on r.id = rl.route_id
    where rl.verification_status = 'crowd_verified'
    union all
    select 'route_through_fare', tf.id, tf.confidence_score, tf.fare_last_verified_at, r.city_id
    from route_through_fares tf
    join routes r on r.id = tf.route_id
    where tf.verification_status = 'crowd_verified'
    union all
    select 'route_stage', rs.id, rs.confidence_score, null, r.city_id
    from route_stages rs
    join routes r on r.id = rs.route_id
    where rs.verification_status = 'crowd_verified'
    union all
    select 'park', p.id, p.confidence_score, null, p.city_id
    from parks p
    where p.verification_status = 'crowd_verified'
  loop
    select max(gc.created_at)
    into v_last_confirmed
    from graph_confirmations gc
    where gc.target_type = v_rec.target_type
      and gc.target_id = v_rec.target_id
      and coalesce(gc.meta->>'outlier', 'false') <> 'true';

    if coalesce(v_rec.fare_last_verified_at, v_last_confirmed, 'epoch'::timestamptz) >= v_cutoff then
      continue;
    end if;

    v_new_conf := v_rec.confidence_score - v_step;

    perform set_config('along.revision_reason', 'decay', true);

    if v_new_conf < 0.5 then
      case v_rec.target_type
        when 'route_leg' then
          update route_legs
          set verification_status = 'candidate',
              confidence_score = v_new_conf
          where id = v_rec.target_id;
        when 'route_through_fare' then
          update route_through_fares
          set verification_status = 'candidate',
              confidence_score = v_new_conf
          where id = v_rec.target_id;
        when 'route_stage' then
          update route_stages
          set verification_status = 'candidate',
              confidence_score = v_new_conf
          where id = v_rec.target_id;
        when 'park' then
          update parks
          set verification_status = 'candidate',
              confidence_score = v_new_conf
          where id = v_rec.target_id;
        else
          null;
      end case;
    else
      case v_rec.target_type
        when 'route_leg' then
          update route_legs set confidence_score = v_new_conf where id = v_rec.target_id;
        when 'route_through_fare' then
          update route_through_fares set confidence_score = v_new_conf where id = v_rec.target_id;
        when 'route_stage' then
          update route_stages set confidence_score = v_new_conf where id = v_rec.target_id;
        when 'park' then
          update parks set confidence_score = v_new_conf where id = v_rec.target_id;
        else
          null;
      end case;
    end if;

    perform set_config('along.revision_reason', '', true);
  end loop;
end;
$$;

grant execute on function promote_candidates() to authenticated;
grant execute on function decay_confidence() to authenticated;

-- pg_cron schedules (doc 03 §12) — idempotent best-effort
do $$
declare
  v_jobid bigint;
begin
  for v_jobid in select jobid from cron.job where jobname = 'promote_candidates' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule('promote_candidates', '*/10 * * * *', $cron$select promote_candidates()$cron$);

  for v_jobid in select jobid from cron.job where jobname = 'decay_confidence' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule('decay_confidence', '0 2 * * *', $cron$select decay_confidence()$cron$);

  for v_jobid in select jobid from cron.job where jobname = 'compute_trust_weights' loop
    perform cron.unschedule(v_jobid);
  end loop;
  perform cron.schedule('compute_trust_weights', '30 2 * * *', $cron$select compute_trust_weights()$cron$);
exception
  when undefined_table then
    raise notice 'pg_cron unavailable — schedule promote_candidates/decay_confidence/compute_trust_weights manually (doc 03 §12)';
  when others then
    raise notice 'pg_cron schedule skipped: %', sqlerrm;
end;
$$;
