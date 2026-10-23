#!/usr/bin/env bash
# Extract a free Abuja (FCT) PMTiles archive from the public Protomaps daily
# planet, then the gallery renders a small PNG set from it.
#
# The daily planet is https://build.protomaps.com/YYYYMMDD.pmtiles
# (about 140 GB; this script range-requests only the FCT bbox).
# Header maxzoom on that build is 15. Passing --maxzoom=16 keeps every
# zoom the planet actually has. Neighborhood gallery frames are the z16
# slippy grid: MapLibre draws them by overzooming the z15 vector, so
# building footprints stay sharp instead of being a scaled raster.
#
# Commit the rendered PNGs under assets/map/tiles/{light,dark,heat}.
# Do not commit the .pmtiles archive.
#
# Requires go-pmtiles (module github.com/protomaps/go-pmtiles):
#   go install github.com/protomaps/go-pmtiles@v1.28.0
#
# Usage:
#   tool/extract_abuja_pmtiles.sh [YYYYMMDD] [output.pmtiles]

set -euo pipefail

day="${1:-20261022}"
out="${2:-/tmp/abuja.pmtiles}"
url="https://build.protomaps.com/${day}.pmtiles"

# Federal Capital Territory. min_lon,min_lat,max_lon,max_lat.
bbox="6.749,8.397,7.616,9.278"

go-pmtiles extract "$url" "$out" \
  --bbox="$bbox" \
  --maxzoom=16 \
  --download-threads=8

echo "Archive: $out"
echo "Serve it, then render assets/map/tiles at device pixel ratio 3."
echo "  go-pmtiles serve \"\$(dirname "$out")\" --port 8098 --cors='*'"
echo "Styles (Protomaps basemap layers, muted light and dark): tool/map/"
echo "Point the style source at http://127.0.0.1:8098/abuja/{z}/{x}/{y}.mvt"
echo "maxzoom on the source is 15. Gallery z16 PNGs are vector overzoom."
echo "Buildings are painted from zoom 14 up, so z15 and z16 frames show them."
echo "Heat tiles are a kernel over the light z16 set, masked off parks and water."
