# 01 — System Architecture

Spec references: §1 (constitution), §3 (repo), §4.1–4.14 (mechanics), §5 (stack), §6 (gates). Decisions recorded in ADR-0001, 0004, 0006, 0007, 0008, 0009, 0010, 0011, 0012.

---

## 1. Architectural stance (read first)

Along is **a deterministic marketplace over a proprietary graph**. Three consequences shape everything below:

1. **Correctness-critical logic lives next to the data.** Fare resolution, ledger posting, trip state transitions, matching eligibility (threshold block), presence status enforcement, disclosure gating and the promotion pipeline execute *inside Postgres* as `security definer` SQL functions wrapped in transactions. This is the only place we can guarantee atomicity, RLS enforcement, and auditability simultaneously. A client or Edge Function never "computes a fare and writes it"; it asks the database to do so.
2. **Orchestration and I/O live in Edge Functions.** Anything that talks to the outside world (OSRM, Paystack, Termii/SMS, FCM push, LLM/STT providers) or fans out (presence broadcast, dispatch cascade) is a Deno/TypeScript Edge Function. They hold the service-role key; clients never do.
3. **Clients are thin and optimistic.** Flutter apps render server state, apply optimistic UI for one-tap actions (spec §4.6), cache aggressively for low connectivity, and own only three pieces of *local* logic: the Na Me trigger (offline by design), the wayfinding renderer, and the offline action queue.

Everything a Worker builds must be attributable to exactly one of these three layers. If a task straddles two, the Orchestrator splits it.

---

## 2. Runtime topology

```
┌──────────────────────────────┐      ┌──────────────────────────────┐
│  mobile-rider (Flutter)      │      │  mobile-driver (Flutter)     │
│  Android + iOS               │      │  Android + iOS (fg service)  │
└──────────────┬───────────────┘      └──────────────┬───────────────┘
               │ HTTPS (PostgREST RPC, Edge Fns)     │
               │ WSS  (Realtime: Broadcast + Presence)│
               ▼                                     ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Supabase project (per environment: local / staging / prod)          │
│  ┌──────────────┐ ┌────────────┐ ┌──────────────┐ ┌────────────────┐ │
│  │ Auth (phone  │ │ PostgREST  │ │ Realtime     │ │ Storage        │ │
│  │ OTP via SMS  │ │ (RLS)      │ │ (Broadcast,  │ │ (private       │ │
│  │ hook→Termii) │ │            │ │  RLS authz)  │ │  buckets)      │ │
│  └──────────────┘ └────────────┘ └──────────────┘ └────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────────┐│
│  │ Postgres 15 + PostGIS + pg_cron + pg_net + pgcrypto              ││
│  │  schemas: public (API surface, RLS) · private (never exposed)   ││
│  │  bounded contexts are table groups within public (doc 01 §5)    ││
│  └──────────────────────────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────────────────────────┐│
│  │ Edge Functions (Deno/TS): plan-trip · dispatch · presence-fanout ││
│  │  · negotiation-clock · settlement · webhooks/paystack · notify   ││
│  │  · parse-itinerary · walking-directions · verification-ocr      ││
│  └──────────────────────────────────────────────────────────────────┘│
└───────────┬───────────────────────────────┬──────────────────────────┘
            │ HTTP (private network / VPC)  │
            ▼                               ▼
┌───────────────────────┐        ┌────────────────────────────────────┐
│ backend/routing       │        │ Object storage + CDN               │
│ OSRM ×2 (car, foot)   │        │ PMTiles vector tiles (OSM-derived) │
│ + Match service       │        │ MapLibre style JSON, sprites, fonts│
│ Docker on VM, weekly  │        │ Verification docs (private bucket) │
│ rebuild from Geofabrik│        └────────────────────────────────────┘
└───────────────────────┘
            ▲
┌───────────┴───────────┐        ┌────────────────────────────────────┐
│ backend/jobs (TS)     │        │ admin-console (Next.js, Vercel)    │
│ heavy batch only:     │        │ Supabase Auth (admin roles) + RLS  │
│ map-matching, speed   │        │ MapLibre GL JS                     │
│ profiles, exports     │        └────────────────────────────────────┘
│ (pg_cron does the rest)│
└───────────────────────┘
External: Paystack (payments) · Termii (SMS/OTP) · FCM (push) · verification provider (NIN/licence) · LLM/STT/TTS provider (bounded uses, §5.3)
```

**Environments:** `local` (Supabase CLI + Docker OSRM with a small extract), `staging` (full Abuja extract, test Paystack keys), `prod`. Every environment is created from the same migrations + seed scripts (doc 09).

---

## 3. Repository layout (spec §3, extended by ADR-0008 without new top-level dirs)

```
along/
├── mobile-rider/                 Flutter app (thin: routes, DI wiring, app-specific screens)
├── mobile-driver/                Flutter app (thin, + foreground location service)
├── backend/
│   ├── db/
│   │   ├── migrations/           supabase/migrations/*.sql (numbered, forward-only)
│   │   ├── policies/             RLS policies, one file per table (applied by migrations)
│   │   ├── functions/            SQL functions grouped by bounded context
│   │   ├── seed/                 seed_core.sql (modes, config), seed_abuja_pilot/, seed_testcity_fixture/
│   │   └── tests/                pgTAP tests (mirror of functions/ and policies/)
│   ├── functions/                Supabase Edge Functions (Deno), one dir per function + _shared/
│   ├── routing/                  OSRM docker-compose, profiles, extract scripts, style JSON build
│   └── jobs/                     TS batch worker (map-matching, speed profiles, exports)
├── admin-console/                Next.js
├── data-collection/              ODK/Kobo XLSForms, ingestion scripts, scout protocol
├── shared/
│   ├── contracts/                OpenAPI 3.1 for Edge Functions + JSON Schemas for RPC payloads
│   ├── design-tokens/            tokens.json (W3C DTCG) + Style Dictionary build → Dart + CSS
│   └── flutter/                  Dart packages: along_core, along_design, along_data, along_map, along_realtime
├── docs/                         spec, blueprint, adr, runbooks, ledger
└── README.md
```

Tooling: `melos` for the Dart workspace; `pnpm` workspaces for TS (`backend/functions`, `backend/jobs`, `admin-console`, `shared/contracts`, `shared/design-tokens`); `supabase` CLI for DB; GitHub Actions for CI (doc 09).

---

## 4. Logic-placement rules (binding)

| Concern | Layer | Why |
|---|---|---|
| Fare resolution Tier 0–2 (`resolve_fare`) | SQL function | Pure graph lookups; must be identical everywhere it's called (planner, hail, extension, commission) |
| Tier 3 anchor estimate | SQL function (distance/time proportional using nearby verified legs) | Same reason; OSRM distance fed in as a parameter by the Edge Function |
| Planner candidate generation | SQL functions (`planner_direct_candidates`, `planner_decompose`) | Spatial + graph joins belong in PostGIS; testable with pgTAP against seed data |
| Planner metric assembly, OSRM calls, ranking sort, response shaping | Edge Function `plan-trip` | Needs OSRM I/O; ranking is a pure TS function unit-tested in isolation |
| Trip state machine | SQL function `trip_transition()` + trigger guard | Atomic; every transition writes `trip_events`; illegal transitions raise |
| Matching eligibility (driver standing, threshold block, verification, women-only) | SQL function `driver_is_matchable()` called inside `trip_transition` and `dispatch` | Single choke point serves park-based and roaming paths (spec §4.4.1) |
| Ledger posting | SQL function `ledger_post()` with per-driver advisory lock; table append-only via trigger | Atomic; balance_after computed under lock |
| Disclosure tiering | SQL views/functions return either Tier A or Tier B shapes; Tier B functions verify caller is party to the trip | Server-side enforcement (FM21) |
| Presence status enforcement | SQL: `set_presence()`; trigger deletes row on `offline`; ping RPC rejects if status not opt-in | FM10 |
| Presence fan-out to riders | Edge Function `presence-fanout` publishing aggregate cells to Realtime Broadcast | Ambient view never exposes rows |
| Committed live position (Tier B) | Driver client → Realtime Broadcast on `trip:{id}` channel with RLS authz; also sampled to `trip_location_samples` via RPC every 5 s | Low latency for rider map; durable trace for reconciliation |
| Negotiation timers / ETA bands | Edge Function `negotiation-clock` (Deno cron every 1 s bucket) + SQL for state | Timers need a runtime; state must be transactional |
| Payments | Edge Function `settlement` + `webhooks/paystack`; SQL `ledger_post` on confirmed webhook only | Never trust client for payment outcome |
| Promotion pipeline, confidence decay, anomaly scoring, request expiry, presence retention, park clustering (`ST_ClusterDBSCAN`) | pg_cron SQL jobs | Set-based, no external I/O |
| Map-matching, segment speed profiles, anonymized exports | `backend/jobs` TS worker | Calls OSRM Match; batch-heavy |
| Na Me trigger | Client only (cached pairing) | Spec §4.8, FM22 |
| Wayfinding rendering (text/map/audio) | Client, from server-provided step list | Steps computed by `walking-directions` Edge Function via OSRM foot profile |
| NL itinerary / route parsing | Edge Function `parse-itinerary` → structured proposal; client confirms | §5.3 guardrail |

Anything not in this table: default to SQL if it touches money, state, or graph data; Edge Function if it touches the network; client only if it must work offline.

---

## 5. Bounded contexts and their tables

| Context | Tables (doc 02) | Owner functions |
|---|---|---|
| **Geo & config** | `countries, cities, corridors, mode_config, app_config, deployments` | `cfg()`, `city_for_point()` |
| **Identity** | `profiles, riders, drivers, vehicles, driver_vehicles, admin_users, driver_verifications, private.identity_hashes, device_tokens` | `submit_verification`, `approve_verification` |
| **Graph** | `data_sources, parks, routes, route_stages, route_legs, route_through_fares, transfer_points, graph_confirmations, graph_revisions, fare_corrections` | `resolve_fare`, `snap_stage`, `promote_candidates`, `decay_confidence` |
| **Driver routes** | `driver_route_profiles, driver_route_stops` | `upsert_route_profile`, `suggest_known_route`, `profile_fare` |
| **Presence** | `driver_presence, driver_presence_history` | `set_presence`, `presence_ping`, `ambient_vehicles` |
| **Planner** | `planner_queries, fare_quotes, coverage_gap_reports` | `planner_direct_candidates`, `planner_decompose`, `record_coverage_gap` |
| **Trips** | `journeys, trips, trip_events, trip_location_samples, trip_extensions, price_negotiations, price_negotiation_rounds` | `request_trip`, `hail_roaming`, `trip_transition`, `propose_extension`, `open_negotiation`, `negotiation_round` |
| **Ledger & payments** | `driver_ledger_entries, settlements, settlement_agents, payments, driver_standing_transitions, guarantors` | `ledger_post`, `driver_balance`, `apply_threshold_policy`, `transition_standing` |
| **Integrity** | `trip_reconciliation_flags, driver_risk_scores` | `reconcile_cancelled_trips`, `compute_risk_scores` |
| **Safety** | `ratings, trip_shares, sos_alerts, incidents` | `raise_sos`, `create_trip_share`, `shared_trip_view` |
| **Day planner** | `itineraries, itinerary_stops` | `itinerary_next_stage` |
| **Intelligence** | `job_runs, candidate_park_clusters, matched_traces, road_geometry_corrections, route_inference_candidates, segment_speed_profiles` | `cluster_candidate_parks`, jobs worker |
| **B2B/B2G (Ph 8+)** | `corporate_accounts, corporate_members, corporate_trip_policies, corporate_invoices, invoice_lines, operator_accounts, operator_members, sponsored_placements, placement_counters, api_keys, api_usage` | |
| **Field data** | `field_submissions, field_reconciliations` | `reconcile_field_entity`, `publish_field_entity` |
| **Audit** | `audit_log, notifications` | trigger `audit_admin_write()` |

---

## 6. Core request flows

### 6.1 Rider opens app (Tier A ambient)
1. Client obtains location → `rpc.ambient_vehicles(lat,lng,radius_m)` (SQL, RLS: any authenticated rider) → returns `cells[]` `{geohash6, mode_code, count_bucket ('1-2','3-5','6+'), heading_sectors int[8]}` — **no ids, no coordinates finer than the cell centroid**.
2. Client subscribes to Realtime Broadcast channel `ambient:{city_slug}:{geohash5}` for deltas pushed by `presence-fanout` every 10 s.
3. Search field is secondary (spec §4.6 — options-first).

### 6.2 Rider searches → plan → one-tap request
1. Client → Edge `POST /plan-trip {origin, destination, filters}`.
2. `plan-trip` (service role):  
   a. `planner_direct_candidates()` (parked, roaming, driver-profile sources) **and** `planner_decompose()` — both always run (§4.2.1).  
   b. Batches OSRM `table` (foot) for walking distances, OSRM `route` (car) for in-vehicle time where a leg lacks `in_vehicle_time_estimate_s`.  
   c. `resolve_fare()` per leg (Tier 0–2; Tier 3 anchor if needed) → `fare_quotes` rows.  
   d. Computes metrics + `recommended_score`; applies direct-first constraint and viability bound; returns top-N per criterion merged.  
   e. Writes `planner_queries` (analytics) and, if candidates are empty and no ambient signal, `coverage_gap_reports` + nearest-stage fallback.
3. Client renders candidates (options-first sheet). Rider taps **Request** on a card → `rpc.request_trip(candidate_id, leg_index, load)`:  
   - creates `journeys` (if first leg) + `trips` row in `requested`, snapshots the `fare_quote`, assigns Na Me pairing, runs `driver_is_matchable()` for a *specific* parked/profile driver, or enqueues cascading dispatch for a roaming-cell hail (§6.4).  
   - Returns Tier B view immediately (driver identity, plate, live channel name). Optimistic UI already showed "Requesting…".
4. Driver device receives FCM push + Realtime event → one-tap Accept/Decline → `rpc.respond_to_trip` → `trip_transition(requested→accepted)`.

### 6.3 Live trip
- Driver client publishes location every 3–5 s to Broadcast `trip:{trip_id}` (authorized by RLS on `realtime.messages`: only rider/driver of that trip) and calls `rpc.trip_location_sample` every 5 s (batched 1–3 points). Rider client does the same for `rider_live_path`.
- `auto_boarding_check()` (SQL, invoked by the sample RPC) transitions `accepted→boarded` when co-location criteria hold (doc 04 §9).
- Completion by driver tap → `trip_transition(→completed)` → `ledger_post(cash_commission_debit)` in the same transaction if `payment_method='cash'`; materializes `driver_live_path`/`rider_live_path` from samples.
- Rider post-trip one-tap confirm → `rpc.confirm_fare` → `fare_corrections` only on mismatch or Tier 3.

### 6.4 Roaming hail (Tier A → Tier B without identity leak)
1. Rider taps a cell/candidate card ("Keke heading your way, ~3 min, 2 seats") → `rpc.hail_roaming(candidate_token, destination, load)`. The `candidate_token` is an HMAC-signed, 60 s reference issued by `plan-trip`/`ambient_vehicles` mapping to `(driver_id, presence_session_id)`; the client cannot decode it.
2. Server creates `trips(requested)` against that driver → Tier B unlocked for *that* rider only.
3. On decline/expiry, `dispatch` Edge Function re-targets the next plausible driver in the cell (max `dispatch.max_cascade`, default 3) — the trip row is re-pointed and `trip_events` records it. Rider sees "Finding another vehicle…" without ever having seen the declining driver's identity.

### 6.5 Driver publishes a route (Tier 0 source)
`rpc.suggest_known_route()` → fast path card; or manual map taps each calling `rpc.snap_stage(lat,lng)` → `rpc.upsert_route_profile(payload)` validates monotone non-increasing `price_to_end`, snaps ≥ `route.snap_radius_m`, creates `candidate` stages for unmatched stops, activates immediately.

### 6.6 Settlement
Self-service: Edge `settlement/initiate` creates `settlements(pending)` + Paystack transaction → webhook verifies HMAC → `ledger_post(digital_settlement_credit)` idempotent on `provider_reference`. Agent-assisted: driver shows `agent_code`; agent app/console calls `rpc.confirm_agent_settlement(code, amount)` → same `ledger_post`. Both paths converge on one function.

---

## 7. Non-functional budgets (binding from Phase 1; load-tested in Phase 7)

| Metric | Budget | Where enforced |
|---|---|---|
| `plan-trip` server p95 | ≤ 800 ms (≤ 1.5 s end-to-end at 3G profile: 400 ms RTT, 750 kbps down) | k6 in CI (staging), Sentry perf in prod |
| `resolve_fare` p95 | ≤ 150 ms | pgTAP timing + k6 |
| `request_trip` / `respond_to_trip` / `set_presence` server p95 | ≤ 300 ms; optimistic UI on tap | k6 |
| Presence ping | interval 3–5 s moving, 15 s stationary; payload ≤ 200 B | client + `presence_ping` validation |
| Ambient fan-out latency | ≤ 10 s | `presence-fanout` schedule |
| Push (FCM) driver request arrival | ≤ 3 s p95 | monitored |
| Rider APK (arm64, release) | ≤ 25 MB; cold start ≤ 2.5 s on 2 GB RAM / Android 10 | CI size check; manual device matrix |
| Map: 60 fps pan/zoom on same device | vector tiles only (FM19) | device test |
| Any list endpoint | paginated, max page 50 | code review + tests |
| DB connections from Edge | pooled via Supavisor transaction mode | config |

---

## 8. Multi-tenancy and geography (Constitution 7)

- Every geographic entity carries `city_id`; `cities.country_code` → `countries`; `countries.deployment_id` → `deployments` (ADR-0004). Tenant isolation is *derived* from city membership; no per-row `tenant_id` needed on transactional tables.
- `city_for_point(geog)` resolves a coordinate to a city (boundary polygon, fallback nearest centroid ≤ 60 km). All planner queries, config resolution and admin scoping key off it.
- `app_config` resolves `corridor → city → country → global` (doc 02 §2.3). A new city = rows in `cities`, `corridors`, graph seed, `app_config` overrides. Zero code (FM5). The `seed_testcity_fixture` (fictional "Zaria-Test") exists purely to prove this in CI.

---

## 9. Failure and degraded modes (design-time decisions)

| Condition | Behaviour |
|---|---|
| OSRM unavailable | Planner falls back to `route_legs.in_vehicle_time_estimate_s` + straight-line×1.3 walking; response flagged `estimates_degraded=true`; UI shows "~" prefix on times |
| Realtime disconnected | Client polls `rpc.trip_snapshot` every 10 s; ambient view shows last cells ≤ 60 s old then greys out (FM10: never show stale pins as live) |
| Rider location permission denied | Planner accepts manual origin; `rider_live_path` absent → reconciliation treats as inconclusive (§4.4.2) |
| Payment provider down | Cash path unaffected; settlement shows retry + agent-code alternative |
| SMS provider down | Auth hook falls back to secondary provider (Twilio) — configured in `app_config.sms.providers` |
| Driver app killed while roaming | Foreground service restarts pings; server marks presence stale after `presence.stale_after_s` (default 45) and removes from ambient; status flips to `offline` after `presence.offline_after_s` (default 180) |
| LLM/STT provider down | Structured entry remains; NL/voice entry hidden |

---

## 10. What is deliberately *not* in the architecture

- No message broker/Kafka; pg_cron + Realtime + pg_net cover every asynchronous need at Phase ≤ 9 scale. Revisit only with a measured bottleneck (spec §5.1).
- No microservices; one Postgres, one Edge runtime, one batch worker. Bounded contexts are schema-level, not deployment-level.
- No custom auth; Supabase Auth phone OTP with a custom SMS hook.
- No fleet, dispatch queue, or vehicle inventory concepts anywhere (FM1). "Dispatch" in this document means *re-targeting a rider's hail to another independent driver*, never assigning Along-owned supply.
