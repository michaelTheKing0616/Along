-- pgTAP: P1-A-01 — doc 09 §2 table coverage smoke (RLS tables from migration 00012)
create extension if not exists pgtap;

begin;
select plan(4);

select has_table('public', 'driver_route_profiles', 'driver_route_profiles exists');
select has_table('public', 'driver_route_stops', 'driver_route_stops exists');
select has_table('public', 'planner_queries', 'planner_queries exists');
select has_table('public', 'coverage_gap_reports', 'coverage_gap_reports exists');

select * from finish();
rollback;
