-- pgTAP: TS-GRAPH-06 — driver route publish via upsert_route_profile (P1-A-03)
create extension if not exists pgtap;

begin;
select plan(6);

insert into deployments (id, tenant_name)
values ('b0000000-0000-4000-8000-000000000001', 'Graph Publish Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XG', 'Graph Test Country', 'NGN', E'₦', '+996', 'UTC', 'b0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'b0000000-0000-4000-8000-000000000002',
  'XG',
  'Graph Publish City',
  'graph-publish-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into data_sources (id, source_type)
values ('b0000000-0000-4000-8000-000000000020', 'import');

insert into parks (id, city_id, name, location, source_id, verification_status, confidence_score) values
  ('b0000000-0000-4000-8000-000000000030', 'b0000000-0000-4000-8000-000000000002', 'Origin Park', st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'b0000000-0000-4000-8000-000000000020', 'field_verified', 0.900),
  ('b0000000-0000-4000-8000-000000000031', 'b0000000-0000-4000-8000-000000000002', 'Destination Park', st_setsrid(st_makepoint(7.50, 9.15), 4326)::geography, 'b0000000-0000-4000-8000-000000000020', 'field_verified', 0.900);

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status, confidence_score)
values (
  'b0000000-0000-4000-8000-000000000040',
  'b0000000-0000-4000-8000-000000000002',
  'b0000000-0000-4000-8000-000000000030',
  'b0000000-0000-4000-8000-000000000031',
  'car',
  'b0000000-0000-4000-8000-000000000020',
  'field_verified',
  0.900
);

insert into route_stages (id, route_id, sequence, location, name, source_id, verification_status, confidence_score) values
  ('b0000000-0000-4000-8000-000000000050', 'b0000000-0000-4000-8000-000000000040', 1, st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'Origin', 'b0000000-0000-4000-8000-000000000020', 'field_verified', 0.900),
  ('b0000000-0000-4000-8000-000000000051', 'b0000000-0000-4000-8000-000000000040', 2, st_setsrid(st_makepoint(7.42, 9.07), 4326)::geography, 'Mid A', 'b0000000-0000-4000-8000-000000000020', 'field_verified', 0.900),
  ('b0000000-0000-4000-8000-000000000052', 'b0000000-0000-4000-8000-000000000040', 3, st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography, 'Mid B', 'b0000000-0000-4000-8000-000000000020', 'field_verified', 0.900);

insert into auth.users (id, aud, role, phone) values
  ('b0000000-0000-4000-8000-000000000060', 'authenticated', 'authenticated', '+2348000002001')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, driver_code, home_park_id)
values (
  'b0000000-0000-4000-8000-000000000060',
  'b0000000-0000-4000-8000-000000000002',
  'verified',
  'GRPHDRV1',
  'b0000000-0000-4000-8000-000000000030'
);

select set_config('request.jwt.claim.sub', 'b0000000-0000-4000-8000-000000000060', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

-- Non-monotone prices rejected
select throws_ok(
  $$ select upsert_route_profile('{
    "mode_code": "car",
    "stops": [
      {"sequence": 1, "route_stage_id": "b0000000-0000-4000-8000-000000000050", "price_to_end": 200},
      {"sequence": 2, "route_stage_id": "b0000000-0000-4000-8000-000000000051", "price_to_end": 300},
      {"sequence": 3, "route_stage_id": "b0000000-0000-4000-8000-000000000052", "price_to_end": 0}
    ]
  }'::jsonb) $$,
  '23514',
  'driver_route_stop price_to_end must be non-increasing with sequence',
  'TS-GRAPH-06: non-monotone prices rejected'
);

-- Publish: 2 snapped stops + 1 unmatched custom stop
select upsert_route_profile('{
  "mode_code": "car",
  "stops": [
    {"sequence": 1, "route_stage_id": "b0000000-0000-4000-8000-000000000050", "price_to_end": 400},
    {"sequence": 2, "location": {"lat": 9.0701, "lng": 7.4201}, "price_to_end": 300},
    {"sequence": 3, "location": {"lat": 9.1200, "lng": 7.4800}, "custom_label": "New Junction", "price_to_end": 0}
  ]
}'::jsonb);

select ok(
  snap_stage(
    st_setsrid(st_makepoint(7.4201, 9.0701), 4326)::geography,
    null,
    'b0000000-0000-4000-8000-000000000002'
  ) = 'b0000000-0000-4000-8000-000000000051'::uuid,
  'TS-GRAPH-06: stop snaps within 60 m to Mid A'
);

select ok(
  exists (
    select 1
    from route_stages rs
    join data_sources ds on ds.id = rs.source_id
    where rs.route_id = 'b0000000-0000-4000-8000-000000000040'
      and rs.name = 'New Junction'
      and rs.verification_status = 'candidate'
      and ds.source_type = 'driver_declared'
  ),
  'TS-GRAPH-06: unmatched stop → candidate stage with driver_declared source'
);

select ok(
  (select active from driver_route_profiles where driver_id = 'b0000000-0000-4000-8000-000000000060' order by created_at desc limit 1),
  'TS-GRAPH-06: profile active immediately'
);

select ok(
  jsonb_array_length(my_route_profiles()) >= 1,
  'TS-GRAPH-06: my_route_profiles returns published profile'
);

select ok(
  (select count(*) from driver_route_stops s
   join driver_route_profiles p on p.id = s.profile_id
   where p.driver_id = 'b0000000-0000-4000-8000-000000000060'
     and p.active) = 3,
  'TS-GRAPH-06: three stops persisted on active profile'
);

select * from finish();
rollback;
