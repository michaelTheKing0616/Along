#!/usr/bin/env bash
# Seed fixture gate (doc 09 §2). Fails until seed_testcity_fixture and TS-CFG-* scenarios exist.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURE="$ROOT/backend/db/seed/seed_testcity_fixture.sql"

if [ ! -f "$FIXTURE" ]; then
  echo "FAIL: backend/db/seed/seed_testcity_fixture.sql is missing (required by doc 09 §2; implemented in P0-E-04)."
  exit 1
fi

scenarios=()
while IFS= read -r file; do
  scenarios+=("$file")
done < <(find "$ROOT/backend/db/tests" -name 'TS-CFG-*.sql' -type f 2>/dev/null | sort)

if [ "${#scenarios[@]}" -eq 0 ]; then
  echo "FAIL: no TS-CFG-* scenario tests found under backend/db/tests/ (required by doc 09 §2)."
  exit 1
fi

echo "PASS: seed fixture and TS-CFG-* scenarios present."
