# P10-A-01 — Second Tenant Dry Run Report

**Task:** P10-A-01 — deployment tenant isolation + portability foundations  
**Branch:** `task/p10-a-01`  
**Date:** 2026-09-07  
**Second tenant:** `along-tenant-b` (fictional Ghana fixture — tests and dry run only)

## Summary

Dry-ran standing up a **second deployment tenant** (`along-tenant-b`) with its own country, city, verification schema, and scoped config **using SQL/RPC tooling only** — no application-code fork. Verified RLS blocks cross-tenant reads once a user belongs to tenant A (`TS-TENANT-01`).

## Steps (local)

```bash
# Apply migration (once)
psql "$DATABASE_URL" -f backend/db/migrations/00000000000077_domain_tenancy_verification_provider.sql

# Create second tenant (SQL — same shape as pgTAP fixture)
psql "$DATABASE_URL" <<'SQL'
insert into deployments (id, tenant_name, branding_config, region_config, active)
values (
  'e0000000-0000-4000-8000-000000000002',
  'along-tenant-b',
  '{"accent_token":"brand.accent.gh"}'::jsonb,
  '{"default_country":"TB"}'::jsonb,
  true
) on conflict (id) do nothing;

insert into countries (
  code, name, currency_code, currency_minor_units, currency_symbol,
  phone_prefix, default_locale, timezone, deployment_id,
  verification_schema, regulatory_flags, active
) values (
  'TB',
  'Tenant B Country',
  'GHS',
  2,
  '₵',
  '+233',
  'en-GH',
  'Africa/Accra',
  'e0000000-0000-4000-8000-000000000002',
  '[
    {"type":"nin","label":"Ghana Card","pattern":"^.{5,}$","provider":"verifyme"}
  ]'::jsonb,
  '{"women_only_matching": false}'::jsonb,
  true
) on conflict (code) do update set deployment_id = excluded.deployment_id;

select admin_create_city(
  p_country_code := 'TB',
  p_name := 'Tenant B City',
  p_slug := 'tenant-b-city',
  p_centroid_lat := 5.603,
  p_centroid_lng := -0.187,
  p_state_region := 'Greater Accra (fixture)',
  p_status := 'alpha',
  p_config_overrides := '{"commission.rate": 0.05}'::jsonb
);
SQL

# Tenant isolation gate
psql "$DATABASE_URL" -f backend/db/tests/TS-TENANT-01-cross-tenant-rls.sql
```

## What this proves

| Check | Evidence |
|---|---|
| Second tenant without code fork | Rows in `deployments` / `countries` / `cities` only; apps read via existing catalog + RLS |
| Verification provider pluggable | `countries.verification_schema[].provider` + `verification_doc_provider()` + stub adapter in `verification-ocr` |
| Currency from country | `countries.currency_code` / `currency_symbol` / `currency_minor_units`; `currencyMetaForCity()` in apps |
| Regulatory flags wired | `women_only_matching` gates request/hail (`TS-REG-01`) |
| Cross-tenant leakage blocked | `TS-TENANT-01`: tenant A SELECT on tenant B cities/drivers/trips/config → **0 rows** |

## Tooling / RPCs used

- `admin_create_city` (migration `00074`) — same as Kaduna-Pilot second-city path (P9-E-01)
- `verification_doc_provider(country, doc_type)` — new in migration `00077`
- `auth_user_deployment_id()` / `city_in_user_deployment()` — tenant RLS helpers in `00077`

## Explicitly not done

- A-18 Markets UI (P10-D-01)
- Locale packs / tenant branding in apps (P10-B-01 / P10-C-01)
- Live VerifyMe API integration (stub only; `verification.provider.verifyme.stub_mode=true`)
- `digital_enabled` not flipped

## Tests

| Test | Result |
|---|---|
| `data-collection/scripts/city_kaduna_pilot.test.ts` | PASS (5/5) |
| `TS-TENANT-01-cross-tenant-rls.sql` | PASS (8/8) |
| `TS-REG-01-women-only-regulatory.sql` | PASS (4/4) |
| `TS-VERIF-02-provider.sql` | PASS (2/2) |
| `backend/functions/_shared/verification/registry_test.ts` | PASS |
| `backend/functions/verification-ocr/handler_test.ts` | PASS |
