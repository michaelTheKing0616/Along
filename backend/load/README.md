# Along load tests (k6)

External binary — **not** an npm dependency (doc 10 §1, doc 09 §2 `load.yml`).

Budgets enforced from `docs/blueprint/01_architecture.md` §7 via `thresholds.js` (mirrors `app_config` defaults: `presence.fanout_interval_s=10`, ping p95 ≤ 300 ms, ambient fan-out ≤ 10 s, trip message p95 ≤ 1 s).

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
# From repo root
chmod +x backend/load/scripts/run_pilot.sh
backend/load/scripts/run_pilot.sh
```

Optional env overrides:

| Variable | Default | Meaning |
|---|---|---|
| `DURATION` | `2m` | k6 scenario duration |
| `DRIVER_VUS` | `10` | concurrent `presence_ping` drivers |
| `AMBIENT_SUBSCRIBER_VUS` | `10` | concurrent `ambient:{city}:{geohash5}` subscribers |
| `TRIP_SUBSCRIBER_VUS` | `5` | concurrent `trip:{id}` subscribers (pilot scale) |
| `FANOUT_MODE` | `direct` (local) / `edge` (staging) | `direct` calls RPC+broadcast REST; `edge` hits `presence-fanout` function |
| `LOAD_RESULTS_DIR` | `results` | k6 JSON summary directory (relative to `backend/load/`) |

Outputs:

- `backend/load/results/pilot-<label>.txt` — human-readable k6 summary (safe to commit)
- `backend/load/results/pilot-<label>.json` — full metrics JSON
- `backend/load/.tokens.json` — **gitignored** pilot JWTs; never commit

Seed fixture: `backend/db/seed/seed_test_scenarios/load_presence.sql` (10 drivers, 5 riders, 3 active trips on Zaria-Test).

## Staging / full TS-OPS-03 (5k subscribers)

Set env vars from your secret store (never commit):

```bash
export SUPABASE_URL=https://<project-ref>.supabase.co
export SUPABASE_ANON_KEY=<anon-key>
export SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
export SUPABASE_FUNCTIONS_URL="${SUPABASE_URL}/functions/v1"
# Apply staging seed + mint tokens with JWT_SECRET from staging dashboard
JWT_SECRET=<staging-jwt-secret> DB_URL=<staging-db-url> deno run backend/load/scripts/mint_tokens.ts
export LOAD_TOKENS_FILE=backend/load/.tokens.json
k6 run -e SUPABASE_URL -e SUPABASE_ANON_KEY -e SUPABASE_SERVICE_ROLE_KEY \
  -e SUPABASE_FUNCTIONS_URL -e LOAD_TOKENS_FILE \
  -e DRIVER_VUS=100 -e AMBIENT_SUBSCRIBER_VUS=500 -e TRIP_SUBSCRIBER_VUS=5000 \
  -e DURATION=10m backend/load/presence_pilot.js
```

Full 5k `trip:*` subscribers is **TS-OPS-03** target scale (Phase 7 nightly). P3-E-01 pilot validates scripts + budgets at reduced concurrency.

## Fan-out tuning

Only adjust via existing `app_config` keys (migrations / ADR-0016 — no hand-edited prod):

| Key | Default | Budget |
|---|---|---|
| `presence.fanout_interval_s` | `10` | ambient fan-out latency ≤ 10 s |
| `presence.fanout_radius_m` | `3000` | cell publish radius |
| `realtime.max_payload_bytes` | `512` | broadcast payload cap |
| `presence.ping_min_interval_s` | `2` | server-side ping throttle |

After k6, if ambient fan-out p95 exceeds 10 s, reduce `presence.fanout_interval_s` for the target city/deployment via `app_config` override (not code).

## Scenarios

| Script | TS-ID | What it exercises |
|---|---|---|
| `presence_pilot.js` | TS-OPS-03 (pilot) | `presence_ping` RPC load + `ambient:*` / `trip:*` Realtime subscribers + `presence-fanout` Edge Function |

Phase 7 adds `plan_trip_mix.js` for **TS-OPS-02** (200 rps plan-trip + 1k pings/s).
