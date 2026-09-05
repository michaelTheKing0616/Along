#!/usr/bin/env bash
# Upload minimal JPEG fixtures for verification E2E document viewer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ADMIN="$ROOT/admin-console"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU}"
SUPABASE_URL="${SUPABASE_URL:-http://127.0.0.1:54321}"
FIXTURE="$ADMIN/e2e/fixtures/sample-doc.jpg"

if [ ! -f "$FIXTURE" ]; then
  echo "FAIL: missing $FIXTURE"
  exit 1
fi

upload() {
  local object_path="$1"
  curl -sf -X POST \
    "${SUPABASE_URL}/storage/v1/object/verification/${object_path}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    -H "Content-Type: image/jpeg" \
    -H "x-upsert: true" \
    --data-binary @"$FIXTURE" >/dev/null
  echo "Uploaded verification/${object_path}"
}

upload "c2000000-0000-4000-8000-000000000010/nin/front.jpg"
upload "c2000000-0000-4000-8000-000000000011/drivers_license/front.jpg"
