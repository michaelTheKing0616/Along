# Observability Catalog

**Owner:** Platform · **Last reviewed:** 2026-09-07 · **Pager/rota:** DEFERRED — live PagerDuty/Better Stack routing is configured per environment outside this repo

Declarative catalog of dashboards and alerts required by blueprint `09_infra_devops.md` §8. Checked into git for review; wire to Better Stack / Logflare / Supabase reports in staging and prod during ops bootstrap (evidence deferred — not a gate failure for Phase 9).

## Log schema (all layers)

Edge Functions and jobs emit structured JSON:

| Field | Type | Notes |
|---|---|---|
| `request_id` | string | Correlation id |
| `user_id_hash` | string | No raw PII |
| `city_id` | uuid | Nullable for global endpoints |
| `duration_ms` | number | Handler latency |
| `level` | string | `info` / `warn` / `error` |
| `function` | string | Edge function or job name |

## Dashboards

| ID | Name | Primary source | Panels |
|---|---|---|---|
| `dash-ops-traffic` | Ops — traffic & latency | Logflare / Supabase Edge logs | RPS by function; p50/p95/p99 latency; 5xx rate; cold starts |
| `dash-ops-errors` | Ops — errors | Logflare + Sentry | Error rate by function; top error codes; recent stack traces (sanitized) |
| `dash-marketplace` | Marketplace funnel | Postgres + Edge logs | `planner_queries`/min; trip request → accept conversion; fulfilment rate |
| `dash-integrity` | Integrity | Postgres `flags`, admin audit | Flags/day; review queue depth; median review latency |
| `dash-finance` | Finance | Postgres ledger + Paystack reconcile | Settlement totals; balance distribution; webhook lag |

## Alerts

All alerts use a 5-minute evaluation window unless noted. Severity maps to on-call rotation when live paging is wired.

| ID | Name | Condition | Window | Severity | Notify | Runbook / action |
|---|---|---|---|---|---|---|
| `alert-plan-trip-p95` | plan-trip slow | Edge `plan-trip` p95 latency > **1.2 s** | 10 min | warning → critical if > 2 s | ops on-call | Check OSRM health, DB connection pool, `planner_queries` volume |
| `alert-error-rate` | High error rate | Aggregate Edge 5xx + unhandled errors > **2%** of requests | 10 min | critical | ops on-call | `docs/runbooks/incident_response.md`; identify failing function |
| `alert-sos-unacked` | SOS unacknowledged | Open `sos_alerts` with `acknowledged_at is null` and age > **60 s** | 1 min | critical (safety) | safety on-call | `docs/runbooks/sos_escalation.md` — page immediately |
| `alert-osrm-down` | OSRM health down | Routing VM `/health` non-200 or Edge OSRM timeout rate > 50% | 5 min | warning | ops on-call | Planner degrades (`degraded=true`); check `backend/routing` compose / VM |
| `alert-presence-fanout` | Presence fanout stalled | `driver_presence` rows with `last_ping_at` stale > **60 s** while status ∈ (`at_park`,`roaming_*`) and fanout queue depth not decreasing | 5 min | warning | ops on-call | Check Realtime, `set_presence` errors, partition job |
| `alert-ledger-invariant` | Ledger invariant failure | Nightly `check_ledger_invariant()` returns `ok=false` or `job_runs.status='failed'` for job `ledger_invariant` | nightly + 15 min lag | critical | platform + finance | Stop commission-affecting deploys; run TS-OPS-01; `TS-LEDGER-01` |
| `alert-paystack-sig` | Paystack webhook signature failures | Edge `paystack-webhook` responses 401 with `signature_ok=false` count > **5/h** | 1 h | warning | platform | Check `PAYSTACK_SECRET`, replay attack, clock skew |
| `alert-db-cpu` | Database CPU high | Supabase report: CPU > **80%** | 15 min | warning → critical if > 90% | platform | Inspect `pg_stat_statements`; partition retention; connection pool |

## Metric queries (reference — adapt to Logflare/Better Stack)

### plan-trip p95

```sql
-- Log-based (Logflare): filter function='plan-trip', percentile(duration_ms, 0.95) over 10m
```

### Error rate

```
sum(rate(http_status >= 500)) / sum(rate(http_requests)) > 0.02
```

### SOS unacked

```sql
select count(*)
from sos_alerts
where status = 'open'
  and acknowledged_at is null
  and created_at < now() - interval '60 seconds';
```

### Ledger invariant (nightly job)

```sql
select (check_ledger_invariant()->>'ok')::boolean;
-- Expect true; job_runs row with job_name='ledger_invariant'
```

### Paystack signature failures

```
count(logs where function='paystack-webhook' and status=401 and signature_ok=false) > 5 per hour
```

## Nightly ledger invariant job

- **Function:** `check_ledger_invariant()` (migration `00000000000076_domain_ledger_invariant_job.sql`)
- **Schedule:** pg_cron `0 3 * * *` (03:00 UTC daily)
- **Alert:** `alert-ledger-invariant` fires on `ok=false`
- **Manual run:** `select check_ledger_invariant();`

## Deferred (not required for P9-E-02 PASS)

- Live PagerDuty / Opsgenie service routing and escalation policies
- Scratch Supabase project `along-restore-scratch` for weekly prod drill (runbook written; evidence per drill)
- k6 trend dashboard import (see `backend/load/` and `load.yml` nightly)

## Related

- Blueprint: `docs/blueprint/09_infra_devops.md` §8
- Restore drill: `docs/runbooks/db_restore_drill.md`
- SOS: `docs/runbooks/sos_escalation.md`
- Incident: `docs/runbooks/incident_response.md`
- Ledger tests: `backend/db/tests/TS-LEDGER-01-06-ledger.sql`, `TS-OPS-01-restore-drill.sql`
