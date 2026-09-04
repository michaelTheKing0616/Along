-- pgTAP: promotion pipeline (doc 04 §6, P0-A-05)
-- TS-GRAPH-01 through TS-GRAPH-05
create extension if not exists pgtap;

begin;
select plan(12);

insert into deployments (id, tenant_name)
values ('c0000000-0000-4000-8000-000000000001', 'Promotion Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XP', 'Promotion Test Country', 'XXX', 'X', '+998', 'UTC', 'c0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'c0000000-0000-4000-8000-000000000002',
  'XP',
  'Promotion Test City',
  'promotion-test-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into data_sources (id, source_type)
values ('c0000000-0000-4000-8000-000000000020', 'admin');

-- Helper: one 3-stage route with verified neighbour leg + one candidate leg (unique stage pairs per route)
-- Route R1 — TS-GRAPH-01
insert into parks (id, city_id, name, location, source_id) values
  ('c0000000-0000-4000-8000-000000000030', 'c0000000-0000-4000-8000-000000000002', 'R1 Origin', st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000031', 'c0000000-0000-4000-8000-000000000002', 'R1 Destination', st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id)
values ('c0000000-0000-4000-8000-000000000040', 'c0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000030', 'c0000000-0000-4000-8000-000000000031', 'car', 'c0000000-0000-4000-8000-000000000020');

insert into route_stages (id, route_id, sequence, location, source_id) values
  ('c0000000-0000-4000-8000-000000000050', 'c0000000-0000-4000-8000-000000000040', 1, st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000051', 'c0000000-0000-4000-8000-000000000040', 2, st_setsrid(st_makepoint(7.42, 9.07), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000052', 'c0000000-0000-4000-8000-000000000040', 3, st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into route_legs (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, verification_status, confidence_score, source_id) values
  ('c0000000-0000-4000-8000-000000000060', 'c0000000-0000-4000-8000-000000000040', 'c0000000-0000-4000-8000-000000000050', 'c0000000-0000-4000-8000-000000000051', 'car', 200.00, 'XXX', 'field_verified', 0.900, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000070', 'c0000000-0000-4000-8000-000000000040', 'c0000000-0000-4000-8000-000000000051', 'c0000000-0000-4000-8000-000000000052', 'car', 200.00, 'XXX', 'candidate', 0.300, 'c0000000-0000-4000-8000-000000000020');

-- Route R2 — TS-GRAPH-02
insert into parks (id, city_id, name, location, source_id) values
  ('c0000000-0000-4000-8000-000000000032', 'c0000000-0000-4000-8000-000000000002', 'R2 Origin', st_setsrid(st_makepoint(7.41, 9.06), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000033', 'c0000000-0000-4000-8000-000000000002', 'R2 Destination', st_setsrid(st_makepoint(7.46, 9.11), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id)
values ('c0000000-0000-4000-8000-000000000041', 'c0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000032', 'c0000000-0000-4000-8000-000000000033', 'car', 'c0000000-0000-4000-8000-000000000020');

insert into route_stages (id, route_id, sequence, location, source_id) values
  ('c0000000-0000-4000-8000-000000000053', 'c0000000-0000-4000-8000-000000000041', 1, st_setsrid(st_makepoint(7.41, 9.06), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000054', 'c0000000-0000-4000-8000-000000000041', 2, st_setsrid(st_makepoint(7.43, 9.08), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000055', 'c0000000-0000-4000-8000-000000000041', 3, st_setsrid(st_makepoint(7.46, 9.11), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into route_legs (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, verification_status, confidence_score, source_id) values
  ('c0000000-0000-4000-8000-000000000061', 'c0000000-0000-4000-8000-000000000041', 'c0000000-0000-4000-8000-000000000053', 'c0000000-0000-4000-8000-000000000054', 'car', 200.00, 'XXX', 'field_verified', 0.900, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000071', 'c0000000-0000-4000-8000-000000000041', 'c0000000-0000-4000-8000-000000000054', 'c0000000-0000-4000-8000-000000000055', 'car', 200.00, 'XXX', 'candidate', 0.300, 'c0000000-0000-4000-8000-000000000020');

-- Route R3 — TS-GRAPH-03
insert into parks (id, city_id, name, location, source_id) values
  ('c0000000-0000-4000-8000-000000000034', 'c0000000-0000-4000-8000-000000000002', 'R3 Origin', st_setsrid(st_makepoint(7.42, 9.07), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000035', 'c0000000-0000-4000-8000-000000000002', 'R3 Destination', st_setsrid(st_makepoint(7.47, 9.12), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id)
values ('c0000000-0000-4000-8000-000000000042', 'c0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000034', 'c0000000-0000-4000-8000-000000000035', 'car', 'c0000000-0000-4000-8000-000000000020');

insert into route_stages (id, route_id, sequence, location, source_id) values
  ('c0000000-0000-4000-8000-000000000056', 'c0000000-0000-4000-8000-000000000042', 1, st_setsrid(st_makepoint(7.42, 9.07), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000057', 'c0000000-0000-4000-8000-000000000042', 2, st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000058', 'c0000000-0000-4000-8000-000000000042', 3, st_setsrid(st_makepoint(7.47, 9.12), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into route_legs (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, verification_status, confidence_score, source_id) values
  ('c0000000-0000-4000-8000-000000000062', 'c0000000-0000-4000-8000-000000000042', 'c0000000-0000-4000-8000-000000000056', 'c0000000-0000-4000-8000-000000000057', 'car', 200.00, 'XXX', 'field_verified', 0.900, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000072', 'c0000000-0000-4000-8000-000000000042', 'c0000000-0000-4000-8000-000000000057', 'c0000000-0000-4000-8000-000000000058', 'car', 200.00, 'XXX', 'candidate', 0.300, 'c0000000-0000-4000-8000-000000000020');

-- Route R4 — TS-GRAPH-04 (outlier)
insert into parks (id, city_id, name, location, source_id) values
  ('c0000000-0000-4000-8000-000000000036', 'c0000000-0000-4000-8000-000000000002', 'R4 Origin', st_setsrid(st_makepoint(7.43, 9.08), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000037', 'c0000000-0000-4000-8000-000000000002', 'R4 Destination', st_setsrid(st_makepoint(7.48, 9.13), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id)
values ('c0000000-0000-4000-8000-000000000043', 'c0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000036', 'c0000000-0000-4000-8000-000000000037', 'car', 'c0000000-0000-4000-8000-000000000020');

insert into route_stages (id, route_id, sequence, location, source_id) values
  ('c0000000-0000-4000-8000-000000000059', 'c0000000-0000-4000-8000-000000000043', 1, st_setsrid(st_makepoint(7.43, 9.08), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-0000000000a0', 'c0000000-0000-4000-8000-000000000043', 2, st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-0000000000a1', 'c0000000-0000-4000-8000-000000000043', 3, st_setsrid(st_makepoint(7.48, 9.13), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into route_legs (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, verification_status, confidence_score, source_id) values
  ('c0000000-0000-4000-8000-000000000063', 'c0000000-0000-4000-8000-000000000043', 'c0000000-0000-4000-8000-000000000059', 'c0000000-0000-4000-8000-0000000000a0', 'car', 200.00, 'XXX', 'field_verified', 0.900, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000073', 'c0000000-0000-4000-8000-000000000043', 'c0000000-0000-4000-8000-0000000000a0', 'c0000000-0000-4000-8000-0000000000a1', 'car', 200.00, 'XXX', 'candidate', 0.300, 'c0000000-0000-4000-8000-000000000020');

-- Route R5 — TS-GRAPH-05 (decay)
insert into parks (id, city_id, name, location, source_id) values
  ('c0000000-0000-4000-8000-000000000038', 'c0000000-0000-4000-8000-000000000002', 'R5 Origin', st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-000000000039', 'c0000000-0000-4000-8000-000000000002', 'R5 Destination', st_setsrid(st_makepoint(7.49, 9.14), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id)
values ('c0000000-0000-4000-8000-000000000044', 'c0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000038', 'c0000000-0000-4000-8000-000000000039', 'car', 'c0000000-0000-4000-8000-000000000020');

insert into route_stages (id, route_id, sequence, location, source_id) values
  ('c0000000-0000-4000-8000-0000000000b0', 'c0000000-0000-4000-8000-000000000044', 1, st_setsrid(st_makepoint(7.44, 9.09), 4326)::geography, 'c0000000-0000-4000-8000-000000000020'),
  ('c0000000-0000-4000-8000-0000000000b1', 'c0000000-0000-4000-8000-000000000044', 2, st_setsrid(st_makepoint(7.49, 9.14), 4326)::geography, 'c0000000-0000-4000-8000-000000000020');

insert into route_legs (id, route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, verification_status, confidence_score, fare_last_verified_at, source_id) values
  ('c0000000-0000-4000-8000-000000000074', 'c0000000-0000-4000-8000-000000000044', 'c0000000-0000-4000-8000-0000000000b0', 'c0000000-0000-4000-8000-0000000000b1', 'car', 200.00, 'XXX', 'crowd_verified', 0.550, now() - interval '91 days', 'c0000000-0000-4000-8000-000000000020');

-- Riders
insert into auth.users (id, aud, role, phone, created_at) values
  ('c0000000-0000-4000-8000-000000000101', 'authenticated', 'authenticated', '+2348000000101', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000102', 'authenticated', 'authenticated', '+2348000000102', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000103', 'authenticated', 'authenticated', '+2348000000103', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000104', 'authenticated', 'authenticated', '+2348000000104', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000105', 'authenticated', 'authenticated', '+2348000000105', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000106', 'authenticated', 'authenticated', '+2348000000106', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000107', 'authenticated', 'authenticated', '+2348000000107', now() - interval '30 days'),
  ('c0000000-0000-4000-8000-000000000108', 'authenticated', 'authenticated', '+2348000000108', now() - interval '30 days');

insert into riders (id, home_city_id, trip_count, account_trust_weight) values
  ('c0000000-0000-4000-8000-000000000101', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000102', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000103', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000104', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000105', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000106', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000107', 'c0000000-0000-4000-8000-000000000002', 20, 1.000),
  ('c0000000-0000-4000-8000-000000000108', 'c0000000-0000-4000-8000-000000000002', 20, 1.000);

insert into device_installs (profile_id, install_id) values
  ('c0000000-0000-4000-8000-000000000105', 'd0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000106', 'd0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000107', 'd0000000-0000-4000-8000-000000000001');

-- TS-GRAPH-01
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000070', '{"fare": 200}'::jsonb, null, 'c0000000-0000-4000-8000-000000000101', 'rider');
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000070', '{"fare": 210}'::jsonb, null, 'c0000000-0000-4000-8000-000000000102', 'rider');
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000070', '{"fare": 190}'::jsonb, null, 'c0000000-0000-4000-8000-000000000103', 'rider');
select promote_candidates();

select is(
  (select verification_status::text from route_legs where id = 'c0000000-0000-4000-8000-000000000070'),
  'crowd_verified',
  'TS-GRAPH-01: 3 trusted riders promote leg to crowd_verified'
);

select ok(
  exists (
    select 1 from graph_revisions
    where target_type = 'route_legs' and target_id = 'c0000000-0000-4000-8000-000000000070' and reason = 'promotion'
  ),
  'TS-GRAPH-01: promotion revision written'
);

-- TS-GRAPH-02
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000071', '{"fare": 200}'::jsonb, null, 'c0000000-0000-4000-8000-000000000104', 'rider');

select throws_ok(
  $$ select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000071', '{"fare": 200}'::jsonb, null, 'c0000000-0000-4000-8000-000000000104', 'rider') $$,
  '23505', null,
  'TS-GRAPH-02: duplicate confirmation rejected (only one per account)'
);

select promote_candidates();

select is(
  (select verification_status::text from route_legs where id = 'c0000000-0000-4000-8000-000000000071'),
  'candidate',
  'TS-GRAPH-02: single account cannot promote (stays candidate)'
);

select is(
  (select count(*)::int from graph_confirmations where target_id = 'c0000000-0000-4000-8000-000000000071'),
  1,
  'TS-GRAPH-02: only one confirmation row for repeated account'
);

-- TS-GRAPH-03
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000072', '{"fare": 200}'::jsonb, null, 'c0000000-0000-4000-8000-000000000105', 'rider');
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000072', '{"fare": 200}'::jsonb, null, 'c0000000-0000-4000-8000-000000000106', 'rider');
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000072', '{"fare": 200}'::jsonb, null, 'c0000000-0000-4000-8000-000000000107', 'rider');
select promote_candidates();

select is(
  (select verification_status::text from route_legs where id = 'c0000000-0000-4000-8000-000000000072'),
  'candidate',
  'TS-GRAPH-03: colluding accounts stay candidate'
);

select is(
  (select round(sum(trust_weight)::numeric, 3) from graph_confirmations where target_id = 'c0000000-0000-4000-8000-000000000072'),
  0.750,
  'TS-GRAPH-03: colluding weight totals 3 × 0.25 = 0.75'
);

-- TS-GRAPH-04
select confirm_graph_value('route_leg', 'c0000000-0000-4000-8000-000000000073', '{"fare": 800}'::jsonb, null, 'c0000000-0000-4000-8000-000000000108', 'rider');

select ok(
  (select coalesce(meta->>'outlier', 'false') from graph_confirmations where target_id = 'c0000000-0000-4000-8000-000000000073') = 'true',
  'TS-GRAPH-04: outlier confirmation flagged in meta'
);

select ok(
  exists (
    select 1 from fare_corrections
    where route_leg_id = 'c0000000-0000-4000-8000-000000000073' and status = 'pending' and proposed_fare = 800.00
  ),
  'TS-GRAPH-04: fare_corrections review row enqueued'
);

select promote_candidates();

select is(
  (select verification_status::text from route_legs where id = 'c0000000-0000-4000-8000-000000000073'),
  'candidate',
  'TS-GRAPH-04: outlier excluded from promotion'
);

-- TS-GRAPH-05
select decay_confidence();

select is(
  (select confidence_score from route_legs where id = 'c0000000-0000-4000-8000-000000000074'),
  0.400,
  'TS-GRAPH-05: confidence drops 0.15 after 91 days without confirmation'
);

select is(
  (select verification_status::text from route_legs where id = 'c0000000-0000-4000-8000-000000000074'),
  'candidate',
  'TS-GRAPH-05: decay below 0.5 sets candidate status'
);

select * from finish();
rollback;
