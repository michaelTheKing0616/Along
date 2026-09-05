-- pgTAP: Phase 0 exit criterion queries (ALONG_BUILD_SPEC §7 Phase 0)
create extension if not exists pgtap;

begin;
\ir ../seed/seed_abuja_pilot/load.sql

select plan(6);

-- Exit: 2-3 corridors with backbone seeding for Tier 1/2 fare resolution
select is(
  (select count(*)::int from corridors where city_id = 'b1000000-0000-4000-8000-000000000001' and status = 'live'),
  3,
  'Phase 0 exit: three live pilot corridors seeded'
);

select ok(
  (select count(*) from route_through_fares rtf
   join routes r on r.id = rtf.route_id
   where r.city_id = 'b1000000-0000-4000-8000-000000000001'
     and rtf.verification_status = 'field_verified') >= 3,
  'Phase 0 exit: multiple field_verified through-fares for Tier 1 resolution'
);

-- Exit: walkable multi-leg path between any two backbone parks
select ok(
  not exists (
    select 1
    from parks o
    cross join parks d
    where o.city_id = 'b1000000-0000-4000-8000-000000000001'
      and d.city_id = 'b1000000-0000-4000-8000-000000000001'
      and o.id <> d.id
      and not exists (
        select 1
        from planner_decompose(o.id, d.id, 'b1000000-0000-4000-8000-000000000001')
      )
  ),
  'Phase 0 exit: planner_decompose path for every ordered backbone park pair'
);

-- Exit: Tier 2 summed-hop fare between intermediate backbone stages (Karu → AYA on Nyanya car)
select is(
  (resolve_fare(
    p_route_id := 'b1400000-0000-4000-8000-000000000011',
    p_from_stage_id := 'b1410000-0000-4000-8000-000000000012',
    p_to_stage_id := 'b1410000-0000-4000-8000-000000000014',
    p_mode_code := 'car',
    p_city_id := 'b1000000-0000-4000-8000-000000000001'
  )).amount,
  150.00::numeric,
  'Phase 0 exit: Tier 2 fare Karu→AYA = sum legs (50+100)'
);

select is(
  (resolve_fare(
    p_route_id := 'b1400000-0000-4000-8000-000000000011',
    p_from_stage_id := 'b1410000-0000-4000-8000-000000000012',
    p_to_stage_id := 'b1410000-0000-4000-8000-000000000014',
    p_mode_code := 'car',
    p_city_id := 'b1000000-0000-4000-8000-000000000001'
  )).tier,
  2::smallint,
  'Phase 0 exit: intermediate pair resolves via Tier 2 (no through-fare S2→S4)'
);

-- Provenance: field_verified graph rows link to field_agent source
select ok(
  not exists (
    select 1 from parks p
    join data_sources ds on ds.id = p.source_id
    where p.city_id = 'b1000000-0000-4000-8000-000000000001'
      and p.verification_status = 'field_verified'
      and ds.source_type <> 'field_agent'
  ),
  'Phase 0 exit: field_verified parks carry source_type=field_agent'
);

select * from finish();
rollback;
