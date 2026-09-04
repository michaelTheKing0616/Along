#!/usr/bin/env bash
# Design tokens freshness gate (doc 09 §2). Fails until Style Dictionary output is committed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOKENS_PKG="$ROOT/shared/design-tokens"
GENERATED_MARKERS=(
  "$TOKENS_PKG/build/dart/along_tokens.dart"
  "$TOKENS_PKG/build/css/tokens.css"
)

for marker in "${GENERATED_MARKERS[@]}"; do
  if [ ! -f "$marker" ]; then
    echo "FAIL: generated token artifact missing: ${marker#"$ROOT"/} (build wired in P0-E-05)."
    exit 1
  fi
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cp -a "$TOKENS_PKG/build" "$TMP_DIR/build-before"
pnpm --dir "$ROOT" --filter @along/design-tokens build

if ! diff -qr "$TMP_DIR/build-before" "$TOKENS_PKG/build"; then
  echo "FAIL: committed design-token outputs are stale — run pnpm --filter @along/design-tokens build and commit."
  exit 1
fi

echo "PASS: design token outputs are current."
