# Architecture Decision Records — Index

**Precedence:** `docs/ALONG_BUILD_SPEC.md` > blueprint > ADRs > code. New top-level directories or schema changes to the along-graph require a new ADR (spec §3, §4).

| ADR | Title | Status |
|---|---|---|
| [0001](0001-supabase-platform-and-logic-placement.md) | Supabase as the backend platform; logic placement SQL vs Edge vs client | Accepted |
| [0002](0002-mode-as-config-table.md) | Vehicle mode is a configuration table, not a Postgres enum | Accepted |
| [0003](0003-journeys-trips-itineraries.md) | Journeys (one destination), trips (one vehicle), itineraries (a day) | Accepted |
| [0004](0004-tenancy-via-city-deployment.md) | Tenant isolation derived from city → country → deployment | Accepted |
| [0005](0005-design-system-resolution.md) | Design system resolution (tokens, type, colour) over the two Stitch variants | Accepted |
| [0006](0006-osrm-pmtiles-maplibre-photon.md) | Self-hosted OSRM (car + foot, Match), PMTiles vector tiles on CDN, MapLibre, Photon places | Accepted |
| [0007](0007-presence-transport-and-ambient-aggregation.md) | Presence transport: DB row per driver + Broadcast fan-out of aggregate cells; Tier B via trip channels | Accepted |
| [0008](0008-flutter-monorepo-riverpod-shared-packages.md) | Flutter: two apps, shared Dart packages under `shared/flutter`, Riverpod + go_router + Drift + MapLibre | Accepted |
| [0009](0009-location-samples-vs-path-columns.md) | Store raw location samples; materialise `driver_live_path`/`rider_live_path` at completion | Accepted |
| [0010](0010-ledger-entry-types-and-payments.md) | Ledger entry types (`payout_debit` added), Paystack behind a provider interface, agent codes | Accepted |
| [0011](0011-push-notifications-fcm.md) | Push notifications via Firebase Cloud Messaging | Accepted |
| [0012](0012-phone-otp-via-supabase-auth-termii.md) | Phone OTP via Supabase Auth with a custom SMS hook (Termii primary, Twilio fallback) | Accepted |
| [0013](0013-pinned-versions-and-region.md) | Pinned toolchain versions and hosting region | Accepted |
| [0014](0014-qr-scan-to-pay.md) | QR scan-to-pay via Along universal links resolving to Paystack split transactions | Accepted |
| [0015](0015-rls-policies-inline-in-migrations.md) | RLS policies live inline in migrations; `policies/` is a generated snapshot | Accepted |
| [0016 (config)](0016-config-defaults-owned-by-migrations.md) | `app_config` defaults are owned by migrations, not seeds | Accepted |
| [0016 (codegen)](0016-contract-codegen-tooling.md) | Contract codegen tooling (OpenAPI + JSON Schema → TS/Dart) | Accepted |
| [0017](0017-edge-function-dependencies.md) | Edge Function npm dependencies (Supabase JS, Zod) | Accepted |
| [0018](0018-flutter-mobile-package-dependencies.md) | Flutter mobile package dependencies (P1-E-01) | Accepted |
| [0019](0019-rider-app-shell-dependencies.md) | Rider app shell dependencies (P1-B-01) | Accepted |
| [0020](0020-flutter-tts-wayfinding.md) | flutter_tts for rider wayfinding audio (P2-B-01) | Accepted |
| [0021](0021-admin-console-pdf-qr-deps.md) | Admin console PDF/QR dependencies for sticker batch preview | Accepted |

**Note:** Two ADRs share the number 0016 — distinct filenames disambiguate config-defaults vs contract-codegen. Renumbering is deferred to avoid breaking references in the ledger and task reports.
