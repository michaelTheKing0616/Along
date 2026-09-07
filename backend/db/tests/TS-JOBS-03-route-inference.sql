-- pgTAP: TS-JOBS-03 — route inference + geometry correction tables (P7-A-04)
create extension if not exists pgtap;

begin;
select plan(8);

select ok(
  to_regclass('public.route_inference_candidates') is not null,
  'route_inference_candidates table exists'
);

select ok(
  to_regclass('public.road_geometry_corrections') is not null,
  'road_geometry_corrections table exists'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.route_inference_candidates'::regclass),
  'route_inference_candidates has RLS enabled'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.road_geometry_corrections'::regclass),
  'road_geometry_corrections has RLS enabled'
);

select is(
  cfg_num('inference.min_trips'),
  20::numeric,
  'inference.min_trips default is 20'
);

select is(
  cfg_num('geometry.min_supporting_traces'),
  15::numeric,
  'geometry.min_supporting_traces default is 15'
);

select ok(
  to_regprocedure('cluster_candidate_parks(uuid)') is not null,
  'cluster_candidate_parks function exists'
);

select is(
  private.propose_from_traces(
    '00000000-0000-4000-8000-000000000099'::uuid,
    'driver'::actor_type
  ),
  '[]'::jsonb,
  'FM27: propose_from_traces returns zero proposals (inference in jobs worker)'
);

select * from finish();
rollback;
