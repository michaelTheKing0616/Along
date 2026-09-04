#!/usr/bin/env bash
# Release APK size gate (doc 09 §2). Fails until the analyze-size build is wired in CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GATE="$ROOT/mobile-rider/scripts/release_apk_gate.sh"

if [ ! -f "$GATE" ]; then
  echo "FAIL: mobile-rider/scripts/release_apk_gate.sh is missing (required by doc 09 §2 mobile.yml)."
  exit 1
fi

exec "$GATE"
