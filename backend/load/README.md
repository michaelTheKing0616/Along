# Along load tests (k6)

External binary — **not** an npm dependency (doc 10 §1, doc 09 §2 `load.yml`).

Budgets enforced from `docs/blueprint/01_architecture.md` §7 via `thresholds.js` (mirrors `app_config` defaults: `presence.fanout_interval_s=10`, ping p95 ≤ 300 ms, plan-trip p95 ≤ 800 ms, ambient fan-out ≤ 10 s, trip message p95 ≤ 1 s).

## Install k6

```bash
# macOS
brew install k6

# Linux (Debian/Ubuntu)
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C0CFC7328068
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

## Local pilot (P3-E-01)

Requires local Supabase (`supabase start`) and Deno (for JWT minting). Does **not** read `env/staging.json`.

```bash
chmod +x backend/load/scripts/run_pilot.sh
backend/load/scripts/run_pilot.sh
```

## Scaled local proof (P7-E-02)

When the laptop cannot sustain full-city VUs, run at 1/10 scale and document the scale factor:

```bash
chmod +x backend/load/scripts/run_scaled_local.sh
backend/load/scripts/run_scaled_local.sh
```

Defaults: 20 rps plan-trip + 100 pings/s + 50 trip subscribers for 2 min (scale factor 10×). Results land in `backend/load/results/p7-e-02-<label>.md` plus per-scenario `.txt`/`.json`.

Requires `supabase functions serve plan-trip` (or deployed Edge) for TS-OPS-02 plan-trip calls to succeed locally.

## Full-city (staging / CI)

Set env vars from your secret store (never commit):

```bash
export SUPABASE_URL=https://<project-ref>.supabase.co
export SUPABASE_ANON_KEY=<anon-key>
export SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
export JWT_SECRET=<staging-jwt-secret>
export DB_URL=<staging-db-url>
chmod +x backend/load/scripts/run_fullcity.sh
backend/load/scripts/run_fullcity.sh
```

Full-city targets (TS-OPS-02/03): 200 rps `plan-trip` + 1,000 presence pings/s for 10 min; 5,000 concurrent `trip:*` subscribers with message p95 ≤ 1 s.

## Optional env overrides

| Variable | Pilot default | Full-city default | Meaning |
|---|---|---|---|
| `DURATION` | `2m` | `10m` | k6 scenario duration |
| `PLAN_TRIP_RATE` | — | `200` | TS-OPS-02 plan-trip requests/s |
| `PRESENCE_PING_RATE` | — | `1000` | TS-OPS-02 presence_ping/s |
| `TRIP_SUBSCRIBER_VUS` | `5` | `5000` | TS-OPS-03 concurrent WS subscribers |
| `TRIP_BROADCAST_RATE` | — | `10` | trip loc broadcasts/s (latency pump) |
| `DRIVER_VUS` | `10` | — | pilot presence_ping VUs |
| `FANOUT_MODE` | `direct` (local) / `edge` (staging) | `edge` | fan-out via Edge or REST fallback |
| `SCALE_FACTOR` | `10` (scaled local) | `1` | documented extrapolation to full city |
| `LOAD_RESULTS_DIR` | `results` | `results` | k6 JSON summary directory |

Outputs (safe to commit):

- `backend/load/results/ts-ops-02-<label>.txt` / `.json`
- `backend/load/results/ts-ops-03-<label>.txt` / `.json`
- `backend/load/results/p7-e-02-<label>.md` — scaled run summary
- `backend/load/.tokens.json` — **gitignored** JWTs; never commit

Seed fixture: `backend/db/seed/seed_test_scenarios/load_fullcity.sql` (100 drivers, 50 riders, 50 active trips on Zaria-Test).

## Fan-out / Realtime tuning

Only adjust via existing `app_config` keys (migrations / ADR-0016 — no hand-edited prod):

| Key | Default | Budget |
|---|---|---|
| `presence.fanout_interval_s` | `10` | ambient fan-out latency ≤ 10 s |
| `presence.fanout_radius_m` | `3000` | cell publish radius |
| `realtime.max_payload_bytes` | `512` | broadcast payload cap |
| `presence.ping_min_interval_s` | `2` | server-side ping throttle |
| `realtime.trip_subscriber_target` | `5000` | TS-OPS-03 reference (migration 00066) |
| `planner.query_log_retention_days` | `7` | curb `planner_queries` bloat during load windows |

Supabase Realtime dashboard (staging/prod, documented in migration 00066): max concurrent connections ≥ 6000; max messages/s ≥ 2000.

## Scenarios

| Script | TS-ID | What it exercises |
|---|---|---|
| `presence_pilot.js` | TS-OPS-03 (pilot) | P3-E-01: `presence_ping` + `ambient:*` / `trip:*` at reduced VUs |
| `plan_trip_mix.js` | TS-OPS-02 | 200 rps `plan-trip` mixed with 1k presence pings/s |
| `realtime_full.js` | TS-OPS-03 | 5k `trip:*` subscribers + loc broadcast latency pump |
