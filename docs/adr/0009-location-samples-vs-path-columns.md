# ADR-0009 — Store raw location samples; materialise `driver_live_path`/`rider_live_path` at completion

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4 (`trips.driver_live_path`, `rider_live_path`), §4.4.2, §4.5.4

## Decision
`trip_location_samples` (partitioned by month) receives batched points from both parties during a trip. On `completed`/cancellation, `trips.driver_live_path` and `rider_live_path` are set to `ST_MakeLine(points ordered by ts)`. Reconciliation reads samples (with timestamps and accuracy, which a LINESTRING loses); map-matching reads samples; the spec's path columns remain as the compact, query-friendly summary.

## Consequences
- No per-ping `UPDATE` on a growing geometry (write amplification avoided).
- Retention on samples (partition drops) is independent of trip rows.
