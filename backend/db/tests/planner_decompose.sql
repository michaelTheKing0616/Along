-- pgTAP: planner_decompose MVP (doc 04 §4.3, P0-A-06)
-- Minimal 3-park backbone triangle: path exists for every ordered park pair.
create extension if not exists pgtap;

begin;
select plan(9);

-- ---------------------------------------------------------------------------
-- Fixtures: parks A, B, C; routes A→B, B→C, C→A; transfer_points at each hub
-- ---------------------------------------------------------------------------
insert into deployments (id, tenant_name)
values ('d0000000-0000-4000-8000-000000000001', 'Planner Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XP', 'Planner Test Country', 'NGN', E'₦', '+997', 'UTC', 'd0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'd0000000-0000-4000-8000-000000000002',
  'XP',
  'Planner Test City',
  'planner-test-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into data_sources (id, source_type)
values ('d0000000-0000-4000-8000-000000000020', 'admin');

insert into parks (id, city_id, name, location, source_id, verification_status)
values
  (
    'd0000000-0000-4000-8000-000000000030',
    'd0000000-0000-4000-8000-000000000002',
    'Backbone Park A',
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    'd0000000-0000-4000-8000-000000000020',
    'field_verified'
  ),
  (
    'd0000000-0000-4000-8000-000000000031',
    'd0000000-0000-4000-8000-000000000002',
    'Backbone Park B',
    st_setsrid(st_makepoint(7.45, 9.05), 4326)::geography,
    'd0000000-0000-4000-8000-000000000020',
    'field_verified'
  ),
  (
    'd0000000-0000-4000-8000-000000000032',
    'd0000000-0000-4000-8000-000000000002',
    'Backbone Park C',
    st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography,
    'd0000000-0000-4000-8000-000000000020',
    'field_verified'
  );

-- Route A → B
insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status)
values (
  'd0000000-0000-4000-8000-000000000040',
  'd0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000030',
  'd0000000-0000-4000-8000-000000000031',
  'car',
  'd0000000-0000-4000-8000-000000000020',
  'field_verified'
);

-- Route B → C
insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status)
values (
  'd0000000-0000-4000-8000-000000000041',
  'd0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000031',
  'd0000000-0000-4000-8000-000000000032',
  'car',
  'd0000000-0000-4000-8000-000000000020',
  'field_verified'
);

-- Route C → A
insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id, verification_status)
values (
  'd0000000-0000-4000-8000-000000000042',
  'd0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000032',
  'd0000000-0000-4000-8000-000000000030',
  'car',
  'd0000000-0000-4000-8000-000000000020',
  'field_verified'
);

insert into route_stages (id, route_id, sequence, park_id, location, source_id, is_official_park, verification_status) values
  ('d0000000-0000-4000-8000-000000000050', 'd0000000-0000-4000-8000-000000000040', 1, 'd0000000-0000-4000-8000-000000000030', st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'd0000000-0000-4000-8000-000000000020', true, 'field_verified'),
  ('d0000000-0000-4000-8000-000000000051', 'd0000000-0000-4000-8000-000000000040', 2, 'd0000000-0000-4000-8000-000000000031', st_setsrid(st_makepoint(7.45, 9.05), 4326)::geography, 'd0000000-0000-4000-8000-000000000020', true, 'field_verified'),
  ('d0000000-0000-4000-8000-000000000060', 'd0000000-0000-4000-8000-000000000041', 1, 'd0000000-0000-4000-8000-000000000031', st_setsrid(st_makepoint(7.45, 9.05), 4326)::geography, 'd0000000-0000-4000-8000-000000000020', true, 'field_verified'),
  ('d0000000-0000-4000-8000-000000000061', 'd0000000-0000-4000-8000-000000000041', 2, 'd0000000-0000-4000-8000-000000000032', st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography, 'd0000000-0000-4000-8000-000000000020', true, 'field_verified'),
  ('d0000000-0000-4000-8000-000000000070', 'd0000000-0000-4000-8000-000000000042', 1, 'd0000000-0000-4000-8000-000000000032', st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography, 'd0000000-0000-4000-8000-000000000020', true, 'field_verified'),
  ('d0000000-0000-4000-8000-000000000071', 'd0000000-0000-4000-8000-000000000042', 2, 'd0000000-0000-4000-8000-000000000030', st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'd0000000-0000-4000-8000-000000000020', true, 'field_verified');

insert into route_legs (
  route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency,
  source_id, verification_status, in_vehicle_time_estimate_s, avg_wait_time_estimate_s
) values
  ('d0000000-0000-4000-8000-000000000040', 'd0000000-0000-4000-8000-000000000050', 'd0000000-0000-4000-8000-000000000051', 'car', 200.00, 'NGN', 'd0000000-0000-4000-8000-000000000020', 'field_verified', 600, 120),
  ('d0000000-0000-4000-8000-000000000041', 'd0000000-0000-4000-8000-000000000060', 'd0000000-0000-4000-8000-000000000061', 'car', 250.00, 'NGN', 'd0000000-0000-4000-8000-000000000020', 'field_verified', 720, 120),
  ('d0000000-0000-4000-8000-000000000042', 'd0000000-0000-4000-8000-000000000070', 'd0000000-0000-4000-8000-000000000071', 'car', 300.00, 'NGN', 'd0000000-0000-4000-8000-000000000020', 'field_verified', 900, 120);

-- Transfer hubs: each park links the two routes that meet there
insert into transfer_points (park_id, route_id, stage_id, walk_distance_m, transfer_time_s) values
  ('d0000000-0000-4000-8000-000000000030', 'd0000000-0000-4000-8000-000000000040', 'd0000000-0000-4000-8000-000000000050', 0, 120),
  ('d0000000-0000-4000-8000-000000000030', 'd0000000-0000-4000-8000-000000000042', 'd0000000-0000-4000-8000-000000000071', 0, 120),
  ('d0000000-0000-4000-8000-000000000031', 'd0000000-0000-4000-8000-000000000040', 'd0000000-0000-4000-8000-000000000051', 0, 120),
  ('d0000000-0000-4000-8000-000000000031', 'd0000000-0000-4000-8000-000000000041', 'd0000000-0000-4000-8000-000000000060', 0, 120),
  ('d0000000-0000-4000-8000-000000000032', 'd0000000-0000-4000-8000-000000000041', 'd0000000-0000-4000-8000-000000000061', 0, 120),
  ('d0000000-0000-4000-8000-000000000032', 'd0000000-0000-4000-8000-000000000042', 'd0000000-0000-4000-8000-000000000070', 0, 120);

-- ---------------------------------------------------------------------------
-- Acceptance: path between every ordered pair of backbone parks
-- ---------------------------------------------------------------------------
select ok(
  not exists (
    select 1
    from parks o
    cross join parks d
    where o.city_id = 'd0000000-0000-4000-8000-000000000002'
      and d.city_id = 'd0000000-0000-4000-8000-000000000002'
      and o.id <> d.id
      and planner_decompose(o.id, d.id, 'd0000000-0000-4000-8000-000000000002') is null
  ),
  'planner_decompose returns a path for every ordered backbone park pair'
);

-- Direct edge A → B is a single leg
select is(
  jsonb_array_length(
    planner_decompose(
      'd0000000-0000-4000-8000-000000000030',
      'd0000000-0000-4000-8000-000000000031',
      'd0000000-0000-4000-8000-000000000002'
    )->'legs'
  ),
  1,
  'direct A→B is one leg'
);

-- Reverse B → A requires a transfer (two legs on the triangle)
select is(
  jsonb_array_length(
    planner_decompose(
      'd0000000-0000-4000-8000-000000000031',
      'd0000000-0000-4000-8000-000000000030',
      'd0000000-0000-4000-8000-000000000002'
    )->'legs'
  ),
  2,
  'reverse B→A uses two legs via transfer'
);

select is(
  planner_decompose(
    'd0000000-0000-4000-8000-000000000031',
    'd0000000-0000-4000-8000-000000000030',
    'd0000000-0000-4000-8000-000000000002'
  )->>'kind',
  'multi_leg',
  'itinerary kind is multi_leg'
);

select ok(
  jsonb_array_length(
    planner_decompose(
      'd0000000-0000-4000-8000-000000000031',
      'd0000000-0000-4000-8000-000000000030',
      'd0000000-0000-4000-8000-000000000002'
    )->'transfers'
  ) >= 1,
  'multi-leg itinerary includes at least one transfer record'
);

-- Same-park query returns empty legs
select is(
  jsonb_array_length(
    planner_decompose(
      'd0000000-0000-4000-8000-000000000030',
      'd0000000-0000-4000-8000-000000000030',
      'd0000000-0000-4000-8000-000000000002'
    )->'legs'
  ),
  0,
  'same origin and destination park yields zero legs'
);

-- Leg count respects cfg.planner.max_legs (global default 3)
select ok(
  (
    select max(jsonb_array_length(planner_decompose(o.id, d.id, 'd0000000-0000-4000-8000-000000000002')->'legs'))
    from parks o
    cross join parks d
    where o.city_id = 'd0000000-0000-4000-8000-000000000002'
      and d.city_id = 'd0000000-0000-4000-8000-000000000002'
      and o.id <> d.id
  ) <= cfg_num('planner.max_legs', 'd0000000-0000-4000-8000-000000000002')::int,
  'every path uses at most cfg.planner.max_legs legs'
);

-- Resolved fares attached when leg fare data exists
select ok(
  (
    planner_decompose(
      'd0000000-0000-4000-8000-000000000030',
      'd0000000-0000-4000-8000-000000000031',
      'd0000000-0000-4000-8000-000000000002'
    )->'legs'->0->'fare'->>'amount'
  ) is not null,
  'direct leg includes resolved fare amount'
);

-- Isolated park (no routes) returns null
insert into parks (id, city_id, name, location, source_id)
values (
  'd0000000-0000-4000-8000-000000000099',
  'd0000000-0000-4000-8000-000000000002',
  'Isolated Park',
  st_setsrid(st_makepoint(7.50, 9.20), 4326)::geography,
  'd0000000-0000-4000-8000-000000000020'
);

select is(
  planner_decompose(
    'd0000000-0000-4000-8000-000000000030',
    'd0000000-0000-4000-8000-000000000099',
    'd0000000-0000-4000-8000-000000000002'
  ),
  null,
  'no path when destination is unreachable'
);

select * from finish();
rollback;
