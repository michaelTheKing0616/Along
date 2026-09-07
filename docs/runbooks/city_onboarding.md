# City Onboarding

**Owner:** Ops lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a

## When to use
Ops or engineering needs to stand up a **new pilot city** — city row, config overrides, and first corridor backbone — using admin-console **A-08** and the data-collection CLI only. Do **not** fork application code or hand-insert graph rows.

**Out of scope here:** corridor-only adds in an existing city (see `corridor_onboarding.md`), printing production QR stickers, enabling digital payments (`payments.digital_enabled` remains **false**).

## Preconditions & access
- Role: `ops_lead` or `superadmin` for city creation and deploy/config.
- Consoles (all under `/{city}/…` after city exists):
  - **A-08** — `/{city}/deploy` (city + corridor bundle import)
  - **A-05** — `/{city}/graph`
  - **A-07** — `/{city}/field`
  - **A-09** — `/{city}/config`
  - **A-02** — `/{city}/dashboard`
  - **A-03** — `/{city}/live`
- `seed_core.sql` applied (active `NG` country row).
- Review city-scoped config keys before go-live: `graph.snap_radius_m`, `graph.stage_merge_radius_m`, `commission.rate`, `dispatch.request_ttl_s`.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| P1 | City created but zero routes after corridor import | Block status advance; re-run corridor dry-run on **A-08** |
| P2 | `admin_create_city` returns slug conflict | Use existing city slug or pick a new slug — do not SQL-insert |
| P3 | Checklist item manual-only (tiles, OSRM) | Ops lead sign-off before `live` status |

## Steps

### 1 — Prepare city fixture (doc 13)
1. Copy `data-collection/fixtures/city_kaduna_pilot/` as a template.
2. Edit `manifest.json`:
   - `city`: `name`, `slug`, `country_code`, `centroid`, `state_region`, `status` (`alpha` for pilots)
   - `corridor`: first corridor `name` + `slug`
   - `config_overrides`: city-scoped keys only (see **A-09** registry)
3. Add doc 13 CSV sections in the same directory:
   - `parks.csv`, `routes.csv`, `stages.csv`, `leg_fares.csv`, `through_fares.csv` (optional)

### 2 — Create city + import corridor (CLI — engineering / CI)
From repo root with local Supabase running and migrations applied (includes `00074`):

```bash
cd data-collection
npm run import:city -- --fixture fixtures/city_kaduna_pilot --dry-run
npm run import:city -- --fixture fixtures/city_kaduna_pilot --apply
```

**Expected:** dry-run returns `action: create` for city (or `skip` if re-run); corridor diff lists `create` rows for parks, routes, stages, fares.

### 2b — Create city + corridor (A-08 — ops preferred)
1. Open **A-08** deploy for an existing deployment city context, or use RPC `admin_create_city` from service console with:
   - `p_name`, `p_slug`, `p_country_code`, `p_centroid_lat`, `p_centroid_lng`, optional `p_state_region`, `p_status`, `p_config_overrides`
2. Navigate to `/{new-city-slug}/deploy`.
3. Paste corridor CSV sections (same as `corridor_onboarding.md` §2).
4. **Corridor dry-run** → **Initialize corridor**.

### 3 — Field verification (A-07)
Same as `corridor_onboarding.md` §4 when field data was collected.

### 4 — City config (A-09)
1. Review overrides applied at city creation; adjust via RPC `admin_set_config` with required reason.
2. **Do not** toggle `payments.digital_enabled`.

### 5 — Advance city status (A-08)
Same as `corridor_onboarding.md` §6 — advance `alpha` → `beta` → `live` when checklist complete.

## Deltas vs `corridor_onboarding.md`
| Topic | `corridor_onboarding.md` | This runbook |
|---|---|---|
| Scope | New corridor in **existing** city | **New city** + first corridor |
| City row | Already in DB (SQL-seeded or prior) | `admin_create_city` RPC or `import:city` CLI |
| Config | Review/adjust on **A-09** | Applied at city creation via manifest `config_overrides` + **A-09** review |
| Fixture path | `fixtures/corridor_*` | `fixtures/city_*` (manifest includes city + corridor) |
| CLI | `npm run import:corridor` | `npm run import:city` (city create → corridor import) |

## Tooling gaps closed (P9-E-01)
- **`admin_create_city` RPC** (`00000000000074_admin_create_city.sql`) — generic city row + validated config overrides; no per-city application branches.
- **`import:city` CLI** (`data-collection/scripts/import_city.ts`) — orchestrates city create + corridor import from one fixture directory.
- **Fixture template** — `data-collection/fixtures/city_kaduna_pilot/` (fictional Kaduna metro pilot; not live ops).

## Stop and escalate
- City dry-run OK but corridor dry-run shows mass deletes — stop; escalate to engineering.
- Unknown config key in manifest — use only keys in `app_config_keys`.
- Attempt to add city-specific `if city == …` branches in apps — architecture defect; fix tooling instead.

## Communication
Internal: Slack `#along-ops` — "City [name] onboarding: slug [slug], corridor [name], status → [alpha/beta/live]."

## After-action
- Record audit log entries for config overrides.
- Run `pilot_day_dry_run.md` on the new corridor before declaring ops-ready.

## Related
- Runbook: `corridor_onboarding.md`
- RPCs: `admin_create_city`, `admin_import_dry_run`, `admin_import_apply`, `admin_set_config`
- CLI: `data-collection/scripts/import_city.ts`, `import_corridor.ts`
- Fixture: `data-collection/fixtures/city_kaduna_pilot/`
- Tests: `data-collection/scripts/city_kaduna_pilot.test.ts`, `backend/db/tests/TS-CITY-01-create.sql`
- Spec §7 Phase 9 exit: second city = data/config only
