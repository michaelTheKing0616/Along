#!/usr/bin/env bash
# Authorization matrix gate (P11-A-01, doc 02 §16).
# 1) Runs machine-checkable non-negotiable SQL checks (fails CI on security drift).
# 2) Regenerates docs/reports/p11-a-01-authz-matrix.md from live pg_policies.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SQL_FILE="$ROOT/backend/db/scripts/check_authz_matrix.sql"
REPORT="$ROOT/docs/reports/p11-a-01-authz-matrix.md"
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

if ! command -v psql >/dev/null 2>&1; then
  echo "FAIL: psql is required for the authz matrix check."
  exit 1
fi

echo "== Authz matrix: non-negotiable SQL checks =="
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SQL_FILE"
echo "PASS: authz matrix non-negotiable checks."

mkdir -p "$(dirname "$REPORT")"
generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

{
  echo "# P11-A-01 Authorization Matrix"
  echo
  echo "**Generated:** ${generated_at} (UTC) from live \`pg_policies\` on \`${DB_URL%%@*}@…\`"
  echo "**Source of truth for expectations:** doc 02 §16 + per-table \`-- RLS:\` comments"
  echo
  echo "## Legend"
  echo
  echo "| Status | Meaning |"
  echo "|---|---|"
  echo "| MATCH | Live policies align with doc 02 §16 summary |"
  echo "| DRIFT | Live policy weaker or missing vs doc — security fix required |"
  echo "| DOC-STALE | Live policy is intentional later-phase behaviour; doc §16 row not yet updated |"
  echo
  echo "## Summary"
  echo

  psql "$DB_URL" -v ON_ERROR_STOP=1 -At <<'SUMMARY_SQL'
WITH tables AS (
  SELECT n.nspname AS schema_name, c.relname AS table_name, c.relrowsecurity AS rls_enabled
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname IN ('public', 'private')
    AND NOT c.relispartition
    AND NOT EXISTS (
      SELECT 1 FROM pg_depend d
      WHERE d.classid = 'pg_class'::regclass AND d.objid = c.oid
        AND d.refobjid IN (SELECT oid FROM pg_extension) AND d.deptype = 'e'
    )
),
classified AS (
  SELECT
    t.schema_name,
    t.table_name,
    t.rls_enabled,
    CASE
      WHEN NOT t.rls_enabled THEN 'DRIFT'
      WHEN t.schema_name = 'private' THEN 'MATCH'
      WHEN t.table_name IN (
        'api_keys', 'api_usage', 'corporate_accounts', 'corporate_invoices',
        'corporate_members', 'corporate_trip_allocations', 'corporate_trip_policies',
        'invoice_lines', 'operator_accounts', 'operator_members',
        'placement_counters', 'sponsored_placements', 'device_installs'
      ) THEN 'DOC-STALE'
      WHEN t.table_name = 'countries' AND EXISTS (
        SELECT 1 FROM pg_policies p
        WHERE p.schemaname = 'public' AND p.tablename = 'countries'
          AND 'anon' = ANY(p.roles)
      ) THEN 'DOC-STALE'
      WHEN t.table_name = 'driver_presence' AND NOT EXISTS (
        SELECT 1 FROM pg_policies p
        WHERE p.schemaname = 'public' AND p.tablename = 'driver_presence'
          AND p.cmd IN ('SELECT', 'ALL') AND 'authenticated' = ANY(p.roles)
          AND coalesce(p.qual, '') NOT IN ('false', '(false)')
          AND coalesce(p.qual, '') NOT LIKE '%driver_id = auth.uid()%'
          AND coalesce(p.qual, '') NOT LIKE '%has_admin_role%'
      ) THEN 'MATCH'
      WHEN t.table_name = 'driver_presence' THEN 'DRIFT'
      WHEN t.table_name IN ('profiles', 'riders', 'driver_verifications', 'fare_quotes', 'trips')
        AND EXISTS (
          SELECT 1 FROM pg_policies p
          WHERE p.schemaname = 'public' AND p.tablename = t.table_name
            AND p.policyname LIKE '%_select_admin'
            AND (
              (t.table_name = 'profiles' AND coalesce(p.qual, '') LIKE '%admin_can_access_profile%')
              OR (t.table_name = 'riders' AND coalesce(p.qual, '') LIKE '%admin_can_access_city%')
              OR (t.table_name IN ('driver_verifications', 'fare_quotes', 'trips')
                  AND coalesce(p.qual, '') LIKE '%admin_can_access_city%')
            )
        ) THEN 'MATCH'
      WHEN t.table_name IN ('profiles', 'riders', 'driver_verifications', 'fare_quotes') THEN 'DRIFT'
      ELSE 'MATCH'
    END AS status
  FROM tables t
)
SELECT format('| %s | %s |', status, count(*))
FROM classified
GROUP BY status
ORDER BY CASE status WHEN 'DRIFT' THEN 1 WHEN 'DOC-STALE' THEN 2 ELSE 3 END;
SUMMARY_SQL

  echo
  echo "## Per-table matrix"
  echo
  echo "| Schema | Table | RLS | Policies | Doc §16 row | Status | Notes |"
  echo "|---|---|---:|---:|---|---|---|"

  psql "$DB_URL" -v ON_ERROR_STOP=1 -At -F $'\t' <<'MATRIX_SQL'
WITH tables AS (
  SELECT n.nspname AS schema_name, c.relname AS table_name, c.relrowsecurity AS rls_enabled
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname IN ('public', 'private')
    AND NOT c.relispartition
    AND NOT EXISTS (
      SELECT 1 FROM pg_depend d
      WHERE d.classid = 'pg_class'::regclass AND d.objid = c.oid
        AND d.refobjid IN (SELECT oid FROM pg_extension) AND d.deptype = 'e'
    )
),
policy_counts AS (
  SELECT schemaname, tablename, count(*) AS policy_count
  FROM pg_policies
  GROUP BY schemaname, tablename
),
doc_rows AS (
  SELECT * FROM (VALUES
    ('countries', 'geo/config'),
    ('cities', 'geo/config'),
    ('corridors', 'geo/config'),
    ('mode_config', 'geo/config'),
    ('app_config', 'geo/config'),
    ('profiles', 'profiles'),
    ('riders', 'riders'),
    ('drivers', 'drivers'),
    ('vehicles', 'vehicles'),
    ('driver_verifications', 'driver_verifications'),
    ('guarantor_ack_tokens', 'private.*'),
    ('payment_webhook_raw', 'private.*'),
    ('qr_resolve_rate_buckets', 'private.*'),
    ('api_rate_windows', 'private.*'),
    ('identity_hashes', 'private.*'),
    ('parks', 'graph'),
    ('routes', 'graph'),
    ('route_stages', 'graph'),
    ('route_legs', 'graph'),
    ('route_through_fares', 'graph'),
    ('transfer_points', 'graph'),
    ('graph_confirmations', 'graph_confirmations'),
    ('graph_revisions', 'intelligence'),
    ('driver_route_profiles', 'driver_route_profiles'),
    ('driver_route_stops', 'driver_route_profiles'),
    ('driver_presence', 'driver_presence'),
    ('driver_presence_history', 'driver_presence_history'),
    ('fare_quotes', 'fare_quotes'),
    ('planner_queries', 'planner_queries'),
    ('coverage_gap_reports', 'coverage_gap_reports'),
    ('journeys', 'journeys'),
    ('trips', 'trips'),
    ('trip_events', 'trip_events'),
    ('trip_location_samples', 'trip_location_samples'),
    ('trip_extensions', 'trip_extensions'),
    ('price_negotiations', 'negotiations'),
    ('price_negotiation_rounds', 'negotiations'),
    ('driver_ledger_entries', 'driver_ledger_entries'),
    ('settlements', 'settlements'),
    ('payments', 'payments'),
    ('rider_payment_methods', 'rider_payment_methods'),
    ('driver_standing_transitions', 'driver_standing_transitions'),
    ('guarantors', 'guarantors'),
    ('trip_reconciliation_flags', 'trip_reconciliation_flags'),
    ('driver_risk_scores', 'trip_reconciliation_flags'),
    ('ratings', 'ratings'),
    ('trip_shares', 'trip_shares'),
    ('sos_alerts', 'sos_alerts'),
    ('incidents', 'incidents'),
    ('itineraries', 'itineraries'),
    ('itinerary_stops', 'itineraries'),
    ('audit_log', 'audit_log'),
    ('notifications', 'notifications'),
    ('device_tokens', 'device_tokens'),
    ('api_keys', '(later-phase B2B)'),
    ('api_usage', '(later-phase B2B)'),
    ('corporate_accounts', '(later-phase corporate)'),
    ('corporate_invoices', '(later-phase corporate)'),
    ('corporate_members', '(later-phase corporate)'),
    ('corporate_trip_allocations', '(later-phase corporate)'),
    ('corporate_trip_policies', '(later-phase corporate)'),
    ('invoice_lines', '(later-phase corporate)'),
    ('operator_accounts', '(later-phase operator)'),
    ('operator_members', '(later-phase operator)'),
    ('sponsored_placements', '(later-phase ads)'),
    ('placement_counters', '(later-phase ads)')
  ) AS d(table_name, doc_row)
),
classified AS (
  SELECT
    t.schema_name,
    t.table_name,
    t.rls_enabled,
    coalesce(pc.policy_count, 0) AS policy_count,
    coalesce(dr.doc_row, '(not in §16 matrix)') AS doc_row,
    CASE
      WHEN NOT t.rls_enabled THEN 'DRIFT'
      WHEN t.schema_name = 'private' THEN 'MATCH'
      WHEN t.table_name IN (
        'api_keys', 'api_usage', 'corporate_accounts', 'corporate_invoices',
        'corporate_members', 'corporate_trip_allocations', 'corporate_trip_policies',
        'invoice_lines', 'operator_accounts', 'operator_members',
        'placement_counters', 'sponsored_placements', 'device_installs'
      ) THEN 'DOC-STALE'
      WHEN t.table_name = 'countries' AND EXISTS (
        SELECT 1 FROM pg_policies p
        WHERE p.schemaname = 'public' AND p.tablename = 'countries' AND 'anon' = ANY(p.roles)
      ) THEN 'DOC-STALE'
      WHEN t.table_name = 'driver_presence' AND NOT EXISTS (
        SELECT 1 FROM pg_policies p
        WHERE p.schemaname = 'public' AND p.tablename = 'driver_presence'
          AND p.cmd IN ('SELECT', 'ALL') AND 'authenticated' = ANY(p.roles)
          AND coalesce(p.qual, '') NOT IN ('false', '(false)')
          AND coalesce(p.qual, '') NOT LIKE '%driver_id = auth.uid()%'
          AND coalesce(p.qual, '') NOT LIKE '%has_admin_role%'
      ) THEN 'MATCH'
      WHEN t.table_name = 'driver_presence' THEN 'DRIFT'
      WHEN t.table_name IN ('profiles', 'riders', 'driver_verifications', 'fare_quotes', 'trips')
        AND EXISTS (
          SELECT 1 FROM pg_policies p
          WHERE p.schemaname = 'public' AND p.tablename = t.table_name
            AND p.policyname LIKE '%_select_admin'
            AND (
              (t.table_name = 'profiles' AND coalesce(p.qual, '') LIKE '%admin_can_access_profile%')
              OR (t.table_name = 'riders' AND coalesce(p.qual, '') LIKE '%admin_can_access_city%')
              OR (t.table_name IN ('driver_verifications', 'fare_quotes', 'trips')
                  AND coalesce(p.qual, '') LIKE '%admin_can_access_city%')
            )
        ) THEN 'MATCH'
      WHEN t.table_name IN ('profiles', 'riders', 'driver_verifications', 'fare_quotes') THEN 'DRIFT'
      ELSE 'MATCH'
    END AS status,
    CASE
      WHEN NOT t.rls_enabled THEN 'missing RLS'
      WHEN t.schema_name = 'private' THEN 'service role only; RLS on, no client policies'
      WHEN t.table_name IN (
        'api_keys', 'api_usage', 'corporate_accounts', 'corporate_invoices',
        'corporate_members', 'corporate_trip_allocations', 'corporate_trip_policies',
        'invoice_lines', 'operator_accounts', 'operator_members',
        'placement_counters', 'sponsored_placements'
      ) THEN 'Phase 8/10 B2B/corporate/operator policies — §16 row pending'
      WHEN t.table_name = 'countries' THEN 'anon active-country read added P9-A-01 onboarding'
      WHEN t.table_name = 'driver_presence' THEN 'no rider SELECT; Tier-A via ambient_vehicles()'
      WHEN t.table_name IN ('profiles', 'riders', 'driver_verifications', 'fare_quotes', 'trips')
        THEN 'city-scoped admin via admin_can_access_* (00079)'
      ELSE ''
    END AS notes
  FROM tables t
  LEFT JOIN policy_counts pc ON pc.schemaname = t.schema_name AND pc.tablename = t.table_name
  LEFT JOIN doc_rows dr ON dr.table_name = t.table_name
)
SELECT format(
  '| %s | %s | %s | %s | %s | %s | %s |',
  schema_name,
  table_name,
  CASE WHEN rls_enabled THEN 'yes' ELSE '**no**' END,
  policy_count,
  doc_row,
  status,
  notes
)
FROM classified
ORDER BY
  CASE status WHEN 'DRIFT' THEN 1 WHEN 'DOC-STALE' THEN 2 ELSE 3 END,
  schema_name,
  table_name;
MATRIX_SQL

  echo
  echo "## Non-negotiables (doc 02 §16 footer, enforced by \`check_authz_matrix.sql\`)"
  echo
  echo "- Every \`public\`/\`private\` application table has RLS enabled"
  echo "- \`private.*\` has no \`anon\`/\`authenticated\` policies (service role + SECURITY DEFINER RPCs only)"
  echo "- \`driver_presence\` has zero rider-readable SELECT policies"
  echo "- \`profiles\`/\`riders\`/\`driver_verifications\`/\`fare_quotes\` admin SELECT is city-scoped"
  echo "- \`trips_select_admin\` includes \`city_admin\` (parity with \`journeys\`)"
  echo
  echo "## Fixes applied (migration 00079)"
  echo
  echo "- Enabled RLS on \`private.guarantor_ack_tokens\`, \`private.payment_webhook_raw\`, \`private.qr_resolve_rate_buckets\`"
  echo "- Added \`admin_can_access_profile(uuid)\` SECURITY DEFINER helper"
  echo "- Scoped \`profiles_select_admin\`, \`riders_select_admin\`, \`driver_verifications_*_admin\`, \`fare_quotes_select_admin\`"
  echo "- Added \`city_admin\` to \`trips_select_admin\`"
  echo
  echo "_Regenerate: \`bash backend/db/scripts/check_authz_matrix.sh\`_"
} > "$REPORT"

drift_count="$(grep -cE '^\| (public|private) \|.*\| DRIFT \|' "$REPORT" || true)"
if [ "${drift_count}" -gt 0 ]; then
  echo "FAIL: authz matrix report lists ${drift_count} DRIFT row(s) — see ${REPORT}"
  exit 1
fi

echo "PASS: authz matrix report generated at ${REPORT} (0 DRIFT rows)."
