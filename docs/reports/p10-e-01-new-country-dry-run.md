# P10-E-01 — New Country Checklist Dry Run Report

**Task:** P10-E-01 — "New country checklist" doc + dry run against a hypothetical country in review  
**Branch:** `task/p10-e-01`  
**Date:** 2026-09-07  
**Hypothetical country:** `GH` / **Ghana-Review** (`active=false` — not a live market)

## Summary

Dry-ran standing up **Ghana-Review** using **config/data RPCs and CLI only** — `admin_upsert_country`, `admin_set_country_schema`, and `import:city` fixture `city_ghana_review`. Verified `payments.digital_enabled` remains **false** and no application-code fork was required. Human ops sign-off remains **DEFERRED**.

## Commands

```bash
# Apply markets RPC migration (once, if not already on target DB)
psql "$DATABASE_URL" -f backend/db/migrations/00000000000078_admin_markets_country_rpc.sql

# Full dry-run (country RPCs + import:city preview; restores active=false)
docs/reports/p10-e-01-ghana-review-apply.sh

# Optional apply path (review DB only — temporarily activates GH for city create)
APPLY=1 docs/reports/p10-e-01-ghana-review-apply.sh

# Payload unit tests (no DB)
cd admin-console && npm test -- src/lib/markets/payload.test.ts
```

**Local DB used:** `postgresql://postgres:postgres@127.0.0.1:54322/postgres`

## RPC payloads (config-only)

### `admin_upsert_country`

```json
{
  "p_code": "GH",
  "p_name": "Ghana-Review",
  "p_currency_code": "GHS",
  "p_currency_symbol": "₵",
  "p_currency_minor_units": 2,
  "p_phone_prefix": "+233",
  "p_default_locale": "en-GH",
  "p_timezone": "Africa/Accra",
  "p_deployment_id": "a0000000-0000-4000-8000-000000000001",
  "p_regulatory_flags": { "women_only_matching": false },
  "p_active": false,
  "p_payment_provider": "paystack"
}
```

### `admin_set_country_schema`

```json
{
  "p_code": "GH",
  "p_verification_schema": [
    {
      "type": "ghana_card",
      "label": "Ghana Card",
      "pattern": "^.{5,}$",
      "provider": "verifyme"
    }
  ]
}
```

### `import:city` fixture (`city_ghana_review/manifest.json`)

```json
{
  "city": {
    "name": "Accra-Review",
    "slug": "accra-review",
    "country_code": "GH",
    "state_region": "Greater Accra (review fixture — not live ops)",
    "status": "alpha",
    "centroid": { "lat": 5.603, "lng": -0.187 }
  },
  "corridor": {
    "name": "Review Corridor Osu–Airport",
    "slug": "osu-airport-review"
  },
  "config_overrides": {
    "commission.rate": 0.05,
    "graph.snap_radius_m": 45,
    "graph.stage_merge_radius_m": 35
  }
}
```

## Results

| Step | Command / RPC | Result |
|---|---|---|
| Country row | `admin_upsert_country` | **PASS** — `GH` / Ghana-Review, `active=false`, GHS/₵/+233/en-GH/Africa/Accra |
| Verification schema | `admin_set_country_schema` | **PASS** — `ghana_card` → verifyme |
| Regulatory flags | via upsert | **PASS** — `women_only_matching: false` |
| Payment provider | via upsert → `admin_set_config` | **PASS** — `payments.provider` = `paystack` scoped to `GH` |
| `digital_enabled` gate | SQL verify | **PASS** — global `false`; not toggled |
| First city dry-run | `import:city --dry-run` | **PASS** — city `action: create` for `accra-review` (requires brief `active=true` flip; restored to `false`) |
| Payload tests | `payload.test.ts` | **PASS** (3/3) |

### `admin_upsert_country` response (excerpt)

```json
{
  "code": "GH",
  "name": "Ghana-Review",
  "active": false,
  "currency_code": "GHS",
  "currency_symbol": "₵",
  "phone_prefix": "+233",
  "default_locale": "en-GH",
  "timezone": "Africa/Accra",
  "payment_provider": "paystack",
  "regulatory_flags": { "women_only_matching": false }
}
```

### `import:city` dry-run response (excerpt)

```json
{
  "city_slug": "accra-review",
  "corridor_slug": "osu-airport-review",
  "dry_run": true,
  "city": { "action": "create", "dry_run": true }
}
```

## Zero application-code fork evidence

| Check | Evidence |
|---|---|
| No `GH`-specific branches in apps | `rg 'country == .GH|Ghana-Review' **/*.{ts,tsx,dart}` → **0 matches** in application code |
| Country upsert payload keys | `COUNTRY_UPSERT_RPC_KEYS` only — `assertConfigOnlyPayload` passes (`payload.test.ts`) |
| Existing RPC/CLI paths reused | `admin_upsert_country` (00078), `admin_set_country_schema` (00078), `admin_create_city` (00074), `import:city` CLI |
| Branding / i18n | Read existing `deployments.branding_config`; `en-GH` shows 0% i18n coverage on **A-18** until pack ships (documented, not coded) |
| `digital_enabled` | Remains global `false`; RPC is read-only on **A-09** |

## i18n coverage note

`buildI18nCoverage(['en-GH'])` returns 0% — no `en-GH` locale pack yet. Base `en`/`en-NG` at 100%. Gap recorded on checklist; not a blocker for review fixture.

## Explicitly not done

- Human ops sign-off on **A-18** walkthrough (**DEFERRED** — do not invent PASS)
- `active=true` for production go-live
- `payments.digital_enabled=true`
- Live VerifyMe API integration
- Locale pack for `en-GH`

## Artifacts

| Artifact | Path |
|---|---|
| Runbook | `docs/runbooks/new_country_checklist.md` |
| Apply script | `docs/reports/p10-e-01-ghana-review-apply.sh` |
| City fixture | `data-collection/fixtures/city_ghana_review/` |
| Runbooks index | `docs/runbooks/README.md` (linked) |

## Related tasks

- P10-D-01 — A-18 Markets RPCs (`00078`)
- P10-A-01 — tenant portability dry run
- P10-B-01 — branding + locale packs
