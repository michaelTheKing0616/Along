#!/usr/bin/env bash
# Download Tier-A open datasets for Along (Abuja/Nigeria). Does NOT commit binaries.
# Usage: scripts/geo/download_tier_a.sh [outdir]
set -euo pipefail
OUT="${1:-$PWD/data/geo}"
mkdir -p "$OUT"/{osm,worldpop,grid3,pmtiles}
echo "Downloading into $OUT"

# WorldPop NGA v3.0 gridded (~44MB)
if [ ! -f "$OUT/worldpop/NGA_population_v3_0_gridded.zip" ]; then
  curl -L --fail --retry 3 -o "$OUT/worldpop/NGA_population_v3_0_gridded.zip" \
    "https://data.worldpop.org/repo/wopr/NGA/population/v3.0/NGA_population_v3_0_gridded.zip" \
    && echo "WorldPop OK" || echo "WorldPop FAILED"
else echo "WorldPop already present"; fi

# Geofabrik Nigeria PBF (large ~675MB) — optional flag
if [ "${FETCH_GEOFABRIK:-0}" = "1" ]; then
  curl -L --fail --retry 3 -C - -o "$OUT/osm/nigeria-latest.osm.pbf" \
    "https://download.geofabrik.de/africa/nigeria-latest.osm.pbf" && echo "Geofabrik OK"
fi

# BBBike Shortbread PMTiles (may be large)
if [ "${FETCH_PMTILES:-0}" = "1" ]; then
  curl -L --fail --retry 3 -C - -o "$OUT/pmtiles/nigeria.osm.pmtiles-shortbread.zip" \
    "https://data.bbbike.org/osm/pmtiles/region/africa/nigeria/nigeria.osm.pmtiles-shortbread.zip" \
    && echo "BBBike PMTiles OK" || echo "BBBike PMTiles FAILED"
fi

# GRID3 wards: HDX often needs browser; print URL for manual / aria2
cat > "$OUT/grid3/README.txt" <<'R'
GRID3 Operational Wards v3.0 (CC BY-SA):
  https://data.humdata.org/dataset/grid3-nga-operational-wards-v3-0
HOT OSM Nigeria POI (ODbL):
  https://data.humdata.org/dataset/hotosm_nga_points_of_interest
  https://production-raw-data-api.s3.amazonaws.com/ISO3/NGA/points_of_interest/hotosm_nga_points_of_interest_osm_geojson.zip
Geofabrik Nigeria OSM:
  https://download.geofabrik.de/africa/nigeria.html
R

# Try HOT POI geojson zip (manageable)
if [ ! -f "$OUT/osm/hotosm_nga_points_of_interest_osm_geojson.zip" ]; then
  curl -L --fail --retry 3 -o "$OUT/osm/hotosm_nga_points_of_interest_osm_geojson.zip" \
    "https://production-raw-data-api.s3.amazonaws.com/ISO3/NGA/points_of_interest/hotosm_nga_points_of_interest_osm_geojson.zip" \
    && echo "HOT POI OK" || echo "HOT POI FAILED (try HDX page)"
fi

echo "Done. See $OUT/grid3/README.txt for HDX wards download."
ls -lhR "$OUT" | head -80
