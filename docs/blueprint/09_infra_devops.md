# 09 — Infrastructure & DevOps

Spec references: §5.1 (stack), §6 (migrations, tests), Phase 9 (load, backups, observability), Phase 11 (security). Decisions: ADR-0001, 0006, 0012.

## 1. Environments

| Env | Supabase | OSRM/Photon/Tiles | Payments | SMS | Apps |
|---|---|---|---|---|---|
| `local` | Supabase CLI (Docker) | `docker compose` in `backend/routing` with a 20 km Abuja extract | Paystack test keys, webhook via `supabase functions serve` + ngrok-free local tunnel script | log-only hook | dev flavour |
| `staging` | dedicated project (`along-staging`), same region as prod | small VM (4 vCPU/8 GB) full Nigeria extract; tiles on CDN bucket `tiles-staging` | Paystack test | Termii sandbox | staging flavour, Firebase App Distribution / TestFlight |
| `prod` | `along-prod`, PITR enabled, compute ≥ Medium from Phase 7 | 2× VM behind a load balancer (car/foot OSRM, Photon), weekly rebuild job | Paystack live | Termii live + Twilio fallback | store releases |

Region: choose the Supabase region with the lowest RTT from Lagos/Abuja (measure at bootstrap; eu-west typically ~100–120 ms). Record in ADR-0013.

## 2. Repos & CI (GitHub Actions)

Workflows (all required checks on PR):
- `db.yml`: `supabase db start` → apply migrations → `pg_prove backend/db/tests/**/*.sql` (pgTAP) → `supabase db lint` → RLS coverage script (every table has RLS + at least one test) → schema diff check against `shared/contracts/db.types.ts` (generated with `supabase gen types`).
- `functions.yml`: `deno lint`, `deno test` for `backend/functions`; OpenAPI contract check (`shared/contracts/openapi.yaml` ↔ handlers via `@hono/zod-openapi` or equivalent; drift fails).
- `mobile.yml`: `melos bootstrap`, `analyze`, `test` (unit + golden), `build apk --release --analyze-size` gate; `patrol test` on an emulator matrix for main flows nightly.
- `admin.yml`: `pnpm lint`, `typecheck`, `vitest`, `playwright` against local stack.
- `tokens.yml`: rebuild tokens; fail if generated files are stale.
- `seed-fixture.yml`: apply `seed_testcity_fixture` to a fresh DB and run `TS-CFG-*` scenarios (proves FM5).
- `load.yml` (staging, nightly from Phase 7): k6 scenarios in `backend/load/` against budgets in doc 01 §7; regression > 20% fails.

Deploy: `main` → staging automatically (migrations via `supabase db push` with `--dry-run` first, Edge Functions deploy, admin to Vercel preview→staging); prod via tagged release + manual approval; migrations are forward-only, each with a tested `down` in comments for emergency use and a rollback runbook (`docs/runbooks/deploy_rollback.md`). Mobile: fastlane lanes for internal → closed → production tracks; staged rollout 10% → 50% → 100% with crash-free ≥ 99.5% gate.

## 3. Database operations

- Migrations: `backend/db/migrations/NNNN_<context>.sql`; one bounded context per file; every function file idempotent (`create or replace`); policies in `backend/db/policies/<table>.sql` applied by migrations (`\ir`).
- Partitions: `ensure_partitions()` (pg_cron daily) for `trip_location_samples`, `driver_presence_history` (monthly); retention drops old partitions per `cfg`.
- Connection pooling: Supavisor transaction mode for Edge Functions; session mode for the jobs worker.
- Backups: Supabase daily backups + PITR (7 days) in prod; weekly restore drill into a scratch project (runbook `db_restore_drill.md`), verified by TS-OPS-01 (row counts + ledger balance invariants).
- Extensions allowed: only those in doc 02 §1. Adding one = ADR.

## 4. Routing, places, tiles (`backend/routing`)

```
backend/routing/
  docker-compose.yml           osrm-car, osrm-foot, photon, (local only: pmtiles-serve)
  profiles/car.lua, foot.lua   OSRM profiles (car tuned for shared-taxi: avoid motorway penalties off; foot default)
  scripts/fetch_extract.sh     Geofabrik nigeria-latest.osm.pbf (+ future countries by config)
  scripts/build_osrm.sh        osrm-extract → osrm-partition → osrm-customize (MLD) per profile; atomic swap of data dirs
  scripts/build_tiles.sh       planetiler → nigeria.pmtiles ; upload to CDN bucket ; bump styles/along-light.json source version
  scripts/build_photon.sh      photon index from the same extract
  style/along-light.json       MapLibre style (doc 05 §8) + sprites + glyphs build
```
Weekly cron on the routing VM rebuilds all three from the same extract snapshot so routing, places and tiles never disagree. Health: `/health` per service; Edge Functions time out OSRM calls at 800 ms and degrade (doc 01 §9).

## 5. Edge Functions (`backend/functions`)

One directory per function; `_shared/` has the Supabase client factory (service role from env), `cfg()` client, OSRM client, Paystack client (HMAC verify), Termii/Twilio client, FCM client, error envelope, idempotency helper (`private.idempotency` table), and structured logger (JSON, `request_id`, no PII). Every function: input validated with `zod`; auth via `supabase.auth.getUser(jwt)`; role checks by table membership; ≤ 5 s budget; cold-start mitigation by keeping functions small and dependency-light.

## 6. Jobs worker (`backend/jobs`)

Node/TS service (Docker) on the routing VM: `map-match`, `speed-profiles`, `route-inference`, `geometry-corrections`, `anonymized-export`, `paystack-reconcile`. Scheduled by systemd timers; each run writes `job_runs`; idempotent by design (uses `job_runs` watermark).

## 7. Secrets

Public web (`along.ng`): the Next.js app on Vercel also serves the public pages W-01…W-04 and the universal-link files `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` (doc 14 §2); `/p/[code]` must render without auth, ≤ 60 KB, cache resolver responses ≤ 30 s, and sit behind Vercel rate limiting / WAF rules for `/p/*` and the `qr/resolve` function.

Supabase Vault for DB-side secrets (identity hash pepper, candidate-token HMAC key, **payment-request token HMAC key** — doc 14 §2, rotates with the same 2-key overlap); Supabase Function secrets for provider keys; GitHub Environments for CI; Vercel env for admin (public keys only). Rotation runbook `secrets_rotation.md`; candidate-token key rotates monthly with a 2-key overlap.

## 8. Observability

- Logs: Supabase logs → Logflare/BigQuery drain (or Better Stack); Edge and jobs emit JSON with `request_id`, `user_id_hash`, `city_id`, `duration_ms`.
- Metrics: Postgres `pg_stat_statements` + Supabase reports; Edge latency histograms via log-based metrics; k6 trend dashboards; mobile Sentry performance.
- Alerts (PagerDuty/Opsgenie or Better Stack): `plan-trip` p95 > 1.2 s (10 min), error rate > 2%, open SOS unacknowledged > 60 s (pages safety on-call), OSRM health down, presence-fanout stalled > 60 s, ledger invariant check failure (nightly `TS-LEDGER-01` job), Paystack webhook signature failures > 5/h, DB CPU > 80% (15 min).
- Dashboards: ops (traffic/latency/errors), marketplace (searches, conversion, fulfilment), integrity (flags/day, review latency), finance (settlements, balance distribution).

## 9. Cost posture (business plan §10)
Supabase Pro + compute add-on; 1–2 small VMs; CDN egress dominated by tiles (PMTiles range requests keep it low); Termii per-SMS; Paystack per-transaction. No per-seat SaaS beyond Sentry/Vercel. Target infra ≤ 2% of GMV at Phase 9 scale; reviewed quarterly.
