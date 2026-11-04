#!/usr/bin/env bash
# Schema contract gate (doc 09 §2). Fails until generated types are committed and current.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TYPES_FILE="$ROOT/shared/contracts/db.types.ts"

if [ ! -f "$TYPES_FILE" ]; then
  echo "FAIL: shared/contracts/db.types.ts is missing (generate with: supabase gen types typescript --local | python3 backend/db/scripts/strip_partition_types.py > shared/contracts/db.types.ts)."
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "FAIL: supabase CLI is required to verify db.types.ts freshness."
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Month partition children roll with the calendar; exclude them (see script).
STRIP="$ROOT/backend/db/scripts/strip_partition_types.py"
supabase gen types typescript --local | python3 "$STRIP" >"$TMP"

if ! diff -u <(python3 "$STRIP" <"$TYPES_FILE") "$TMP"; then
  echo "FAIL: shared/contracts/db.types.ts is stale — regenerate and commit."
  exit 1
fi

echo "PASS: shared/contracts/db.types.ts matches local schema."
