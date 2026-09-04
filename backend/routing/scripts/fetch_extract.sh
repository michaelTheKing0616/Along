#!/usr/bin/env bash
# Fetch OSM extract(s) for routing/places/tiles (doc 09 §4).
# P1-A-07: stub — does not download extracts in this task.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${ROOT}/routing/data/raw"

echo "fetch_extract.sh: configure Geofabrik URL in app_config / env, then download to ${DATA_DIR}"
echo "Example: wget -O ${DATA_DIR}/nigeria-latest.osm.pbf https://download.geofabrik.de/africa/nigeria-latest.osm.pbf"
echo "Local dev may use a clipped Abuja extract (~20 km) instead of the full country file."

exit 0
