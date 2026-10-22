#!/usr/bin/env python3
"""Build Abuja pilot corridor demand GeoJSON from WorldPop NGA v3.0 (CC BY 4.0)."""
# See docs/geo_data_sources.md. Requires: pip install rasterio shapely numpy
import json, zipfile, math
from pathlib import Path
import numpy as np
import rasterio
from rasterio.windows import from_bounds
from shapely.geometry import LineString, Point, mapping
from shapely.ops import unary_union

ROOT = Path(__file__).resolve().parents[2]
WP_ZIP = ROOT / "data/geo/worldpop/NGA_population_v3_0_gridded.zip"
OUT = ROOT / "data/geo/demand"

CORRIDORS = {
  "nyanya_cbd": {"name": "Nyanya / Mararaba ↔ CBD", "coords": [
    (7.595, 9.012), (7.575, 9.025), (7.555, 9.030), (7.520, 9.038), (7.535, 9.045), (7.433, 9.067)]},
  "lugbe_area1": {"name": "Lugbe ↔ Area 1 / Berger", "coords": [
    (7.365, 8.987), (7.433, 9.067), (7.495, 9.048)]},
  "kubwa_wuse": {"name": "Kubwa ↔ Wuse / Berger", "coords": [
    (7.398, 9.158), (7.410, 9.120), (7.438, 9.082), (7.433, 9.067), (7.489, 9.074)]},
}

def main():
    extract = ROOT / "data/geo/worldpop/extracted"
    extract.mkdir(parents=True, exist_ok=True)
    tif = None
    with zipfile.ZipFile(WP_ZIP) as z:
        for n in z.namelist():
            if n.endswith(".tif"):
                z.extract(n, extract); tif = extract / n; break
    for c in CORRIDORS.values():
        c["line"] = LineString(c["coords"]); c["buffer"] = c["line"].buffer(0.015)
    union = unary_union([c["buffer"] for c in CORRIDORS.values()])
    minx, miny, maxx, maxy = union.bounds
    step = 0.0045
    features = []
    with rasterio.open(tif) as ds:
        win = from_bounds(minx-0.02, miny-0.02, maxx+0.02, maxy+0.02, transform=ds.transform)
        data = ds.read(1, window=win, boundless=True, fill_value=0)
        transform = ds.window_transform(win)
        nodata = ds.nodata
        for y in np.arange(miny, maxy+step, step):
            for x in np.arange(minx, maxx+step, step):
                pt = Point(x, y)
                if not union.contains(pt): continue
                r, c = rasterio.transform.rowcol(transform, x, y)
                if r < 0 or c < 0 or r >= data.shape[0] or c >= data.shape[1]: continue
                val = float(data[r, c])
                if nodata is not None and val == nodata: continue
                if not math.isfinite(val) or val <= 0: continue
                cid = next((k for k,corr in CORRIDORS.items() if corr["buffer"].contains(pt)), None)
                features.append({"type":"Feature","geometry":{"type":"Point","coordinates":[round(x,5),round(y,5)]},
                    "properties":{"population":round(val,2),"weight":round(val,2),"corridor":cid,
                      "corridor_name": CORRIDORS[cid]["name"] if cid else None,
                      "source":"WorldPop NGA v3.0","license":"CC BY 4.0"}})
    pmax = max(f["properties"]["population"] for f in features) or 1
    for f in features:
        f["properties"]["weight_norm"] = round(f["properties"]["population"]/pmax, 4)
        f["properties"]["mag"] = f["properties"]["weight_norm"]
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT/"abuja_corridor_demand.geojson").write_text(json.dumps({
        "type":"FeatureCollection","name":"abuja-corridor-demand-worldpop-v3",
        "attribution":"WorldPop (www.worldpop.org) CC BY 4.0 — NGA population v3.0",
        "features": features}))
    line_fc={"type":"FeatureCollection","features":[
        {"type":"Feature","geometry":mapping(c["line"]),"properties":{"id":cid,"name":c["name"]}}
        for cid,c in CORRIDORS.items()]}
    (OUT/"abuja_corridor_centerlines.geojson").write_text(json.dumps(line_fc))
    print(f"wrote {len(features)} demand points → {OUT}")

if __name__ == "__main__":
    main()
