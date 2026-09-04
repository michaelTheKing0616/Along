-- pgTAP: two-scout field reconciliation (doc 10 TS-GRAPH-07, P0-A-07)
create extension if not exists pgtap;

begin;
select plan(8);

insert into deployments (id, tenant_name)
values ('e0000000-0000-4000-8000-000000000001', 'Field Test Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('XF', 'Field Test Country', 'NGN', '₦', '+997', 'UTC', 'e0000000-0000-4000-8000-000000000001', true);

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'e0000000-0000-4000-8000-000000000002',
  'XF',
  'Field Test City',
  'field-test-city',
  st_setsrid(st_makepoint(7.40, 9.05), 4326)::geography,
  'live'
);

insert into auth.users (id, aud, role, phone) values
  ('e0000000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000000010'),
  ('e0000000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000000011'),
  ('e0000000-0000-4000-8000-000000000012', 'authenticated', 'authenticated', '+2348000000012');

insert into admin_users (id, role, city_scope)
values ('e0000000-0000-4000-8000-000000000012', 'ops_agent', array['e0000000-0000-4000-8000-000000000002']::uuid[]);

insert into field_agents (id, city_id) values
  ('e0000000-0000-4000-8000-000000000010', 'e0000000-0000-4000-8000-000000000002'),
  ('e0000000-0000-4000-8000-000000000011', 'e0000000-0000-4000-8000-000000000002');

insert into field_submissions (
  id, city_id, scout_profile_id, form_id, form_version, submission_uid,
  payload, entity_type, entity_key, submitted_at
) values
  (
    'e0000000-0000-4000-8000-000000000020',
    'e0000000-0000-4000-8000-000000000002',
    'e0000000-0000-4000-8000-000000000010',
    'along_park_v1',
    '1',
    'scout-a-park-001',
    '{"name":"Scout Park","lat":9.05,"lng":7.40,"name_aliases":["Scout"]}'::jsonb,
    'park',
    'park:field-test-city:scout-park',
    now()
  ),
  (
    'e0000000-0000-4000-8000-000000000021',
    'e0000000-0000-4000-8000-000000000002',
    'e0000000-0000-4000-8000-000000000011',
    'along_park_v1',
    '1',
    'scout-b-park-001',
    '{"name":"Scout Park","lat":9.0501,"lng":7.4001,"name_aliases":["Scout"]}'::jsonb,
    'park',
    'park:field-test-city:scout-park',
    now()
  );

select reconcile_field_submission('e0000000-0000-4000-8000-000000000020');
select reconcile_field_submission('e0000000-0000-4000-8000-000000000021');

select set_config('request.jwt.claim.sub', 'e0000000-0000-4000-8000-000000000012', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

-- TS-GRAPH-07: publish blocked when awaiting_second
update field_reconciliations
set status = 'awaiting_second', submission_b = null, variance = null, published_target_id = null
where entity_key = 'park:field-test-city:scout-park';

select throws_ok(
  $$ select admin_publish_field_entity(
    (select id from field_reconciliations where entity_key = 'park:field-test-city:scout-park')
  ) $$,
  '22023',
  null,
  'TS-GRAPH-07: publish blocked when awaiting_second'
);

-- Restore matched reconciliation for publish tests
update field_reconciliations
set status = 'matched',
    submission_b = 'e0000000-0000-4000-8000-000000000021',
    variance = compute_field_variance(
      'e0000000-0000-4000-8000-000000000020',
      'e0000000-0000-4000-8000-000000000021'
    ),
    published_target_id = null
where entity_key = 'park:field-test-city:scout-park';

select admin_publish_field_entity(
  (select id from field_reconciliations where entity_key = 'park:field-test-city:scout-park')
);

select is(
  (
    select p.verification_status::text
    from parks p
    join field_reconciliations fr on fr.published_target_id = p.id
    where fr.entity_key = 'park:field-test-city:scout-park'
  ),
  'field_verified',
  'TS-GRAPH-07: matched reconciliation publishes field_verified park'
);

select ok(
  exists (
    select 1
    from parks p
    join field_reconciliations fr on fr.published_target_id = p.id
    join data_sources ds on ds.id = p.source_id
    where fr.entity_key = 'park:field-test-city:scout-park'
      and ds.source_type = 'field_agent'
      and ds.field_submission_id = 'e0000000-0000-4000-8000-000000000020'
  ),
  'TS-GRAPH-07: published park carries field_agent provenance via data_sources'
);

-- Second reconciliation for resolved-path test
insert into field_submissions (
  id, city_id, scout_profile_id, form_id, form_version, submission_uid,
  payload, entity_type, entity_key, submitted_at
) values
  (
    'e0000000-0000-4000-8000-000000000030',
    'e0000000-0000-4000-8000-000000000002',
    'e0000000-0000-4000-8000-000000000010',
    'along_park_v1',
    '1',
    'scout-a-park-002',
    '{"name":"Resolved Park","lat":9.06,"lng":7.41}'::jsonb,
    'park',
    'park:field-test-city:resolved-park',
    now()
  ),
  (
    'e0000000-0000-4000-8000-000000000031',
    'e0000000-0000-4000-8000-000000000002',
    'e0000000-0000-4000-8000-000000000011',
    'along_park_v1',
    '1',
    'scout-b-park-002',
    '{"name":"Resolved Park Far","lat":9.10,"lng":7.50}'::jsonb,
    'park',
    'park:field-test-city:resolved-park',
    now()
  );

select reconcile_field_submission('e0000000-0000-4000-8000-000000000030');
select reconcile_field_submission('e0000000-0000-4000-8000-000000000031');

select is(
  (select status from field_reconciliations where entity_key = 'park:field-test-city:resolved-park'),
  'discrepant',
  'TS-GRAPH-07: far-apart scouts produce discrepant reconciliation'
);

select admin_reconcile_field_entity(
  (select id from field_reconciliations where entity_key = 'park:field-test-city:resolved-park'),
  'resolve',
  '{"payload":{"name":"Resolved Park","lat":9.06,"lng":7.41,"name_aliases":[]}}'::jsonb
);

select is(
  (select status from field_reconciliations where entity_key = 'park:field-test-city:resolved-park'),
  'resolved',
  'TS-GRAPH-07: admin resolve sets status resolved'
);

select admin_publish_field_entity(
  (select id from field_reconciliations where entity_key = 'park:field-test-city:resolved-park')
);

select is(
  (
    select p.verification_status::text
    from parks p
    join field_reconciliations fr on fr.published_target_id = p.id
    where fr.entity_key = 'park:field-test-city:resolved-park'
  ),
  'field_verified',
  'TS-GRAPH-07: resolved reconciliation publishes field_verified park'
);

select ok(
  exists (
    select 1
    from parks p
    join field_reconciliations fr on fr.published_target_id = p.id
    join data_sources ds on ds.id = p.source_id
    where fr.entity_key = 'park:field-test-city:resolved-park'
      and ds.source_type = 'field_agent'
      and ds.field_submission_id is not null
      and p.verified_by = 'e0000000-0000-4000-8000-000000000012'::uuid
  ),
  'TS-GRAPH-07: resolved publish row has verifier + submission provenance'
);

select is(
  (
    select p.confidence_score::text
    from parks p
    join field_reconciliations fr on fr.published_target_id = p.id
    where fr.entity_key = 'park:field-test-city:scout-park'
  ),
  '0.950',
  'TS-GRAPH-07: field publish sets confidence_score 0.950'
);

select * from finish();
rollback;
