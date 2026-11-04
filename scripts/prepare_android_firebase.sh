#!/usr/bin/env bash
# Copy google-services.json from env/ when present; otherwise write a compile-only
# stub covering every flavor's applicationId so `flutter build apk` works in CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

prepare() {
  local role="$1"
  local dest="${ROOT}/mobile-${role}/android/app/google-services.json"
  for src in "${ROOT}/env/google-services.${role}.json" "${ROOT}/env/google-services.json"; do
    if [[ -f "${src}" ]]; then
      cp "${src}" "${dest}"
      echo "copied ${src#${ROOT}/} -> ${dest#${ROOT}/}"
      return 0
    fi
  done
  if [[ -f "${dest}" ]]; then
    echo "exists ${dest#${ROOT}/}"
    return 0
  fi
  python3 - "${dest}" "ng.along.${role}" <<'PY'
import json, sys
dest, base = sys.argv[1], sys.argv[2]
clients = [{
    "client_info": {
        "mobilesdk_app_id": f"1:000000000000:android:{i:016x}",
        "android_client_info": {"package_name": base + suffix},
    },
    "oauth_client": [],
    "api_key": [{"current_key": "ci-placeholder-key"}],
    "services": {"appinvite_service": {"other_platform_oauth_client": []}},
} for i, suffix in enumerate(["", ".dev", ".staging"], start=1)]
json.dump({
    "project_info": {
        "project_number": "000000000000",
        "project_id": "along-ci-placeholder",
        "storage_bucket": "along-ci-placeholder.appspot.com",
    },
    "client": clients,
    "configuration_version": "1",
}, open(dest, "w"), indent=2)
PY
  echo "wrote compile-only ${dest#${ROOT}/}"
}

prepare rider
prepare driver
