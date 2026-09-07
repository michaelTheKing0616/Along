-- pgTAP: TS-JOBS-02 — speed-profiles job config + segment_speed_profiles (P7-A-03)
create extension if not exists pgtap;

begin;
select plan(4);

select ok(
  to_regclass('public.segment_speed_profiles') is not null,
  'segment_speed_profiles table exists'
);

select is(
  cfg_num('jobs.speed_profile_min_samples'),
  8::numeric,
  'jobs.speed_profile_min_samples default is 8'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.segment_speed_profiles'::regclass),
  'segment_speed_profiles has RLS enabled'
);

select is(
  private.aggregate_speed_profiles_from_matched_traces(null)->>'source',
  'matched_traces_only',
  'FM27: speed profile aggregation source is matched_traces only'
);

select * from finish();
rollback;
