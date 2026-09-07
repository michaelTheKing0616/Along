# P9-E-02 — Restore Drill & Observability Report

**Task:** P9-E-02 — Observability & backups maturity  
**Branch:** `task/p9-e-02`  
**Date:** 2026-09-07  
**Environment:** local Supabase CLI (`postgresql://postgres:postgres@127.0.0.1:54322/postgres`)

## Summary

Delivered restore drill runbook, TS-OPS-01 verification SQL, observability alert/dashboard catalog, and nightly `check_ledger_invariant()` job (migration `00076`). **Local restore drill executed and passed** on 2026-09-07 using schema-based scratch restore (documented Supabase CLI limitation for separate-database restore).

## Restore drill execution

### Commands run

```bash
# Apply nightly invariant migration (once)
psql "$DATABASE_URL" -f backend/db/migrations/00000000000076_domain_ledger_invariant_job.sql

# Full automated drill
backend/db/scripts/run_restore_drill.sh

# Standalone TS-OPS-01 on source (post-restore verification SQL)
psql "$DATABASE_URL" -f backend/db/tests/TS-OPS-01-restore-drill.sql

# Nightly invariant smoke
psql "$DATABASE_URL" -c "select check_ledger_invariant();"
```

### Local restore method

| Step | Action | Result |
|---|---|---|
| 1 | `pg_dump --schema=public` (custom format) | Dump written to `/tmp/along-restore-drill.dump` |
| 2 | Capture baseline row counts from `public` | 17 key tables recorded |
| 3 | Clone `public` → schema `along_restore_scratch` | 17 tables cloned with data |
| 4 | Compare row counts `public` vs scratch | **MATCH** |
| 5 | TS-LEDGER-01 invariant on scratch schema | **PASS** (0 violations; no ledger rows in local seed) |
| 6 | Drop scratch schema | Cleaned up |

**Separate-database restore:** Attempted first; `pg_restore` into `along_restore_scratch` database failed with 864 errors (Supabase extensions `pg_cron`/`postgis`/`pg_net` not creatable outside `postgres` DB). Documented in runbook; schema clone is the accepted local equivalent per task ("scratch DB **or** schema").

### Row counts (source = scratch)

| Table | Row count |
|---|---|
| app_config | 163 |
| app_config_keys | 41 |
| cities | 2 |
| corridors | 2 |
| countries | 2 |
| deployments | 2 |
| driver_ledger_entries | 0 |
| drivers | 0 |
| parks | 2 |
| payments | 0 |
| profiles | 2 |
| riders | 0 |
| route_legs | 6 |
| route_stages | 8 |
| route_through_fares | 1 |
| routes | 2 |
| trips | 0 |

### Invariant results

| Check | Result |
|---|---|
| TS-LEDGER-01 `sum(amount) = latest balance_after` (scratch schema) | **PASS** |
| `driver_balances` view consistency (`TS-OPS-01-restore-drill.sql` on source) | **PASS** |
| `check_ledger_invariant()` nightly job smoke | **PASS** (`ok: true`, 0 violations) |

## Observability catalog

Checked in at `docs/runbooks/observability.md` — declarative catalog covering blueprint 09 §8 alerts:

- `plan-trip` p95 > 1.2 s
- Error rate > 2%
- SOS unacknowledged > 60 s
- OSRM health down
- Presence fanout stalled > 60 s
- Ledger invariant failure (nightly job)
- Paystack webhook signature failures > 5/h
- DB CPU > 80%

Live PagerDuty / scratch Supabase project wiring: **DEFERRED** (not a gate failure).

## Artifacts added

| Path | Purpose |
|---|---|
| `docs/runbooks/db_restore_drill.md` | Weekly restore drill runbook |
| `docs/runbooks/observability.md` | Alert & dashboard catalog |
| `backend/db/tests/TS-OPS-01-restore-drill.sql` | Post-restore verification SQL |
| `backend/db/scripts/run_restore_drill.sh` | Local drill orchestration |
| `backend/db/scripts/restore_drill_clone_schema.sql` | Scratch schema clone helper |
| `backend/db/scripts/restore_drill_verify_scratch.sql` | Scratch schema invariant check |
| `backend/db/migrations/00000000000076_domain_ledger_invariant_job.sql` | Nightly `check_ledger_invariant()` + pg_cron |

## Explicitly not done

- Live PagerDuty / Better Stack routing (deferred evidence)
- Prod/staging scratch Supabase project weekly drill (runbook written; ops to schedule)
- `digital_enabled` not touched

## Open questions

None.
