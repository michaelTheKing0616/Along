# P9-E-01 — Second Nigerian City Onboarding Report

**Task:** P9-E-01 — Stand up second Nigerian city using only tooling  
**Branch:** `task/p9-e-01`  
**Date:** 2026-09-07  
**Pilot city:** Kaduna-Pilot (`kaduna-pilot`) — fictional fixture, not live production ops

## Summary

Stood up a second Nigerian pilot city end-to-end using **data/config only**: city row, config overrides, and one corridor backbone (Kawo–Malali). Closed the city-creation tooling gap with generic `admin_create_city` RPC and `import:city` CLI. **Zero bespoke application code** — no `if city == kaduna` branches in mobile, admin, or backend handlers.

## Steps run (local)

```bash
# Apply migration (once)
psql "$DATABASE_URL" -f backend/db/migrations/00000000000074_admin_create_city.sql

# Dry-run
cd data-collection
npm run import:city -- --fixture fixtures/city_kaduna_pilot --dry-run

# Apply
npm run import:city -- --fixture fixtures/city_kaduna_pilot --apply

# Tests
npm test
psql "$DATABASE_URL" -f backend/db/tests/TS-CITY-01-create.sql
```

### Apply result (2026-09-07)

| Step | Outcome |
|---|---|
| `admin_create_city` | Created `kaduna-pilot` (status `alpha`) + 3 config overrides |
| `admin_import_apply` | 20 graph entities created (1 corridor, 2 parks, 2 routes, 8 stages, 6 leg fares, 1 through fare) |
| Re-run dry-run | City action `skip` (idempotent); corridor diff shows existing rows as `skip` |

## Tooling deltas (gaps closed)

| Gap | Fix |
|---|---|
| Cities were SQL-seeded only (`seed_abuja_pilot`, `seed_testcity_fixture`) | **`admin_create_city` RPC** — migration `00000000000074_admin_create_city.sql` |
| No CLI to create city + first corridor from one fixture | **`import:city` CLI** — `data-collection/scripts/import_city.ts` |
| No runbook for new-city path | **`docs/runbooks/city_onboarding.md`** (deltas vs `corridor_onboarding.md` documented) |
| No city-level fixture template | **`data-collection/fixtures/city_kaduna_pilot/`** |

Existing corridor import tooling (`import:corridor`, `admin_import_dry_run` / `admin_import_apply`) was reused unchanged for the backbone graph.

## Zero bespoke code evidence

1. **Grep audit** — `kaduna-pilot` appears only in:
   - `data-collection/fixtures/city_kaduna_pilot/`
   - Tooling: `import_city.ts`, `city-import.ts`, migration `00074`, tests
   - Docs/runbooks/reports
   - **Not** in `mobile-rider/`, `mobile-driver/`, `admin-console/src/` (excluding generic tooling), or `backend/functions/`

2. **Vitest** — `city_kaduna_pilot.test.ts` asserts slug hits are confined to data/config paths.

3. **P9-A-01 baseline** — prior hardcode audit removed Abuja/NGN centroids from apps; Kaduna-Pilot uses the same generic `city_centroid` RPC and city-scoped config resolution as Abuja and Zaria-Test.

4. **No new app_config keys** — overrides use existing registered keys (`commission.rate`, `graph.snap_radius_m`, `graph.stage_merge_radius_m`). `payments.digital_enabled` not touched.

## Fixture details

- **City:** Kaduna-Pilot, slug `kaduna-pilot`, centroid (10.510, 7.417), state_region "Kaduna (pilot fixture — not live ops)"
- **Corridor:** Pilot Corridor Kawo–Malali (`kawo-malali`), 2 modes (car + keke), 4 stages each, 6 leg fares, 1 through fare
- **Config overrides:** `commission.rate=0.06`, `graph.snap_radius_m=45`, `graph.stage_merge_radius_m=35`

## Tests added/run

| Test | Verifies | Result |
|---|---|---|
| `city_kaduna_pilot.test.ts` | Fixture parse, grep audit, DB dry-run | PASS |
| `TS-CITY-01-create.sql` | `admin_create_city` dry-run/apply/skip + config override | PASS (5/5) |

## Explicitly not done

- Human ops sign-off on A-08 city-create UI (RPC/CLI path sufficient for Phase 9 exit; A-08 UI wiring deferred)
- Vector tiles / OSRM extract for Kaduna-Pilot (manual checklist items per runbook)
- Live ops declaration — fixture is explicitly fictional

## OPEN QUESTIONS

None — Kaduna-Pilot chosen per task recommendation; all acceptance criteria met via generic tooling.
