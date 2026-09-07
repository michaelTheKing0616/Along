# Corridor Onboarding

**Owner:** Ops lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a

## When to use
Ops needs to stand up or extend a **pilot corridor** in an existing city — corridor record, backbone parks, routes, stages, leg/through fares — using admin-console **A-08** and the data-collection CLI only. Do **not** fork application code or run ad hoc SQL against graph tables.

**Out of scope here:** printing production QR stickers, enabling digital payments (`payments.digital_enabled` remains **false**), or national scale-out automation beyond this runbook.

## Preconditions & access
- Role: `ops_lead` or `superadmin` for deploy/config; `ops_agent` for field/graph steps.
- Consoles (all under `/{city}/…`):
  - **A-08** — `/{city}/deploy` (city deployment playbook — parks CSV **and** corridor bundle import)
  - **A-05** — `/{city}/graph` (graph editor + single-entity edits)
  - **A-07** — `/{city}/field` (two-scout reconciliation)
  - **A-09** — `/{city}/config` (city config overrides via `admin_set_config`)
  - **A-02** — `/{city}/dashboard` (readiness counts)
  - **A-03** — `/{city}/live` (smoke-check presence after go-live)
- Field data: scout submissions in ODK/Kobo pipeline (Phase 0) when not using CSV seed path.
- Review city-scoped config keys before go-live: `graph.snap_radius_m`, `graph.stage_merge_radius_m`, `commission.rate`, `dispatch.request_ttl_s`.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| P1 | Zero routes or zero leg fares for corridor after import | Block city status advance; re-run corridor dry-run on **A-08** |
| P2 | Field reconciliation variance unresolved | Do not publish; reconcile on **A-07** |
| P3 | Checklist item manual-only (tiles, OSRM) | Ops lead sign-off before `live` status |

## Steps

### 1 — Baseline inventory (A-08)
1. Open **A-08** (`/{city}/deploy`). Note corridor/park/route counts in the checklist header.
2. Walk the deployment checklist: geofence, corridor bundle, config overrides, vector tiles, OSRM extract.
3. **Expected:** auto-checks pass when corridor count, park count, and route count are > 0 after import.

### 2 — Import corridor backbone (A-08 — preferred)
1. Prepare doc 13 CSV sections (see `data-collection/fixtures/corridor_zaria_beta/` for a fictional example):
   - `parks.csv` — `name,aliases,lat,lng,modes`
   - `routes.csv` — `origin_park,destination_park,mode,name`
   - `stages.csv` — `route_name,sequence,stage_name,lat,lng,is_official_park`
   - `leg_fares.csv` — `route_name,from_seq,to_seq,fare`
   - `through_fares.csv` — optional `route_name,from_seq,to_seq,fare`
2. On **A-08**, enter corridor **name** + **slug**, paste each CSV section, click **Corridor dry-run**.
3. **Expected:** diff lists `create` rows for corridor, parks, routes, stages, leg fares (and through fares if supplied); no parse errors.
4. Click **Initialize corridor** — RPC `admin_import_apply(p_city_id, p_diff)`.
5. **Expected:** rows created with `source_type = import`, `verification_status = candidate`.
6. **Stop and escalate** if apply errors — do not insert graph rows via SQL.

### 2b — Import corridor backbone (CLI — engineering / CI validation)
From repo root with local Supabase running and migrations applied:

```bash
cd data-collection
npm run import:corridor -- --fixture fixtures/corridor_zaria_beta --dry-run
npm run import:corridor -- --fixture fixtures/corridor_zaria_beta --apply
```

**Expected:** dry-run JSON shows pending creates; apply returns `created` > 0 for a fresh fixture on `zaria-test`.

### 3 — Parks-only drop (legacy / incremental)
When adding parks without a full corridor bundle:
1. On **A-08** parks section, paste `name,lat,lng[,aliases]`, **Dry-run** → **Initialize (apply import)**.
2. Or on **A-05**, bulk parks CSV via the same `admin_import_dry_run` / `admin_import_apply` RPCs.

### 4 — Field verification (A-07)
1. Open **A-07** (`/{city}/field`). Review paired scout submissions when field data was collected.
2. Reconcile: RPC `admin_reconcile_field_entity(p_reconciliation_id, p_action)` — `match`, `discrepant`, `resolve`, or `reject`.
3. Publish verified entities: RPC `admin_publish_field_entity` → **Expected:** target published as `field_verified`.
4. **Stop and escalate** if publish returns unsupported entity type — park publish works; route/stage publish may be deferred (error code `0A000`).

### 5 — City config (A-09)
1. Open **A-09** (`/{city}/config`). Review overrides for:
   - `graph.snap_radius_m` (driver stop snap)
   - `graph.stage_merge_radius_m` (stage dedupe)
   - `commission.rate` (pilot default 7.5% global; city override if approved)
   - `dispatch.request_ttl_s` (driver request TTL)
2. Changes via RPC `admin_set_config` with required reason — audited on **A-16**.
3. **Do not** toggle `payments.digital_enabled` (read-only; stays false).

### 6 — Advance city status (A-08)
1. When checklist complete, advance city status `alpha` → `beta` → `live` on **A-08** (ops lead only).
2. Smoke on **A-03** (`/{city}/live`): `admin_presence_snapshot`, `admin_active_trips_map` return data when test drivers online.
3. Confirm **A-02** dashboard shows corridor in analytics selector and non-zero graph counts.

### Stop and escalate
- Corridor dry-run shows unexpected mass deletes — stop; escalate to ops lead + engineering.
- Two-scout reconciliation irreconcilable — hold publish; send scouts back to field.
- Config key rejected by validation — use only keys registered in `app_config_keys`; do not invent keys.

## Communication
Internal: Slack `#along-ops` — "Corridor [name] onboarding: parks [n], routes [n], status → [beta/live]. Config reviewed."

Field scouts: use standard ODK resubmit template when reconciliation rejected.

## After-action
- Record: graph revisions, audit log on config changes, field publish targets.
- Run `pilot_day_dry_run.md` on the new corridor before declaring ops-ready.

## Ops validation (P7-E-01)
| Check | Status | Evidence |
|---|---|---|
| Human ops live sign-off on hardened A-08 + CLI | **DEFERRED** (owner 2026-09-07) | Awaiting ops lead walkthrough |
| Engineering dry-run / test validation | **PASS** (2026-09-07) | `data-collection/scripts/corridor_config_only.test.ts`; `admin-console/src/lib/deploy/corridor-bundle.test.ts`; fixture `data-collection/fixtures/corridor_zaria_beta/` |

## Related
- Runbook: `city_onboarding.md` (new city + first corridor)
- Screens: **A-08** deploy, **A-05** graph, **A-07** field, **A-09** config, **A-02** dashboard, **A-03** live
- RPCs: `admin_import_dry_run`, `admin_import_apply`, `admin_update_graph_entity`, `admin_reconcile_field_entity`, `admin_publish_field_entity`, `admin_set_config`
- CLI: `data-collection/scripts/import_corridor.ts`
- Fixture: `data-collection/fixtures/corridor_zaria_beta/`
- Config keys: `graph.snap_radius_m`, `graph.stage_merge_radius_m`, `commission.rate`, `dispatch.request_ttl_s`, `payments.digital_enabled` (read-only)
- Runbook: `pilot_day_dry_run.md`
- Spec §7 Phase 7 gate: new corridor = data/config only
