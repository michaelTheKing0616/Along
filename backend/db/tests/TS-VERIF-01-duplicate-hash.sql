-- pgTAP: P1-A-09 — verification RPCs, duplicate identity hash (doc 10 TS-PRES-03 retained elsewhere)
create extension if not exists pgtap;

begin;
select plan(8);

\ir ../seed/seed_testcity_fixture/00_zaria_test.sql

select set_config('app.settings.identity_hash_pepper', 'along-test-pepper-do-not-commit', true);

insert into auth.users (id, aud, role, phone) values
  ('0a100000-0000-4000-8000-000000000010', 'authenticated', 'authenticated', '+2348000001010'),
  ('0a100000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', '+2348000001011'),
  ('0a100000-0000-4000-8000-000000000012', 'authenticated', 'authenticated', '+2348000001012'),
  ('b0000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', '+2348000001999')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code) values
  ('0a100000-0000-4000-8000-000000000010', '0a000000-0000-4000-8000-000000000001', 'unverified', 'good_standing', 'TSTVR010'),
  ('0a100000-0000-4000-8000-000000000011', '0a000000-0000-4000-8000-000000000001', 'unverified', 'good_standing', 'TSTVR011')
on conflict (id) do update set verified_status = excluded.verified_status;

insert into admin_users (id, role, deployment_id) values
  ('b0000000-0000-4000-8000-000000000002', 'verifier', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, disabled_at = null;

-- register_vehicle
select set_config('request.jwt.claim.sub', '0a100000-0000-4000-8000-000000000010', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select ok(
  (register_vehicle('keke', 'ABC-123-XY', 3::smallint, true)->>'vehicle_id') is not null,
  'register_vehicle returns vehicle_id'
);

select ok(
  exists (
    select 1
    from driver_vehicles dv
    join vehicles v on v.id = dv.vehicle_id
    where dv.driver_id = '0a100000-0000-4000-8000-000000000010'
      and dv.active
      and v.plate_number = 'ABC-123-XY'
  ),
  'register_vehicle links active vehicle to driver'
);

-- submit_verification rejects raw ID in client hint
select throws_ok(
  $$ select submit_verification(
    'nin',
    '0a100000-0000-4000-8000-000000000010/nin/front.jpg',
    null,
    '{"id_number":"12345678901"}'
  ) $$,
  'P0001',
  'VALIDATION',
  'submit_verification rejects client id_number hint'
);

-- submit_verification creates pending row
select ok(
  (submit_verification(
    'nin',
    '0a100000-0000-4000-8000-000000000010/nin/front.jpg'
  )->>'verification_id') is not null,
  'submit_verification creates verification row'
);

select ok(
  (select verified_status::text from drivers where id = '0a100000-0000-4000-8000-000000000010') = 'pending',
  'submit_verification moves driver to pending'
);

-- my_verifications returns status-only rows
select ok(
  jsonb_array_length(my_verifications()) >= 1,
  'my_verifications returns submitted docs'
);

set local role postgres;

create temp table verif_hash_ctx (
  verification_a uuid,
  verification_b uuid
);

insert into verif_hash_ctx (verification_a)
select id
from driver_verifications
where driver_id = '0a100000-0000-4000-8000-000000000010'
  and document_type = 'nin'
order by submitted_at desc
limit 1;

update driver_verifications
set ocr_extract = jsonb_build_object(
  'hints', jsonb_build_object('full_name', 'Driver A'),
  'id_hash', encode(
    compute_identity_hash('nin', '12345678901'),
    'base64'
  )
)
where id = (select verification_a from verif_hash_ctx);

insert into driver_verifications (
  driver_id, country_code, document_type, status, storage_path, ocr_extract
) values (
  '0a100000-0000-4000-8000-000000000011',
  'NG',
  'nin',
  'pending',
  '0a100000-0000-4000-8000-000000000011/nin/front.jpg',
  jsonb_build_object(
    'hints', jsonb_build_object('full_name', 'Driver B'),
    'id_hash', encode(
      compute_identity_hash('nin', '12345678901'),
      'base64'
    )
  )
);

update verif_hash_ctx
set verification_b = (
  select id
  from driver_verifications
  where driver_id = '0a100000-0000-4000-8000-000000000011'
    and document_type = 'nin'
  order by submitted_at desc
  limit 1
);

grant select on verif_hash_ctx to authenticated;

select set_config('request.jwt.claim.sub', 'b0000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

select lives_ok(
  format(
    'select admin_approve_verification(%L::uuid)',
    (select verification_a from verif_hash_ctx)
  ),
  'admin_approve_verification succeeds for first driver'
);

select throws_ok(
  format(
    'select admin_approve_verification(%L::uuid)',
    (select verification_b from verif_hash_ctx)
  ),
  'P0001',
  'DUPLICATE_IDENTITY',
  'duplicate identity hash detected on second approval'
);

select * from finish();
rollback;
