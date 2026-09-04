#!/usr/bin/env bash
# Build OSRM car + foot graphs from the same extract (doc 09 §4, ADR-0013 OSRM v5.27.1).
# P1-A-07: stub — run after fetch_extract.sh has populated data/raw/*.osm.pbf
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="${ROOT}/routing/data/raw"
PROFILES="${ROOT}/routing/profiles"

echo "build_osrm.sh: osrm-extract → osrm-partition → osrm-customize per profile"
echo "  car  → ${ROOT}/routing/data/car"
echo "  foot → ${ROOT}/routing/data/foot"
echo "Profiles: ${PROFILES}/car.lua, ${PROFILES}/foot.lua"
echo "Run inside osrm/osrm-backend:v5.27.1 container; atomic swap data dirs on success."

exit 0
