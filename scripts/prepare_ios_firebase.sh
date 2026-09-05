#!/usr/bin/env bash
# Copy GoogleService-Info.plist from env/ when present; otherwise keep compile stub (P1-E-05).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

copy_plist() {
  local app="$1"
  local role="$2"
  local dest="${ROOT}/${app}/ios/Runner/GoogleService-Info.plist"
  local candidates=(
    "${ROOT}/env/GoogleService-Info.${role}.staging.plist"
    "${ROOT}/env/GoogleService-Info.${role}.plist"
    "${ROOT}/env/GoogleService-Info.staging.plist"
  )

  for src in "${candidates[@]}"; do
    if [[ -f "${src}" ]]; then
      cp "${src}" "${dest}"
      echo "copied ${src#${ROOT}/} → ${app}/ios/Runner/GoogleService-Info.plist"
      return 0
    fi
  done

  if [[ -f "${dest}" ]]; then
    echo "using compile stub at ${app}/ios/Runner/GoogleService-Info.plist"
  else
    echo "ERROR: missing ${dest} (stub not found)" >&2
    exit 1
  fi
}

copy_plist "mobile-rider" "rider"
copy_plist "mobile-driver" "driver"
