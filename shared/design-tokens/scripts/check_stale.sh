#!/usr/bin/env bash
# Design tokens freshness gate (doc 09 §2). Fails when generated output is stale.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOKENS_PKG="$ROOT/shared/design-tokens"
GENERATED_MARKERS=(
  "$TOKENS_PKG/build/dart/along_tokens.dart"
  "$TOKENS_PKG/build/css/tokens.css"
  "$TOKENS_PKG/build/tailwind/preset.cjs"
  "$ROOT/shared/flutter/along_design/lib/src/tokens.g.dart"
  "$ROOT/admin-console/src/styles/tokens.css"
  "$ROOT/admin-console/tailwind.preset.cjs"
)

for marker in "${GENERATED_MARKERS[@]}"; do
  if [ ! -f "$marker" ]; then
    echo "FAIL: generated token artifact missing: ${marker#"$ROOT"/} — run pnpm --filter @along/design-tokens build."
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

pnpm --dir "$ROOT" --filter @along/design-tokens build

for marker in "${GENERATED_MARKERS[@]}"; do
  rel="${marker#"$ROOT"/}"
  if ! diff -q "$TMP_DIR/$rel" "$marker" >/dev/null 2>&1; then
    echo "FAIL: committed design-token outputs are stale — run pnpm --filter @along/design-tokens build and commit."
    exit 1
  fi
done

echo "PASS: design token outputs are current."
