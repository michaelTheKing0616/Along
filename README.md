# Along

Along is a two-sided mobile marketplace (rider app + driver app + ops console) built on a proprietary, crowdsourced map of Nigeria's informal shared-transport network — parks, stages, routes and standard fares — across shared taxis, kekes, okadas and minibuses. Asset-light, cash-first, multi-modal, built for low-end devices and low connectivity.

## Where to start

| You are… | Read |
|---|---|
| Anyone | `docs/ALONG_BUILD_SPEC.md` §0–§1 (the constitution) |
| The Orchestrator agent | spec §2, §6, §7 → `docs/blueprint/00_README.md` → `docs/blueprint/11_task_breakdown.md` → `docs/BUILD_LEDGER.md` |
| A Worker agent | the sections your task lists under *Attach* — nothing more |
| A Reviewer agent | spec §6 + the phase gates + the task's TS-* scenarios in `docs/blueprint/10_testing_strategy.md` |
| A human engineer | `docs/blueprint/01_architecture.md`, then `09_infra_devops.md` to run the stack |
| Product / ops | `docs/Along_Business_Plan.docx`, `docs/blueprint/06_ui_audit_and_screens.md`, `docs/runbooks/` |

## Repository layout (target — see `docs/blueprint/01_architecture.md` §3)

```
mobile-rider/  mobile-driver/  backend/{db,functions,routing,jobs}/  admin-console/  data-collection/  shared/{contracts,design-tokens,flutter}/  docs/
```

## Documents

- `docs/ALONG_BUILD_SPEC.md` — canonical engineering specification (v11). Wins every conflict.
- `docs/blueprint/` — the implementation blueprint: architecture, DDL, API contracts, algorithms, design system, screen inventory, mobile/admin/infra, testing, security, task breakdown, data collection.
- `docs/adr/` — architecture decision records.
- `docs/runbooks/` — operational procedures.
- `docs/design/` — Stitch reference screenshots (layout intent only), the two original Stitch design docs, brand logos.
- `docs/BUILD_LEDGER.md` — append-only build history (Orchestrator only); archive guide in `docs/BUILD_LEDGER_ARCHIVE.md`.
- `docs/CONFIG_REFERENCE.md` — `app_config` keys, defaults, and env file templates.
- `docs/adr/INDEX.md` — architecture decision record index.

## Starting the build

Open a Cursor Agent chat at the repo root and paste one line:

> Read `docs/AUTOPILOT_PROMPT.md` in full and execute it exactly. Start now.

That session becomes the Orchestrator: it spawns a fresh Worker subagent per task and a fresh Reviewer subagent per review, maintains `docs/BUILD_LEDGER.md`, merges passing branches, and stops only for the human decisions listed in the prompt's §6 (blocked tasks, blueprint gaps, credentials, phase gates). Reply with your decisions and "continue" to resume.

## Status

**Phases 0–11 complete; Phase 12 (docs & ops hardening) in progress.** The repo contains the full stack: Postgres migrations + Edge Functions, Flutter rider/driver apps, Next.js admin console, routing compose, and CI workflows. Pin versions in [ADR-0013](docs/adr/0013-pinned-versions-and-region.md).

| Layer | Location |
|---|---|
| Database & RPC | `backend/db/`, `supabase/` |
| Edge Functions | `backend/functions/` |
| Admin console | `admin-console/` |
| Mobile apps | `mobile-rider/`, `mobile-driver/`, `shared/flutter/` |
| Config reference | `docs/CONFIG_REFERENCE.md` |
| Runbooks | `docs/runbooks/` |
| Build history | `docs/BUILD_LEDGER.md` (append-only — see [archive guide](docs/BUILD_LEDGER_ARCHIVE.md)) |

## Local stack

Prerequisites: **Docker Desktop**, **Node.js 22**, **pnpm 9** ([ADR-0013](docs/adr/0013-pinned-versions-and-region.md)). For mobile: **Flutter 3.47.2** via [FVM](https://fvm.app) (`.fvmrc`).

Copy env templates only — never commit real secrets:

- Admin: `admin-console/.env.example` → `admin-console/.env.local`
- Mobile staging template: `env/staging.example.json` (fill from your Supabase project dashboard)

From the repo root:

1. `pnpm install` — workspace deps + pinned Supabase CLI
2. `pnpm supabase start` — local Postgres (:54322), API (:54321), Studio (:54323)
3. `pnpm supabase db reset` — apply migrations + `seed_core` (first run or after schema pull)
4. `pnpm supabase status` — confirm URLs; DB is `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
5. `cp admin-console/.env.example admin-console/.env.local` — local admin keys (demo values in example)
6. `pnpm --filter @along/admin-console dev` — admin console at http://localhost:3000
7. `dart pub global activate melos` — once per machine (Flutter workspace)
8. `melos bootstrap` — link shared Flutter packages
9. `cd mobile-rider && flutter run --dart-define-from-file=env/dev.json` — rider app (repeat for `mobile-driver/`)
10. *(Optional)* `docker compose -f backend/routing/docker-compose.yml up -d` — local OSRM for planner smokes

Verify: `psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "select cfg('payments.digital_enabled');"` → `false`.

More detail: [blueprint 09 — Infra & DevOps](docs/blueprint/09_infra_devops.md) · [config reference](docs/CONFIG_REFERENCE.md) · [dry-run evidence](docs/reports/p12-e-01-fresh-engineer.md)
