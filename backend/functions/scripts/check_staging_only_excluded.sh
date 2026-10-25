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
echo "PASS: staging-otp excluded from prod deploys."
