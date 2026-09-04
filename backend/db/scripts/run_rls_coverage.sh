#!/usr/bin/env bash
# Runs check_rls_coverage.sql against the local Supabase Postgres instance.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SQL_FILE="$ROOT/backend/db/scripts/check_rls_coverage.sql"

DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

if ! command -v psql >/dev/null 2>&1; then
  echo "FAIL: psql is required to run the RLS coverage check."
  exit 1
fi

psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SQL_FILE"
echo "PASS: RLS coverage check — all public/private tables have RLS enabled."
