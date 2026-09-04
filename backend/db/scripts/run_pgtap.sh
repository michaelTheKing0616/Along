#!/usr/bin/env bash
# pgTAP gate (doc 09 §2). Fails when required SQL tests are missing or pg_prove fails.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TEST_DIR="$ROOT/backend/db/tests"

tests=()
while IFS= read -r file; do
  tests+=("$file")
done < <(find "$TEST_DIR" -name '*.sql' -type f | sort)

if [ "${#tests[@]}" -eq 0 ]; then
  echo "FAIL: no pgTAP tests found under backend/db/tests/ (required by doc 09 §2; first tests land in P0-A-01)."
  exit 1
fi

if ! command -v pg_prove >/dev/null 2>&1; then
  echo "FAIL: pg_prove is not installed (required to run backend/db/tests/**/*.sql)."
  exit 1
fi

DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
pg_prove -d "$DB_URL" "${tests[@]}"
