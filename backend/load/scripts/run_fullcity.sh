#!/usr/bin/env bash
# P7-E-02: full-city k6 targets for staging/CI (TS-OPS-02 + TS-OPS-03).
# Requires env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, JWT_SECRET, DB_URL
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LOAD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEED_SQL="${ROOT}/backend/db/seed/seed_test_scenarios/load_fullcity.sql"

if ! command -v k6 >/dev/null 2>&1; then
  echo "ERROR: k6 not installed" >&2
  exit 1
fi

: "${SUPABASE_URL:?SUPABASE_URL required}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY required}"
: "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY required}"
: "${JWT_SECRET:?JWT_SECRET required}"
: "${DB_URL:?DB_URL required}"

FUNCTIONS_URL="${SUPABASE_FUNCTIONS_URL:-${SUPABASE_URL}/functions/v1}"
RUN_LABEL="${RUN_LABEL:-staging-$(date +%Y%m%d)}"
DURATION="${DURATION:-10m}"
PLAN_TRIP_RATE="${PLAN_TRIP_RATE:-200}"
PRESENCE_PING_RATE="${PRESENCE_PING_RATE:-1000}"
TRIP_SUBSCRIBER_VUS="${TRIP_SUBSCRIBER_VUS:-5000}"

echo "Applying load_fullcity seed to target DB..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SEED_SQL" >/dev/null

echo "Minting load JWTs..."
JWT_SECRET="$JWT_SECRET" DB_URL="$DB_URL" \
  LOAD_DRIVER_COUNT=100 LOAD_RIDER_COUNT=50 LOAD_TRIP_LIMIT=50 \
  deno run --allow-read --allow-write --allow-env --allow-run \
  "${LOAD_DIR}/scripts/mint_tokens.ts"

mkdir -p "${LOAD_DIR}/results"

K6_ENV=(
  -e "SUPABASE_URL=${SUPABASE_URL}"
  -e "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
  -e "SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}"
  -e "SUPABASE_FUNCTIONS_URL=${FUNCTIONS_URL}"
  -e "LOAD_TOKENS_FILE=${LOAD_DIR}/.tokens.json"
  -e "FANOUT_MODE=${FANOUT_MODE:-edge}"
  -e "LOAD_RESULTS_DIR=results"
  -e "RUN_LABEL=${RUN_LABEL}"
  -e "SCALE_FACTOR=1"
  -e "DURATION=${DURATION}"
)

echo "=== TS-OPS-02 full city ==="
(
  cd "${LOAD_DIR}"
  k6 run "${K6_ENV[@]}" \
    -e "PLAN_TRIP_RATE=${PLAN_TRIP_RATE}" \
    -e "PRESENCE_PING_RATE=${PRESENCE_PING_RATE}" \
    plan_trip_mix.js
) 2>&1 | tee "${LOAD_DIR}/results/ts-ops-02-${RUN_LABEL}.txt"

echo "=== TS-OPS-03 full city ==="
(
  cd "${LOAD_DIR}"
  k6 run "${K6_ENV[@]}" \
    -e "TRIP_SUBSCRIBER_VUS=${TRIP_SUBSCRIBER_VUS}" \
    -e "TRIP_BROADCAST_RATE=${TRIP_BROADCAST_RATE:-10}" \
    realtime_full.js
) 2>&1 | tee "${LOAD_DIR}/results/ts-ops-03-${RUN_LABEL}.txt"

echo "Full-city run complete. Results under backend/load/results/"
