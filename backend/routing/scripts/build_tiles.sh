#!/usr/bin/env bash
# Build PMTiles vector tiles and upload to CDN (doc 09 §4, ADR-0013 Planetiler 0.8.2).
# P1-A-07: stub — shares extract with OSRM/Photon for consistency.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TILES="${ROOT}/routing/data/tiles"

echo "build_tiles.sh: planetiler → ${TILES}/nigeria.pmtiles"
echo "Upload to CDN bucket and bump style/along-light.json source version."

exit 0
