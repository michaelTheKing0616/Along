#!/usr/bin/env bash
# Write compile-only mobile env/staging.json when gitignored files are absent (CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

write_if_missing() {
  local path="$1"
  local sentry_key="$2"
  if [[ -f "${path}" ]]; then
    echo "exists ${path#${ROOT}/}"
    return 0
  fi
  mkdir -p "$(dirname "${path}")"
  cat >"${path}" <<EOF
{
  "FLAVOR": "staging",
  "SUPABASE_URL": "https://ci-placeholder.supabase.co",
  "SUPABASE_ANON_KEY": "ci-placeholder-anon-key",
  "SENTRY_DSN": "",
  "TILES_BASE_URL": "",
  "OTP_RESEND_COOLDOWN_S": "30",
  "OTP_RATE_LIMIT_RETRY_S": "60",
  "SENTRY_TRACES_SAMPLE_RATE": "0.2"
}
EOF
  echo "wrote compile-only ${path#${ROOT}/}"
}

write_if_missing "${ROOT}/mobile-rider/env/staging.json" "SENTRY_DSN"
write_if_missing "${ROOT}/mobile-driver/env/staging.json" "SENTRY_DSN"
