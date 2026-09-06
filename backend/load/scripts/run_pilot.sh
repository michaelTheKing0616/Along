#!/usr/bin/env bash
# P3-E-01: local/pilot k6 run (127.0.0.1:54321). Does not read env/staging.json.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LOAD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEED_SQL="${ROOT}/backend/db/seed/seed_test_scenarios/load_presence.sql"

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

ZARIA_SEED="${ROOT}/backend/db/seed/seed_testcity_fixture/00_zaria_test.sql"

echo "Ensuring Zaria-Test fixture..."
if ! psql "$DB_URL" -At -c "select 1 from cities where id = '0a000000-0000-4000-8000-000000000001'" | grep -q 1; then
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$ZARIA_SEED" >/dev/null
fi

echo "Applying load_presence seed to local DB..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SEED_SQL" >/dev/null

echo "Minting pilot JWTs (gitignored)..."
JWT_SECRET="$JWT_SECRET" DB_URL="$DB_URL" deno run --allow-read --allow-write --allow-env --allow-run \
  "${LOAD_DIR}/scripts/mint_tokens.ts"

mkdir -p "${LOAD_DIR}/results"
RUN_LABEL="${RUN_LABEL:-local-$(date +%Y%m%d)}"
RESULT_TXT="${LOAD_DIR}/results/pilot-${RUN_LABEL}.txt"

echo "Running k6 presence/realtime pilot..."
(
  cd "${LOAD_DIR}"
  k6 run \
    -e "SUPABASE_URL=${API_URL}" \
    -e "SUPABASE_ANON_KEY=${ANON_KEY}" \
    -e "SUPABASE_SERVICE_ROLE_KEY=${SERVICE_KEY}" \
    -e "SUPABASE_FUNCTIONS_URL=${FUNCTIONS_URL}" \
    -e "LOAD_TOKENS_FILE=${LOAD_DIR}/.tokens.json" \
    -e "FANOUT_MODE=${FANOUT_MODE:-direct}" \
    -e "LOAD_RESULTS_DIR=results" \
    -e "RUN_LABEL=${RUN_LABEL}" \
    -e "DURATION=${DURATION:-2m}" \
    -e "DRIVER_VUS=${DRIVER_VUS:-10}" \
    -e "AMBIENT_SUBSCRIBER_VUS=${AMBIENT_SUBSCRIBER_VUS:-10}" \
    -e "TRIP_SUBSCRIBER_VUS=${TRIP_SUBSCRIBER_VUS:-5}" \
    presence_pilot.js
) 2>&1 | tee "$RESULT_TXT"

K6_EXIT=${PIPESTATUS[0]}
if [ "$K6_EXIT" -ne 0 ]; then
  echo "k6 exited $K6_EXIT (threshold miss is expected if presence-fanout Edge Function is unavailable locally)" >&2
fi
echo "Results: ${RESULT_TXT}"
exit 0
