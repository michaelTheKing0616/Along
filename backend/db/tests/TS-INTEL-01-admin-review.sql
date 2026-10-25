-- pgTAP: P7-D-01 — intelligence review RPCs promote + audit (doc 03 §11, doc 04 §14–15)
create extension if not exists pgtap;

begin;
select plan(12);

select ok(
  to_regprocedure('admin_review_candidate_park(uuid,text)') is not null,
  'admin_review_candidate_park exists'
);

select ok(
  to_regprocedure('admin_review_route_inference(uuid,text)') is not null,
  'admin_review_route_inference exists'
);

select ok(
  to_regprocedure('admin_review_geometry_correction(uuid,text)') is not null,
  'admin_review_geometry_correction exists'
);

select ok(
  exists (
    select 1
    from pg_trigger tg
    join pg_class c on c.oid = tg.tgrelid
    join pg_proc p on p.oid = tg.tgfoid
    where c.relname = 'candidate_park_clusters'
      and p.proname = 'audit_admin_write'
  ),
  'candidate_park_clusters has audit_admin_write trigger'
);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('f7000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000000701')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id) values
  ('f7000000-0000-4000-8000-000000000001', 'ops_lead', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

select set_config('request.jwt.claim.sub', 'f7000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

insert into job_runs (id, job_name, status, finished_at)
values ('f7100000-0000-4000-8000-000000000001', 'cluster_candidate_parks', 'succeeded', now())
on conflict (id) do nothing;

insert into candidate_park_clusters (
  id,
  job_run_id,
  city_id,
  centroid,
  distinct_driver_count,
  distinct_day_count,
  sample_count,
  first_seen,
  last_seen,
  status
) values (
  'f7200000-0000-4000-8000-000000000001',
  'f7100000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makepoint(7.910, 11.210), 4326)::geography,
  6,
  4,
  24,
  now() - interval '10 days',
  now(),
  'new'
);

insert into route_inference_candidates (
  id,
  city_id,
  mode_code,
  geometry,
  origin_cluster,
  destination_cluster,
  supporting_trip_count,
  status
) values (
  'f7300000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'car',
  st_setsrid(st_makeline(st_makepoint(7.910, 11.210), st_makepoint(7.920, 11.220)), 4326)::geography,
  st_setsrid(st_makepoint(7.910, 11.210), 4326)::geography,
  st_setsrid(st_makepoint(7.920, 11.220), 4326)::geography,
  25,
  'new'
);

insert into road_geometry_corrections (
  id,
  city_id,
  geometry,
  supporting_trace_count,
  status
) values (
  'f7400000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  st_setsrid(st_makeline(st_makepoint(7.915, 11.215), st_makepoint(7.916, 11.216)), 4326)::geography,
  18,
  'candidate'
);

select admin_review_candidate_park('f7200000-0000-4000-8000-000000000001', 'promote');

select is(
  (select status from candidate_park_clusters where id = 'f7200000-0000-4000-8000-000000000001'),
  'promoted_to_stage',
  'candidate park promote updates cluster status'
);

select ok(
  exists (
    select 1
    from parks p
    join data_sources ds on ds.id = p.source_id
    where p.city_id = '0a000000-0000-4000-8000-000000000001'
      and ds.source_type = 'presence_cluster'
      and p.verification_status = 'candidate'
      and st_dwithin(p.location, st_setsrid(st_makepoint(7.910, 11.210), 4326)::geography, 5)
  ),
  'candidate park promote creates candidate park with presence_cluster provenance'
);

select admin_review_route_inference('f7300000-0000-4000-8000-000000000001', 'promote');

select is(
  (select status from route_inference_candidates where id = 'f7300000-0000-4000-8000-000000000001'),
  'promoted_to_route',
  'route inference promote updates candidate status'
);

select ok(
  exists (
    select 1
    from routes r
    join data_sources ds on ds.id = r.source_id
    where r.city_id = '0a000000-0000-4000-8000-000000000001'
      and ds.source_type = 'trace_inference'
      and r.verification_status = 'candidate'
      and r.id = (
        select route_id
        from route_inference_candidates
        where id = 'f7300000-0000-4000-8000-000000000001'
      )
  ),
  'route inference promote creates candidate route with trace_inference provenance'
);

select admin_review_geometry_correction('f7400000-0000-4000-8000-000000000001', 'promote');

select is(
  (select status from road_geometry_corrections where id = 'f7400000-0000-4000-8000-000000000001'),
  'reviewed_for_osm',
  'geometry promote sets reviewed_for_osm without OSM write'
);

select ok(
  exists (
    select 1
    from audit_log
    where target_type = 'candidate_park_clusters'
      and target_id = 'f7200000-0000-4000-8000-000000000001'
      and actor_id = 'f7000000-0000-4000-8000-000000000001'
  ),
  'candidate park review writes audit_log with actor'
);

select ok(
  exists (
    select 1
    from audit_log
    where target_type = 'route_inference_candidates'
      and target_id = 'f7300000-0000-4000-8000-000000000001'
      and actor_id = 'f7000000-0000-4000-8000-000000000001'
  ),
  'route inference review writes audit_log with actor'
);

select ok(
  exists (
    select 1
    from audit_log
    where target_type = 'road_geometry_corrections'
      and target_id = 'f7400000-0000-4000-8000-000000000001'
      and actor_id = 'f7000000-0000-4000-8000-000000000001'
  ),
  'geometry correction review writes audit_log with actor'
);

select * from finish();
rollback;
