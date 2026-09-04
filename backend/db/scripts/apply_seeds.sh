#!/usr/bin/env bash
# Apply optional graph seeds after seed_core (doc 02 §17, P0-E-04).
# seed_core remains the only path in supabase/config.toml [db.seed] — this script is manual/CI opt-in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SEED_DIR="$ROOT/backend/db/seed"
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

apply() {
  local label="$1"
  local file="$2"
  echo "Applying $label ..."
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$file"
}

cd "$SEED_DIR"

case "${1:-all}" in
  core)
    apply seed_core seed_core.sql
    ;;
  abuja)
    apply seed_abuja_pilot seed_abuja_pilot/load.sql
    ;;
  testcity)
    apply seed_testcity_fixture seed_testcity_fixture/load.sql
    ;;
  scenarios)
    apply seed_test_scenarios seed_test_scenarios/load.sql
    ;;
  all)
    apply seed_core seed_core.sql
    apply seed_abuja_pilot seed_abuja_pilot/load.sql
    apply seed_testcity_fixture seed_testcity_fixture/load.sql
    apply seed_test_scenarios seed_test_scenarios/load.sql
    ;;
  *)
    echo "Usage: $0 [core|abuja|testcity|scenarios|all]"
    exit 1
    ;;
esac

echo "Done."
