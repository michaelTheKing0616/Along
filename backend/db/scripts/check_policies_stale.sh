#!/usr/bin/env bash
# RLS snapshot freshness gate (ADR-0015, doc 09 §3). Fails when policies/*.sql is stale.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
POLICIES_DIR="$ROOT/backend/db/policies"
DUMP_SCRIPT="$ROOT/backend/db/scripts/dump_policies.sh"

if [ ! -d "$POLICIES_DIR" ]; then
  echo "FAIL: missing policies directory — run bash backend/db/scripts/dump_policies.sh."
  exit 1
fi

shopt -s nullglob
existing=("$POLICIES_DIR"/*.sql)
shopt -u nullglob

if [ "${#existing[@]}" -eq 0 ]; then
  echo "FAIL: no committed RLS snapshot files — run bash backend/db/scripts/dump_policies.sh."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for file in "${existing[@]}"; do
  rel="${file#"$ROOT"/}"
  dest="$TMP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -a "$file" "$dest"
done

bash "$DUMP_SCRIPT"

for file in "${existing[@]}"; do
  rel="${file#"$ROOT"/}"
  if ! diff -q "$TMP_DIR/$rel" "$file" >/dev/null 2>&1; then
    echo "FAIL: committed RLS policy snapshots are stale — run bash backend/db/scripts/dump_policies.sh and commit."
    exit 1
  fi
done

shopt -s nullglob
for file in "$POLICIES_DIR"/*.sql; do
  rel="${file#"$ROOT"/}"
  if [ ! -f "$TMP_DIR/$rel" ]; then
    echo "FAIL: committed RLS policy snapshots are stale — run bash backend/db/scripts/dump_policies.sh and commit."
    exit 1
  fi
done
shopt -u nullglob

echo "PASS: RLS policy snapshots are current."
