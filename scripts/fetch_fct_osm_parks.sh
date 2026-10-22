#!/usr/bin/env bash
# Fetch FCT OSM parks/terminals via Overpass and write raw JSON next to the seed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/backend/db/seed/seed_abuja_osm_parks/overpass_fct_raw.json}"
QL=$(mktemp)
cat > "$QL" <<'QL'
[out:json][timeout:90];
(
  node["amenity"="bus_station"](8.70,6.90,9.35,7.75);
  way["amenity"="bus_station"](8.70,6.90,9.35,7.75);
  node["public_transport"="station"](8.70,6.90,9.35,7.75);
  way["public_transport"="station"](8.70,6.90,9.35,7.75);
  node["name"~"Motor Park|Bus Park|Bus Terminal|Taxi Park|Motor park",i](8.70,6.90,9.35,7.75);
  node["highway"="bus_stop"]["name"](8.70,6.90,9.35,7.75);
);
out center tags;
QL
URL="${OVERPASS_URL:-https://maps.mail.ru/osm/tools/overpass/api/interpreter}"
echo "POST $URL -> $OUT"
curl -sS --max-time 120 -X POST -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data@$QL" "$URL" -o "$OUT"
rm -f "$QL"
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get('elements',[])),'elements')" "$OUT"
