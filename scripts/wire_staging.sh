#!/usr/bin/env bash
# Sync staging env from env/staging.json into admin + mobile flavours (P1-E-04).
# Never commit env/*.json except *.example.json — this script writes gitignored targets.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_JSON="${ROOT}/env/staging.json"
GOOGLE_SERVICES="${ROOT}/env/google-services.staging.json"

if [[ ! -f "${STAGING_JSON}" ]]; then
  echo "ERROR: missing ${STAGING_JSON}. Copy env/staging.example.json and fill values." >&2
  exit 1
fi

python3 - "${STAGING_JSON}" <<'PY'
import json, sys
from pathlib import Path

root = Path(sys.argv[1]).resolve().parent.parent
staging_path = Path(sys.argv[1])
staging = json.loads(staging_path.read_text())

def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"wrote {path.relative_to(root)}")

# --- mobile-rider ---
rider = {
    "FLAVOR": "staging",
    "SUPABASE_URL": staging["SUPABASE_URL"],
    "SUPABASE_ANON_KEY": staging["SUPABASE_ANON_KEY"],
    "SENTRY_DSN": staging.get("SENTRY_DSN_MOBILE_RIDER", ""),
    "TILES_BASE_URL": staging.get("TILES_BASE", ""),
    "OTP_RESEND_COOLDOWN_S": "30",
    "OTP_RATE_LIMIT_RETRY_S": "60",
    "SENTRY_TRACES_SAMPLE_RATE": "0.2",
}
write_json(root / "mobile-rider/env/staging.json", rider)

# --- mobile-driver ---
driver = {
    **rider,
    "SENTRY_DSN": staging.get("SENTRY_DSN_MOBILE_DRIVER", ""),
    "BATTERY_GUARD_PERCENT": "15",
}
write_json(root / "mobile-driver/env/staging.json", driver)

# --- admin-console (.env.local is gitignored) ---
admin_lines = [
    f"NEXT_PUBLIC_SUPABASE_URL={staging['SUPABASE_URL']}",
    f"NEXT_PUBLIC_SUPABASE_ANON_KEY={staging['SUPABASE_ANON_KEY']}",
    f"SENTRY_DSN={staging.get('SENTRY_DSN_ADMIN', '')}",
    f"PUBLIC_ORIGIN={staging.get('PUBLIC_ORIGIN', '')}",
]
(root / "admin-console/.env.local").write_text("\n".join(admin_lines) + "\n")
print(f"wrote admin-console/.env.local")

# --- Edge function secret hints (not written; human/CI sets via supabase secrets) ---
print("")
print("Edge function secrets (set manually if not already present):")
print("  FCM_SERVICE_ACCOUNT=<service-account JSON>")
print("  FCM_PROJECT_ID=" + staging.get("FIREBASE_PROJECT_ID", "<firebase-project-id>"))
if staging.get("OSRM_URL"):
    print("  OSRM_URL=" + staging["OSRM_URL"])
else:
    print("  OSRM_URL=<empty until cloudflared tunnel is up>")
if staging.get("TILES_BASE"):
    print("  TILES_BASE=" + staging["TILES_BASE"])
else:
    ref = staging.get("SUPABASE_PROJECT_REF", "<project-ref>")
    print(f"  TILES_BASE=<empty; after upload use https://{ref}.supabase.co/storage/v1/object/public/tiles-staging>")
print("  SENTRY_DSN_FUNCTIONS=" + ("<set>" if staging.get("SENTRY_DSN_FUNCTIONS") else "<empty>"))
PY

if [[ -f "${GOOGLE_SERVICES}" ]]; then
  for app in mobile-rider mobile-driver; do
    dest="${ROOT}/${app}/android/app/src/staging/google-services.json"
    mkdir -p "$(dirname "${dest}")"
    cp "${GOOGLE_SERVICES}" "${dest}"
    echo "copied google-services → ${app}/android/app/src/staging/google-services.json"
  done
else
  echo "WARN: ${GOOGLE_SERVICES} not found — skipped google-services copy" >&2
fi

bash "${ROOT}/scripts/prepare_ios_firebase.sh"

echo ""
echo "Done. Re-run after env/staging.json changes."
