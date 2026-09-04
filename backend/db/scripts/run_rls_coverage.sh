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

tables=()
while IFS='|' read -r schema table; do
  schema="${schema// /}"
  table="${table// /}"
  [ -n "$table" ] || continue
  tables+=("${schema}.${table}")
done < <(
  psql "$DB_URL" -At -c "
    SELECT n.nspname, c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND n.nspname IN ('public', 'private')
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        WHERE d.classid = 'pg_class'::regclass
          AND d.objid = c.oid
          AND d.refobjid IN (SELECT oid FROM pg_extension)
          AND d.deptype = 'e'
      )
    ORDER BY 1, 2;
  "
)

if [ "${#tables[@]}" -gt 0 ]; then
  for qualified in "${tables[@]}"; do
    table="${qualified#*.}"
    if ! find "$ROOT/backend/db/tests" -name '*.sql' -type f -print0 2>/dev/null \
      | xargs -0 grep -l "$table" >/dev/null 2>&1; then
      echo "FAIL: no pgTAP test references table ${qualified} (doc 09 §2 requires RLS + at least one test per table)."
      exit 1
    fi
  done
fi

echo "PASS: RLS coverage check — all Along application tables in public/private have RLS enabled."
