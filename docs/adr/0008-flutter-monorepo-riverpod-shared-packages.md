# ADR-0008 — Flutter: two apps, shared Dart packages under `shared/flutter`, Riverpod + go_router + Drift + MapLibre

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §3 (repo layout), §5.1, §5.2

## Decision
- Keep the spec's top-level dirs; place Dart packages in `shared/flutter/` (the spec's `shared/` is for cross-app contracts; Dart packages are exactly that). No new top-level directory.
- Packages: `along_core` (pure Dart domain), `along_design` (tokens + components), `along_data` (Supabase repos + Drift offline), `along_map`, `along_realtime`, `along_location`, `along_notifications`. Managed with `melos`.
- State: **Riverpod 2 (codegen)** only; navigation: **go_router**; local DB: **Drift**; map: **maplibre_gl**; HTTP: `supabase_flutter` + `dio`.
- Separate rider and driver apps (different permissions, store listings, cadences).

## Alternatives
BLoC (more boilerplate for the same testability), single app with role switch (permission footprint and store-review risk), Isar/Hive for local DB (Drift's SQL is better for queue/graph queries).

## Consequences
Exact versions pinned in ADR-0013 at bootstrap; all business logic outside widgets; goldens for every component.
