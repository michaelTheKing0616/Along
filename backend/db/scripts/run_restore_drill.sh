#!/usr/bin/env bash
# TS-OPS-01 local restore drill — dump/clone public schema to scratch schema, verify row counts + ledger invariant.
# Local Supabase CLI: pg_restore into a separate database fails on extensions (pg_cron, postgis, etc.).
# This script uses a scratch schema (along_restore_scratch) — equivalent logical restore for TS-OPS-01.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SOURCE_URL="${SOURCE_DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
SCRATCH_SCHEMA="${RESTORE_SCRATCH_SCHEMA:-along_restore_scratch}"
DUMP_FILE="${RESTORE_DUMP_FILE:-${TMPDIR:-/tmp}/along-restore-drill.dump}"
BASELINE_FILE="${RESTORE_BASELINE_FILE:-${TMPDIR:-/tmp}/ts-ops-01-baseline.tsv}"
KEEP_SCRATCH="${KEEP_SCRATCH_SCHEMA:-0}"

cd "$ROOT"

echo "TS-OPS-01 restore drill (local schema mode)"
echo "  source: ${SOURCE_URL}"
echo "  scratch schema: ${SCRATCH_SCHEMA}"
echo "  dump: ${DUMP_FILE}"

KEY_TABLES=(
  cities parks routes route_stages route_legs route_through_fares
  corridors profiles drivers riders trips driver_ledger_entries
  payments app_config app_config_keys deployments countries
)

capture_counts() {
  local url="$1"
  local out="$2"
  psql "$url" -v ON_ERROR_STOP=1 -At <<'SQL' >"$out"
begin;
create temp table ts_ops_01_counts (
  table_name text primary key,
  row_count bigint not null
) on commit drop;

do $$
declare
  v_table text;
  v_count bigint;
  v_tables text[] := array[
    'cities', 'parks', 'routes', 'route_stages', 'route_legs', 'route_through_fares',
    'corridors', 'profiles', 'drivers', 'riders', 'trips', 'driver_ledger_entries',
    'payments', 'app_config', 'app_config_keys', 'deployments', 'countries'
  ];
begin
  foreach v_table in array v_tables loop
    execute format('select count(*)::bigint from public.%I', v_table)
      into v_count;
    insert into ts_ops_01_counts (table_name, row_count)
    values (v_table, v_count);
  end loop;
end;
$$;

copy ts_ops_01_counts to stdout with (format csv, delimiter E'\t', header false);
commit;
SQL
}

echo "== Step 1: pg_dump source (public schema, custom format) =="
pg_dump "$SOURCE_URL" \
  --schema=public \
  --format=custom \
  --no-owner \
  --no-privileges \
  --file="$DUMP_FILE"

echo "== Step 2: capture source row counts =="
capture_counts "$SOURCE_URL" "$BASELINE_FILE"
echo "  baseline written: ${BASELINE_FILE}"
cat "$BASELINE_FILE"

echo "== Step 3: rebuild scratch schema from public (logical restore) =="
psql "$SOURCE_URL" -v ON_ERROR_STOP=1 <<SQL
set restore.scratch_schema = '${SCRATCH_SCHEMA}';
\\i backend/db/scripts/restore_drill_clone_schema.sql
SQL

echo "== Step 4: compare row counts (public vs scratch schema) =="
SCRATCH_COUNTS="$(mktemp "${TMPDIR:-/tmp}/ts-ops-01-scratch.XXXXXX")"
psql "$SOURCE_URL" -v ON_ERROR_STOP=1 -At \
  -v scratch_schema="$SCRATCH_SCHEMA" <<SQL >"$SCRATCH_COUNTS"
begin;
create temp table ts_ops_01_counts (
  table_name text primary key,
  row_count bigint not null
) on commit drop;

do \$\$
declare
  v_table text;
  v_count bigint;
  v_schema text := '${SCRATCH_SCHEMA}';
  v_tables text[] := array[
    'cities', 'parks', 'routes', 'route_stages', 'route_legs', 'route_through_fares',
    'corridors', 'profiles', 'drivers', 'riders', 'trips', 'driver_ledger_entries',
    'payments', 'app_config', 'app_config_keys', 'deployments', 'countries'
  ];
begin
  foreach v_table in array v_tables loop
    execute format('select count(*)::bigint from %I.%I', v_schema, v_table)
      into v_count;
    insert into ts_ops_01_counts (table_name, row_count)
    values (v_table, v_count);
  end loop;
end;
\$\$;

copy ts_ops_01_counts to stdout with (format csv, delimiter E'\t', header false);
commit;
SQL

if ! diff -u "$BASELINE_FILE" "$SCRATCH_COUNTS"; then
  echo "FAIL TS-OPS-01: row counts differ between public and scratch schema"
  exit 1
fi
echo "PASS TS-OPS-01: row counts match source"

echo "== Step 5: TS-OPS-01 ledger invariant on scratch schema =="
psql "$SOURCE_URL" -v ON_ERROR_STOP=1 <<SQL
set restore.scratch_schema = '${SCRATCH_SCHEMA}';
\\i backend/db/scripts/restore_drill_verify_scratch.sql
SQL

if [ "$KEEP_SCRATCH" != "1" ]; then
  echo "== Step 6: drop scratch schema =="
  psql "$SOURCE_URL" -v ON_ERROR_STOP=1 \
    -c "drop schema if exists ${SCRATCH_SCHEMA} cascade;"
else
  echo "== Step 6: KEEP_SCRATCH_SCHEMA=1 — leaving ${SCRATCH_SCHEMA} in place =="
fi

echo "PASS TS-OPS-01 restore drill complete"
