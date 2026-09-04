#!/usr/bin/env bash
# OpenAPI contract gate (doc 09 §2). Fails until the contract file and checker are wired.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OPENAPI="$ROOT/shared/contracts/openapi.yaml"
CHECKER="$ROOT/backend/functions/scripts/verify_openapi_handlers.ts"

if [ ! -f "$OPENAPI" ]; then
  echo "FAIL: shared/contracts/openapi.yaml is missing (required by doc 09 §2)."
  exit 1
fi

if [ ! -f "$CHECKER" ]; then
  echo "FAIL: OpenAPI handler drift checker is missing at backend/functions/scripts/verify_openapi_handlers.ts."
  exit 1
fi

if ! command -v deno >/dev/null 2>&1; then
  echo "FAIL: deno is required to run the OpenAPI contract check."
  exit 1
fi

deno run --allow-read "$CHECKER"
echo "PASS: OpenAPI contract check."
