#!/usr/bin/env bash
# Build PMTiles vector tiles and upload to CDN (doc 09 §4, ADR-0013 Planetiler 0.8.2).
# Shares the same OSM extract as OSRM/Photon for consistency.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="${ROOT}/data/raw/nigeria-latest.osm.pbf"
TILES_DIR="${ROOT}/data/tiles"
OUTPUT="${TILES_DIR}/nigeria.pmtiles"
STYLE="${ROOT}/style/along-light.json"
PLANETILER_VERSION="${PLANETILER_VERSION:-0.8.2}"
PLANETILER_JAR="${PLANETILER_JAR:-/opt/planetiler/planetiler-${PLANETILER_VERSION}.jar}"
CDN_BUCKET="${CDN_BUCKET:-tiles-staging}"
TILES_BASE="${TILES_BASE:-https://tiles-staging.along.ng}"

usage() {
  cat <<'EOF'
Usage: build_tiles.sh [--dry-run]

Planetiler → nigeria.pmtiles from the shared OSM extract, then bump along-light.json
source version. Set UPLOAD_TILES=1 to push to CDN (never in CI/tests).

Environment:
  PLANETILER_JAR     Path to planetiler JAR (default /opt/planetiler/planetiler-0.8.2.jar)
  UPLOAD_TILES       1 to upload to CDN_BUCKET after build (default 0)
  CDN_BUCKET         Object storage bucket name
  TILES_BASE         Public CDN base URL for style placeholders
EOF
}

DRY_RUN=0
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ "${DRY_RUN}" -eq 0 && ! -f "${RAW}" ]]; then
  echo "ERROR: extract not found at ${RAW}. Run scripts/fetch_extract.sh first." >&2
  echo "Local dev may use a clipped Abuja extract instead of the full country file." >&2
  exit 1
fi

mkdir -p "${TILES_DIR}"

VERSION="$(date -u +%Y%m%d)"
PMTILES_URL="${TILES_BASE}/nigeria.pmtiles?v=${VERSION}"

echo "build_tiles.sh: planetiler ${PLANETILER_VERSION} → ${OUTPUT}"
echo "  extract: ${RAW}"
echo "  tile version: ${VERSION}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "[dry-run] would run: java -jar ${PLANETILER_JAR} --osm-path=${RAW} --output=${OUTPUT}"
  echo "[dry-run] would bump ${STYLE} PMTILES_URL → ${PMTILES_URL}"
  exit 0
fi

if [[ ! -f "${PLANETILER_JAR}" ]]; then
  echo "ERROR: Planetiler JAR not found at ${PLANETILER_JAR}" >&2
  echo "Install Planetiler ${PLANETILER_VERSION} or set PLANETILER_JAR." >&2
  exit 1
fi

java -jar "${PLANETILER_JAR}" \
  --download \
  --osm-path="${RAW}" \
  --output="${OUTPUT}" \
  --maxzoom=14 \
  --force

if [[ ! -f "${OUTPUT}" ]]; then
  echo "ERROR: Planetiler did not produce ${OUTPUT}" >&2
  exit 1
fi

# Bump style placeholders (PMTILES_URL, sprite, glyphs version tag).
if [[ -f "${STYLE}" ]]; then
  TMP="$(mktemp)"
  sed \
    -e "s|\"along:tile-version\": \"[^\"]*\"|\"along:tile-version\": \"${VERSION}\"|" \
    -e "s|pmtiles://{{PMTILES_URL}}|pmtiles://${PMTILES_URL}|" \
    -e "s|pmtiles://[^\"]*nigeria.pmtiles[^\"]*|pmtiles://${PMTILES_URL}|" \
    "${STYLE}" > "${TMP}"
  mv "${TMP}" "${STYLE}"
  echo "Updated ${STYLE} with tile version ${VERSION}"
fi

if [[ "${UPLOAD_TILES:-0}" == "1" ]]; then
  if command -v aws >/dev/null 2>&1; then
    aws s3 cp "${OUTPUT}" "s3://${CDN_BUCKET}/nigeria.pmtiles" \
      --content-type "application/vnd.pmtiles"
    echo "Uploaded to s3://${CDN_BUCKET}/nigeria.pmtiles"
  elif command -v gsutil >/dev/null 2>&1; then
    gsutil cp "${OUTPUT}" "gs://${CDN_BUCKET}/nigeria.pmtiles"
    echo "Uploaded to gs://${CDN_BUCKET}/nigeria.pmtiles"
  else
    echo "ERROR: UPLOAD_TILES=1 but neither aws nor gsutil found." >&2
    exit 1
  fi
else
  echo "Skipping CDN upload (set UPLOAD_TILES=1 to upload)."
fi

echo "Done: ${OUTPUT} ($(du -h "${OUTPUT}" | cut -f1))"
