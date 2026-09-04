# 03 — API Contracts

Spec references: §4.1.2 (disclosure tiers), §4.6 (one-tap/optimistic), §6 (validation, pagination). Machine-readable versions live in `shared/contracts/` (OpenAPI 3.1 for Edge Functions, JSON Schema for RPC payloads) and are generated *from this document* in task P1-A-02; the two must never diverge (CI diff check).

## 0. Conventions

- **Transport**: PostgREST RPC (`POST /rest/v1/rpc/<fn>`) for SQL functions; Supabase Edge Functions (`POST /functions/v1/<name>`) for orchestration; Supabase Realtime for push.
- **Auth**: Supabase JWT (`Authorization: Bearer`). Role derived server-side from `riders`/`drivers`/`admin_users` membership — never from a client-sent claim.
- **Envelope** (Edge Functions): success `{ "data": ..., "meta": {"request_id","degraded"?} }`; error `{ "error": { "code", "message", "details"? }, "meta": {...} }`. RPCs raise `sqlstate` + message; the client maps `P0001` with `MESSAGE = 'ALONG:<CODE>'` to the same code set.
- **Error codes** (stable strings): `UNAUTHENTICATED, FORBIDDEN, NOT_FOUND, VALIDATION, CONFLICT, RATE_LIMITED, STATE_INVALID, DRIVER_NOT_MATCHABLE, LEDGER_BLOCKED, CANDIDATE_EXPIRED, NEGOTIATION_CLOSED, FARE_UNRESOLVED, COVERAGE_GAP, DEGRADED_UPSTREAM, IDEMPOTENT_REPLAY`.
- **Idempotency**: every mutating Edge Function accepts `Idempotency-Key` header (UUID) stored 24 h in `private.idempotency` → replays return the original response with `IDEMPOTENT_REPLAY` meta. RPCs that create rows accept `p_client_ref uuid` and are unique on it.
- **Pagination**: cursor-based: `?limit≤50&cursor=<opaque>`; response `meta.next_cursor`. No offset pagination anywhere.
- **Validation**: all geo inputs `lat ∈ [-90,90]`, `lng ∈ [-180,180]`, accuracy `≤ 500 m` else rejected; text lengths per doc 02; enums validated against `mode_config` etc. Validation is server-side always (spec §6).
- **Disclosure tier label** on every endpoint: **A** (ambient/anonymous), **B** (requires the caller be party to an existing `trips`/`journeys` row), **I** (internal/admin/service).
- **Rate limits** (per user unless stated): `plan-trip` 30/min; `ambient_vehicles` 12/min; `request_trip`/`hail_roaming` 10/min; OTP 5/h per phone + 20/h per IP; `presence_ping` 30/min; `raise_sos` unlimited (never rate-limit SOS).
- **Time**: ISO-8601 UTC strings. Money: `{"amount":"450.00","currency":"NGN"}` strings, never floats.

Shared shapes:

```ts
type Money = { amount: string; currency: string };
type Point = { lat: number; lng: number };
type FareTier = 0|1|2|3;
type Fare = { total: Money; tier: FareTier; confidence: number; unconfirmed: boolean; components: FareComponent[]; quote_id: string; expires_at: string };
type FareComponent = { kind: 'through_fare'|'leg'|'profile'|'estimate'|'load_surcharge'|'negotiated'; ref_id?: string; amount: Money; label: string };
type ModeRef = { code: string; label: string; icon_key: string; color_token: string };
type Metrics = { total_fare: Money; total_time_s: number; in_vehicle_s: number; wait_s: number; walk_s: number; transfer_count: number; total_walking_distance_m: number; strenuousness_score: number; recommended_score: number; explain: Record<string, number> };
```

---

## 1. Auth & profile

| Endpoint | Tier | Notes |
|---|---|---|
| Supabase Auth `signInWithOtp({phone})` | — | SMS hook → Termii; fallback Twilio. Rate limits above. |
| Supabase Auth `verifyOtp` | — | On first sign-in, trigger creates `profiles` row. |
| `rpc.complete_rider_onboarding({display_name?, home_city_id?})` | — | Creates `riders` row. Display name optional (can be added later). |
| `rpc.start_driver_onboarding({city_id, display_name, gender?})` | — | Creates `drivers(unverified)`. |
| `rpc.register_vehicle({mode_code, plate_number, seat_capacity, color?, make_model?, owner_is_me: bool, owner_name?, owner_phone?})` | — | Returns `vehicle_id`; sets `driver_vehicles.active`. Plate uniqueness per country → `CONFLICT`. |
| `rpc.submit_verification({vehicle_id?, document_type, storage_path, client_ocr_hint?})` | — | Validates `document_type` ∈ `countries.verification_schema`; path must be under `verification/{auth.uid()}/`. Enqueues `verification-ocr`. Never accepts the ID number itself. |
| `rpc.my_verifications()` | — | `[{document_type,status,rejection_reason,submitted_at}]` |
| `rpc.register_device_token({platform, token, app})` | — | |
| `rpc.update_rider_prefs({wayfinding_mode?, saved_sort?, women_only_pref?})` | — | |
| `rpc.register_guarantor({guarantor_type, name, phone_e164, profile_id?})` | — | Sends acknowledgement SMS link → `rpc.acknowledge_guarantor(token)`. |

---

## 2. Ambient discovery (Tier A) — spec §4.1.2

### `rpc.ambient_vehicles(p_lat, p_lng, p_radius_m ≤ 3000, p_dest_lat?, p_dest_lng?)` → **A**
```json
{ "as_of": "…", "cells": [
  { "cell": "s0k8tz", "centroid": {"lat":9.05,"lng":7.49}, "mode": {"code":"keke",…},
    "count_bucket": "3-5", "heading_sectors": [0,1,0,2,0,0,0,0], "serves_destination": true, "eta_band_s": 180 }
]}
```
Rules: cells are geohash precision `cfg presence.ambient_cell_precision`; a cell needs ≥1 vehicle; `count_bucket ∈ {"1-2","3-5","6+"}`; never returns driver ids, plates, or raw coordinates; `serves_destination` computed by heading/declared-route plausibility (doc 04 §7) when a destination is passed; `eta_band_s` is the *cell's* minimum ETA rounded to 60 s. Excludes drivers where `driver_is_matchable()=false` so the count is honest.

### Realtime Broadcast `ambient:{city_slug}:{geohash5}` → **A**
Message `{"type":"cells","cells":[…same shape…],"as_of"}` every 10 s from `presence-fanout`. Client keeps max 60 s; then greys.

### `rpc.ambient_demand(p_lat, p_lng, p_radius_m)` → **A** (driver app, §4.1.2 symmetric)
`{ "cells":[{cell, centroid, searches_last_15m_bucket, top_destination_directions:[sector,…]}] }` from `planner_queries` — aggregate only, never a rider.

---

## 3. Planning

### `POST /functions/v1/plan-trip` → **A** (candidates carry no driver identity)
Request:
```json
{ "origin": {"lat":..,"lng":..}, "destination": {"lat":..,"lng":..}, "destination_label": "Wuse Market",
  "filters": { "women_only": false, "load": {"flagged": true, "size": "medium"} , "modes": null },
  "session_id": "uuid", "itinerary_stop_id": null }
```
Response:
```json
{ "data": {
  "query_id": "uuid", "city_id": "uuid", "degraded": false,
  "candidates": [ {
     "candidate_id": "uuid", "kind": "direct" | "multi_leg", "source": "parked"|"roaming"|"driver_profile"|"graph",
     "viable_direct": true,
     "legs": [ { "leg_index": 0, "mode": ModeRef, "board": {"stage_id","name","location","walk_m","walk_s","wayfinding_available":true},
                 "alight": {"stage_id","name","location"}, "route_id", "route_leg_ids":[…], "in_vehicle_s", "wait_s", "fare": Fare,
                 "supply": {"kind":"parked","vehicles_bucket":"1-2"} | {"kind":"roaming","eta_band_s":120,"seats_bucket":"1-2","candidate_token":"…"} | {"kind":"driver_profile","profile_present":true} | {"kind":"graph"},
                 "load_warning": null | {"reason":"mode_capacity","mode_capacity":"none"} } ],
     "transfers": [ {"at_park_id","park_name","walk_m","transfer_s"} ],
     "metrics": Metrics
  } ],
  "sort_orders": { "recommended": ["cid…"], "cheapest": [...], "fastest": [...], "least_strenuous": [...] },
  "coverage_gap": null | { "report_id", "nearest_stage": {"stage_id","name","location","distance_m"}, "ambient_vehicle_count": 0 }
}}
```
Rules (doc 04 §3–§5): both searches always run; `sort_orders.recommended` must place a `viable_direct` candidate first when one exists; `total_fare` is always summed `resolve_fare` output; `unconfirmed=true` ⇒ Tier 3 → UI offers Along Pricing, never a silent number. `candidate_token` = HMAC-signed `{driver_id, presence_session_id, exp}` (60 s), opaque to client. Max candidates `cfg planner.max_candidates`.

### `POST /functions/v1/places-search` → **A**
`{ "q": "wuse mar", "near": Point, "city_id", "limit": 8 }` → `{ "results": [{"kind":"park"|"stage"|"place","id"?,"name","area","location","distance_m"}] }`. Parks/stages first (trigram on `parks.name`/`name_aliases`/`route_stages.name`), then places from the self-hosted Photon index (`backend/routing/photon`, built from the same OSM extract as tiles/OSRM). Debounced client-side at 250 ms; cached per `(q, geohash5)` for 24 h in Edge KV.

### `POST /functions/v1/walking-directions` → **A**
`{ "from": Point, "to": Point, "mode_pref": "text"|"map"|"audio" }` → `{ "distance_m", "duration_s", "steps":[{"instruction","distance_m","bearing","maneuver","geometry":[Point…]}], "polyline":[Point…], "tts_script": [...]? }` via OSRM foot profile. Same endpoint for park walks, coverage-gap fallback, and day-planner transitions (§4.11 shared infra).

### `POST /functions/v1/parse-itinerary` → **A**
`{ "text": "drop the kids at school then work then market", "city_id", "voice_transcript_id"? }` → `{ "proposal": [{"sequence","destination_description","resolved":{"label","location","confidence"}|null}], "needs_confirmation": true }`. Never writes; client confirms via `rpc.create_itinerary`.

---

## 4. Requests, hails, negotiation (transition A → B)

### `rpc.request_trip(p_candidate_id uuid, p_leg_index int, p_load jsonb?, p_women_only bool, p_client_ref uuid)` → returns **B**
Creates `journeys` (first leg) or advances an existing one; snapshots the leg's `fare_quote`; for `source ∈ {parked, driver_profile}` targets the specific driver (checks `driver_is_matchable`); for `roaming` requires the leg's `candidate_token`. Returns `TripView` (below). Errors: `CANDIDATE_EXPIRED` (quote/token expired → replan), `DRIVER_NOT_MATCHABLE`, `VALIDATION` (load size vs mode capacity requires `p_load.acknowledged_warning=true`, FM36).

### `rpc.hail_roaming(p_candidate_token text, p_destination Point, p_load jsonb?, p_women_only bool, p_client_ref uuid)` → **B**
Same as above for a cell-card hail without a full plan; server resolves fare via `nearest_stage_id`/declared route (Tier 0–2) or returns `FARE_UNRESOLVED` with an `anchor` so the client opens Along Pricing first.

### `rpc.respond_to_trip(p_trip_id, p_action 'accept'|'decline', p_decline_reason?)` → **B** (driver)
One tap. `decline_reason ∈ cfg('decline.reasons') ∪ {'no_room_for_load'}`. Decline/expiry on a roaming hail triggers `dispatch` cascade.

### `rpc.cancel_trip(p_trip_id, p_reason?)` → **B** (rider or driver; both recorded distinctly)

### `rpc.open_negotiation(p_context, p_candidate_token?|p_driver_id?, p_from Point|stage, p_to Point|stage, p_client_ref)` → **B-pending**
Server verifies Tier 3 (raises `STATE_INVALID` if a Tier 0–2 fare resolves — FM31), computes anchor (`fare_quotes tier=3`), sets `round_cap/round_timeout_s/eta_band/pickup_radius_m` per context (doc 04 §8). Returns `{negotiation_id, anchor: Money, chip_steps:[…], round_cap, round_timeout_s, eta_band, expires_at}`.

### `rpc.negotiation_round(p_negotiation_id, p_action 'accept'|'counter'|'decline', p_amount?)` → **B-pending**
Counter requires `p_amount = last_amount ± step` where step ∈ `chip_steps`. `accept` locks in → creates `trips(requested)` (or `accepted` when the accepting party is the driver and the rider already committed) with `fare_tier=3` quote and posts `fare_corrections(status=pending, submitter_role='system')` (FM33). Returns updated negotiation + `trip` when created.

### `rpc.negotiation_split(p_negotiation_id)` → **B-pending**
Allowed only when `rounds = round_cap` and status open; creates system round at midpoint rounded to currency minor unit; either party's next `accept` locks it.

### Realtime Broadcast `negotiation:{id}` — both parties receive `{round, amount, proposed_by, expires_at, status}`. Countdown is client-rendered from `expires_at`.

---

## 5. Trip lifecycle (Tier B)

`TripView` (returned by all Tier B calls; both parties get the same shape with role-specific redactions):
```json
{ "trip_id","journey_id","journey_sequence","status","mode":ModeRef,
  "rider": {"display_name","rating","trip_count"},                       // driver sees; no phone
  "driver": {"display_name","rating","trips_completed","photo_url":null}, // rider sees; photo optional post-verification
  "vehicle": {"plate_number","color","make_model","seat_capacity"},       // rider sees only after status ≥ accepted
  "board": {...}, "alight": {...}, "route_leg_ids":[...],
  "fare": Fare, "load": {"flagged","size","note"}, "women_only",
  "na_me": {"color_token","shape","label":"Green Diamond"},                // §4.8 cached client-side immediately
  "live_channel": "trip:{id}", "expires_at", "timestamps": {...},
  "extension": null | {...}, "payment_method" }
```

| Endpoint | Actor | Notes |
|---|---|---|
| `rpc.trip_snapshot(p_trip_id)` | party | Polling fallback. |
| `rpc.trip_location_sample(p_trip_id, p_points [{ts,lat,lng,accuracy_m,speed_mps,heading}] ≤ 5)` | party | Inserts samples; runs `auto_boarding_check()`; returns `{boarded_auto: bool}`. Rejects if trip not in `accepted|boarded|in_transit`. |
| `rpc.mark_boarded(p_trip_id)` | rider or driver | Manual fallback (§4.6). Records `boarded_via`. |
| `rpc.start_trip(p_trip_id)` | driver | `boarded → in_transit` (also auto when speed > threshold for 30 s). |
| `rpc.complete_trip(p_trip_id, p_alighting Point?)` | driver | `→ completed`; posts commission if cash; materializes paths; returns `{commission: Money, fare: Money}` itemized (FM3). |
| `rpc.mark_no_show(p_trip_id)` | driver | Only after `accepted` + `cfg dispatch.no_show_after_s` (default 300) at pickup. |
| `rpc.propose_extension(p_trip_id, p_new_alight Point|stage_id)` | rider or driver | Re-runs `resolve_fare` from current position/alight to new; returns `{extension_id, fare_delta, new_total, tier, unconfirmed}`; if tier 3 → client opens negotiation `context='extension'`. |
| `rpc.respond_extension(p_extension_id, 'accept'|'decline')` | other party | On accept: updates `trips.alighting_*`, posts incremental commission debit if cash (§4.12, FM24). |
| `rpc.confirm_fare(p_trip_id, p_outcome 'as_shown'|'different', p_paid_amount?)` | rider | One-tap default `as_shown`. `different` creates `fare_corrections`; Tier 3 trips always create one (FM33). |
| `rpc.rate_trip(p_trip_id, p_score, p_tags[], p_comment?)` | party | |
| `rpc.driver_manifest()` | driver | Active/accepted trips with rider display names + boarding stage (passenger manifest, Phase 3). |

### Realtime Broadcast `trip:{trip_id}` → **B**
Authorized via RLS on `realtime.messages` (topic must match a trip the caller is party to). Payloads: `{"type":"loc","actor":"driver"|"rider","lat","lng","heading","speed_mps","ts"}`, `{"type":"status","status","ts"}`, `{"type":"extension","extension_id","status"}`, `{"type":"na_me","triggered_by"}` (informational only; the trigger itself is local).

### Realtime Broadcast `driver:{driver_id}` → **B** (driver only)
`{"type":"trip_request","trip":TripView(pre-accept, includes load flag — FM35),"expires_at"}` plus FCM data push with the same payload for background wake.

---

## 6. Driver presence & routes

| Endpoint | Tier | Notes |
|---|---|---|
| `rpc.set_presence(p_status, p_location Point, p_heading?, p_seats_available, p_park_id?, p_declared_route_profile_id?, p_declared_route_leg_id?)` | I (own) | `offline` deletes the row (FM10). Requires `verified_status='verified'`, `driver_is_matchable()` (otherwise `LEDGER_BLOCKED` with balance + settle CTA), active vehicle. Returns `{session_id, status}`. |
| `rpc.presence_ping(p_location, p_heading, p_speed_mps, p_accuracy_m, p_seats_available?)` | I (own) | Rejects if no row (`STATE_INVALID`). Updates `nearest_stage_id`. Appends `driver_presence_history`. Interval enforced server-side (min 2 s). |
| `rpc.suggest_known_route()` | I (own) | Returns best canonical route match from `home_park_id` + presence history → `{route, stages:[{stage, default_price_to_end}]}` or `null`. |
| `rpc.snap_stage(p_lat, p_lng)` | A | `{stage_id, name, distance_m, route_ids[]} | null` within `cfg graph.snap_radius_m`. |
| `rpc.upsert_route_profile(p_profile jsonb)` | I (own) | `{id?, mode_code, name?, load_surcharge?, stops:[{sequence, route_stage_id?|location, custom_label?, price_to_end}]}`; validates non-increasing prices, last = 0; snaps unmatched stops (creates `candidate` stages with `source_type='driver_declared'`). Active immediately (§4.7 step 4). |
| `rpc.my_route_profiles()` / `rpc.deactivate_route_profile(id)` | I (own) | |
| `rpc.suggested_stop_price(p_profile_id, p_sequence, p_location)` | I (own) | Smart default: interpolation + nearby consensus (§4.7 step 3). |

---

## 7. Ledger, settlement, standing

| Endpoint | Tier | Notes |
|---|---|---|
| `rpc.driver_balance()` | I (own) | `{balance: Money, block_threshold: Money, standing, grace_deadline?, deposit_held: Money}` from `driver_balances` view. |
| `rpc.driver_ledger(p_cursor?, p_limit)` | I (own) | Entries with human labels resolved client-side from `entry_type`. |
| `POST /functions/v1/settlement/initiate` | I (own) | `{amount, channel: 'paystack_transfer'|'paystack_ussd'|'paystack_card'}` → `{settlement_id, authorization_url|ussd_code|bank_account, expires_at}`. |
| `rpc.create_agent_code(p_amount)` | I (own) | `{agent_code, expires_at}` (15 min). |
| `rpc.confirm_agent_settlement(p_agent_code, p_amount)` | agent | Agent must be active in driver's city; posts `digital_settlement_credit`; idempotent on code. |
| `POST /functions/v1/webhooks/paystack` | service | Verifies `x-paystack-signature` HMAC-SHA512 with secret; stores raw; on `charge.success` → `ledger_post` (settlement) or `payments.succeeded` (rider trip payment) idempotent on `reference`. Always 200 after signature check; retries safe. |
| `POST /functions/v1/payments/initiate` | B (rider) | Digital trip payment for `trips.payment_method='digital'`; creates a Paystack transaction with `split` to the driver's subaccount (driver share = fare − commission, Along = commission; ADR-0010). Returns authorization. Only offered when the driver has a subaccount; cash trips never call this (Phase 4 gate). |
| `rpc.set_payout_bank(p_bank_code, p_account_number)` | I (own driver) | Verifies account name via provider, creates the Paystack subaccount, stores the subaccount code (never the account number in plaintext beyond what the provider returns). Requires re-auth (OTP) — doc 12 T7. |
| `rpc.my_standing_history()` | I (own) | |

---

## 8. Safety

| Endpoint | Tier | Notes |
|---|---|---|
| `rpc.raise_sos(p_trip_id?, p_journey_id?, p_location, p_accuracy_m)` | own | Never rate-limited; minimal payload (≤ 300 B) for low-data; returns `{sos_id, emergency_number}`; triggers `notify` → safety on-call (push + SMS) per runbook. |
| `rpc.update_sos(p_sos_id, 'cancel')` | raiser | Hold-to-cancel; recorded as `false_alarm` by safety, not deleted. |
| `rpc.create_trip_share(p_journey_id, p_contact_name?, p_contact_phone?)` | own | Returns `{url: "https://along.ng/s/<token>", expires_at}`; token shown once. |
| `rpc.revoke_trip_share(p_share_id)` | own | |
| `rpc.shared_trip_view(p_token)` | anon (security definer) | `{rider_first_name, status, mode, vehicle:{plate,color}, driver_first_name, current_location (≤ 30 s old), destination_label, eta_s, legs_progress}` — only while journey active and token valid; nothing else. |
| `rpc.report_incident(p_trip_id?, p_type, p_description, p_attachment_paths[])` | own | |

---

## 9. Day planner

| Endpoint | Notes |
|---|---|
| `rpc.create_itinerary(p_stops [{sequence, destination_description, location?}], p_load?)` | |
| `rpc.update_itinerary_stops(p_itinerary_id, p_ops [{add|remove|reorder|edit}])` | |
| `rpc.itinerary_state(p_itinerary_id)` | Full plan with statuses and `prepared_plan` for the next pending stop. |
| `rpc.itinerary_match_next(p_itinerary_id)` | Runs `plan-trip` for the next pending stop from current location, stores `prepared_plan`; UI shows "Match now" (one tap) → `request_trip`. Copy rules FM23. |
| Edge job `itinerary-prepare` | When a stop's journey reaches `in_transit` with ETA ≤ 10 min, precomputes next stop's plan. |

---

## 10. Graph contributions

| Endpoint | Notes |
|---|---|
| `rpc.confirm_graph_value(p_target_type, p_target_id, p_value jsonb, p_trip_id?)` | Sets trust weight server-side; one per account per target; feeds promotion. |
| `rpc.submit_correction(p_trip_id, p_proposed_fare, p_target…)` | Called by `confirm_fare(different)`; also driver "fare changed" from route profile view. |
| `rpc.report_stage_here(p_trip_id, p_location, p_label?)` | "Not quite right, I'm actually here" → candidate stage (§4.5 lifecycle 1). |

---

## 11. Admin (Next.js) — all **I**, all audited

Tables are read via PostgREST under RLS with server-side filters. State changes only via RPC:

| RPC | Roles | Effect |
|---|---|---|
| `admin_approve_verification(p_verification_id, p_women_only_eligible?)` / `admin_reject_verification(id, reason)` | verifier, ops_lead | Sets doc status; when all required docs approved → `drivers.verified_status='verified'`, `tenure_started_at`. Human step is mandatory (§5.3). |
| `admin_review_fare_correction(id, 'approve'|'reject', note)` | ops_agent+ | Approve → writes `graph_confirmations` (admin weight) and may promote. |
| `admin_publish_graph_entity(p_type, p_payload)` / `admin_update_graph_entity` / `admin_deactivate_graph_entity` | ops_lead, ops_agent | All write `graph_revisions` + `data_sources(admin)`. |
| `admin_reconcile_field_entity(p_reconciliation_id, 'match'|'discrepant'|'resolve', p_resolution)` / `admin_publish_field_entity(id)` | ops_agent+ | Two-scout gate: publish requires `status='matched' or 'resolved'` → `field_verified`. |
| `admin_review_flag(p_flag_id, 'clear'|'action', note)` | safety, ops_lead | `action` opens a standing-transition dialog; never automatic. |
| `admin_transition_standing(p_driver_id, p_to, p_reason)` | ops_lead, finance | Validates ladder (doc 04 §12). |
| `admin_notify_guarantor(p_driver_id)` | ops_lead | Runbook step; notification only. |
| `admin_manual_ledger_adjustment(p_driver_id, p_amount, p_memo)` | finance | Requires memo; two-person rule for |amount| > `cfg ledger.dual_control_threshold`. |
| `admin_ack_sos(id)` / `admin_resolve_sos(id, status, note)` | safety | |
| `admin_triage_incident(id, status, assigned_to, severity)` | safety, ops_agent | |
| `admin_set_config(key, scope_type, scope_id, value)` | ops_lead, superadmin | Validated against a JSON schema per key. |
| `admin_review_candidate_park(id, 'promote'|'dismiss')` / `admin_review_route_inference(...)` / `admin_review_geometry_correction(...)` | ops_lead | |
| `admin_corridor_analytics(p_corridor_id, p_from, p_to)` | analyst+ | Paginated/bounded aggregates: searches, conversions (ambient→commit rate, §4.1.2 diagnostic), fulfilment, wait, fare-discrepancy rate. |

---

## 12. Scheduled jobs (pg_cron unless noted)

| Job | Schedule | Function | Notes |
|---|---|---|---|
| `expire_requests` | every 5 s (pg_cron `* * * * *` + loop) or Edge cron 1 s | `trips requested → expired` past `expires_at`; triggers dispatch cascade for roaming hails |
| `negotiation_expiry` | Edge `negotiation-clock` every 1 s | lapse open negotiations past `expires_at`; roaming radius check (FM38) |
| `presence_stale` | every 15 s | remove from ambient after `stale_after_s`; delete row after `offline_after_s` |
| `presence_retention` | hourly | downsample >24 h to 60 s; drop >30 d (cfg) |
| `promote_candidates` | every 10 min | doc 04 §6 |
| `decay_confidence` | daily 02:00 | doc 04 §6.4 |
| `compute_trust_weights` | daily 02:30 | riders.account_trust_weight |
| `reconcile_cancelled_trips` | every 15 min | doc 04 §13; flags only |
| `compute_risk_scores` | daily 03:00 | rolling 30-day |
| `apply_threshold_policy` | every 10 min | ledger-driven `warned/matching_paused` transitions (system actor), deposit drawdown after grace; never flag-driven |
| `cluster_candidate_parks` | daily 03:30 | `ST_ClusterDBSCAN` over `driver_presence_history` (doc 04 §14) |
| `ensure_partitions` | daily | next 2 monthly partitions for samples/history |
| `itinerary-prepare` | Edge, event-driven | §9 |
| `presence-fanout` | Edge, every 10 s | ambient cells → Broadcast |
| `jobs/map-match` | worker, hourly | completed trips → `matched_traces` (FM27) |
| `jobs/speed-profiles` | worker, nightly | `segment_speed_profiles` |
| `jobs/route-inference`, `jobs/geometry-corrections` | worker, weekly | candidates only |
| `jobs/anonymized-export` | worker, on demand (Phase 8) | k-anonymity ≥ `cfg export.k` (default 10) |

---

## 13. Storage buckets

| Bucket | Access | Path convention |
|---|---|---|
| `verification` (private) | owner write via signed upload URL; verifier read via signed URL (10 min) | `verification/{driver_id}/{document_type}/{uuid}.jpg` |
| `incidents` (private) | reporter write; safety read | `incidents/{profile_id}/{uuid}` |
| `avatars` (private, optional) | owner write; party-to-trip read via signed URL | |
| `tiles` (public CDN) | read-only | `tiles/{country}/{version}.pmtiles`, `styles/along-light.json`, sprites, glyphs |
