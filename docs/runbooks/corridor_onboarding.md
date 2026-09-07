# Corridor Onboarding

**Owner:** Ops lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a

## When to use
Ops needs to stand up or extend a **pilot corridor** in an existing city — backbone parks, routes, stages, leg fares — using admin-console tooling only. This runbook documents the **Phase 6** procedure; **P7-E-01** later validates it with ops and enhanced A-08 tooling. Do **not** fork application code or run ad hoc SQL against graph tables.

**Out of scope here:** printing production QR stickers, enabling digital payments (`payments.digital_enabled` remains **false**), or national scale-out automation (Phase 7 engineering).

## Preconditions & access
- Role: `ops_lead` or `superadmin` for deploy/config; `ops_agent` for field/graph steps.
- Consoles (all under `/{city}/…`):
  - **A-08** — `/{city}/deploy` (city deployment playbook, parks CSV)
  - **A-05** — `/{city}/graph` (graph editor + CSV import)
  - **A-07** — `/{city}/field` (two-scout reconciliation)
  - **A-09** — `/{city}/config` (city config overrides via `admin_set_config`)
  - **A-02** — `/{city}/dashboard` (readiness counts)
  - **A-03** — `/{city}/live` (smoke-check presence after go-live)
- Field data: backbone parks CSV and scout submissions in ODK/Kobo pipeline (Phase 0).
- Review city-scoped config keys before go-live: `graph.snap_radius_m`, `graph.stage_merge_radius_m`, `commission.rate`, `dispatch.request_ttl_s`.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| P1 | Zero routes or zero leg fares for corridor after import | Block city status advance; fix on **A-05** / **A-07** |
| P2 | Field reconciliation variance unresolved | Do not publish; reconcile on **A-07** |
| P3 | Checklist item manual-only (tiles, OSRM) | Ops lead sign-off before `live` status |

## Steps

### 1 — Baseline inventory (A-08)
1. Open **A-08** (`/{city}/deploy`). Note corridor/park/route counts in the checklist header.
2. Walk the deployment checklist: geofence, backbone parks CSV, routes seeded, leg/through fares, config overrides, vector tiles, OSRM extract.
3. **Expected:** auto-checks pass for parks (`parks_csv`) and routes when counts > 0.

### 2 — Import backbone parks (A-08 → graph)
1. On **A-08**, paste parks CSV (`name,lat,lng[,aliases]`). Run **Dry-run**.
2. **Expected:** diff shows `create` / `skip` rows; no parse errors.
3. **Apply import** — creates parks with `verification_status = candidate`, `source = import`.
4. **Stop and escalate** if apply errors — do not insert parks via SQL.

### 3 — Graph routes, stages, fares (A-05)
1. Open **A-05** (`/{city}/graph`). Select target corridor.
2. For bulk stage/route CSV: run **Dry-run** → RPC `admin_import_dry_run(p_city_id, p_csv)` then review diff.
3. **Apply** → RPC `admin_import_apply(p_city_id, p_diff)`.
4. For single-entity edits: save via **Save** → RPC `admin_update_graph_entity(p_type, p_payload)` per entity. **Expected:** success message with graph revision id.
5. Confirm leg fares and through-fares exist for primary trips on the corridor (manual checklist item on A-08).

### 4 — Field verification (A-07)
1. Open **A-07** (`/{city}/field`). Review paired scout submissions.
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
- Graph import dry-run shows unexpected mass deletes — stop; escalate to ops lead + engineering.
- Two-scout reconciliation irreconcilable — hold publish; send scouts back to field.
- Config key rejected by validation — use only keys registered in `app_config_keys`; do not invent keys.

## Communication
Internal: Slack `#along-ops` — "Corridor [name] onboarding: parks [n], routes [n], status → [beta/live]. Config reviewed."

Field scouts: use standard ODK resubmit template when reconciliation rejected.

## After-action
- Record: graph revisions, audit log on config changes, field publish targets.
- Run `pilot_day_dry_run.md` on the new corridor before declaring ops-ready.
- Quarterly review of this runbook with Phase 7 tooling updates (P7-E-01).

## Related
- Screens: **A-08** deploy, **A-05** graph, **A-07** field, **A-09** config, **A-02** dashboard, **A-03** live
- RPCs: `admin_import_dry_run`, `admin_import_apply`, `admin_update_graph_entity`, `admin_reconcile_field_entity`, `admin_publish_field_entity`, `admin_set_config`
- Config keys: `graph.snap_radius_m`, `graph.stage_merge_radius_m`, `commission.rate`, `dispatch.request_ttl_s`, `payments.digital_enabled` (read-only)
- Runbook: `pilot_day_dry_run.md`
- Spec §7 Phase 6 exit criterion; Phase 7 exit criterion (ops-only onboarding — validation deferred to P7-E-01)
