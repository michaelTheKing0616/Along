# ADR-0007 — Presence transport: DB row per driver + Broadcast fan-out of aggregate cells; Tier B via trip channels

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4.1, §4.1.2, FM10, FM21

## Context
Riders must see ambient supply without any vehicle being identifiable; drivers' positions must reach the server for matching/clustering; matched parties need low-latency live positions.

## Decision
- `driver_presence` holds exactly one row per opted-in driver (deleted on offline). Pings are RPCs (validated, throttled) that also append to `driver_presence_history`.
- Riders never read `driver_presence`. `ambient_vehicles()` returns geohash-6 cells with count buckets and heading sectors; `presence-fanout` publishes the same to `ambient:{city}:{gh5}` Broadcast channels every 10 s.
- After a `trips` row exists, positions flow on `trip:{id}` Broadcast (RLS-authorised to the two parties) and are sampled into `trip_location_samples`.
- Roaming hails reference vehicles through opaque, 60-second HMAC `candidate_token`s; the server resolves them.

## Alternatives
Postgres Changes subscriptions on `driver_presence` (leaks rows; heavy), a separate in-memory geo service (premature).

## Consequences
Two write paths per ping (row upsert + history) are acceptable at pilot scale; history is partitioned and downsampled per config.
