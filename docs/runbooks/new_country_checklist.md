# New Country Checklist

**Owner:** Ops lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a

## When to use
Ops or engineering is standing up a **new country market in review** — country catalog row, verification schema, regulatory flags, payment provider, locale/currency metadata, tenant branding review, i18n gap assessment, and the **first pilot city** — using admin-console **A-18** and data-collection CLI only. Do **not** fork application code, hand-insert graph rows, or flip `payments.digital_enabled`.

**Out of scope here:** activating a country for production (`active=true`), enabling digital payments, live VerifyMe integration, or human ops sign-off rows (those remain **DEFERRED** until review completes).

## Preconditions & access
- Role: `ops_lead` or `superadmin` for **A-18** Markets and city deploy.
- Consoles:
  - **A-18** — `/{city}/markets` (countries, verification schema, regulatory flags, i18n coverage, payment provider)
  - **A-08** — `/{city}/deploy` (first city + corridor after country exists)
  - **A-09** — `/{city}/config` (city overrides; `payments.digital_enabled` read-only)
- `seed_core.sql` applied (active `NG` deployment baseline).
- Migration `00078` applied (`admin_upsert_country`, `admin_set_country_schema`).
- Hypothetical review fixture: `GH` / **Ghana-Review** (`active=false`) — not a live market.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| P1 | Country row missing currency/locale/tz after upsert | Block checklist; re-run **A-18** country save or `admin_upsert_country` |
| P2 | First city import fails (country inactive) | Expected for review — use `import:city` with `--dry-run`; apply only when country code exists |
| P3 | i18n coverage 0% for new locale (e.g. `en-GH`) | Document gap on **A-18** i18n tab; do not block review fixture |
| P3 | Attempt to set `payments.digital_enabled=true` | **Stop** — read-only key; escalate to Phase 4 gate owner |

## Steps

### 1 — Country row (**A-18** Countries tab or RPC)
1. Open **A-18** (`/{any-city}/markets`) → **Countries**.
2. Prefill hypothetical **Ghana-Review** (code `GH`) or enter manually:
   - **Name:** `Ghana-Review` (review fixture — not live ops)
   - **Currency:** `GHS`, symbol `₵`, minor units `2`
   - **Phone prefix:** `+233`
   - **Default locale:** `en-GH`
   - **Timezone:** `Africa/Accra`
   - **Deployment:** active tenant (e.g. Along NG deployment id)
   - **Active:** **false** (review only)
   - **Payment provider:** `paystack` (country-scoped via `admin_set_config`)
3. Save → RPC `admin_upsert_country`.
4. **Expected:** country row in `countries`; `payments.provider` scoped to `GH`; no app redeploy.

**CLI equivalent** (local / CI):

```bash
docs/reports/p10-e-01-ghana-review-apply.sh          # dry-run RPCs + import:city --dry-run
APPLY=1 docs/reports/p10-e-01-ghana-review-apply.sh  # apply country + first city (review DB only)
```

### 2 — Verification schema (**A-18** Verification tab)
1. Select country `GH` → **Verification** tab.
2. Add document type row(s), e.g.:
   - type: `ghana_card`, label: `Ghana Card`, pattern: `^.{5,}$`, provider: `verifyme`
3. Save → RPC `admin_set_country_schema(p_code, p_verification_schema)`.
4. **Expected:** `countries.verification_schema` JSON array updated; OCR adapter resolves provider via existing registry (no new handler branch).

### 3 — Regulatory flags (**A-18** Regulatory tab)
1. Set `women_only_matching` per market policy (default **false** for Ghana-Review fixture).
2. Stored in `countries.regulatory_flags` via `admin_upsert_country` — config only.
3. **Expected:** request/hail gating reads flag via existing `TS-REG-01` path.

### 4 — Payment provider (**A-18** Payment tab)
1. Confirm country-scoped `payments.provider` (`paystack` | `flutterwave` | `none`).
2. Set during country upsert — **not** a separate code path.
3. **Do not** toggle `payments.digital_enabled` — remains **false** (global default; read-only on **A-09**).

### 5 — Currency / phone / locale / timezone (country row)
Verify on **A-18** Countries list or SQL:

| Field | Ghana-Review value |
|---|---|
| `currency_code` | `GHS` |
| `currency_symbol` | `₵` |
| `currency_minor_units` | `2` |
| `phone_prefix` | `+233` |
| `default_locale` | `en-GH` |
| `timezone` | `Africa/Accra` |

Apps format money and phone via existing catalog readers — no hardcoded ₦/NGN fork.

### 6 — Branding config (deployment row)
1. Review `deployments.branding_config` for the target tenant — token overrides only (e.g. `brand.yellow`).
2. Update via deployment admin if review requires distinct accent; apps read via `CatalogRepository.brandingConfigForCountry()`.
3. **Expected:** theme extension applies overrides; default palette when `{}`.

### 7 — i18n coverage (**A-18** i18n tab)
1. Open **i18n coverage** tab after country save.
2. **Expected for `en-GH`:** 0% until locale pack shipped (P10-B-01 packs: `ha`, `yo`, `ig`, `pcm`; base `en`/`en-NG` at 100%).
3. Record gap in review notes — do not invent translated strings in application code.

### 8 — First city via `import:city` (see `city_onboarding.md`)
1. Copy template: `data-collection/fixtures/city_ghana_review/`.
2. Edit `manifest.json`: `country_code: GH`, fictional slug `accra-review`, `status: alpha`.
3. Dry-run then apply (city import requires country `active=true` at RPC — script temporarily flips for preview, then restores `false`):

```bash
cd data-collection
npm run import:city -- --fixture fixtures/city_ghana_review --dry-run   # or use apply script below
docs/reports/p10-e-01-ghana-review-apply.sh                               # handles active flip + restore
```

4. **Expected:** `admin_create_city` + corridor import; graph rows `source_type=import`, `verification_status=candidate`.
5. Continue per `city_onboarding.md` §3–5 (field, config, status advance) when ops-ready.

### 9 — Final review gate (before `active=true`)
| Check | Required | Notes |
|---|---|---|
| Country row complete | yes | All §5 fields populated |
| `verification_schema` | yes | At least one doc type |
| `regulatory_flags` | yes | Explicit boolean |
| `payments.provider` | yes | Country-scoped |
| `payments.digital_enabled` | **false** | Do not flip |
| First city + corridor | yes | `import:city` or **A-08** |
| i18n gap documented | yes | May be 0% for new locale |
| Branding reviewed | optional | Token overrides only |
| Human ops sign-off | **DEFERRED** | Do not mark PASS without ops lead |

## Stop and escalate
- RPC returns `VALIDATION` — fix payload; do not SQL-insert into `countries`.
- Payload contains code-path fields (`code_path`, `handler`, etc.) — architecture defect.
- Need for country-specific `if country == 'GH'` in apps — fix tooling instead.
- Request to enable digital payments before Phase 4 gate — escalate to product owner.

## Communication
Internal: Slack `#along-ops` — "Country [GH] Ghana-Review checklist: active=false, first city [accra-review], digital_enabled unchanged."

## After-action
- Record: `audit_log` entries for config overrides; dry-run report `docs/reports/p10-e-01-new-country-dry-run.md`.
- When country goes live: set `active=true` on **A-18**, run `pilot_day_dry_run.md` on first corridor.

## Ops validation (P10-E-01)
| Check | Status | Evidence |
|---|---|---|
| Checklist doc (config/data only) | **PASS** (2026-09-07) | This runbook |
| Engineering dry-run Ghana-Review | **PASS** (2026-09-07) | `docs/reports/p10-e-01-new-country-dry-run.md`; `p10-e-01-ghana-review-apply.sh` |
| Human ops live sign-off | **DEFERRED** | Awaiting ops lead walkthrough on **A-18** |

## Related
- Runbook: `city_onboarding.md`, `corridor_onboarding.md`
- Screen: **A-18** Markets & portability
- RPCs: `admin_upsert_country`, `admin_set_country_schema`, `admin_create_city`, `admin_import_dry_run`, `admin_import_apply`
- CLI: `data-collection/scripts/import_city.ts`
- Fixture: `data-collection/fixtures/city_ghana_review/`
- Reports: `docs/reports/p10-a-01-tenant-dry-run.md`, `p10-b-01-whitelabel.md`, `p10-e-01-new-country-dry-run.md`
- Migration: `00000000000078_admin_markets_country_rpc.sql`
- Spec §7 Phase 10 gate: new country = data/config only
