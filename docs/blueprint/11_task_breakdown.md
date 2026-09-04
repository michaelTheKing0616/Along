# 11 — Task Breakdown (Phases 0–12)

Spec references: §2 (agent workflow), §6 (gates), §7 (phase plan — objectives, deliverables, gates and exit criteria are *there*; this document decomposes them into issuable tasks). The Orchestrator issues one task at a time per Worker, attaching only the sections listed under **Attach**. Reviewer runs the **Acceptance** items plus spec §6 and the phase gates.

**Streams** (parallelisable; a task depends only on what its `Depends` column lists):
- **A** Backend: Postgres (migrations, functions, policies, pgTAP), Edge Functions, jobs
- **B** Rider app (Flutter)
- **C** Driver app (Flutter)
- **D** Admin console & public web (Next.js)
- **E** Infra, design tokens, data collection, docs

Task ID = `P<phase>-<stream>-<nn>`. Sizes: **S** ≤ ½ day, **M** ≤ 1.5 days, **L** ≤ 3 days of a Worker session; anything larger is split. Every task ends with a report in spec §2.3 format and a `BUILD_LEDGER.md` entry by the Orchestrator.

Standing acceptance for *every* task (not repeated below): spec §6 checklist; tests listed pass in CI; no new dependency without an ADR; no literal thresholds (`cfg` used); doc 05 grep gates on UI tasks; blueprint sections updated if the task revealed a needed change (recorded as an escalation, never a silent edit).

---

## Phase 0 — Data & Graph Foundation

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P0-E-01 | Bootstrap repo: layout (doc 01 §3), `melos.yaml`, `pnpm-workspace.yaml`, `.fvmrc`, Supabase CLI init, `.editorconfig`, lint configs, CODEOWNERS, PR template with spec §2.3 report sections | M | 01 §3, 09 §2 | — | `supabase start` works; `melos bootstrap` works; CI skeleton green on empty projects; ADR-0013 records pinned versions/region |
| P0-E-02 | CI workflows (`db`, `functions`, `mobile`, `admin`, `tokens`, `seed-fixture`) with placeholders that fail if a required check is missing | M | 09 §2 | P0-E-01 | Each workflow runs on PR; RLS coverage script exists and fails on a table without RLS |
| P0-A-01 | Migration 0001 extensions/schemas/helpers (doc 02 §1) + 0002 geo & config (§2) incl. `cfg()` and `city_for_point()` + `seed_core.sql` with all config keys | M | 02 §1–2, §17 | P0-E-01 | pgTAP: `cfg` resolution order (corridor>city>country>global); `city_for_point` boundary + fallback; every key in doc 02 §2.3 present |
| P0-A-02 | Migration 0003 identity (§3) incl. `profiles` auto-create trigger, column-protection triggers, `private.identity_hashes` | M | 02 §3, 12 §3 | P0-A-01 | pgTAP RLS: rider/driver own-row; driver cannot update protected cols; private schema no grants |
| P0-A-03 | Migration 0004 along-graph (§4) with adjacency/order triggers, `graph_revisions` triggers, `data_sources` | L | 02 §4 | P0-A-01 | pgTAP: adjacency trigger rejects non-adjacent leg; revision written on update; unique confirmation per account |
| P0-A-04 | `snap_stage()` + `resolve_fare()` Tier 1–2 (Tier 0/3 in P1) + `fare_quotes` | M | 04 §2–3, 02 §7 | P0-A-03 | TS-FARE-01/02/03/08 |
| P0-A-05 | Promotion pipeline: `compute_trust_weights`, `promote_candidates`, outlier MAD guard, `decay_confidence`, pg_cron schedules | L | 04 §6, 02 §2.3 | P0-A-03 | TS-GRAPH-01/02/03/04/05 (collusion scenario is the Phase 0 gate) |
| P0-A-06 | Multi-leg path query MVP (`planner_decompose` over seeded graph, walkable path between any two backbone parks) | M | 04 §4.3 | P0-A-03 | Query returns a path between every pair of seeded backbone parks (exit criterion) |
| P0-A-07 | Field tables (§14) + `admin_reconcile_field_entity` / `admin_publish_field_entity` + ingestion contract | M | 02 §14, 13 §3 | P0-A-03 | TS-GRAPH-07: publish blocked until matched/resolved; provenance on every row |
| P0-A-08 | Audit log table + `audit_admin_write()` trigger attached to Phase 0 tables; `admin_users` seeding script | S | 02 §15 | P0-A-02 | pgTAP: admin update writes audit row; audit append-only |
| P0-E-03 | ODK/Kobo XLSForms (park, route) + `export_choices.ts` + `ingest.ts` + `PROTOCOL.md` | M | 13 §1–3 | P0-A-07 | Round-trip test: sample submissions → `field_submissions` → reconciliation rows with correct variance |
| P0-E-04 | Seed: `seed_abuja_pilot/` from reconciled field data (≥ 3 corridors backbone) + `seed_testcity_fixture/` + `seed_test_scenarios/` | L | 02 §17, 13 §5–6, 10 §2 | P0-A-07, P0-E-03 | Exit criterion queries pass; TS-CFG-01 passes on Zaria-Test |
| P0-D-01 | Admin console bootstrap: Next.js, Supabase SSR auth (email+TOTP), tokens CSS placeholder, role routing, `AuditDrawer` | M | 08 §1–3 | P0-E-01, P0-A-08 | Playwright: sign-in per role; unauthorized route redirect |
| P0-D-02 | A-07 Field reconciliation queue + A-05 graph editor (read + basic edit) + A-08 city playbook (checklist, CSV dry-run/apply) | L | 06 B3 A-05/07/08, 08 §5 | P0-D-01, P0-A-07 | Ops can reconcile two scouts and publish to `field_verified` without SQL (exit criterion) |
| P0-E-05 | Design tokens source (`tokens.json`) + Style Dictionary build → Dart + CSS/Tailwind preset; `along_design` package skeleton with theme | M | 05 §1–5, §10–11 | P0-E-01 | Generated files committed; `tokens.yml` fails on stale output; TS-DS-02 (₦ glyph) golden |
| P0-E-06 | Brand assets: vectorise `main_logo_along_*` → SVG, app icons (adaptive), splash | S | 05 §1 | — | Assets in `shared/flutter/along_design/assets`; icons render at all densities |

**Phase 0 exit review**: Orchestrator confirms the §7 exit criterion with a recorded query log in the ledger.

---

## Phase 1 — Core Booking MVP (single corridor)

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P1-A-01 | Migrations: driver routes (§5), presence (§6), planner support (§7), journeys/trips (§8) tables + guard trigger + partitions job | L | 02 §5–8 | P0-A-03 | pgTAP: append-only; guard trigger blocks direct status write (TS-TRIP-03); partitions created |
| P1-A-02 | `shared/contracts`: OpenAPI 3.1 for Edge Functions + JSON Schemas for RPC payloads + generated TS/Dart types; CI drift check | M | 03 §0 | P1-A-01 | Generated types compile in Dart and TS; CI fails on drift |
| P1-A-03 | `resolve_fare` Tier 0 (profile) + Tier 3 anchor + load surcharge; `upsert_route_profile`, `suggest_known_route`, `suggested_stop_price`, `my_route_profiles` | L | 04 §3, 03 §6 | P1-A-01 | TS-FARE-04/05/06/07; TS-GRAPH-06 |
| P1-A-04 | Presence: `set_presence`, `presence_ping`, `presence_stale` job, `ambient_vehicles`, `ambient_demand`, plausibility fn | L | 04 §7, 03 §2, 02 §6 | P1-A-01 | TS-PRES-01/02/03/04; TS-DISC-01/02; TS-PLAN-10 |
| P1-A-05 | `driver_is_matchable()` (verification-only until Phase 4 adds ledger) + `request_trip` (parked/profile sources) + `respond_to_trip` + `cancel_trip` + `expire_requests` + `trip_transition` (requested/accepted/declined/expired/cancelled subset) + `TripView` functions + Na Me pairing generation | L | 04 §10, §16, 03 §4–5 | P1-A-01 | TS-TRIP-02 (subset), TS-TRIP-06, TS-DISC-03 |
| P1-A-06 | Edge `plan-trip` v1: direct candidates (parked/profile/graph) + metrics + sort orders + `fare_quotes`; OSRM client with degrade; `planner_queries`; coverage-gap fallback | L | 04 §4–5, §19, 03 §3, 01 §6.2 | P1-A-03, P1-A-04 | TS-PLAN-01 (direct only), TS-PLAN-05/06/08; p95 budget on seed |
| P1-A-07 | Edge `places-search` + Photon in `backend/routing` compose; `walking-directions` (OSRM foot) | M | 03 §3, 09 §4 | P0-E-01 | Deno tests with mocked OSRM; results parks-first |
| P1-A-08 | Realtime: Broadcast authz policies (`trip:*`, `driver:*`, `ambient:*`), Edge `presence-fanout`, `driver:{id}` request notification, FCM `notify` function, `device_tokens` RPC | M | 03 §2, §5, 07 §5, §8 | P1-A-04, P1-A-05 | TS-DISC-04; fan-out ≤ 10 s in staging |
| P1-A-09 | Verification RPCs (`register_vehicle`, `submit_verification`, `my_verifications`, admin approve/reject) + storage bucket policies + `verification-ocr` Edge (assistive, redacting ids) + identity hash on approval | L | 03 §1, §11, 02 §3, 12 §5 | P0-A-02 | pgTAP: unverified cannot go online (TS-PRES-03); duplicate hash detected; OCR output has no id numbers |
| P1-E-01 | `along_core` (models, Money, formatting, Na Me model, errors) + `along_data` (Supabase client, auth, repositories for auth/planner/trips/presence/routes, Drift schema, pending-action queue) + `along_realtime` + `along_location` + `along_notifications` skeletons | L | 07 §2–6, §8 | P1-A-02 | Unit tests ≥ 95% in core; repository tests with mocks; queue replay test |
| P1-E-02 | `along_map`: MapLibre integration, `along-light` style + PMTiles build scripts (`build_tiles.sh`), layers (puck, clusters, parks/stages, polylines, vehicle) | L | 05 §8, 07 §7, 09 §4 | P0-E-05 | Renders Abuja tiles offline from cache; 60 fps pan on reference device |
| P1-E-03 | `along_design` components batch 1: AlongButton, HoldButton, OptionCard, TierPill, ModeChip, SortChips, BottomSheet, SearchField, PhoneField/OtpField, Skeleton, Toast(undo), EmptyState, StatusToggle, RequestSheet, BalanceCard(stub), NaMeChip | L | 05 §9 | P0-E-05 | Goldens per component × state × text scale (TS-DS-03) |
| P1-B-01 | Rider app shell: flavours, DI, router, l10n, Sentry; R-01..R-04 onboarding | M | 07 §1, §3, §10–11; 06 R-01–04 | P1-E-01 | Patrol: OTP flow on emulator; strings keyed |
| P1-B-02 | R-05 Home with ambient clusters + peek sheet + recents; R-06/R-06b search & adjust pickup | L | 06 R-05/06, 03 §2–3 | P1-E-02, P1-E-03, P1-A-04, P1-A-07 | No specific vehicle rendered (review); stale greying; location-denied banner |
| P1-B-03 | R-07 Trip options (direct candidates), R-09 load flag, R-10 requesting, R-18 coverage gap; one-tap request with undo | L | 06 R-07/09/10/18, Part C | P1-B-02, P1-A-06, P1-A-05 | TS-UI-01 (request = 1 tap), TS-UI-03, load warning FM36; "Agree price" placeholder for Tier 3 (negotiation in P2) |
| P1-C-01 | Driver app shell + D-01..D-07 onboarding, vehicle, documents with OCR-assist confirm, pending screen | L | 06 D-01–07, 07 §6 | P1-E-01, P1-A-09 | Patrol: document upload → pending; ids never typed by OCR into fields without confirm |
| P1-C-02 | D-08 Home: StatusToggle (4 states), park picker D-09, seats, foreground service pings, demand cells | L | 06 D-08/09, 07 §6, 03 §6 | P1-E-02, P1-E-03, P1-A-04 | Offline → row deleted and ambient drops within 10 s (gate); battery guard; notification while online |
| P1-C-03 | D-10/11/12/13 Routes list, fast route setup, draw route with snapping, price keypad, load surcharge; publish = 1 tap | L | 06 D-10–13, 04 §2, 03 §6 | P1-C-02, P1-A-03 | Fast path 1 tap on pre-matched test account (gate); manual path snaps to existing stage (gate); non-monotone price rejected inline |
| P1-C-04 | D-14 Incoming request with load row, fare vs Along fee lines, countdown, Accept/Decline; FCM wake | M | 06 D-14, 03 §5 | P1-E-03, P1-A-08 | Load flag visible pre-accept (FM35 gate); Accept 1 tap |
| P1-D-01 | A-04 Verification queue + document viewer (signed, watermarked, access-logged) | M | 06 A-04, 08 §5 | P1-A-09, P0-D-01 | Playwright approve/reject; audit rows incl. `view_document` |
| P1-E-04 | Staging environment: Supabase project, routing VM (OSRM car/foot, Photon), tiles CDN, Termii sandbox hook, FCM project, Sentry | M | 09 §1, §4, §7 | P1-A-08 | Smoke: staging plan-trip end-to-end from a device |

**Phase 1 exit**: live test on a pilot corridor per §7 exit criterion, recorded with screenshots in the ledger.

---

## Phase 2 — Multi-Leg Planning, Ranking, Stage Fares & Along Pricing

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P2-A-01 | `planner_decompose` production version (k-shortest, transfer edges, ≤ 3 legs, no route reuse) + `plan-trip` v2 merging both searches, direct-first constraint, viability bound, `explain` | L | 04 §4.3–§5 | P1-A-06 | TS-PLAN-01/02/03/04/07/09; gate: multiple genuinely different candidates returned; four sorts differ on engineered dataset |
| P2-A-02 | Negotiation: tables (§8), `open_negotiation`, `negotiation_round`, `negotiation_split`, Edge `negotiation-clock` (timeouts, roaming radius lapse), Broadcast `negotiation:*`, `fare_corrections` posting | L | 04 §8, 03 §4 | P1-A-05 | TS-NEG-01..06 (FM31–38 gates) |
| P2-A-03 | Roaming hail: `hail_roaming`, candidate tokens (HMAC, Vault key), Edge `dispatch` cascade | M | 01 §6.4, 04 §10, 03 §4 | P1-A-05, P2-A-02 | TS-DISC-05/06 |
| P2-A-04 | Journeys multi-trip: `journeys` state machine, transfer handling, `walking-directions` pre-fetch hook | M | 04 §11 | P1-A-05 | TS-TRIP-07 |
| P2-A-05 | Speed-profile hook in metrics (reads `segment_speed_profiles` when present; table created now, populated in P7) | S | 04 §4.4, 02 §12 | P2-A-01 | Unit test: profile scales in-vehicle time |
| P2-B-01 | R-07 multi-leg cards + `LegTimeline` + explain popover + all four sort chips + per-leg request; R-14 transfer screen; R-19 wayfinding (text/map/audio) | L | 06 R-07/14/19, 05 §9 | P2-A-01, P2-A-04, P1-A-07 | Gate: per-leg accept/decline; TS-UI-01; audio via TTS |
| P2-B-02 | R-16 Along Pricing sheet (park / roaming bands / split) + hail-from-cell flow on R-05 | L | 06 R-16, 04 §8 | P2-A-02, P2-A-03 | Patrol: full round-cap flow; band UI per ETA; lapsed/out-of-range states |
| P2-C-01 | D-16 negotiation (driver side) + roaming request path in D-14 (cell hail, cascade re-target) | M | 06 D-14/16 | P2-A-02, P2-A-03 | Driver never sees rider identity pre-request beyond Tier B (review) |
| P2-E-01 | `along_design` batch 2: NegotiationSheet, LegTimeline, FareHero, StepList, AmbientCluster polish, Snackbar variants | M | 05 §9 | P1-E-03 | Goldens |
| P2-D-01 | A-06 Fare corrections queue (with MAD badge, negotiation-sourced rows) | M | 06 A-06 | P2-A-02, P0-D-01 | Playwright approve → confirmation row + possible promotion |

---

## Phase 3 — Live Tracking, Trip Lifecycle & Presence Hardening

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P3-A-01 | Full `trip_transition` (all states in doc 04 §10), `trip_location_sample`, `auto_boarding_check`, `mark_boarded`, `start_trip`, `complete_trip` (paths materialised; commission hook stubbed until P4), `mark_no_show`, `driver_manifest`, `trip_snapshot` | L | 04 §9–10, 03 §5 | P2-A-04 | TS-TRIP-01/02/04/05; false-trigger scenario (co-located without match) gate |
| P3-A-02 | Presence retention (`presence_retention` downsample/drop), history partitions, `presence_stale` hardening, Realtime scale config | M | 02 §6, 03 §12 | P1-A-04 | TS-PRES-02; retention verified by fixture |
| P3-A-03 | Realtime location channel hardening: authz tests, message size, polling fallback endpoint, `admin:{city}` precise channel for ops | M | 03 §5, 07 §5 | P1-A-08 | TS-DISC-04; TS-OPS-03 (staging, smaller scale now) |
| P3-B-01 | R-11 Meet your vehicle (live marker, plate, Na Me chip/button, wayfinding, boarded override), R-12 Na Me fullscreen (offline), R-13 Active trip with LegTimeline + SOS placeholder + share placeholder | L | 06 R-11/12/13, 07 §9 | P3-A-01, P2-E-01 | TS-UI-02 (airplane-mode Na Me gate); directional arrow; auto-boarding observed in live test |
| P3-C-01 | D-15 Manifest, D-16 Active trip (Na Me, start/complete), Na Me shared component, location publishing during trips | L | 06 D-15/16 | P3-A-01 | Live test: end-to-end transitions incl. transfer; Na Me offline |
| P3-E-01 | Realtime/presence load test v1 (k6: pings + subscribers) on staging; tune fan-out | M | 10 §3 Ops, 01 §7 | P3-A-02 | Results attached; budgets met at pilot scale |

---

## Phase 4 — Fare Transparency, Commission, Ledger & Payments

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P4-A-01 | Ledger migration (§9): entries (append-only), `ledger_post` (advisory lock, idempotency), `driver_balances`, `driver_is_matchable` with balance, `complete_trip` commission posting, config snapshot at request | L | 04 §12.1–12.2, 02 §9 | P3-A-01 | TS-LEDGER-01/02/04/05/06 (both matching paths gate) |
| P4-A-02 | Threshold policy job + standing ladder `transition_standing` + notifications + guarantors RPCs + `my_standing_history` | M | 04 §12.3–12.4, 03 §7 | P4-A-01 | TS-LEDGER-07; flags never transition (asserted) |
| P4-A-03 | Settlements: Edge `settlement/initiate` (Paystack), `webhooks/paystack` (HMAC, raw store, idempotent), agent codes + `confirm_agent_settlement`, `settlement_agents`; Paystack adapter behind `PaymentProvider` interface | L | 03 §7, 12 §7, 01 §6.6 | P4-A-01 | TS-LEDGER-03/08/09; cash trip makes zero payment calls (gate, asserted by network mock) |
| P4-A-04 | Rider digital payment (optional): `payments`, Edge `payments/initiate`, completion itemisation; `confirm_fare` → `fare_corrections`; `rate_trip`; `ratings` | M | 03 §5, 02 §11 | P4-A-01 | TS-UI-04 server side; corrections for Tier 3 always (FM33) |
| P4-A-05 | Extensions: `trip_extensions`, `propose_extension`, `respond_extension`, commission delta at completion, negotiation context `extension` | M | 04 §17, 03 §5 | P4-A-01, P2-A-02 | TS-TRIP-08 (gate: reuses resolve_fare unmodified — reviewer diff) |
| P4-A-06 | Reconciliation job (`reconcile_cancelled_trips`, undeclared extension), `trip_reconciliation_flags`, `compute_risk_scores` | L | 04 §13, 02 §10 | P3-A-01, P4-A-05 | TS-INTEG-01..05 (missing rider trace + multi-rider gates) |
| P4-A-07 | Manual adjustments with dual control (SQL-enforced), payouts for positive balances (Paystack transfer), finance RPCs | M | 03 §11, 08 §5 | P4-A-03 | TS-LEDGER-10 |
| P4-B-01 | R-17 Trip complete (fare confirm one-tap + rating), R-15 Extend trip (both directions), R-22 Trips history + receipt itemised, R-27 digital payment sheet (flag-gated) | L | 06 R-15/17/22/27 | P4-A-04, P4-A-05 | TS-UI-04; 2-tap default path |
| P4-C-01 | D-18 Trip complete summary (fare vs fee vs balance), D-19 Earnings & balance (two sections), D-20 Settle (channels + agent code), D-21 Standing, D-22 Guarantor, D-17 Extend; blocked banner on D-08 | L | 06 D-17–22 | P4-A-02, P4-A-03 | TS-UI-05 (blocked banner gate); labels human, never enum names |
| P4-D-01 | A-10 Integrity review (side-by-side traces, evidence, corroboration, Clear/Action→standing dialog), A-11 Driver detail (ledger, standing, guarantor notify), A-13 Finance (settlements, agents, dual-control queue) | L | 06 A-10/11/13, 08 §5 | P4-A-06, P4-A-07 | TS-INTEG-06; Playwright dual control; no auto action path exists (review) |
| P4-E-01 | Agent app surface: minimal agent web page in admin console (`agent` role) for `confirm_agent_settlement` | S | 03 §7 | P4-A-03 | Playwright: code redeem, replay rejected |
| P4-A-08 | Paystack subaccounts: `set_payout_bank` (account-name verification, subaccount creation, re-auth), split configuration in `payments/initiate`, reconciliation of split settlements | M | 03 §7, ADR-0010 | P4-A-03 | Split amounts equal fare − commission / commission to the minor unit; driver without subaccount → digital option hidden |
| P4-E-02 | **Legal review checkpoint (human):** confirm no-funds-held posture under CBN rules with split payments, subaccount KYC obligations, VAT treatment of commission, terms for drivers/riders. Digital payments stay behind `cfg payments.digital_enabled=false` in prod until sign-off. | S | 12 §7, ADR-0010 | P4-A-08 | Written sign-off attached to the ledger; flag flipped only after |

---

## Phase 5 — Safety & Trust (+ Day Planner stream)

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P5-A-01 | `raise_sos`/`update_sos` (≤ 300 B, never rate-limited), `notify` safety on-call (push + SMS), `trip_shares` + `shared_trip_view`, `report_incident`, incidents RLS | M | 03 §8, 02 §11, 12 §1 T10 | P3-A-01 | pgTAP RLS: incidents restricted to safety roles (gate); share token only while active |
| P5-A-02 | Women-only matching: eligibility flag on approval, planner filter, `request_trip` enforcement, regulatory flag gating | M | 04 §5, 03 §1 | P2-A-01 | TS-PLAN-07; request to non-eligible → `DRIVER_NOT_MATCHABLE` |
| P5-A-03 | Day planner: itineraries tables + RPCs + Edge `itinerary-prepare` + `parse-itinerary` (LLM/STT bounded) | L | 03 §9, 02 §11, 01 §4 | P2-A-04 | Unit: parse never writes; prepared plan present before stop completes |
| P5-B-01 | R-23 SOS (honest copy, 112 call, hold-to-cancel, low-data), R-24 Report, R-25 Share sheet + W-01 public page, R-26 Account & settings (women-only, wayfinding pref, saved sort) | L | 06 R-23–26, W-01 | P5-A-01, P5-A-02 | Gate: SOS under 2G profile reaches pipeline ≤ 10 s; W-01 shows minimal data |
| P5-B-02 | R-20 Day planner, R-21 itinerary entry (structured + NL/voice confirm) | L | 06 R-20/21 | P5-A-03 | Copy never says booked (review); Match now = 1 tap |
| P5-C-01 | Driver SOS + incident report + rating rider (D-18 extension) + D-24 Account | M | 06 D-18/24 | P5-A-01 | Same SOS gates |
| P5-D-01 | A-12 Safety board (SOS live, incidents triage, SLA timers) + runbook `sos_escalation.md` completed with on-call rota fields | M | 06 A-12, 08 §5 | P5-A-01 | Exit: simulated SOS visible on board within latency; ack pushes to rider |
| P5-E-01 | `along_design` batch 3: NaMeScreen polish, StepList audio state, itinerary timeline, SOS styles | S | 05 §9 | P2-E-01 | Goldens |

---

## Phase 6 — Admin/Ops Console Maturity

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P6-D-01 | A-02 Ops dashboard + A-15 Corridor analytics (`admin_corridor_analytics`, bounded/paginated) | L | 06 A-02/15, 03 §11 | P4-A-06 | Gate: analytics paginated; conversion metric present |
| P6-D-02 | A-03 Live map (layers, filters, side panel) | M | 06 A-03 | P3-A-03 | Precise positions only under admin role (RLS test) |
| P6-D-03 | A-05 Graph editor complete (map drag, adjacency validation, bulk import diff), A-09 Config editor (schema-validated, effective preview, reason) | L | 06 A-05/09, 08 §5 | P0-D-02 | Playwright: edit → revision + audit; config change → audit with reason |
| P6-D-04 | A-16 Audit log viewer, A-17 Admin users (invite, roles, scope, TOTP status) | M | 06 A-16/17 | P0-D-01 | Every admin write in Phase ≤ 6 appears (grep of RPC list vs audited tables) |
| P6-A-01 | Attach `audit_admin_write` to all remaining admin-modifiable tables; `admin_set_config` validation; analytics SQL functions | M | 02 §15, 03 §11 | P4-A-07 | pgTAP: audit coverage list = doc 02 §15 list |
| P6-E-01 | Runbooks: `corridor_onboarding.md`, `verification_review.md`, `fare_dispute.md`, `incident_response.md` (safety) | S | runbooks/README | P5-D-01 | Ops dry-run of a "pilot day" per exit criterion recorded |

---

## Phase 7 — Abuja Scale-Out & Trace Intelligence

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P7-E-01 | Corridor onboarding tooling hardening (A-08 for corridors, ingestion CLI), runbook validated by ops (not engineering) | M | 13, 06 A-08 | P6-D-03 | Gate: new corridor with zero code changes (diff shows only data/config) |
| P7-A-01 | Caching: `graph-bundle` Edge endpoint (per-city compact graph, versioned), `plan-trip` result cache for hot OD pairs (60 s), Edge KV for places | M | 07 §4, 03 §3 | P2-A-01 | Cache hit ratio reported; correctness tests unchanged |
| P7-A-02 | `backend/jobs` worker: `map-match` (OSRM Match) → `matched_traces`; regression test with raw traces produces zero proposals (FM27) | L | 04 §15, 09 §6 | P3-A-01 | Gate FM27 test; confidence filter |
| P7-A-03 | `speed-profiles` job + planner calibration; ETA accuracy A/B report vs generic defaults | M | 04 §15, §4.4 | P7-A-02 | Exit: measurable ETA improvement documented |
| P7-A-04 | `route-inference` + `geometry-corrections` jobs → candidates; `cluster_candidate_parks` pg_cron job | L | 04 §14–15 | P7-A-02 | TS-GRAPH-08; exit: simulated undeclared corridor yields reviewable route candidate |
| P7-D-01 | A-14 Intelligence review (candidate parks, route inference, geometry) | M | 06 A-14 | P7-A-04 | Promote creates `candidate` rows with provenance; audit |
| P7-E-02 | Load tests (k6) at full-city concurrency targets; DB tuning; Realtime scale; results attached | L | 10 Ops, 01 §7 | P7-A-01 | TS-OPS-02/03 pass |
| P7-B-01 | Rider low-data mode, graph-bundle offline cache, corridor tile pre-cache, cached options when offline | M | 07 §4 | P7-A-01 | Patrol under `edge` netspeed: search works from cache with stale badge |

---

## Phase 8 — B2B & B2G

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P8-A-01 | Corporate tables + policies + allocation on completion + monthly invoice job + reconciliation against trips | L | 02 §13 | P4-A-01 | Gate: invoice reconciles; discrepancy cases tested |
| P8-A-02 | `anonymized-export` job with k-anonymity (k ≥ cfg), suppression, re-identification test suite | M | 12 §1 T9, 02 §13 | P7-A-02 | Gate: re-identification tests pass (no singleton cells) |
| P8-A-03 | Operator accounts + scoped RLS + aggregates; `sponsored_placements` (contextual only) + counters; `api_keys` + rate-limited aggregate endpoints | L | 02 §13, 03 §11 | P6-A-01 | FM39/FM40 tests: no rider id path; API returns aggregates only |
| P8-D-01 | Corporate portal C-01..C-05; Operator portal O-01; A-19 revenue hooks admin | L | 06 B4, A-19 | P8-A-01, P8-A-03 | Exit criterion flows via Playwright |
| P8-B-01 | Contextual placement slot on R-07/R-22 (config-gated, clearly labelled "Sponsored") | S | 06, 02 §13 | P8-A-03 | No personal data in request (network assertion) |
| P8-E-01 | **Legal review checkpoint (human):** corporate invoicing/VAT, B2G data licensing terms under NDPA, advertising standards, operator SaaS terms | S | 12 §7 | P8-A-01..03 | Sign-off in ledger before any B2B contract goes live |

---

## Phase 9 — Multi-City Generalisation

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P9-A-01 | Audit: grep-and-verify no city/currency hardcodes (`'abuja'`, `NGN`, `₦`, `+234`) outside seeds/config; fix findings; city-level admin roles verified | M | 01 §8, 10 TS-CFG-01 | P7-E-01 | Gate artifact: grep report attached |
| P9-E-01 | Stand up second Nigerian city (e.g., Kaduna or Lagos pilot corridor) using only tooling; document deltas as tooling fixes | L | 13, runbooks | P9-A-01 | Exit: zero bespoke code |
| P9-B-01 / P9-C-01 | Apps: city switching, per-city tiles, l10n review for portability (labels via `mode_config.label_i18n`) | M | 07 §10 | P9-A-01 | Golden with alternate city data |
| P9-E-02 | Observability & backups maturity: dashboards, alerts (doc 09 §8), restore drill runbook + TS-OPS-01 | M | 09 §3, §8 | P7-E-02 | Drill executed and recorded |

---

## Phase 10 — Pan-African Portability & Tenancy

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P10-A-01 | Verification provider interface (pluggable per `countries.verification_schema.provider`), currency formatting from `countries`, regulatory flags wired (women-only, others), `deployments` tenant isolation RLS tests | L | 02 §2.1, §3, 12 | P9-A-01 | Gate: second tenant dry run, cross-tenant leakage tests |
| P10-D-01 | A-18 Markets & portability (countries, verification schema editor, flags, i18n coverage, payment provider per country) | M | 06 A-18 | P10-A-01 | Playwright: add hypothetical country config without code |
| P10-B-01 / P10-C-01 | Apps: tenant branding from `deployments.branding_config` (token overrides only), locale packs `ha/yo/ig/pcm`, currency-agnostic formatting | M | 07 §10, 05 | P10-A-01 | Goldens per locale; white-label dry run screenshots |
| P10-E-01 | "New country checklist" doc + dry run against a hypothetical country in review | S | runbooks | P10-D-01 | Gate artifact |

## Phase 11 — Hardening, Performance & Security Audit

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P11-A-01 | Authorization matrix artifact: generated from live policies vs doc 02 §16; discrepancies fixed | M | 02 §16, 12 | all | Gate artifact |
| P11-E-01 | External pen test coordination; remediation tasks; dependency audit; secret scanning; semgrep ruleset | L | 12 | all | Report with no open critical/high |
| P11-E-02 | Performance budget review: APK size, cold start, p95s under load; fixes | M | 01 §7, 07 | P7-E-02 | Budgets met; report |

## Phase 12 — Documentation & Deployment Readiness

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P12-E-01 | README (local stack in ≤ 10 commands), environment/config reference (generated from `app_config` descriptions), ADR index refresh, deploy + rollback runbooks, ledger archive | M | 00, 09 | all | Exit: fresh engineer runs stack from docs only (recorded) |
| P12-E-02 | Store readiness: listings, privacy labels, data-safety forms, W-03 legal pages, staged rollout config | M | 09 §2, 12 §5 | P11-E-01 | Store review passes |

---

## Parallelism guide (what the Orchestrator can run concurrently)

- Phase 0: E-01 → {A-01..A-03, E-05, D-01} → {A-04..A-08, E-03, D-02, E-06} → E-04.
- Phase 1: A-01/A-02 first; then A-03..A-09 in parallel with E-01..E-03; B and C streams start once E-01/E-03 and their A dependencies land; E-04 any time after A-08.
- Phase 2–5: A tasks lead by ~1 task; B/C/D follow; E design batches precede the screens that need them.
- Never run two tasks that touch the same migration file or the same Flutter package concurrently.

## Blueprint-level scheduling decisions (recorded here, mirrored in `BUILD_LEDGER.md`)
1. Wayfinding (§4.11) and coverage-gap fallback (§4.9) are built in Phases 1–2 because the planner UI needs them for walk legs; the spec does not assign them a phase.
2. The day planner (§4.10) is scheduled in Phase 5 (stream B, parallel to safety) — it depends on journeys (P2) and benefits from live ETAs (P3), and Phase 5's backend load is light.
3. Design tokens and the component library start in Phase 0 (P0-E-05) rather than Phase 1 so the admin console's Phase 0 screens draw from the same tokens (spec §5.2 intent).
4. Mid-trip extensions (§4.12) sit in Phase 4 as the spec states, but the negotiation machinery they reuse is Phase 2 — hence P4-A-05 depends on P2-A-02.
