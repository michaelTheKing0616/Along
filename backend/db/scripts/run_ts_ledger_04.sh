#!/usr/bin/env bash
# TS-LEDGER-04: 50 parallel ledger_post calls for one driver → exact balance (advisory lock)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
DRIVER_ID='0e900000-0000-4000-8000-000000000001'
TMPDIR="${TMPDIR:-/tmp}"

cd "$ROOT"

psql "$DB_URL" -v ON_ERROR_STOP=1 <<'SQL'
begin;

\ir backend/db/seed/seed_testcity_fixture/00_zaria_test.sql

insert into auth.users (id, aud, role, phone) values
  ('0e900000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000006401')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('0e900000-0000-4000-8000-000000000001', '+2348000006401', 'Ledger Concurrency Driver')
on conflict (id) do nothing;

insert into drivers (id, city_id, verified_status, standing, driver_code, home_park_id)
values (
  '0e900000-0000-4000-8000-000000000001',
  '0a000000-0000-4000-8000-000000000001',
  'verified',
  'good_standing',
  'LEDG04',
  '0a020000-0000-4000-8000-000000000001'
)
on conflict (id) do update set standing = excluded.standing;

delete from driver_ledger_entries
where driver_id = '0e900000-0000-4000-8000-000000000001';

commit;
SQL

LOG_DIR="$(mktemp -d "${TMPDIR}/ts-ledger-04.XXXXXX")"
trap 'rm -rf "$LOG_DIR"' EXIT

post_one() {
  local idx="$1"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -q -c "
    select ledger_post(
      '${DRIVER_ID}'::uuid,
      'manual_adjustment',
      -1.00,
      'NGN',
      '{}'::jsonb,
      'ts-ledger-04:${idx}',
      'system',
      null,
      'TS-LEDGER-04 parallel post ${idx}'
    );
  " >"${LOG_DIR}/${idx}.out" 2>"${LOG_DIR}/${idx}.err"
}

export DB_URL DRIVER_ID LOG_DIR
export -f post_one

seq 1 50 | xargs -P 50 -I{} bash -c 'post_one "$@"' _ {}

RESULT="$(
  psql "$DB_URL" -v ON_ERROR_STOP=1 -At <<SQL
select
  (select count(*)::int from driver_ledger_entries where driver_id = '${DRIVER_ID}'),
  (select coalesce(sum(amount), 0) from driver_ledger_entries where driver_id = '${DRIVER_ID}'),
  (select balance_after from driver_ledger_entries where driver_id = '${DRIVER_ID}' order by id desc limit 1);
SQL
)"

ROW_COUNT="$(echo "$RESULT" | cut -d'|' -f1)"
SUM_AMOUNT="$(echo "$RESULT" | cut -d'|' -f2)"
LATEST_BALANCE="$(echo "$RESULT" | cut -d'|' -f3)"

if [ "$ROW_COUNT" != "50" ]; then
  echo "FAIL TS-LEDGER-04: expected 50 ledger rows, got ${ROW_COUNT}"
  exit 1
fi

if [ "$SUM_AMOUNT" != "-50.00" ]; then
  echo "FAIL TS-LEDGER-04: expected sum(amount)=-50.00, got ${SUM_AMOUNT}"
  exit 1
fi

if [ "$LATEST_BALANCE" != "-50.00" ]; then
  echo "FAIL TS-LEDGER-04: expected latest balance_after=-50.00, got ${LATEST_BALANCE}"
  exit 1
fi

echo "PASS TS-LEDGER-04: 50 parallel posts → exact balance -50.00 (rows=${ROW_COUNT}, sum=${SUM_AMOUNT}, latest=${LATEST_BALANCE})"
