-- pgTAP: TS-RLS-02 — RLS shape for the phase C–E tables (migrations 0084–0088).
-- Pins: RLS on, the exact policy set, read-only client policies (writes go
-- through security-definer RPCs), and owner scoping on per-user tables.
create extension if not exists pgtap;

begin;
select plan(72);

select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'conductor_sessions'),
  'TS-RLS-02: conductor_sessions has RLS enabled'
);
select policies_are('public', 'conductor_sessions', array['conductor_sessions_read'], 'TS-RLS-02: conductor_sessions policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'conductor_sessions'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: conductor_sessions has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'conductor_sessions'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: conductor_sessions grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'driver_day_plans'),
  'TS-RLS-02: driver_day_plans has RLS enabled'
);
select policies_are('public', 'driver_day_plans', array['driver_day_plans_read'], 'TS-RLS-02: driver_day_plans policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_day_plans'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: driver_day_plans has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_day_plans'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: driver_day_plans grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_day_plans'
          and cmd = 'SELECT' and qual like '%(driver_id = auth.uid())%'),
  'TS-RLS-02: driver_day_plans reads are scoped to driver_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'driver_earnings_goals'),
  'TS-RLS-02: driver_earnings_goals has RLS enabled'
);
select policies_are('public', 'driver_earnings_goals', array['driver_earnings_goals_owner'], 'TS-RLS-02: driver_earnings_goals policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_earnings_goals'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: driver_earnings_goals has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_earnings_goals'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: driver_earnings_goals grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_earnings_goals'
          and cmd = 'SELECT' and qual like '%(driver_id = auth.uid())%'),
  'TS-RLS-02: driver_earnings_goals reads are scoped to driver_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'driver_rest_prefs'),
  'TS-RLS-02: driver_rest_prefs has RLS enabled'
);
select policies_are('public', 'driver_rest_prefs', array['driver_rest_prefs_owner'], 'TS-RLS-02: driver_rest_prefs policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_rest_prefs'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: driver_rest_prefs has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_rest_prefs'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: driver_rest_prefs grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_rest_prefs'
          and cmd = 'SELECT' and qual like '%(driver_id = auth.uid())%'),
  'TS-RLS-02: driver_rest_prefs reads are scoped to driver_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'driver_rests'),
  'TS-RLS-02: driver_rests has RLS enabled'
);
select policies_are('public', 'driver_rests', array['driver_rests_read'], 'TS-RLS-02: driver_rests policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_rests'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: driver_rests has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_rests'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: driver_rests grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_rests'
          and cmd = 'SELECT' and qual like '%(driver_id = auth.uid())%'),
  'TS-RLS-02: driver_rests reads are scoped to driver_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'driver_ride_rules'),
  'TS-RLS-02: driver_ride_rules has RLS enabled'
);
select policies_are('public', 'driver_ride_rules', array['driver_ride_rules_read'], 'TS-RLS-02: driver_ride_rules policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_ride_rules'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: driver_ride_rules has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'driver_ride_rules'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: driver_ride_rules grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'fare_observations'),
  'TS-RLS-02: fare_observations has RLS enabled'
);
select policies_are('public', 'fare_observations', array['fare_observations_owner'], 'TS-RLS-02: fare_observations policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'fare_observations'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: fare_observations has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'fare_observations'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: fare_observations grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'fare_observations'
          and cmd = 'SELECT' and qual like '%(rider_id = auth.uid())%'),
  'TS-RLS-02: fare_observations reads are scoped to rider_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'fuel_notes'),
  'TS-RLS-02: fuel_notes has RLS enabled'
);
select policies_are('public', 'fuel_notes', array['fuel_notes_read'], 'TS-RLS-02: fuel_notes policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'fuel_notes'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: fuel_notes has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'fuel_notes'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: fuel_notes grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'guardian_events'),
  'TS-RLS-02: guardian_events has RLS enabled'
);
select policies_are('public', 'guardian_events', array['guardian_events_read'], 'TS-RLS-02: guardian_events policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'guardian_events'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: guardian_events has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'guardian_events'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: guardian_events grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'live_segment_observations'),
  'TS-RLS-02: live_segment_observations has RLS enabled'
);
select policies_are('public', 'live_segment_observations', array['live_segment_observations_no_client_write', 'live_segment_observations_select_admin'], 'TS-RLS-02: live_segment_observations policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'live_segment_observations'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: live_segment_observations has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'live_segment_observations'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: live_segment_observations grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'pickup_events'),
  'TS-RLS-02: pickup_events has RLS enabled'
);
select policies_are('public', 'pickup_events', array['pickup_events_read'], 'TS-RLS-02: pickup_events policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'pickup_events'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: pickup_events has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'pickup_events'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: pickup_events grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'rider_favourites'),
  'TS-RLS-02: rider_favourites has RLS enabled'
);
select policies_are('public', 'rider_favourites', array['rider_favourites_owner'], 'TS-RLS-02: rider_favourites policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'rider_favourites'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: rider_favourites has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'rider_favourites'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: rider_favourites grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rider_favourites'
          and cmd = 'SELECT' and qual like '%(rider_id = auth.uid())%'),
  'TS-RLS-02: rider_favourites reads are scoped to rider_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'rider_guardian_prefs'),
  'TS-RLS-02: rider_guardian_prefs has RLS enabled'
);
select policies_are('public', 'rider_guardian_prefs', array['rider_guardian_prefs_owner'], 'TS-RLS-02: rider_guardian_prefs policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'rider_guardian_prefs'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: rider_guardian_prefs has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'rider_guardian_prefs'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: rider_guardian_prefs grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rider_guardian_prefs'
          and cmd = 'SELECT' and qual like '%(profile_id = auth.uid())%'),
  'TS-RLS-02: rider_guardian_prefs reads are scoped to profile_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'route_requests'),
  'TS-RLS-02: route_requests has RLS enabled'
);
select policies_are('public', 'route_requests', array['route_requests_owner'], 'TS-RLS-02: route_requests policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'route_requests'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: route_requests has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'route_requests'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: route_requests grants no client write'
);
select ok(
  exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'route_requests'
          and cmd = 'SELECT' and qual like '%(rider_id = auth.uid())%'),
  'TS-RLS-02: route_requests reads are scoped to rider_id'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'stage_dwell_samples'),
  'TS-RLS-02: stage_dwell_samples has RLS enabled'
);
select policies_are('public', 'stage_dwell_samples', array['stage_dwell_samples_no_client_write', 'stage_dwell_samples_select_admin'], 'TS-RLS-02: stage_dwell_samples policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'stage_dwell_samples'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: stage_dwell_samples has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'stage_dwell_samples'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: stage_dwell_samples grants no client write'
);
select ok(
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname = 'trip_messages'),
  'TS-RLS-02: trip_messages has RLS enabled'
);
select policies_are('public', 'trip_messages', array['trip_messages_party'], 'TS-RLS-02: trip_messages policy set');
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'trip_messages'
       and 'anon' = any (roles) $$,
  'TS-RLS-02: trip_messages has no anon policy'
);
select is_empty(
  $$ select 1 from pg_policies where schemaname = 'public' and tablename = 'trip_messages'
       and cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
       and coalesce(qual, 'true') <> 'false' $$,
  'TS-RLS-02: trip_messages grants no client write'
);

select * from finish();
rollback;
