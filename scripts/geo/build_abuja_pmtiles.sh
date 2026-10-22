#!/usr/bin/env bash
# Build OpenMapTiles-compatible Abuja PMTiles from Geofabrik Nigeria PBF via Planetiler,
# upload to tiles-staging, and point along-light basemap at it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PBF="${1:-$ROOT/data/geo/osm/nigeria-latest.osm.pbf}"
JAR="${PLANETILER_JAR:-$ROOT/backend/routing/tools/planetiler/planetiler-0.8.2.jar}"
OUT_DIR="$ROOT/backend/routing/data/tiles"
OUT="$OUT_DIR/abuja.pmtiles"
TILES_BASE="${TILES_BASE:-https://upqeypbdegteofwvekie.supabase.co/storage/v1/object/public/tiles-staging}"
# FCT-ish bbox
BOUNDS="${BOUNDS:-6.90,8.70,7.75,9.35}"

if [[ ! -f "$PBF" ]]; then echo "Missing PBF: $PBF" >&2; exit 1; fi
if [[ ! -f "$JAR" ]]; then echo "Missing Planetiler JAR: $JAR" >&2; exit 1; fi
mkdir -p "$OUT_DIR"
# Keep shared extract path in sync
mkdir -p "$ROOT/backend/routing/data/raw"
ln -sfn "$PBF" "$ROOT/backend/routing/data/raw/nigeria-latest.osm.pbf"

echo "Planetiler → $OUT (bounds=$BOUNDS)"
java -Xmx4g -jar "$JAR" \
  --download \
  --osm-path="$PBF" \
  --output="$OUT" \
  --bounds="$BOUNDS" \
  --maxzoom=14 \
  --force

ls -lh "$OUT"

# Upload (replace stub)
npx supabase storage rm ss:///tiles-staging/ng/abuja.pmtiles --experimental --yes 2>/dev/null || true
npx supabase storage cp "$OUT" ss:///tiles-staging/ng/abuja.pmtiles --experimental

# Point style basemap at PMTiles (keep OpenFreeMap sprites/glyphs)
python3 - <<PY
import json
from pathlib import Path
tiles = "$TILES_BASE"
pm = f"{tiles}/ng/abuja.pmtiles"
p = Path("$ROOT/backend/routing/style/along-light.json")
d = json.loads(p.read_text())
d["sources"]["basemap"] = {
  "type": "vector",
  "url": f"pmtiles://{pm}",
  "attribution": "© OpenStreetMap contributors © OpenMapTiles",
}
# keep OpenFreeMap sprite/glyphs (Planetiler tiles still OpenMapTiles schema)
d.setdefault("metadata", {})["along:basemap"] = "planetiler-abuja-pmtiles"
d["metadata"]["along:tile-version"] = __import__("datetime").datetime.utcnow().strftime("%Y%m%d")
p.write_text(json.dumps(d, indent=2) + "\n")
print("style basemap →", d["sources"]["basemap"]["url"])
PY

npx supabase storage rm ss:///tiles-staging/styles/along-light.json --experimental --yes 2>/dev/null || true
npx supabase storage cp "$ROOT/backend/routing/style/along-light.json" ss:///tiles-staging/styles/along-light.json --experimental
echo "Done. APK already has TILES_BASE; style is remote — reinstall optional."
