#!/usr/bin/env bash
# Contract codegen freshness gate (doc 09 §2, P1-A-02).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GENERATED_MARKERS=(
  "$ROOT/shared/contracts/generated/edge.ts"
  "$ROOT/shared/contracts/generated/rpc.ts"
  "$ROOT/shared/contracts/generated/common.ts"
  "$ROOT/shared/flutter/along_data/lib/src/contracts/api_contracts.g.dart"
)

for marker in "${GENERATED_MARKERS[@]}"; do
  if [ ! -f "$marker" ]; then
    echo "FAIL: generated contract artifact missing: ${marker#"$ROOT"/} — run pnpm --filter @along/contracts build."
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for marker in "${GENERATED_MARKERS[@]}"; do
  rel="${marker#"$ROOT"/}"
  dest="$TMP_DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  cp -a "$marker" "$dest"
done

pnpm --dir "$ROOT" --filter @along/contracts build

for marker in "${GENERATED_MARKERS[@]}"; do
  rel="${marker#"$ROOT"/}"
  if ! diff -q "$TMP_DIR/$rel" "$marker" >/dev/null 2>&1; then
    echo "FAIL: committed contract outputs are stale — run pnpm --filter @along/contracts build and commit."
    exit 1
  fi
done

echo "PASS: contract generated outputs are current."
