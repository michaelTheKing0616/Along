#!/usr/bin/env bash
# Verifies check_rls_coverage.sql fails on a table without RLS and passes after cleanup.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUNNER="$ROOT/backend/db/scripts/run_rls_coverage.sh"
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
TABLE="_rls_coverage_test_$(date +%s)"

if ! command -v psql >/dev/null 2>&1; then
  echo "SKIP: psql not available — start Supabase locally to run this test."
  exit 0
fi

if ! psql "$DB_URL" -c 'SELECT 1' >/dev/null 2>&1; then
  echo "SKIP: local Postgres not reachable at $DB_URL — run supabase start first."
  exit 0
fi

cleanup() {
  psql "$DB_URL" -v ON_ERROR_STOP=1 -c "DROP TABLE IF EXISTS public.${TABLE};" >/dev/null
}
trap cleanup EXIT

echo "== RLS coverage test: expect PASS on clean schema =="
"$RUNNER"

psql "$DB_URL" -v ON_ERROR_STOP=1 -c "CREATE TABLE public.${TABLE} (id int);"

echo "== RLS coverage test: expect FAIL with table lacking RLS =="
if "$RUNNER" >/dev/null 2>&1; then
  echo "FAIL: RLS coverage check should have failed for public.${TABLE} without RLS."
  exit 1
fi
echo "PASS: RLS coverage check correctly failed for table without RLS."

cleanup
trap - EXIT

echo "== RLS coverage test: expect PASS after dropping offending table =="
"$RUNNER"

echo "PASS: RLS coverage regression test complete."
