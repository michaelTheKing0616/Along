#!/usr/bin/env bash
# Gate: the prod deploy plan must not include staging-only functions.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plan="$(bash "$DIR/deploy_functions.sh" --dry-run prod ci-prod-ref)"
if echo "$plan" | grep -qx 'deploy: staging-otp'; then
  echo "FAIL: prod deploy plan includes staging-otp"; exit 1
fi
echo "$plan" | grep -qx 'skip (staging-only): staging-otp' || { echo "FAIL: staging-otp not found/skipped"; exit 1; }
bash "$DIR/deploy_functions.sh" --dry-run staging ci-staging-ref | grep -qx 'deploy: staging-otp' \
  || { echo "FAIL: staging plan is missing staging-otp"; exit 1; }
# Mobile: the staging OTP key must never sit in a committed env file (pass it
# via --dart-define on staging smoke builds only; prod/dev builds refuse it).
ROOT="$(cd "$DIR/../../.." && pwd)"
if grep -l 'STAGING_OTP_KEY' "$ROOT"/mobile-*/env/*.json "$ROOT"/env/*.json 2>/dev/null; then
  echo "FAIL: STAGING_OTP_KEY found in a committed env file"; exit 1
fi
echo "PASS: staging-otp excluded from prod deploys; no committed STAGING_OTP_KEY."
