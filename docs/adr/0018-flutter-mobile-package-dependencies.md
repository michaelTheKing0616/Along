# ADR-0018 — Flutter mobile package dependencies (P1-E-01)

**Status:** Accepted · **Date:** 2026-09-04 · **Task:** P1-E-01 · **Spec:** §6 (no unpinned dependencies), ADR-0008

## Decision

Pin first-party Flutter/Dart dependencies introduced by `along_core`, `along_data`, `along_realtime`, `along_location`, and `along_notifications`. All versions are compatible with Flutter **3.47.2** / Dart **3.13.2** (ADR-0013).

| Package | Version | Used in |
|---|---|---|
| `decimal` | **3.2.1** | `along_core` |
| `intl` | **0.20.2** | `along_core` |
| `collection` | **1.19.1** | `along_core` |
| `supabase_flutter` | **2.8.4** | `along_data`, `along_realtime` |
| `dio` | **5.8.0+1** | `along_data` |
| `drift` | **2.20.3** | `along_data` |
| `drift_dev` | **2.20.3** | `along_data` (dev) |
| `sqlite3_flutter_libs` | **0.5.28** | `along_data` |
| `path_provider` | **2.1.5** | `along_data` |
| `path` | **1.9.1** | `along_data` |
| `flutter_secure_storage` | **9.2.4** | `along_data` |
| `connectivity_plus` | **6.1.4** | `along_data` |
| `geolocator` | **13.0.2** | `along_location` |
| `firebase_messaging` | **15.2.4** | `along_notifications` |
| `flutter_local_notifications` | **18.0.1** | `along_notifications` |
| `maplibre_gl` | **0.22.0** | `along_map` |
| `build_runner` | **2.4.12** | `along_data` (dev) |

## Alternatives

- **Isar/Hive** for offline store — rejected in ADR-0008 (Drift SQL fits queue/graph queries).
- **http** instead of dio — rejected; dio is already chosen in ADR-0008 for interceptors and Edge calls.

## Consequences

- Major upgrades require a new ADR superseding the relevant row.
- CI `melos run test` resolves these via each package `pubspec.yaml`.
- Drift schema changes require `dart run build_runner build` in `along_data`.
