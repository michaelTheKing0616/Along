-- P7-D-01: A-14 intelligence review RPCs (doc 03 §11, doc 04 §14–15).

-- ---------------------------------------------------------------------------
-- Provenance helper for intelligence promotions
-- ---------------------------------------------------------------------------
create or replace function _intelligence_source(
  p_source_type source_type,
  p_job_run_id uuid default null,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
begin
  insert into data_sources (source_type, actor_profile_id, job_run_id, notes)
  values (p_source_type, auth.uid(), p_job_run_id, p_note)
  returning id into v_id;
  return v_id;
end;
$$;

-- Snap to an existing park or create a candidate park at a cluster point.
create or replace function _snap_or_create_intelligence_park(
  p_city_id uuid,
  p_location geography,
  p_source_id uuid,
  p_label text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_merge_radius numeric;
  v_park_id uuid;
begin
  v_merge_radius := cfg_num('graph.stage_merge_radius_m', p_city_id);

  select p.id into v_park_id
  from parks p
  where p.city_id = p_city_id
    and p.active
    and st_dwithin(p.location, p_location, v_merge_radius)
  order by st_distance(p.location, p_location)
  limit 1;

  if v_park_id is not null then
    return v_park_id;
  end if;

  insert into parks (
    city_id,
    name,
    location,
    source_id,
    verification_status,
    confidence_score
  ) values (
    p_city_id,
    p_label,
    p_location,
    p_source_id,
    'candidate',
    0.350
  )
  returning id into v_park_id;

  return v_park_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- admin_review_candidate_park — promote → candidate park; dismiss
-- ---------------------------------------------------------------------------
create or replace function admin_review_candidate_park(
  id uuid,
  action text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_row candidate_park_clusters%rowtype;
  v_source_id uuid;
  v_park_id uuid;
  v_confidence numeric(4,3);
begin
  if not has_admin_role(array['ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action not in ('promote', 'dismiss') then
    raise exception 'VALIDATION: action must be promote or dismiss' using errcode = 'P0001';
  end if;

  select * into v_row
  from candidate_park_clusters
  where candidate_park_clusters.id = admin_review_candidate_park.id
  for update;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_row.status <> 'new' then
    raise exception 'STATE_INVALID: cluster is not pending review' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_row.city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action = 'dismiss' then
    update candidate_park_clusters
    set status = 'dismissed',
        reviewed_by = auth.uid(),
        reviewed_at = now()
    where candidate_park_clusters.id = admin_review_candidate_park.id;

    return jsonb_build_object(
      'id', admin_review_candidate_park.id,
      'status', 'dismissed',
      'park_id', null
    );
  end if;

  v_confidence := least(
    0.500,
    0.300 + (v_row.distinct_driver_count::numeric / 100.0)
  );

  v_source_id := _intelligence_source(
    'presence_cluster',
    v_row.job_run_id,
    format('admin_review_candidate_park:%s', admin_review_candidate_park.id)
  );

  insert into parks (
    city_id,
    name,
    location,
    source_id,
    verification_status,
    confidence_score
  ) values (
    v_row.city_id,
    format(
      'Candidate park (%s drivers, %s days)',
      v_row.distinct_driver_count,
      v_row.distinct_day_count
    ),
    v_row.centroid,
    v_source_id,
    'candidate',
    v_confidence
  )
  returning parks.id into v_park_id;

  update candidate_park_clusters
  set status = 'promoted_to_stage',
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where candidate_park_clusters.id = admin_review_candidate_park.id;

  return jsonb_build_object(
    'id', admin_review_candidate_park.id,
    'status', 'promoted_to_stage',
    'park_id', v_park_id,
    'source_type', 'presence_cluster',
    'verification_status', 'candidate'
  );
end;
$$;

grant execute on function admin_review_candidate_park(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_review_route_inference — promote → routes(candidate) trace_inference
-- ---------------------------------------------------------------------------
create or replace function admin_review_route_inference(
  id uuid,
  action text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_row route_inference_candidates%rowtype;
  v_source_id uuid;
  v_origin_park_id uuid;
  v_dest_park_id uuid;
  v_route_id uuid;
  v_confidence numeric(4,3);
begin
  if not has_admin_role(array['ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action not in ('promote', 'dismiss') then
    raise exception 'VALIDATION: action must be promote or dismiss' using errcode = 'P0001';
  end if;

  select * into v_row
  from route_inference_candidates
  where route_inference_candidates.id = admin_review_route_inference.id
  for update;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_row.status <> 'new' then
    raise exception 'STATE_INVALID: inference candidate is not pending review' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_row.city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action = 'dismiss' then
    update route_inference_candidates
    set status = 'dismissed',
        reviewed_by = auth.uid(),
        reviewed_at = now()
    where route_inference_candidates.id = admin_review_route_inference.id;

    return jsonb_build_object(
      'id', admin_review_route_inference.id,
      'status', 'dismissed',
      'route_id', null
    );
  end if;

  if v_row.origin_cluster is null or v_row.destination_cluster is null then
    raise exception 'VALIDATION: inference candidate missing origin or destination cluster'
      using errcode = 'P0001';
  end if;

  v_confidence := least(
    0.500,
    0.300 + (v_row.supporting_trip_count::numeric / 100.0)
  );

  v_source_id := _intelligence_source(
    'trace_inference',
    null,
    format('admin_review_route_inference:%s', admin_review_route_inference.id)
  );

  v_origin_park_id := _snap_or_create_intelligence_park(
    v_row.city_id,
    v_row.origin_cluster,
    v_source_id,
    format('Inferred origin (%s trips)', v_row.supporting_trip_count)
  );

  v_dest_park_id := _snap_or_create_intelligence_park(
    v_row.city_id,
    v_row.destination_cluster,
    v_source_id,
    format('Inferred destination (%s trips)', v_row.supporting_trip_count)
  );

  insert into routes (
    city_id,
    origin_park_id,
    destination_park_id,
    mode_code,
    name,
    path,
    source_id,
    verification_status,
    confidence_score
  ) values (
    v_row.city_id,
    v_origin_park_id,
    v_dest_park_id,
    coalesce(v_row.mode_code, 'car'),
    format(
      'Inferred route (%s trips, %s)',
      v_row.supporting_trip_count,
      coalesce(v_row.mode_code, 'car')
    ),
    v_row.geometry,
    v_source_id,
    'candidate',
    v_confidence
  )
  returning routes.id into v_route_id;

  update route_inference_candidates
  set status = 'promoted_to_route',
      route_id = v_route_id,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where route_inference_candidates.id = admin_review_route_inference.id;

  return jsonb_build_object(
    'id', admin_review_route_inference.id,
    'status', 'promoted_to_route',
    'route_id', v_route_id,
    'source_type', 'trace_inference',
    'verification_status', 'candidate'
  );
end;
$$;

grant execute on function admin_review_route_inference(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- admin_review_geometry_correction — promote/dismiss; no OSM auto-write
-- ---------------------------------------------------------------------------
create or replace function admin_review_geometry_correction(
  id uuid,
  action text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_row road_geometry_corrections%rowtype;
  v_new_status text;
begin
  if not has_admin_role(array['ops_lead', 'superadmin']) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  if action not in ('promote', 'dismiss') then
    raise exception 'VALIDATION: action must be promote or dismiss' using errcode = 'P0001';
  end if;

  select * into v_row
  from road_geometry_corrections
  where road_geometry_corrections.id = admin_review_geometry_correction.id
  for update;

  if not found then
    raise exception 'NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_row.status <> 'candidate' then
    raise exception 'STATE_INVALID: geometry correction is not pending review' using errcode = 'P0001';
  end if;

  if not admin_can_access_city(v_row.city_id) then
    raise exception 'FORBIDDEN' using errcode = '42501';
  end if;

  v_new_status := case action
    when 'promote' then 'reviewed_for_osm'
    else 'rejected'
  end;

  update road_geometry_corrections
  set status = v_new_status,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where road_geometry_corrections.id = admin_review_geometry_correction.id;

  return jsonb_build_object(
    'id', admin_review_geometry_correction.id,
    'status', v_new_status,
    'osm_changeset_id', null
  );
end;
$$;

grant execute on function admin_review_geometry_correction(uuid, text) to authenticated;

-- Audit triggers for intelligence review tables (P7-D-01 AC)
create trigger audit_candidate_park_clusters
  after update on candidate_park_clusters
  for each row execute function audit_admin_write();

create trigger audit_route_inference_candidates
  after update on route_inference_candidates
  for each row execute function audit_admin_write();

create trigger audit_road_geometry_corrections
  after update on road_geometry_corrections
  for each row execute function audit_admin_write();
