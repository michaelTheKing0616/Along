#!/usr/bin/env bash
# TS-CFG-02 gate (doc 10 §143, ADR-0016): migrations alone, no seed — every §2.3 key resolves.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SUPABASE="$ROOT/node_modules/.bin/supabase"
TEST="$ROOT/backend/db/tests/TS-CFG-02.sql"
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

if [ ! -x "$SUPABASE" ]; then
  SUPABASE="$(command -v supabase)"
fi

"$SUPABASE" db reset --yes --no-seed

if ! command -v pg_prove >/dev/null 2>&1; then
  echo "FAIL: pg_prove is not installed (required for TS-CFG-02)."
  exit 1
fi

pg_prove -d "$DB_URL" "$TEST"
