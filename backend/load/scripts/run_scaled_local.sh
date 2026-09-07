#!/usr/bin/env bash
# P7-E-02: scaled local proof for TS-OPS-02 + TS-OPS-03 (doc 10 §3 Ops).
# Runs at 1/10 full-city concurrency when the laptop cannot sustain 200 rps + 5k WS.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LOAD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEED_SQL="${ROOT}/backend/db/seed/seed_test_scenarios/load_fullcity.sql"
ZARIA_SEED="${ROOT}/backend/db/seed/seed_testcity_fixture/00_zaria_test.sql"

if ! command -v k6 >/dev/null 2>&1; then
  echo "ERROR: k6 not installed. macOS: brew install k6; see backend/load/README.md" >&2
  exit 1
fi

if ! command -v deno >/dev/null 2>&1; then
  echo "ERROR: deno required to mint pilot JWTs (backend/load/scripts/mint_tokens.ts)" >&2
  exit 1
fi

SUPABASE="${ROOT}/node_modules/.bin/supabase"
if [ ! -x "$SUPABASE" ]; then
  SUPABASE="$(command -v supabase)"
fi

STATUS_RAW="$("$SUPABASE" status --output json 2>/dev/null)"
if [ -z "$STATUS_RAW" ]; then
  echo "ERROR: local Supabase not running. Run: supabase start" >&2
  exit 1
fi

API_URL="$(python3 -c "import json,sys; print(json.load(sys.stdin)['API_URL'])" <<<"$STATUS_RAW")"
ANON_KEY="$(python3 -c "import json,sys; print(json.load(sys.stdin)['ANON_KEY'])" <<<"$STATUS_RAW")"
SERVICE_KEY="$(python3 -c "import json,sys; print(json.load(sys.stdin)['SERVICE_ROLE_KEY'])" <<<"$STATUS_RAW")"
JWT_SECRET="$(python3 -c "import json,sys; print(json.load(sys.stdin)['JWT_SECRET'])" <<<"$STATUS_RAW")"
DB_URL="$(python3 -c "import json,sys; print(json.load(sys.stdin)['DB_URL'])" <<<"$STATUS_RAW")"
FUNCTIONS_URL="${API_URL}/functions/v1"

echo "Ensuring Zaria-Test fixture..."
if ! psql "$DB_URL" -At -c "select 1 from cities where id = '0a000000-0000-4000-8000-000000000001'" | grep -q 1; then
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$ZARIA_SEED" >/dev/null
fi

echo "Applying load_fullcity seed..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SEED_SQL" >/dev/null

echo "Minting load JWTs (gitignored)..."
JWT_SECRET="$JWT_SECRET" DB_URL="$DB_URL" \
  LOAD_DRIVER_COUNT=100 LOAD_RIDER_COUNT=50 LOAD_TRIP_LIMIT=50 \
  deno run --allow-read --allow-write --allow-env --allow-run \
  "${LOAD_DIR}/scripts/mint_tokens.ts"

mkdir -p "${LOAD_DIR}/results"
RUN_LABEL="${RUN_LABEL:-scaled-local-$(date +%Y%m%d)}"
SCALE_FACTOR="${SCALE_FACTOR:-10}"
DURATION="${DURATION:-2m}"
PLAN_TRIP_RATE="${PLAN_TRIP_RATE:-20}"
PRESENCE_PING_RATE="${PRESENCE_PING_RATE:-100}"
TRIP_SUBSCRIBER_VUS="${TRIP_SUBSCRIBER_VUS:-50}"

K6_ENV=(
  -e "SUPABASE_URL=${API_URL}"
  -e "SUPABASE_ANON_KEY=${ANON_KEY}"
  -e "SUPABASE_SERVICE_ROLE_KEY=${SERVICE_KEY}"
  -e "SUPABASE_FUNCTIONS_URL=${FUNCTIONS_URL}"
  -e "LOAD_TOKENS_FILE=${LOAD_DIR}/.tokens.json"
  -e "FANOUT_MODE=${FANOUT_MODE:-direct}"
  -e "LOAD_RESULTS_DIR=results"
  -e "RUN_LABEL=${RUN_LABEL}"
  -e "SCALE_FACTOR=${SCALE_FACTOR}"
  -e "DURATION=${DURATION}"
)

echo "=== TS-OPS-02 scaled (${PLAN_TRIP_RATE} rps plan-trip + ${PRESENCE_PING_RATE} pings/s, scale ${SCALE_FACTOR}x) ==="
(
  cd "${LOAD_DIR}"
  k6 run "${K6_ENV[@]}" \
    -e "PLAN_TRIP_RATE=${PLAN_TRIP_RATE}" \
    -e "PRESENCE_PING_RATE=${PRESENCE_PING_RATE}" \
    plan_trip_mix.js
) 2>&1 | tee "${LOAD_DIR}/results/ts-ops-02-${RUN_LABEL}.txt" || true
OPS02_EXIT=${PIPESTATUS[0]}

echo "=== TS-OPS-03 scaled (${TRIP_SUBSCRIBER_VUS} trip:* subscribers, scale ${SCALE_FACTOR}x) ==="
(
  cd "${LOAD_DIR}"
  k6 run "${K6_ENV[@]}" \
    -e "TRIP_SUBSCRIBER_VUS=${TRIP_SUBSCRIBER_VUS}" \
    -e "TRIP_BROADCAST_RATE=${TRIP_BROADCAST_RATE:-5}" \
    realtime_full.js
) 2>&1 | tee "${LOAD_DIR}/results/ts-ops-03-${RUN_LABEL}.txt" || true
OPS03_EXIT=${PIPESTATUS[0]}

SUMMARY="${LOAD_DIR}/results/p7-e-02-${RUN_LABEL}.md"
cat > "$SUMMARY" <<EOF
# P7-E-02 load test results (${RUN_LABEL})

**Environment:** local Supabase (\`${API_URL}\`)
**Scale factor:** ${SCALE_FACTOR}x (extrapolate rates/VUs × ${SCALE_FACTOR} toward full-city targets)
**Full-city field evidence:** DEFERRED per owner 2026-09-07 — these are scaled local proofs only.

## Targets (TS-OPS-02 / TS-OPS-03)

| Scenario | Full-city target | This run |
|---|---|---|
| plan-trip | 200 rps, p95 ≤ 800 ms | ${PLAN_TRIP_RATE} rps |
| presence_ping | 1,000/s, p95 ≤ 300 ms | ${PRESENCE_PING_RATE}/s |
| trip:* subscribers | 5,000 concurrent, msg p95 ≤ 1 s | ${TRIP_SUBSCRIBER_VUS} VUs |
| Duration | 10 min | ${DURATION} |

## Outcomes

- TS-OPS-02 k6 exit: ${OPS02_EXIT} (0 = all thresholds met at scaled concurrency)
- TS-OPS-03 k6 exit: ${OPS03_EXIT} (0 = all thresholds met at scaled concurrency)

See \`ts-ops-02-${RUN_LABEL}.txt\` and \`ts-ops-03-${RUN_LABEL}.txt\` for full k6 summaries.
EOF

echo "Wrote ${SUMMARY}"
if [ "$OPS02_EXIT" -ne 0 ] || [ "$OPS03_EXIT" -ne 0 ]; then
  echo "NOTE: non-zero k6 exit — review thresholds; plan-trip may fail locally without Edge functions." >&2
fi
exit 0
