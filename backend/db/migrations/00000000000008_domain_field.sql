-- P0-A-07: doc 02 §14 — field data tables, two-scout reconciliation, admin RPCs,
-- ingestion upsert helper (doc 13 §3).

create or replace function has_admin_role(roles text[]) returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from admin_users a
    where a.id = auth.uid()
      and a.disabled_at is null
      and (a.role::text = any(roles) or a.role = 'superadmin'::admin_role)
  ) $$;

-- field_agents (doc 02 §14 RLS note)
create table field_agents (
  id uuid primary key references profiles(id) on delete cascade,
  city_id uuid not null references cities(id),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger field_agents_set_updated_at before update on field_agents
  for each row execute function set_updated_at();

-- field_submissions (doc 02 §14)
create table field_submissions (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references cities(id),
  corridor_id uuid references corridors(id),
  scout_profile_id uuid not null references profiles(id),
  form_id text not null,
  form_version text not null,
  submission_uid text not null unique,
  payload jsonb not null,
  gpx_storage_path text,
  entity_type text not null check (entity_type in ('park','route','stage','leg_fare','through_fare')),
  entity_key text not null,
  submitted_at timestamptz not null,
  status text not null default 'received' check (status in ('received','reconciled','published','rejected')),
  created_at timestamptz not null default now()
);

create index field_submissions_key on field_submissions(entity_key, status);
create index field_submissions_city on field_submissions(city_id);

-- field_reconciliations (doc 02 §14)
create table field_reconciliations (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_key text not null,
  submission_a uuid not null references field_submissions(id),
  submission_b uuid references field_submissions(id),
  submission_c uuid references field_submissions(id),
  variance jsonb,
  status text not null default 'awaiting_second'
    check (status in ('awaiting_second','matched','discrepant','resolved','rejected')),
  resolved_by uuid references admin_users(id),
  resolved_at timestamptz,
  resolution jsonb,
  published_target_type text,
  published_target_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index field_reconciliations_key_status on field_reconciliations(entity_key, status);
create unique index field_reconciliations_open_key
  on field_reconciliations(entity_type, entity_key)
  where status in ('awaiting_second', 'discrepant') and published_target_id is null;

create trigger field_reconciliations_set_updated_at before update on field_reconciliations
  for each row execute function set_updated_at();

alter table data_sources
  add constraint data_sources_field_fk
  foreign key (field_submission_id) references field_submissions(id);

-- Extract lat/lng from a field submission payload (doc 13 §3 variance: location_m).
create or replace function _field_payload_point(p_payload jsonb)
returns geography(Point, 4326)
language sql
immutable
as $$
  select st_setsrid(
    st_makepoint((p_payload->>'lng')::double precision, (p_payload->>'lat')::double precision),
    4326
  )::geography
  where p_payload ? 'lat' and p_payload ? 'lng';
$$;

-- Variance between two scout submissions (doc 13 §3 step 3).
create or replace function compute_field_variance(
  p_submission_a uuid,
  p_submission_b uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_a field_submissions%rowtype;
  v_b field_submissions%rowtype;
  v_variance jsonb := '{}'::jsonb;
  v_loc_tol numeric;
  v_fare_tol numeric;
  v_loc_m numeric;
  v_fare_a numeric;
  v_fare_b numeric;
  v_fare_pct numeric;
  v_name_sim numeric;
begin
  select * into v_a from field_submissions where id = p_submission_a;
  if not found then
    raise exception 'compute_field_variance: submission_a not found'
      using errcode = '22023';
  end if;

  select * into v_b from field_submissions where id = p_submission_b;
  if not found then
    raise exception 'compute_field_variance: submission_b not found'
      using errcode = '22023';
  end if;

  if v_a.entity_type <> v_b.entity_type or v_a.entity_key <> v_b.entity_key then
    raise exception 'compute_field_variance: entity_type/entity_key mismatch'
      using errcode = '22023';
  end if;

  v_loc_tol := cfg_num('field.location_tol_m', v_a.city_id);
  v_fare_tol := cfg_num('field.fare_tol_pct', v_a.city_id);

  if _field_payload_point(v_a.payload) is not null and _field_payload_point(v_b.payload) is not null then
    v_loc_m := st_distance(_field_payload_point(v_a.payload), _field_payload_point(v_b.payload));
    v_variance := v_variance || jsonb_build_object('location_m', round(v_loc_m::numeric, 2));
  end if;

  if v_a.payload ? 'name' and v_b.payload ? 'name' then
    v_name_sim := similarity(v_a.payload->>'name', v_b.payload->>'name');
    v_variance := v_variance || jsonb_build_object('name_similarity', round(v_name_sim::numeric, 3));
  end if;

  if v_a.payload ? 'fare_amount' and v_b.payload ? 'fare_amount' then
    v_fare_a := (v_a.payload->>'fare_amount')::numeric;
    v_fare_b := (v_b.payload->>'fare_amount')::numeric;
    if v_fare_a > 0 then
      v_fare_pct := abs(v_fare_a - v_fare_b) / v_fare_a;
      v_variance := v_variance || jsonb_build_object('fare_pct', round(v_fare_pct::numeric, 4));
    end if;
  end if;

  if v_a.payload ? 'stage_count' and v_b.payload ? 'stage_count' then
    v_variance := v_variance || jsonb_build_object(
      'stage_count_diff',
      abs((v_a.payload->>'stage_count')::int - (v_b.payload->>'stage_count')::int)
    );
  end if;

  v_variance := v_variance || jsonb_build_object(
    'within_tolerance',
    (v_loc_m is null or v_loc_m <= v_loc_tol)
    and (v_fare_pct is null or v_fare_pct <= v_fare_tol)
  );

  return v_variance;
end;
$$;

-- Ingestion upsert (doc 13 §3 step 3): first scout → awaiting_second; second → variance + matched/discrepant.
create or replace function reconcile_field_submission(p_submission_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sub field_submissions%rowtype;
  v_rec field_reconciliations%rowtype;
  v_variance jsonb;
  v_status text;
begin
  select * into v_sub from field_submissions where id = p_submission_id for update;
  if not found then
    raise exception 'reconcile_field_submission: submission not found'
      using errcode = '22023';
  end if;

  if not exists (
    select 1 from field_agents fa
    where fa.id = v_sub.scout_profile_id and fa.city_id = v_sub.city_id and fa.active
  ) then
    raise exception 'reconcile_field_submission: scout is not an active field agent for city'
      using errcode = '42501';
  end if;

  select * into v_rec
  from field_reconciliations
  where entity_type = v_sub.entity_type
    and entity_key = v_sub.entity_key
    and status in ('awaiting_second', 'discrepant')
    and published_target_id is null
  for update;

  if not found then
    insert into field_reconciliations (entity_type, entity_key, submission_a, status)
    values (v_sub.entity_type, v_sub.entity_key, v_sub.id, 'awaiting_second')
    returning id into v_rec.id;
    return v_rec.id;
  end if;

  if v_rec.submission_a = v_sub.id then
    return v_rec.id;
  end if;

  if v_rec.status = 'awaiting_second' and v_rec.submission_b is null then
    v_variance := compute_field_variance(v_rec.submission_a, v_sub.id);
    v_status := case when coalesce((v_variance->>'within_tolerance')::boolean, false)
      then 'matched' else 'discrepant' end;

    update field_reconciliations
    set submission_b = v_sub.id,
        variance = v_variance,
        status = v_status,
        updated_at = now()
    where id = v_rec.id;

    update field_submissions set status = 'reconciled'
    where id in (v_rec.submission_a, v_sub.id);

    return v_rec.id;
  end if;

  if v_rec.status = 'discrepant' and v_rec.submission_c is null and v_sub.id not in (v_rec.submission_a, v_rec.submission_b) then
    update field_reconciliations
    set submission_c = v_sub.id,
        updated_at = now()
    where id = v_rec.id;
    return v_rec.id;
  end if;

  raise exception 'reconcile_field_submission: no reconciliation slot for submission %', p_submission_id
    using errcode = '22023';
end;
$$;

-- Admin reconciliation actions (doc 03 §11).
create or replace function admin_reconcile_field_entity(
  p_reconciliation_id uuid,
  p_action text,
  p_resolution jsonb default null
)
returns field_reconciliations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rec field_reconciliations%rowtype;
  v_city_id uuid;
begin
  if not has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) then
    raise exception 'admin_reconcile_field_entity: forbidden'
      using errcode = '42501';
  end if;

  if p_action not in ('match', 'discrepant', 'resolve', 'reject') then
    raise exception 'admin_reconcile_field_entity: invalid action %', p_action
      using errcode = '22023';
  end if;

  select * into v_rec from field_reconciliations where id = p_reconciliation_id for update;
  if not found then
    raise exception 'admin_reconcile_field_entity: reconciliation not found'
      using errcode = '22023';
  end if;

  select fs.city_id into v_city_id
  from field_submissions fs
  where fs.id = v_rec.submission_a;

  if not admin_can_access_city(v_city_id) then
    raise exception 'admin_reconcile_field_entity: city scope denied'
      using errcode = '42501';
  end if;

  case p_action
    when 'match' then
      if v_rec.submission_b is null then
        raise exception 'admin_reconcile_field_entity: cannot match without a second submission'
          using errcode = '22023';
      end if;
      update field_reconciliations
      set status = 'matched',
          resolution = coalesce(p_resolution, resolution),
          updated_at = now()
      where id = p_reconciliation_id
      returning * into v_rec;

    when 'discrepant' then
      update field_reconciliations
      set status = 'discrepant',
          resolution = coalesce(p_resolution, resolution),
          updated_at = now()
      where id = p_reconciliation_id
      returning * into v_rec;

    when 'resolve' then
      if p_resolution is null then
        raise exception 'admin_reconcile_field_entity: resolve requires p_resolution'
          using errcode = '22023';
      end if;
      update field_reconciliations
      set status = 'resolved',
          resolution = p_resolution,
          resolved_by = auth.uid(),
          resolved_at = now(),
          updated_at = now()
      where id = p_reconciliation_id
      returning * into v_rec;

    when 'reject' then
      update field_reconciliations
      set status = 'rejected',
          resolution = coalesce(p_resolution, resolution),
          resolved_by = auth.uid(),
          resolved_at = now(),
          updated_at = now()
      where id = p_reconciliation_id
      returning * into v_rec;
  end case;

  return v_rec;
end;
$$;

-- Publish reconciled field entity to the along-graph (doc 13 §3 step 4, doc 03 §11).
create or replace function admin_publish_field_entity(p_reconciliation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rec field_reconciliations%rowtype;
  v_sub field_submissions%rowtype;
  v_payload jsonb;
  v_source_id uuid;
  v_park_id uuid;
  v_currency char(3);
  v_confidence numeric := 0.950;
begin
  if not has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) then
    raise exception 'admin_publish_field_entity: forbidden'
      using errcode = '42501';
  end if;

  select * into v_rec from field_reconciliations where id = p_reconciliation_id for update;
  if not found then
    raise exception 'admin_publish_field_entity: reconciliation not found'
      using errcode = '22023';
  end if;

  if v_rec.status not in ('matched', 'resolved') then
    raise exception 'admin_publish_field_entity: publish blocked until matched or resolved (status=%)', v_rec.status
      using errcode = '22023';
  end if;

  if v_rec.published_target_id is not null then
    raise exception 'admin_publish_field_entity: already published'
      using errcode = '22023';
  end if;

  select * into v_sub from field_submissions where id = v_rec.submission_a;
  if not admin_can_access_city(v_sub.city_id) then
    raise exception 'admin_publish_field_entity: city scope denied'
      using errcode = '42501';
  end if;

  v_payload := case
    when v_rec.status = 'resolved' and v_rec.resolution ? 'payload'
      then v_rec.resolution->'payload'
    else v_sub.payload
  end;

  perform set_config('along.revision_reason', 'field_publish', true);

  insert into data_sources (source_type, actor_profile_id, field_submission_id, notes)
  values ('field_agent', v_sub.scout_profile_id, v_sub.id, format('field_reconciliation:%s', v_rec.id))
  returning id into v_source_id;

  select c.currency_code into v_currency
  from cities ci
  join countries c on c.code = ci.country_code
  where ci.id = v_sub.city_id;

  case v_rec.entity_type
    when 'park' then
      if not (v_payload ? 'name' and v_payload ? 'lat' and v_payload ? 'lng') then
        raise exception 'admin_publish_field_entity: park payload requires name, lat, lng'
          using errcode = '22023';
      end if;

      insert into parks (
        city_id,
        name,
        name_aliases,
        location,
        verification_status,
        confidence_score,
        source_id,
        verified_by,
        verified_at
      ) values (
        v_sub.city_id,
        v_payload->>'name',
        coalesce(
          (select array_agg(x) from jsonb_array_elements_text(coalesce(v_payload->'name_aliases', '[]'::jsonb)) as t(x)),
          '{}'::text[]
        ),
        st_setsrid(st_makepoint((v_payload->>'lng')::double precision, (v_payload->>'lat')::double precision), 4326)::geography,
        'field_verified',
        v_confidence,
        v_source_id,
        auth.uid(),
        now()
      )
      returning id into v_park_id;

      update field_reconciliations
      set published_target_type = 'park',
          published_target_id = v_park_id,
          updated_at = now()
      where id = p_reconciliation_id;

      update field_submissions
      set status = 'published'
      where id in (v_rec.submission_a, v_rec.submission_b, v_rec.submission_c)
        and id is not null;

      return jsonb_build_object('target_type', 'park', 'target_id', v_park_id, 'source_id', v_source_id);

    else
      raise exception 'admin_publish_field_entity: entity_type % publish deferred to P0-E-03/A-08', v_rec.entity_type
        using errcode = '0A000';
  end case;
end;
$$;

-- RLS policies inlined (Supabase CLI does not support \ir).
alter table field_agents enable row level security;
alter table field_submissions enable row level security;
alter table field_reconciliations enable row level security;

create policy field_agents_select_admin
  on field_agents for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy field_agents_select_self
  on field_agents for select to authenticated
  using (id = auth.uid());

create policy field_agents_write_admin
  on field_agents for all to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy field_submissions_insert_agent
  on field_submissions for insert to authenticated
  with check (
    scout_profile_id = auth.uid()
    and exists (
      select 1 from field_agents fa
      where fa.id = auth.uid() and fa.city_id = field_submissions.city_id and fa.active
    )
  );

create policy field_submissions_select_agent
  on field_submissions for select to authenticated
  using (scout_profile_id = auth.uid());

create policy field_submissions_select_admin
  on field_submissions for select to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy field_submissions_update_admin
  on field_submissions for update to authenticated
  using (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id))
  with check (has_admin_role(array['superadmin', 'ops_lead', 'ops_agent']) and admin_can_access_city(city_id));

create policy field_reconciliations_select_admin
  on field_reconciliations for select to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select fs.city_id from field_submissions fs where fs.id = submission_a
    ))
  );

create policy field_reconciliations_update_admin
  on field_reconciliations for update to authenticated
  using (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select fs.city_id from field_submissions fs where fs.id = submission_a
    ))
  )
  with check (
    has_admin_role(array['superadmin', 'ops_lead', 'ops_agent'])
    and admin_can_access_city((
      select fs.city_id from field_submissions fs where fs.id = submission_a
    ))
  );

grant select on field_agents to authenticated;
grant select, insert on field_submissions to authenticated;
grant select, update on field_reconciliations to authenticated;

grant execute on function compute_field_variance(uuid, uuid) to authenticated;
grant execute on function reconcile_field_submission(uuid) to authenticated;
grant execute on function admin_reconcile_field_entity(uuid, text, jsonb) to authenticated;
grant execute on function admin_publish_field_entity(uuid) to authenticated;
