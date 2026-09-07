-- TS-CORRIDOR-01: Corridor bundle import via admin_import_dry_run / admin_import_apply (P7-E-01)
-- Requires seed_core.sql + seed_testcity_fixture/00_zaria_test.sql

begin;
select plan(6);

\set zaria_city '0a000000-0000-4000-8000-000000000001'

-- Simulate ops-agent admin (superadmin for local test)
select test_set_jwt(
  '0f000000-0000-4000-8000-000000000001'::uuid,
  'superadmin',
  null,
  '0e000000-0000-4000-8000-000000000001'::uuid
);

select is(
  (
    admin_import_dry_run(
      :'zaria_city'::uuid,
      jsonb_build_object(
        'kind', 'corridor',
        'corridor', jsonb_build_object('name', 'CLI Test Corridor', 'slug', 'cli-test-corridor'),
        'parks', jsonb_build_array(
          jsonb_build_object('name', 'CLI Park One', 'lat', 11.080, 'lng', 7.680, 'name_aliases', '[]'::jsonb)
        ),
        'routes', jsonb_build_array(
          jsonb_build_object(
            'origin_park', 'CLI Park One',
            'destination_park', 'Test Park Beta',
            'mode', 'car',
            'name', 'CLI Car Route'
          )
        ),
        'stages', jsonb_build_array(
          jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 1, 'stage_name', 'CLI Park One', 'lat', 11.080, 'lng', 7.680, 'is_official_park', true),
          jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 2, 'stage_name', 'CLI Mid Stop', 'lat', 11.082, 'lng', 7.682, 'is_official_park', false),
          jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 3, 'stage_name', 'Test Park Beta', 'lat', 11.065, 'lng', 7.705, 'is_official_park', true)
        ),
        'leg_fares', jsonb_build_array(
          jsonb_build_object('route_name', 'CLI Car Route', 'from_seq', 1, 'to_seq', 2, 'fare', 120),
          jsonb_build_object('route_name', 'CLI Car Route', 'from_seq', 2, 'to_seq', 3, 'fare', 120)
        ),
        'through_fares', '[]'::jsonb
      )::text
    )->>'kind'
  ),
  'corridor',
  'dry-run returns corridor kind'
);

select ok(
  jsonb_array_length(
    (admin_import_dry_run(
      :'zaria_city'::uuid,
      jsonb_build_object(
        'kind', 'corridor',
        'corridor', jsonb_build_object('name', 'CLI Test Corridor', 'slug', 'cli-test-corridor'),
        'parks', jsonb_build_array(
          jsonb_build_object('name', 'CLI Park One', 'lat', 11.080, 'lng', 7.680, 'name_aliases', '[]'::jsonb)
        ),
        'routes', jsonb_build_array(
          jsonb_build_object(
            'origin_park', 'CLI Park One',
            'destination_park', 'Test Park Beta',
            'mode', 'car',
            'name', 'CLI Car Route'
          )
        ),
        'stages', jsonb_build_array(
          jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 1, 'stage_name', 'CLI Park One', 'lat', 11.080, 'lng', 7.680, 'is_official_park', true),
          jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 2, 'stage_name', 'CLI Mid Stop', 'lat', 11.082, 'lng', 7.682, 'is_official_park', false),
          jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 3, 'stage_name', 'Test Park Beta', 'lat', 11.065, 'lng', 7.705, 'is_official_park', true)
        ),
        'leg_fares', jsonb_build_array(
          jsonb_build_object('route_name', 'CLI Car Route', 'from_seq', 1, 'to_seq', 2, 'fare', 120),
          jsonb_build_object('route_name', 'CLI Car Route', 'from_seq', 2, 'to_seq', 3, 'fare', 120)
        ),
        'through_fares', '[]'::jsonb
      )::text
    )->'diff')
  ) >= 5,
  'dry-run diff includes corridor + graph entities'
);

with dry as (
  select admin_import_dry_run(
    :'zaria_city'::uuid,
    jsonb_build_object(
      'kind', 'corridor',
      'corridor', jsonb_build_object('name', 'CLI Test Corridor', 'slug', 'cli-test-corridor'),
      'parks', jsonb_build_array(
        jsonb_build_object('name', 'CLI Park One', 'lat', 11.080, 'lng', 7.680, 'name_aliases', '[]'::jsonb)
      ),
      'routes', jsonb_build_array(
        jsonb_build_object(
          'origin_park', 'CLI Park One',
          'destination_park', 'Test Park Beta',
          'mode', 'car',
          'name', 'CLI Car Route'
        )
      ),
      'stages', jsonb_build_array(
        jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 1, 'stage_name', 'CLI Park One', 'lat', 11.080, 'lng', 7.680, 'is_official_park', true),
        jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 2, 'stage_name', 'CLI Mid Stop', 'lat', 11.082, 'lng', 7.682, 'is_official_park', false),
        jsonb_build_object('route_name', 'CLI Car Route', 'sequence', 3, 'stage_name', 'Test Park Beta', 'lat', 11.065, 'lng', 7.705, 'is_official_park', true)
      ),
      'leg_fares', jsonb_build_array(
        jsonb_build_object('route_name', 'CLI Car Route', 'from_seq', 1, 'to_seq', 2, 'fare', 120),
        jsonb_build_object('route_name', 'CLI Car Route', 'from_seq', 2, 'to_seq', 3, 'fare', 120)
      ),
      'through_fares', '[]'::jsonb
    )::text
  ) as result
),
applied as (
  select admin_import_apply(
    :'zaria_city'::uuid,
    (select result->'diff' from dry)
  ) as result
)
select ok(
  ((select result->>'created' from applied)::int) >= 5,
  'apply creates corridor backbone rows'
);

select ok(
  exists (
    select 1 from corridors c
    where c.city_id = :'zaria_city'::uuid
      and c.slug = 'cli-test-corridor'
  ),
  'corridor row exists after apply'
);

select ok(
  exists (
    select 1
    from routes r
    join corridors c on c.id = r.corridor_id
    where c.slug = 'cli-test-corridor'
      and r.name = 'CLI Car Route'
  ),
  'route linked to new corridor'
);

select cmp_ok(
  (
    select count(*)::int
    from route_legs rl
    join routes r on r.id = rl.route_id
    join corridors c on c.id = r.corridor_id
    where c.slug = 'cli-test-corridor'
  ),
  '>=',
  2,
  'leg fares created for corridor route'
);

select * from finish();
rollback;
