# ADR-0003 — Journeys (one destination), trips (one vehicle), itineraries (a day)

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4 `trips`, Phase 3 state machine (`transfer`), §4.10 `itinerary_stops.linked_trip_id`, §4.12

## Context
The spec's `trips` has a single `driver_id` and a `route_leg_ids[]` array, and its lifecycle includes `transfer`. A multi-leg journey across *different vehicles* has different drivers, fares and commissions per vehicle; a single row cannot hold that without losing the per-driver ledger link and Na Me pairing.

## Decision
- `journeys`: one rider → one destination; holds the chosen plan snapshot, load flag, women-only flag; states `planning → active ⇄ transfer → completed | abandoned`.
- `trips`: one rider in one vehicle with one driver; `route_leg_ids[]` = the adjacent stage-hops traversed in that vehicle; states per doc 04 §10. `transfer` lives at journey level.
- `itineraries`/`itinerary_stops`: a day plan; each stop links to a journey (`linked_journey_id`, generalising the spec's `linked_trip_id`).

## Consequences
- Commission, extensions, Na Me, ratings and reconciliation remain strictly per trip (per driver).
- The spec's "trip" in prose maps to *journey* where it means the rider's whole movement and to *trip* where it means one vehicle. Blueprint docs use the terms precisely.
- `journeys.plan_snapshot` is the immutable evidence for disputes about what was offered.
