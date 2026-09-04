# Along — Engineering Blueprint (index)

**Status:** Authoritative implementation blueprint, sitting *beneath* `docs/ALONG_BUILD_SPEC.md` (the constitution) and *above* the code. Where the spec says *what* and *why*, this blueprint says *exactly how*: schemas, contracts, algorithms, screens, tokens, tasks.

**Precedence:** `ALONG_BUILD_SPEC.md` > this blueprint > ADRs > code comments. If the blueprint ever contradicts the spec, the spec wins and the blueprint has a bug — file it as an escalation in `BUILD_LEDGER.md`, do not silently pick one.

**Why several files rather than one:** worker models receive tasks with a bounded context window. Each document below is self-contained enough that an Orchestrator can attach *only the relevant sections* to a task. Never paste the whole blueprint into a Worker session.

---

## Documents

| # | File | Contents | Primary consumers |
|---|------|----------|-------------------|
| 00 | `00_README.md` | This index; reading order per role; conventions | Everyone |
| 01 | `01_architecture.md` | System boundaries, runtime topology, logic-placement rules (SQL vs Edge vs client), request flows, non-functional budgets | Orchestrator, all Workers |
| 02 | `02_data_model.md` | Full Postgres DDL: every table, column, enum, constraint, index; RLS policy matrix; config resolution; append-only triggers | Backend Workers, Reviewers |
| 03 | `03_api_contracts.md` | Every RPC / Edge Function / Realtime channel / scheduled job: auth, request, response, errors, idempotency, disclosure tier | Backend + Mobile + Admin Workers |
| 04 | `04_domain_logic.md` | Algorithms in pseudocode: fare resolution (Tier 0–3), planner search + ranking, stage snapping, promotion pipeline, ledger, trip/negotiation/standing state machines, reconciliation, presence, Na Me, auto-boarding, clustering, map-matching | Backend Workers, Reviewers |
| 05 | `05_design_system.md` | Resolved design tokens (the two Stitch variants reconciled), type scale, component library spec, Flutter + Tailwind mapping, motion, map style | Mobile + Admin Workers |
| 06 | `06_ui_audit_and_screens.md` | Critical audit of every Stitch screen (adopt / upgrade / reject with reasons); complete screen inventory for rider, driver, admin, B2B with per-screen specs, states, one-tap compliance | Mobile + Admin Workers, Reviewers |
| 07 | `07_mobile_architecture.md` | Flutter monorepo layout, packages, state management, navigation, offline/caching, realtime, map, background location, push, error handling, performance | Mobile Workers |
| 08 | `08_admin_console.md` | Next.js architecture, auth/roles, page inventory, data access, audit logging | Admin Workers |
| 09 | `09_infra_devops.md` | Environments, Supabase project layout, migrations, OSRM + tiles hosting, CI/CD, secrets, observability, backups, retention jobs | Infra Workers |
| 10 | `10_testing_strategy.md` | Test pyramid per layer, seed datasets, low-bandwidth simulation, gate-mapped test scenario IDs (TS-*), load-test plan | All Workers, Reviewers |
| 11 | `11_task_breakdown.md` | Phase-by-phase work breakdown: task IDs, scope, dependencies, parallel streams, acceptance criteria mapped to spec §6/§7 gates | Orchestrator |
| 12 | `12_security_privacy.md` | Threat model, authorization matrix, PII/NDPR handling, secrets, abuse/rate limiting, incident classes | Backend Workers, Reviewers, Phase 11 audit |
| 13 | `13_data_collection.md` | ODK/Kobo form schemas, field-agent protocol, ingestion + two-scout reconciliation pipeline, seed data formats, fictional test-city fixture | Data Workers |

Supporting folders:
- `docs/adr/` — Architecture Decision Records. ADR-0001…0012 record the decisions this blueprint makes beyond the spec. New top-level dirs or schema changes to the along-graph require a new ADR (spec §3, §4).
- `docs/design/` — the two original Stitch `DESIGN.md` variants, reference screenshots for every screen discussed in doc 06, and the brand logos.
- `docs/runbooks/` — runbook templates (SOS escalation, incident response, deploy, corridor onboarding, guarantor referral). Filled in by the phases that own them.
- `docs/BUILD_LEDGER.md` — append-only; Orchestrator only.

---

## Reading order per role

**Orchestrator (first session):** spec §0–§3, §6, §7 → blueprint 00, 01, 11 in full → skim 02–04 headings → `BUILD_LEDGER.md` last 15 entries. Issue tasks from doc 11 by ID, attaching the sections each task lists under *"Attach"*.

**Worker (per task):** spec §1 (constitution), §2.3 (report format), the §6 checklist, the spec sections named in the task → the blueprint sections the task names under *"Attach"*. Nothing else.

**Reviewer (per task):** spec §6 + the phase's gates in §7 → the task's acceptance criteria → the same blueprint sections as the Worker → doc 10's TS-* scenarios referenced by the task.

---

## Conventions used throughout

- **IDs**: tasks `P<phase>-<stream>-<nn>` (e.g., `P1-B-04`); test scenarios `TS-<AREA>-<nn>`; ADRs `ADR-nnnn`; screens `R-nn` (rider), `D-nn` (driver), `A-nn` (admin), `C-nn` (corporate/operator), `W-nn` (public web).
- **Money**: `numeric(12,2)` + ISO-4217 `char(3)`. Never floats. Minor-unit rounding per `countries.currency_minor_units`.
- **Geo**: `geography(Point,4326)` everywhere; distances in metres (`_m`), durations in seconds (`_s`), speeds in m/s (`_mps`), bearings in degrees clockwise from north (`0..359`).
- **Time**: `timestamptz` only; the DB is UTC; presentation converts using `cities.timezone`.
- **Naming**: snake_case in SQL/JSON; lowerCamelCase in Dart/TS; enums are lowercase snake strings.
- **Config, not code**: any threshold, weight, radius, timeout, or rate mentioned in the spec lives in `app_config` (doc 02 §2.3) with a documented default. Hardcoding one is FM5/FM2-class defect.
- **Disclosure tiers** (spec §4.1.2): every endpoint in doc 03 is labelled `Tier A` (ambient, no identity/precise position), `Tier B` (requires a `trips` row the caller is party to), or `Internal`.
- **Money words**: *fare* is what the rider pays the driver; *commission* is what the driver owes Along; *balance* is the signed sum of the driver's ledger. Never blend (FM3).
