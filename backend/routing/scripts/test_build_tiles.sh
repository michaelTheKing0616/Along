#!/usr/bin/env bash
# Smoke test build_tiles.sh dry-run (P1-E-02) — no extract download.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT}/scripts/build_tiles.sh"

bash "${SCRIPT}" --help >/dev/null
echo "build_tiles.sh --help: OK"

dry_run_output="$(bash "${SCRIPT}" --dry-run 2>&1)"
if echo "${dry_run_output}" | grep -q 'dry-run'; then
  echo "build_tiles.sh --dry-run: OK"
else
  echo "build_tiles.sh --dry-run: unexpected output"
  echo "${dry_run_output}"
  exit 1
fi

# With a fake extract, dry-run path should succeed.
mkdir -p "${ROOT}/data/raw"
touch "${ROOT}/data/raw/nigeria-latest.osm.pbf"
extract_output="$(bash "${SCRIPT}" --dry-run 2>&1)"
echo "${extract_output}" | grep -q 'planetiler'
echo "build_tiles.sh dry-run with stub extract: OK"
