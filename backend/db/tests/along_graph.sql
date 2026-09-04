-- pgTAP: along-graph integrity (doc 02 §4, P0-A-03)
-- adjacency trigger, graph_revisions on update, unique confirmation per account
create extension if not exists pgtap;

begin;
select plan(6);

-- Fixtures
insert into deployments (id, tenant_name)
values ('b0000000-0000-4000-8000-000000000001', 'Graph Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XG', 'Graph Test Country', 'XXX', 'X', '+996', 'UTC', 'b0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'b0000000-0000-4000-8000-000000000002',
  'XG',
  'Graph Test City',
  'graph-test-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into auth.users (id, aud, role, phone) values
  ('b0000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000000010');

insert into data_sources (id, source_type)
values ('b0000000-0000-4000-8000-000000000020', 'admin');

insert into parks (id, city_id, name, location, source_id)
values
  (
    'b0000000-0000-4000-8000-000000000030',
    'b0000000-0000-4000-8000-000000000002',
    'Origin Park',
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    'b0000000-0000-4000-8000-000000000020'
  ),
  (
    'b0000000-0000-4000-8000-000000000031',
    'b0000000-0000-4000-8000-000000000002',
    'Destination Park',
    st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography,
    'b0000000-0000-4000-8000-000000000020'
  );

insert into routes (id, city_id, origin_park_id, destination_park_id, mode_code, source_id)
values (
  'b0000000-0000-4000-8000-000000000040',
  'b0000000-0000-4000-8000-000000000002',
  'b0000000-0000-4000-8000-000000000030',
  'b0000000-0000-4000-8000-000000000031',
  'car',
  'b0000000-0000-4000-8000-000000000020'
);

insert into route_stages (id, route_id, sequence, location, source_id) values
  (
    'b0000000-0000-4000-8000-000000000050',
    'b0000000-0000-4000-8000-000000000040',
    1,
    st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
    'b0000000-0000-4000-8000-000000000020'
  ),
  (
    'b0000000-0000-4000-8000-000000000051',
    'b0000000-0000-4000-8000-000000000040',
    2,
    st_setsrid(st_makepoint(7.42, 9.07), 4326)::geography,
    'b0000000-0000-4000-8000-000000000020'
  ),
  (
    'b0000000-0000-4000-8000-000000000052',
    'b0000000-0000-4000-8000-000000000040',
    3,
    st_setsrid(st_makepoint(7.45, 9.10), 4326)::geography,
    'b0000000-0000-4000-8000-000000000020'
  );

-- Valid adjacent leg succeeds
insert into route_legs (
  route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id
) values (
  'b0000000-0000-4000-8000-000000000040',
  'b0000000-0000-4000-8000-000000000050',
  'b0000000-0000-4000-8000-000000000051',
  'car',
  200.00,
  'XXX',
  'b0000000-0000-4000-8000-000000000020'
);

-- Non-adjacent leg (sequence 1 -> 3) must be rejected
select throws_ok(
  $$
    insert into route_legs (
      route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id
    ) values (
      'b0000000-0000-4000-8000-000000000040',
      'b0000000-0000-4000-8000-000000000050',
      'b0000000-0000-4000-8000-000000000052',
      'car',
      400.00,
      'XXX',
      'b0000000-0000-4000-8000-000000000020'
    )
  $$,
  '23514',
  'route_legs must connect adjacent stages (from.sequence + 1 = to.sequence); got 1 -> 3',
  'adjacency trigger rejects non-adjacent leg'
);

-- graph_revisions written on update
update parks
set name = 'Origin Park Updated'
where id = 'b0000000-0000-4000-8000-000000000030';

select ok(
  exists (
    select 1 from graph_revisions
    where target_type = 'parks'
      and target_id = 'b0000000-0000-4000-8000-000000000030'
      and before is not null
      and after is not null
      and (before->>'name') = 'Origin Park'
      and (after->>'name') = 'Origin Park Updated'
  ),
  'revision written on update'
);

-- unique confirmation per account
insert into graph_confirmations (
  target_type, target_id, confirmer_profile_id, confirmer_role,
  trust_weight, proposed_value, source_id
) values (
  'park',
  'b0000000-0000-4000-8000-000000000030',
  'b0000000-0000-4000-8000-000000000010',
  'rider',
  0.200,
  '{"verified": true}'::jsonb,
  'b0000000-0000-4000-8000-000000000020'
);

select throws_ok(
  $$
    insert into graph_confirmations (
      target_type, target_id, confirmer_profile_id, confirmer_role,
      trust_weight, proposed_value, source_id
    ) values (
      'park',
      'b0000000-0000-4000-8000-000000000030',
      'b0000000-0000-4000-8000-000000000010',
      'rider',
      0.200,
      '{"verified": true}'::jsonb,
      'b0000000-0000-4000-8000-000000000020'
    )
  $$,
  '23505',
  null,
  'unique confirmation per account'
);

-- route_through_fares order trigger: from.sequence must be < to.sequence
select throws_ok(
  $$
    insert into route_through_fares (
      route_id, from_stage_id, to_stage_id, mode_code, fare_amount, fare_currency, source_id
    ) values (
      'b0000000-0000-4000-8000-000000000040',
      'b0000000-0000-4000-8000-000000000052',
      'b0000000-0000-4000-8000-000000000050',
      'car',
      500.00,
      'XXX',
      'b0000000-0000-4000-8000-000000000020'
    )
  $$,
  '23514',
  'route_through_fares from_stage.sequence must be less than to_stage.sequence; got 3 >= 1',
  'route_through_fares order trigger rejects reversed stages'
);

-- transfer_points links a park to a route stage
insert into transfer_points (park_id, route_id, stage_id)
values (
  'b0000000-0000-4000-8000-000000000030',
  'b0000000-0000-4000-8000-000000000040',
  'b0000000-0000-4000-8000-000000000050'
);

select ok(
  exists (
    select 1 from transfer_points
    where park_id = 'b0000000-0000-4000-8000-000000000030'
      and route_id = 'b0000000-0000-4000-8000-000000000040'
  ),
  'transfer_points row links park to route stage'
);

-- fare_corrections accepts route_leg target
insert into fare_corrections (
  route_leg_id, submitted_by, submitter_role, proposed_fare, currency, source_id
)
select
  rl.id,
  'b0000000-0000-4000-8000-000000000010',
  'rider',
  250.00,
  'XXX',
  'b0000000-0000-4000-8000-000000000020'
from route_legs rl
where rl.route_id = 'b0000000-0000-4000-8000-000000000040'
limit 1;

select ok(
  exists (
    select 1 from fare_corrections
    where submitted_by = 'b0000000-0000-4000-8000-000000000010'
      and proposed_fare = 250.00
  ),
  'fare_corrections row created for route_leg'
);

select * from finish();
rollback;
