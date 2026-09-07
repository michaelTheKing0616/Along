-- pgTAP: verification_doc_provider resolves countries.verification_schema.provider (P10-A-01)
create extension if not exists pgtap;

begin;
select plan(2);

insert into deployments (id, tenant_name)
values ('f0000000-0000-4000-8000-000000000001', 'Verify Provider Test Tenant')
on conflict (id) do nothing;

insert into countries (
  code, name, currency_code, currency_symbol, phone_prefix, timezone,
  deployment_id, verification_schema, active
) values (
  'VP',
  'Verify Provider Country',
  'XXX',
  'X',
  '+998',
  'UTC',
  'f0000000-0000-4000-8000-000000000001',
  '[{"type":"passport","label":"Passport","pattern":"^.{5,}$","provider":"custom-stub"}]'::jsonb,
  true
) on conflict (code) do update set verification_schema = excluded.verification_schema;

select is(
  verification_doc_provider('NG', 'nin'),
  'verifyme',
  'verification_doc_provider returns verifyme for NG NIN'
);

select is(
  verification_doc_provider('VP', 'passport'),
  'custom-stub',
  'verification_doc_provider reads provider from country verification_schema'
);

select * from finish();
rollback;
