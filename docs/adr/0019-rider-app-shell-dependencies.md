# ADR-0019 — Rider app shell dependencies (P1-B-01)

**Status:** Accepted · **Date:** 2026-09-05 · **Task:** P1-B-01 · **Spec:** §6, ADR-0008, ADR-0013

## Decision

Pin app-layer Flutter dependencies introduced by `mobile-rider` (shell, routing, DI, l10n, observability, Patrol). All versions are compatible with Flutter **3.47.2** / Dart **3.13.2** (ADR-0013).

| Package | Version | Used in |
|---|---|---|
| `flutter_riverpod` | **2.6.1** | `mobile-rider` |
| `riverpod_annotation` | **2.6.1** | `mobile-rider` |
| `go_router` | **15.1.2** | `mobile-rider` |
| `sentry_flutter` | **8.14.2** | `mobile-rider` |
| `flutter_svg` | **2.0.17** | `mobile-rider` (logo from `along_design`) |
| `patrol` | **3.14.1** | `mobile-rider` (dev / integration_test) |
| `app_links` | **6.4.1** | `mobile-rider` (universal links R-27 cold/warm, P4-B-02) |

## Alternatives

- **BLoC** — rejected in ADR-0008.
- **auto_route** — rejected; go_router is the ADR-0008 choice.
- **Firebase Crashlytics** — rejected; Sentry chosen in blueprint doc 07 §11.

## Consequences

- Major upgrades require a new ADR superseding the relevant row.
- Sentry DSN is supplied via `--dart-define-from-file`; never committed.
- Patrol runs on emulator in CI nightly (doc 09); local runs require a device/emulator.
