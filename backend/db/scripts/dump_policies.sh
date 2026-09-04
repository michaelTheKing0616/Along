#!/usr/bin/env bash
# Regenerate backend/db/policies/*.sql from pg_policies (ADR-0015, doc 09 §3).
# Run after supabase db reset against the local Supabase Postgres instance.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT_DIR="$ROOT/backend/db/policies"
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

if ! command -v psql >/dev/null 2>&1; then
  echo "FAIL: psql is required to dump RLS policies."
  exit 1
fi

mkdir -p "$OUT_DIR"

TABLES=()
while IFS='|' read -r schema table enabled forced; do
  schema="${schema// /}"
  table="${table// /}"
  enabled="${enabled// /}"
  forced="${forced// /}"
  [ -n "$table" ] || continue
  TABLES+=("${schema}|${table}|${enabled}|${forced}")
done < <(
  psql "$DB_URL" -v ON_ERROR_STOP=1 -At -c "
    SELECT n.nspname, c.relname,
           CASE WHEN c.relrowsecurity THEN 'true' ELSE 'false' END,
           CASE WHEN c.relforcerowsecurity THEN 'true' ELSE 'false' END
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'p')  -- include partitioned parent tables (relkind = p)
      AND NOT c.relispartition     -- exclude partition children; parent policies apply
      AND c.relrowsecurity
      AND n.nspname IN ('public', 'private')
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        WHERE d.classid = 'pg_class'::regclass
          AND d.objid = c.oid
          AND d.refobjid IN (SELECT oid FROM pg_extension)
          AND d.deptype = 'e'
      )
    ORDER BY n.nspname, c.relname;
  "
)

if [ "${#TABLES[@]}" -eq 0 ]; then
  echo "FAIL: no RLS-enabled Along application tables found — is the local DB running?"
  exit 1
fi

EXPECTED_LIST="$(mktemp)"
trap 'rm -f "$EXPECTED_LIST"' EXIT

for entry in "${TABLES[@]}"; do
  IFS='|' read -r schema table enabled forced <<< "$entry"
  outfile="$OUT_DIR/${table}.sql"
  echo "$outfile" >> "$EXPECTED_LIST"

  {
    echo "-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh"
    echo "-- Table: ${schema}.${table}"
    echo "-- RLS enabled: ${enabled}"
    echo "-- RLS forced: ${forced}"
    echo

    table_ref="$table"
    if [ "$schema" != "public" ]; then
      table_ref="${schema}.${table}"
    fi

    policy_sql="$(
      psql "$DB_URL" -v ON_ERROR_STOP=1 -At <<SQL
WITH normalized AS (
  SELECT
    p.*,
    CASE
      WHEN p.qual IS NOT NULL AND p.qual LIKE '(%' AND right(p.qual, 1) = ')'
        THEN substring(p.qual from 2 for length(p.qual) - 2)
      ELSE p.qual
    END AS qual_expr,
    CASE
      WHEN p.with_check IS NOT NULL AND p.with_check LIKE '(%' AND right(p.with_check, 1) = ')'
        THEN substring(p.with_check from 2 for length(p.with_check) - 2)
      ELSE p.with_check
    END AS with_check_expr
  FROM pg_policies p
  WHERE p.schemaname = '${schema}'
    AND p.tablename = '${table}'
)
SELECT coalesce(
  string_agg(
    CASE
      WHEN cmd = 'INSERT' AND (qual IS NULL OR btrim(qual) = '') AND with_check IS NOT NULL THEN
        format(
          E'create policy %I\n  on ${table_ref} for insert to %s\n  with check (%s);',
          policyname,
          array_to_string(roles, ', '),
          with_check_expr
        )
      WHEN with_check IS NOT NULL AND (qual IS NOT NULL AND btrim(qual) <> '') THEN
        format(
          E'create policy %I\n  on ${table_ref} for %s to %s\n  using (%s)\n  with check (%s);',
          policyname,
          lower(cmd),
          array_to_string(roles, ', '),
          qual_expr,
          with_check_expr
        )
      WHEN with_check IS NOT NULL THEN
        format(
          E'create policy %I\n  on ${table_ref} for %s to %s\n  with check (%s);',
          policyname,
          lower(cmd),
          array_to_string(roles, ', '),
          with_check_expr
        )
      ELSE
        format(
          E'create policy %I\n  on ${table_ref} for %s to %s\n  using (%s);',
          policyname,
          lower(cmd),
          array_to_string(roles, ', '),
          qual_expr
        )
    END,
    E'\n\n'
    ORDER BY policyname
  ),
  '-- (no policies)'
)
FROM normalized;
SQL
    )"

    printf '%s\n' "$policy_sql"
  } > "$outfile"
done

shopt -s nullglob
for existing in "$OUT_DIR"/*.sql; do
  if ! grep -Fxq "$existing" "$EXPECTED_LIST"; then
    rm -f "$existing"
  fi
done
shopt -u nullglob

echo "PASS: regenerated ${#TABLES[@]} RLS policy snapshot file(s) in backend/db/policies/."
