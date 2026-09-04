#!/usr/bin/env bash
# Playwright E2E gate (doc 09 §2). Fails until Playwright is configured against the local stack.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$ROOT/admin-console/playwright.config.ts"

if [ ! -f "$CONFIG" ]; then
  echo "FAIL: admin-console/playwright.config.ts is missing (required by doc 09 §2; wired in P0-D-01)."
  exit 1
fi

if ! grep -q '"@playwright/test"' "$ROOT/admin-console/package.json" 2>/dev/null; then
  echo "FAIL: @playwright/test is not listed in admin-console/package.json."
  exit 1
fi

echo "FAIL: Playwright E2E runner is not yet implemented (pnpm exec playwright test against local stack)."
exit 1
