#!/usr/bin/env bash
# Build Photon geocoding index from the same OSM extract (doc 09 §4, ADR-0013 Photon 0.6.2).
# P1-A-07: stub — run after fetch_extract.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="${ROOT}/routing/data/raw"
PHOTON="${ROOT}/routing/data/photon"

echo "build_photon.sh: import OSM PBF into Photon index at ${PHOTON}"
echo "Use komoot/photon:0.6.2 with -nigeria or country-specific import flags."
echo "Edge places-search reads PHOTON_BASE_URL (compose exposes :2322)."

exit 0
