# 07 — Mobile Architecture (Flutter)

Spec references: §5.1 (Flutter), §5.2 (low-end devices, tokens, one-tap), §4.6, §4.8, FM19–FM22. Decisions: ADR-0008 (monorepo + packages), ADR-0011 (FCM push).

Two thin apps (`mobile-rider`, `mobile-driver`) over five shared Dart packages in `shared/flutter/`. Rider and driver are *separate apps* (spec §3) because their permission footprints differ (driver needs foreground location service + camera; rider should not request them), store listings differ, and update cadences differ.

---

## 1. Toolchain and pinning

- Flutter **stable** channel at project start; exact version pinned in `.fvmrc` (FVM) and recorded in ADR-0013 at bootstrap (never hardcode a version in docs — pin in the repo).
- Dart SDK per Flutter; `melos` workspace at `shared/flutter/melos.yaml` also including the two apps; `very_good_analysis` lint set + project overrides (no `avoid_print` exceptions; `prefer_const_constructors` on).
- Android: `minSdk 24` (Android 7.0 — covers > 97% of Nigerian Android devices; 23 and lower excluded for TLS 1.2 + WebView reasons), `targetSdk` latest. iOS 14+.
- Build flavours: `dev`, `staging`, `prod` (bundle ids `ng.along.rider.dev` …). Env via `--dart-define-from-file=env/<flavor>.json` (Supabase URL/anon key, tiles URL, Sentry DSN). **No secrets in the app** — the anon key is public by design; every privilege is RLS.
- CI: `melos run analyze`, `melos run test`, golden tests on Linux with pinned fonts, `flutter build apk --release --analyze-size` gate ≤ 25 MB (rider), ≤ 28 MB (driver).

## 2. Packages

| Package | Depends on | Responsibility |
|---|---|---|
| `along_core` | (pure Dart; `freezed`, `json_serializable`, `decimal`, `collection`) | Domain models (Trip, Journey, Candidate, Fare, LedgerEntry, Presence…), value types (`Money`, `GeoPoint`, `FareTier`), enums, formatting (`formatMoney`, `formatMoneySpoken`, `formatDuration`), Na Me pairing model, itinerary model, pure helpers (bearing, distance), error types (`AlongException` with `code`). **No Flutter import.** 100% unit-tested. |
| `along_design` | flutter, `along_core` | Tokens (generated), theme, all components in doc 05 §9, icons (custom SVGs via `flutter_svg` compiled to code with `vector_graphics`), golden tests. |
| `along_data` | `along_core`, `supabase_flutter`, `dio`, `drift`, `flutter_secure_storage` | Repositories (one per bounded context) wrapping RPC/Edge calls, DTO ↔ model mapping, offline cache (Drift), pending-action queue, auth session, error mapping (`PostgrestException` → `AlongException`). Interfaces in `along_core`? — No: interfaces live here as abstract classes; apps depend on abstractions via Riverpod providers. |
| `along_map` | `maplibre_gl`, `along_design`, `along_core` | `AlongMap` widget, style loader (PMTiles + style JSON), layers (puck, ambient clusters, parks/stages, route polylines, vehicle marker), camera helpers, tile cache management. |
| `along_realtime` | `supabase_flutter`, `along_core` | Broadcast channel wrappers (`TripChannel`, `AmbientChannel`, `DriverChannel`, `NegotiationChannel`) with reconnect + polling fallback, typed events, heartbeat monitoring. |
| `along_location` | `geolocator`, `flutter_foreground_task` (driver), `along_core` | Location stream abstraction with accuracy filtering, batching, throttling by movement; foreground service (driver only) |
| `along_notifications` | `firebase_messaging`, `flutter_local_notifications` | Token registration, background handler, deep-link routing |

Apps contain: `app.dart` (ProviderScope, theme, router), `features/<feature>/{presentation}` (screens + widgets + controllers), `routing/` (go_router config), `di/` (provider overrides per flavour), `l10n/` (ARB). Business logic that is *not* UI orchestration belongs in `along_core` or the server — never in a widget (user rule: no business logic in UI components).

## 3. Architecture inside a feature

```
features/trip_options/
  presentation/
    trip_options_screen.dart          -- ConsumerWidget; reads state, dispatches intents
    widgets/option_card.dart          -- from along_design or feature-local composition
    trip_options_controller.dart      -- Riverpod AsyncNotifier: holds PlanResult + sort; exposes request(candidate)
```
- **State**: Riverpod 2 with codegen (`@riverpod`). `AsyncNotifier` per screen-level state; `Notifier` for small UI state; family providers for per-trip channels. No `setState` beyond purely local animation state. No BLoC (one pattern only).
- **Intents → repository → server**. Controllers never call Supabase directly; they call `TripsRepository.request(candidateId, ...)`.
- **Optimistic UI (§4.6)**: controller sets `state = state.copyWith(requesting: candidateId)` synchronously, calls the RPC, and reconciles; on error it reverts and surfaces a `Toast`. Undo snackbar for one-tap request cancels via `cancel_trip` within 3 s.
- **Navigation**: `go_router` with typed routes (`go_router_builder`); deep links `along://trip/{id}`, `along://share/{token}`; guards for auth and for "active trip" (an active trip always re-opens R-13 on launch).
- **Errors**: every `Future` in a controller is wrapped by `guard()` mapping to `AlongException`; UI maps `code` → localized message + action (e.g., `LEDGER_BLOCKED` → BalanceCard CTA). Unknown errors → generic message + Sentry event with `request_id`. **No silent catch.**

## 4. Offline & low-data (spec §5.2, §4.8)

Drift (SQLite) database `along.db` per app:

| Table | Content | Policy |
|---|---|---|
| `kv` | session flags, prefs, last known location, Na Me pairing for active trips (`trip_id, color, shape, label`) | Na Me pairing written *synchronously on receipt* before the UI renders (FM22) |
| `graph_cache` | parks/stages/legs for cities the user has searched in (from a `graph-bundle` Edge endpoint returning a compact JSON per city version) | refreshed when `graph_version` changes; used for offline name lookups and rendering |
| `plan_cache` | last 20 `plan-trip` results keyed by (origin geohash7, destination geohash7, filters hash) | shown as "cached options" with a stale badge when offline; quotes flagged expired |
| `trip_cache` | active journey/trips `TripView` JSON | restores R-13/D-16 instantly on cold start |
| `steps_cache` | last wayfinding steps per trip | offline wayfinding |
| `pending_actions` | queue of `{id, type, payload, created_at, attempts}` for `confirm_fare`, `rate_trip`, `submit_correction`, `report_incident`, `trip_location_sample` batches | replayed FIFO on connectivity with exponential backoff; idempotent via `p_client_ref`; dropped after 7 days with a Sentry breadcrumb |
| `tiles` | handled by MapLibre's own cache (150 MB cap) | corridor pre-cache after first plan |

Network rules: gzip on; no images except avatars (optional, 96 px) and verification captures (compressed to ≤ 400 KB JPEG before upload); Realtime messages ≤ 300 B; `plan-trip` responses typically ≤ 12 KB. A `LowDataMode` (auto when `connectivity` reports 2G or the OS data saver is on) disables map tile refresh beyond zoom 15, avatars, and ambient Broadcast (falls back to 30 s polling).

## 5. Realtime

- `along_realtime` opens one Supabase Realtime socket; channels are lazily joined: `ambient:{city}:{gh5}` on R-05, `trip:{id}` on any Tier B screen, `driver:{id}` always while driver non-offline, `negotiation:{id}` during R-16.
- Heartbeat: if no message on `trip:{id}` for 15 s the client polls `trip_snapshot` every 10 s and shows "Live updates paused" after 30 s. Reconnect with jitter (1, 2, 4, 8 s max 30 s).
- Location publish (Tier B): rider and driver publish `{type:'loc',...}` at the same cadence as samples (3–5 s moving, 15 s still); also batched to `trip_location_sample` every 5 s (≤ 5 points).

## 6. Location (rider) and foreground service (driver)

- Rider: `geolocator` `LocationSettings(accuracy: high, distanceFilter: 5)` only while a Tier B screen is visible or a journey is active; never in background beyond the active trip (Android: "while in use" permission only). Accuracy filter: drop samples with `accuracy > 50 m` for boarding detection but keep for display.
- Driver: `flutter_foreground_task` starts when status ≠ offline; notification "Along — you're visible to riders"; stops on offline (spec §4.1: no passive tracking). Pings via `presence_ping` from the service isolate; battery guard: if battery < 15% and not charging, interval doubles and a banner informs the driver.
- Both: permission rationale screens are contextual (R-05 banner / D-08 toggle), never at onboarding.

## 7. Map

- `maplibre_gl` with style URL `${TILES_BASE}/styles/along-light.json` (PMTiles source via `pmtiles://` protocol supported by MapLibre Native ≥ 6; else a tiny range-request proxy on the CDN). Sprites/glyphs self-hosted.
- Layers managed by `along_map` controllers as GeoJSON sources updated in place (no marker widgets — Flutter overlay markers jank on low-end devices). Vehicle marker uses `icon-rotate` by heading; puck uses two circle layers (pulse via animated radius).
- Camera: `motion.camera` 350 ms; follows vehicle in R-13 with a "recenter" pill when the user pans.

## 8. Push (ADR-0011)

FCM (Android + APNs via FCM on iOS). Driver request pushes are `data` messages with `trip_id`, high priority, TTL 25 s (= `dispatch.request_ttl_s`), collapse key per trip; the background handler shows a full-screen intent notification (Android) that opens D-14. Rider pushes: accepted/declined/extension/negotiation/SOS ack. Token refresh → `register_device_token`.

## 9. Na Me implementation (§4.8)

`NaMeController` (in app, uses `along_core.NaMePairing`): on trigger → `WakelockPlus.enable()`, `ScreenBrightness.setScreenBrightness(1.0)`, run `motion.naMe` strobe (`AnimationController` toggling the full-screen container colour), `Vibration.vibrate(pattern)` in sync, `torch_light` toggle if `TorchLight.isTorchAvailable()`, `flutter_tts.speak(label)` once if enabled; on stop restore brightness/wakelock. Everything reads from the Drift `kv` pairing — zero network.

## 10. Localization

ARB files per app + shared strings in `along_core/l10n`; locales `en-NG` (default), `ha`, `yo`, `ig`, `pcm` scaffolded (spec §Phase 10); money/dates via `intl` with `countries` data (symbol, minor units). Mode labels come from `mode_config.label_i18n`. Every string in the UI is a key (Reviewer greps for `Text('`).

## 11. Observability

`sentry_flutter` with performance tracing (screen load, `plan-trip` span), `request_id` from every server response attached as breadcrumb; PII scrubbing (phone, plate). No analytics SDK that fingerprints devices; product events (search, view options, request, complete) go to `planner_queries`/`trip_events` server-side, not to a third party.

## 12. Testing (see doc 10)

- `along_core`: unit tests ≥ 95% line coverage.
- `along_design`: golden per component × state; text-scale 1.0 and 1.3.
- `along_data`: repository tests with mocked Supabase client; Drift queue replay tests.
- Apps: widget tests for every screen's states (loading/empty/error/offline) + `patrol` integration flows on emulator: onboarding, search→request→complete, driver online→accept→complete, negotiation, Na Me offline.
- Performance: `flutter drive --profile` timeline on the reference device; frame build ≤ 16 ms for option list scroll.

## 13. Device matrix (reference for perf and manual QA)
Tecno Spark 8C (2 GB), Infinix Hot 10 Lite (2 GB, Android 10 Go), Samsung A12 (3 GB), Redmi 9A, plus one iPhone SE 2 and one Pixel-class emulator. Network profiles: 2G-edge (50 kbps, 800 ms RTT), 3G (750 kbps, 400 ms), LTE.
