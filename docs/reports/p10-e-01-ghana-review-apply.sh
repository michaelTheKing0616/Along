#!/usr/bin/env bash
# P10-E-01 — Ghana-Review hypothetical country dry-run / apply script.
# Config/data only — no application-code fork. digital_enabled stays false.
set -euo pipefail

DATABASE_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEPLOYMENT_ID="${DEPLOYMENT_ID:-a0000000-0000-4000-8000-000000000001}"
ADMIN_USER_ID="${ADMIN_USER_ID:-0f000000-0000-4000-8000-000000000002}"
APPLY="${APPLY:-0}"

echo "== P10-E-01 Ghana-Review dry-run (APPLY=${APPLY}) =="
echo "DATABASE_URL=${DATABASE_URL}"

# Ensure markets RPC migration is present (idempotent)
if ! psql "$DATABASE_URL" -tAc "select 1 from pg_proc where proname = 'admin_upsert_country'" | grep -q 1; then
  echo "Applying migration 00078 (admin_upsert_country)..."
  psql "$DATABASE_URL" -f "$REPO_ROOT/backend/db/migrations/00000000000078_admin_markets_country_rpc.sql" >/dev/null
fi

echo ""
echo "-- Steps 1–3: country RPCs + verification (single transaction) --"
psql "$DATABASE_URL" <<SQL
begin;

insert into auth.users (id, aud, role, phone) values
  ('${ADMIN_USER_ID}', 'authenticated', 'authenticated', '+2338000000101')
on conflict (id) do nothing;

insert into admin_users (id, role, deployment_id) values
  ('${ADMIN_USER_ID}', 'ops_lead', '${DEPLOYMENT_ID}')
on conflict (id) do update set role = excluded.role, deployment_id = excluded.deployment_id;

select set_config('request.jwt.claim.sub', '${ADMIN_USER_ID}', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

\\echo '--- admin_upsert_country ---'
select jsonb_pretty(admin_upsert_country(
  'GH'::char(2),
  'Ghana-Review',
  'GHS'::char(3),
  '₵',
  '+233',
  'en-GH',
  'Africa/Accra',
  '${DEPLOYMENT_ID}'::uuid,
  2::smallint,
  '{"women_only_matching": false}'::jsonb,
  false,
  'paystack'
));

\\echo '--- admin_set_country_schema ---'
select jsonb_pretty(admin_set_country_schema(
  'GH'::char(2),
  '[
    {"type":"ghana_card","label":"Ghana Card","pattern":"^.{5,}$","provider":"verifyme"}
  ]'::jsonb
));

\\echo '--- country row ---'
select code, name, currency_code, currency_symbol, phone_prefix, default_locale, timezone, active,
       verification_schema, regulatory_flags
from countries where code = 'GH';

\\echo '--- payment provider + digital_enabled gate ---'
select key, scope_type, scope_id, value
from app_config
where key in ('payments.provider', 'payments.digital_enabled')
  and (
    (scope_type = 'country' and scope_id = 'GH')
    or (scope_type = 'global' and key = 'payments.digital_enabled')
  )
order by key, scope_type;

commit;
SQL

echo ""
echo "-- Step 4: import:city (fixture city_ghana_review) --"
echo "Fixture manifest:"
cat "$REPO_ROOT/data-collection/fixtures/city_ghana_review/manifest.json"

cd "$REPO_ROOT/data-collection"

if [[ "$APPLY" == "1" ]]; then
  echo "Note: admin_create_city requires active country — temporarily setting GH active=true for apply, then restoring false."
  psql "$DATABASE_URL" -c "update countries set active = true where code = 'GH';"
  npm run import:city -- --fixture fixtures/city_ghana_review --apply
  psql "$DATABASE_URL" -c "update countries set active = false where code = 'GH';"
else
  # Dry-run city RPC: requires active country; restore inactive after preview.
  psql "$DATABASE_URL" -c "update countries set active = true where code = 'GH';"
  if npm run import:city -- --fixture fixtures/city_ghana_review --dry-run; then
    IMPORT_OK=1
  else
    IMPORT_OK=0
  fi
  psql "$DATABASE_URL" -c "update countries set active = false where code = 'GH';"
  if [[ "$IMPORT_OK" != "1" ]]; then
    echo "import:city dry-run failed unexpectedly" >&2
    exit 1
  fi
fi

echo ""
echo "Done. digital_enabled was NOT toggled; country active=false."
