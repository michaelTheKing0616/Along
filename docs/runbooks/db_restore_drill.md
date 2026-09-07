# Database Restore Drill

**Owner:** Platform / DBA · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a (weekly maintenance; pages only if TS-OPS-01 fails in prod scratch project)

## When to use

Weekly verification that Supabase backups (daily + PITR in prod) restore cleanly and that domain data integrity holds after restore. Run every **Monday 06:00 WAT** in prod (scratch Supabase project) and **before every major migration** in staging. Locally, run against the Supabase CLI stack before merging observability/ledger changes.

Evidence of each drill is recorded in `docs/reports/p9-e-02-restore-drill.md` (local) or the ops ticket / Better Stack incident note (prod scratch project).

## Preconditions & access

| Environment | Source | Scratch target | Access |
|---|---|---|---|
| **local** | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` (Supabase CLI) | DB `along_restore_scratch` on same instance | `postgres` superuser via CLI |
| **staging** | `along-staging` project | Dedicated scratch project (`along-restore-scratch`) | Supabase dashboard + `supabase db dump` |
| **prod** | `along-prod` (PITR or daily backup) | Dedicated scratch project (`along-restore-scratch`) | Platform lead + dual approval |

Required tools: `pg_dump`, `pg_restore`, `psql`, repo checkout at `main` or release tag being verified.

Verification script: `backend/db/tests/TS-OPS-01-restore-drill.sql`  
Orchestration (local): `backend/db/scripts/run_restore_drill.sh`

## Severity / triage

| Level | Signal | Action |
|---|---|---|
| S1 | TS-OPS-01 ledger invariant FAIL after restore | Stop deploys; page platform + finance on-call; treat as data-integrity incident |
| S2 | Row count mismatch on any key table | Investigate partial restore or missing extensions; do not promote release |
| S3 | Restore succeeds but drill overdue (> 8 days) | Schedule scratch restore within 24 h |
| S4 | Local-only drill for dev PR | Log in PR / task report; no page |

## Steps

### Local (Supabase CLI)

**Note:** `pg_restore` into a separate database (`along_restore_scratch`) fails on Supabase CLI because extensions (`pg_cron`, `postgis`, `pg_net`) are bound to the `postgres` database. Local drills therefore use a **scratch schema** (`along_restore_scratch`) after a real `pg_dump` of `public` — row-count parity + ledger invariant are equivalent for TS-OPS-01.

1. Ensure local stack is up: `supabase status` → DB on port **54322**. **Expected:** `postgres` healthy.
2. From repo root, run the automated drill:
   ```bash
   chmod +x backend/db/scripts/run_restore_drill.sh
   backend/db/scripts/run_restore_drill.sh
   ```
   **Expected:** `PASS TS-OPS-01 restore drill complete`.
3. To inspect scratch DB before drop: `KEEP_SCRATCH_DB=1 backend/db/scripts/run_restore_drill.sh`, then connect to `along_restore_scratch`.
4. Record output (commands, row-count table, invariant pass/fail) in `docs/reports/p9-e-02-restore-drill.md` or a dated follow-on report.

### Manual local (if script unavailable)

1. Capture baseline counts:
   ```bash
   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/db/tests/TS-OPS-01-restore-drill.sql
   ```
2. Dump source:
   ```bash
   pg_dump "$DATABASE_URL" --format=custom --no-owner --no-privileges -f /tmp/along-restore.dump
   ```
3. Create scratch DB and restore:
   ```bash
   psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "drop database if exists along_restore_scratch;"
   psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "create database along_restore_scratch;"
   pg_restore --dbname="postgresql://postgres:postgres@127.0.0.1:54322/along_restore_scratch" \
     --no-owner --no-privileges /tmp/along-restore.dump
   ```
4. Verify scratch:
   ```bash
   psql "postgresql://postgres:postgres@127.0.0.1:54322/along_restore_scratch" \
     -v ON_ERROR_STOP=1 -f backend/db/tests/TS-OPS-01-restore-drill.sql
   ```
5. Compare row counts to step 1 — must match exactly.
6. Drop scratch: `drop database along_restore_scratch;`

### Staging / prod (scratch Supabase project)

1. **Stop** — prod restore requires platform lead approval and a ticket. Never restore prod backup into the live prod project.
2. Export from source (Supabase CLI or dashboard backup):
   ```bash
   supabase db dump --db-url "$SOURCE_DATABASE_URL" -f along-restore.dump
   ```
3. Create or reset scratch project `along-restore-scratch` (empty).
4. Restore dump into scratch per Supabase docs (`psql` or `pg_restore` depending on format).
5. Run TS-OPS-01 against scratch connection string.
6. Attach evidence (row-count table, invariant result, backup timestamp) to the weekly ops ticket.

### Stop and escalate

- Ledger invariant FAIL → S1: open incident, notify finance (commission balances may be wrong), do **not** fail over traffic.
- Restore errors on extensions (`postgis`, `pg_cron`, `pgtap`) → check `backend/db/migrations/00000000000001_extensions_schemas_helpers.sql`; scratch project must enable same extensions before restore.
- Row counts match but application smoke fails → escalate to engineering; TS-OPS-01 is necessary but not sufficient.

## Communication

Internal (on failure): Slack `#along-platform` — "Restore drill FAIL [env] [date]: TS-OPS-01 [row-count mismatch | ledger invariant]. Backup from [timestamp]. Incident [id]."

No rider/driver communication unless prod data loss is confirmed (extremely unlikely for drill-only scope).

## After-action

- Record: drill date, backup/PITR timestamp, operator, pass/fail, row-count table, invariant result.
- Update `docs/reports/p9-e-02-restore-drill.md` (local) or attach to Better Stack / ticket (prod).
- If FAIL: root-cause within 24 h; re-run drill before next deploy.
- Metrics: `job_runs` entry from nightly `check_ledger_invariant()` (migration `00076`) is separate — do not conflate with restore drill.

## Related

- Blueprint: `docs/blueprint/09_infra_devops.md` §3 (backups), §8 (observability)
- Test: `backend/db/tests/TS-OPS-01-restore-drill.sql`, `TS-LEDGER-01` in `TS-LEDGER-01-06-ledger.sql`
- Observability alerts: `docs/runbooks/observability.md`
- Deploy rollback: `docs/runbooks/deploy_rollback.md` (template)
- Report: `docs/reports/p9-e-02-restore-drill.md`
