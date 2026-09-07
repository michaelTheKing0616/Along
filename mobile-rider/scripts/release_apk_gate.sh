#!/usr/bin/env bash
# P11-E-02: rider release APK size gate (doc 01 §7 ≤ 25 MB arm64; doc 07 §1).
# Parses `flutter build apk --release --analyze-size` JSON when present; skips when Android SDK absent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RIDER_DIR="$ROOT/mobile-rider"
MAX_BYTES=$((25 * 1024 * 1024))
ARTIFACT_DIR="${APK_SIZE_ARTIFACT_DIR:-$RIDER_DIR/build/app/outputs/flutter-apk}"
SIZE_JSON="${APK_SIZE_JSON:-$ARTIFACT_DIR/app-release.apk.json}"

if [ -f "$SIZE_JSON" ]; then
  BYTES="$(python3 - <<'PY' "$SIZE_JSON"
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
# Flutter analyze-size JSON: total package size under "summary" or root "size"
summary = data.get("summary") or data
size = summary.get("size") or summary.get("totalSize") or data.get("size")
if size is None:
    raise SystemExit("missing size field in analyze-size JSON")
print(int(size))
PY
)"
  MB="$(python3 -c "print(f'{$BYTES / (1024*1024):.2f}')")"
  echo "Rider release APK: ${MB} MB (${BYTES} bytes); budget ≤ 25 MB"
  if [ "$BYTES" -gt "$MAX_BYTES" ]; then
    echo "FAIL: rider APK exceeds 25 MB budget (doc 01 §7)"
    exit 1
  fi
  echo "PASS: rider APK within budget"
  exit 0
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "DEFERRED: flutter not on PATH and no analyze-size artifact at $SIZE_JSON"
  exit 0
fi

if ! flutter doctor -v 2>/dev/null | grep -q 'Android SDK'; then
  echo "DEFERRED: Android SDK not configured — commit analyze-size JSON from CI or reference device"
  echo "  Expected artifact: $SIZE_JSON"
  exit 0
fi

echo "Building rider release APK with --analyze-size..."
(
  cd "$RIDER_DIR"
  flutter build apk --release --analyze-size \
    --dart-define-from-file=env/staging.json \
    --target-platform android-arm64
)

exec "$0"
