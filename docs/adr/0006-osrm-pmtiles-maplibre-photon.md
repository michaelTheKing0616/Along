# ADR-0006 — Self-hosted OSRM (car + foot, Match), PMTiles vector tiles on CDN, MapLibre, Photon places

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §5.1 (OSM + self-hosted router, MapLibre), §5.2 (vector tiles), §4.5.4 (map-matching)

## Decision
- **OSRM** (MLD pipeline) with two profiles: `car` (shared-taxi tuned) and `foot`; the **Match** service powers map-matching. Chosen over Valhalla for simpler ops and a mature Match API; revisit only if isochrones or turn-costs by vehicle class become necessary.
- **Tiles**: Planetiler → single `nigeria.pmtiles` on object storage/CDN; MapLibre reads via range requests; no tile server to run. Style `along-light` (doc 05 §8) with self-hosted glyphs/sprites.
- **Places**: Photon over the same OSM extract; our parks/stages ranked first. No Google Places (cost, data-sovereignty, offline).
- All three rebuild weekly from the same extract snapshot so they never disagree.

## Consequences
- One small VM (two in prod) + CDN; predictable cost.
- Road-geometry corrections flow back to OSM via manual review (doc 04 §15), keeping our basemap and routing improving together.
