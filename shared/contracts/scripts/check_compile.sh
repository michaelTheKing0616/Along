#!/usr/bin/env bash
# Compile-check generated contract types (P1-A-02 acceptance gate).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

echo "== TS contract typecheck =="
pnpm --dir "$ROOT" --filter @along/contracts typecheck

echo "== Dart contract analyze =="
cd "$ROOT/shared/flutter/along_data"
dart analyze --fatal-infos lib/src/contracts/api_contracts.g.dart

echo "PASS: generated contract types compile (TS + Dart)."
