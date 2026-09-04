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
- `docs/BUILD_LEDGER.md` — append-only build history (Orchestrator only).

## Starting the build

Open a Cursor Agent chat at the repo root and paste one line:

> Read `docs/AUTOPILOT_PROMPT.md` in full and execute it exactly. Start now.

That session becomes the Orchestrator: it spawns a fresh Worker subagent per task and a fresh Reviewer subagent per review, maintains `docs/BUILD_LEDGER.md`, merges passing branches, and stops only for the human decisions listed in the prompt's §6 (blocked tasks, blueprint gaps, credentials, phase gates). Reply with your decisions and "continue" to resume.

## Status

Planning complete; no application code yet. Phase 0 begins with task `P0-E-01` (repo bootstrap) in `docs/blueprint/11_task_breakdown.md`.
