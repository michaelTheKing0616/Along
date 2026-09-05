# 10 — Testing Strategy & Gate-mapped Scenarios

Spec references: §6 (tests required), §7 (gates). Every `TS-*` below names the phase gate it proves; the Orchestrator lists the relevant IDs in each task's acceptance criteria and the Reviewer runs them.

## 1. Pyramid by layer

| Layer | Tool | Must cover |
|---|---|---|
| SQL functions & policies | pgTAP (`backend/db/tests`) | every function in doc 04 with seed fixtures; every RLS policy with `set role authenticated` + `request.jwt.claims` for rider/driver/admin roles; append-only triggers; state-machine illegal transitions |
| Edge Functions | Deno test + `msw`-style HTTP mocks for OSRM/Paystack/Termii | validation, tier labelling, ranking (pure TS), idempotency, webhook HMAC |
| Dart core | `test` | models, money formatting (₦ rounding to minor units), Na Me pairing, itinerary ordering |
| Design | golden tests | every component × state × text-scale 1.0/1.3 |
| Apps | widget + `patrol` | screen states; end-to-end flows on emulator against local stack |
| Admin | Vitest + Playwright | role guards, queues, dual control, audit rows |
| Load | k6 (`backend/load`) | budgets doc 01 §7 |
| Network | emulator `-netspeed edge/umts`, `tc netem` for admin | 3G/2G flows |
| Security | doc 12 checklist, `semgrep` ruleset, dependency audit | Phase 11 |

Determinism: fixed seeds, frozen clock (`set_config('along.now', …)` in SQL tests; `Clock` injection in Dart/TS), no sleeps in tests.

## 2. Seed fixtures (`backend/db/seed/seed_test_scenarios/`)
- `city_abuja_min.sql`: 2 corridors, 3 parks, 2 routes (keke, car) with 5 stages each, legs + 2 through-fares, transfer at park B.
- `city_zaria_test.sql`: fictional city with different config overrides.
- `drivers.sql`: 6 drivers: verified/good, verified/warned, verified/paused (balance −5,200), unverified, women-only eligible, deactivated.
- `riders.sql`: 5 riders with trust weights 0 (new), 0.3, 0.6, 1.0, plus 3 colluding accounts sharing a device fingerprint.
- `presence.sql`: parked at A (2), roaming toward dest (1), roaming away (1), stale (1).
- `traces/*.geojson`: driver/rider traces for reconciliation scenarios.

## 3. Scenarios

### Fare (Phase 1 gate)
- **TS-FARE-01** Tier 1: through-fare exists for (S1→S4) → amount = through-fare, tier 1, `unconfirmed=false`.
- **TS-FARE-02** Tier 2: no through-fare (S2→S4) → sum legs S2S3+S3S4, tier 2, confidence = min(legs).
- **TS-FARE-03** Mid-route boarding never full-route price: (S3→S5) < (S1→S5).
- **TS-FARE-04** Tier 3: unknown pair on candidate route → tier 3, `unconfirmed=true`, anchor within ±30% of distance model; `fare_quotes` row written.
- **TS-FARE-05** Tier 0: driver profile prices `[400,300,150,0]`, board stop 2 alight stop 4 → 300; board 4 alight 2 → error (direction).
- **TS-FARE-06** Load surcharge: profile surcharge 100 → component added; without profile surcharge → `load_surcharge_pending`.
- **TS-FARE-07** Currency: Zaria-Test city (different `commission.rate`) → commission uses city config (proves FM5).
- **TS-FARE-08** p95 `resolve_fare` ≤ 150 ms over 1,000 random pairs on the Abuja seed.

### Planner (Phase 2 gate)
- **TS-PLAN-01** Direct exists (parked at A, route to D) and multi-leg exists → both returned; `viable_direct` true; recommended[0] is the direct.
- **TS-PLAN-02** Direct 90 min vs multi-leg 20 min → direct `viable_direct=false`, multi-leg recommended first, direct still present.
- **TS-PLAN-03** Sort orders: cheapest by fare, fastest by time, least strenuous by score; ties broken as doc 04 §5.
- **TS-PLAN-04** Metrics present on every candidate; `explain` sums to `recommended_score` ± 1e-6.
- **TS-PLAN-05** OSRM down → response `degraded=true`, times from fallback, no error.
- **TS-PLAN-06** Coverage gap → zero candidates, `coverage_gap` with nearest stage and report row.
- **TS-PLAN-07** Women-only filter removes non-eligible live candidates; graph-only remain.
- **TS-PLAN-08** Load large + okada candidate → candidate kept with `load_warning`.
- **TS-PLAN-09** Candidate limit respected; p95 ≤ 800 ms on seed with 50 presence rows.
- **TS-PLAN-10** Roaming plausibility: heading toward → included; heading away → excluded; stationary → included.

### Disclosure (Phase 3/5 gates, FM21)
- **TS-DISC-01** `ambient_vehicles` output contains no uuid, plate, or coordinate not equal to a cell centroid (schema test).
- **TS-DISC-02** Rider cannot `select` from `driver_presence` (RLS) — expect 0 rows/permission error.
- **TS-DISC-03** `TripView` for a trip the caller isn't party to → `FORBIDDEN`.
- **TS-DISC-04** Realtime authz: rider joining `trip:{other}` rejected.
- **TS-DISC-05** `candidate_token` tampered → `CANDIDATE_EXPIRED`; expired → same.
- **TS-DISC-06** Dispatch cascade: rider never receives identity of a declining driver (event payload test).

### Trips & state machine (Phase 3)
- **TS-TRIP-01** Legal path requested→accepted→boarded→in_transit→completed writes 4 `trip_events`, sets timestamps.
- **TS-TRIP-02** Illegal transitions (completed→boarded, requested→in_transit) raise `STATE_INVALID`.
- **TS-TRIP-03** Direct `update trips set status` outside `trip_transition` is rejected by the guard trigger, even as superadmin.
- **TS-TRIP-04** Expiry job flips `requested` past `expires_at` to `expired`.
- **TS-TRIP-05** Auto-boarding: co-located 20 s with movement → `boarded (auto_colocation)`; co-located but both stationary → no transition; rider without samples → no auto.
- **TS-TRIP-06** Na Me pairing unique across a driver's concurrent trips and rider's; label localized.
- **TS-TRIP-07** Journey advances: 2-leg journey → `transfer` after trip 1, `completed` after trip 2.
- **TS-TRIP-08** Extension: propose +150 → accept → `alighting_*` updated; completion posts base + delta commission; declined extension bills nothing.
- **TS-TRIP-09** Load flag present in driver pre-accept payload; decline reason `no_room_for_load` accepted and excluded from risk metrics.

### Negotiation (Phase 3, FM31–38)
- **TS-NEG-01** Tier 1/2 pair → `open_negotiation` raises `STATE_INVALID`.
- **TS-NEG-02** Park: 4 rounds alternate; 5th counter rejected; split creates midpoint; accept → trip with tier 3 + `fare_corrections(pending)`.
- **TS-NEG-03** Roaming bands: eta 15 s → `none` (counter rejected); 45 s → `single`; 150 s → `full`.
- **TS-NEG-04** Roaming vehicle moves > pickup radius away → `lapsed` even mid-round.
- **TS-NEG-05** Timeout → `lapsed`; round rows immutable (delete rejected).
- **TS-NEG-06** Roaming driver with declared profile covering pair → negotiation refused (standard fare exists).

### Ledger & standing (Phase 4)
- **TS-LEDGER-01** Invariant: for every driver `sum(amount) = latest balance_after` (also nightly prod job).
- **TS-LEDGER-02** Cash completion posts exactly one `cash_commission_debit` = round(fare×rate); replay with same idempotency key returns same row.
- **TS-LEDGER-03** Digital trip completion posts no cash debit; webhook success posts `digital_settlement_credit`.
- **TS-LEDGER-04** Concurrency: 50 parallel posts for one driver → exact balance (advisory lock).
- **TS-LEDGER-05** Update/delete on ledger rejected for all roles.
- **TS-LEDGER-06** Threshold: balance −5,200 → `driver_is_matchable=false`; `request_trip` → `DRIVER_NOT_MATCHABLE`; `set_presence` → `LEDGER_BLOCKED`; planner excludes the driver; roaming hail excludes too (FM11).
- **TS-LEDGER-07** Policy job: −3,100 → `warned` (+notification); settle to −2,000 → `good_standing`; −5,200 → `matching_paused`; flags never transition standing (assert no transition after inserting 10 flags).
- **TS-LEDGER-08** Webhook: bad signature → 401 + raw stored with `signature_ok=false`, no ledger row; duplicate reference → single row.
- **TS-LEDGER-09** Agent settlement: valid code → credit; reused code → `IDEMPOTENT_REPLAY`; agent from another city → `FORBIDDEN`.
- **TS-LEDGER-10** Manual adjustment above dual-control threshold requires second approver (SQL-enforced).

### Integrity (Phase 4)
- **TS-INTEG-01** Driver trace reaches destination, rider trace reaches destination → flag score ≥ 0.8.
- **TS-INTEG-02** Driver reaches, no rider trace, no peers → score capped 0.5 → flag with `rider_trace_quality=none` (inconclusive band).
- **TS-INTEG-03** Driver diverts elsewhere → no flag.
- **TS-INTEG-04** Two peer riders corroborate → score includes corroboration term; `corroborating_rider_count=2`.
- **TS-INTEG-05** Undeclared extension: trace continues 600 m beyond alight with rider co-located → flag.
- **TS-INTEG-06** Flag review: `clear` updates status; `action` requires a standing transition id.

### Graph & promotion (Phase 6)
- **TS-GRAPH-01** 3 distinct trusted riders (w ≥ 1.0 total) agree within 15% → `crowd_verified`, revision written.
- **TS-GRAPH-02** 5 confirmations from one account → count 1, stays `candidate`.
- **TS-GRAPH-03** 3 colluding accounts (shared fingerprint) → down-weighted, stays candidate.
- **TS-GRAPH-04** Outlier (3×MAD) → excluded + review row.
- **TS-GRAPH-05** Decay: no confirmation for 91 days → confidence −0.15; below 0.5 → candidate.
- **TS-GRAPH-06** Driver route publish: snaps within 60 m; unmatched stop → candidate stage with `driver_declared` source; non-monotone prices rejected; active immediately.
- **TS-GRAPH-07** Two-scout: publish blocked when `awaiting_second`; allowed when `matched`/`resolved`; result `field_verified`.
- **TS-GRAPH-08** Clustering: fixture with 1 driver idling 10 days at home → no candidate; 5 drivers × 4 days → candidate cluster; nothing written to `route_stages` until admin promote.

### Presence (Phase 3)
- **TS-PRES-01** `set_presence(offline)` deletes the row; ambient count drops immediately.
- **TS-PRES-02** Stale > 45 s excluded from ambient; > 180 s row deleted.
- **TS-PRES-03** Unverified/blocked driver cannot go online.
- **TS-PRES-04** Ping < 2 s apart dropped silently; history appended for accepted pings.

### Design & UI (every UI task)
- **TS-DS-01** No literal colours/sizes outside `along_design` (grep gate).
- **TS-DS-02** ₦ glyph renders in Inter subset (golden).
- **TS-DS-03** Text scale 1.3× — no fare truncation on R-07/D-14/D-19 goldens.
- **TS-UI-01** One-tap table (doc 06 Part C) verified by patrol tap counts.
- **TS-UI-02** Offline: Na Me fires with airplane mode on (integration test using cached pairing).
- **TS-UI-03** Skeletons appear for > 300 ms waits (widget test with delayed mock).
- **TS-UI-04** Cash trip shows no payment UI unless the rider opens Pay; R-27 amount is locked when a trip/token is attached.
- **TS-UI-05** Driver blocked banner shows balance, threshold and Settle CTA (Phase 4 gate).
- **TS-UI-06** Tap budgets for payments (doc 06 Part C): app + matched trip + saved method = 1 tap after scan (patrol); W-04 = 2 taps before provider checkout (Playwright); `different_driver` warning blocks Pay until confirmed.

### QR & digital payments (Phase 4, doc 14)
- **TS-QR-01** `qr/resolve` known code → first name/plate/mode only; unknown code → 404 with the same response time class; inactive driver → `active=false`, no identity; 31st request/min/IP → 429.
- **TS-QR-02** Authenticated rider with an unpaid trip with this driver (≤ lookback) → `context.amount = fare_shown + load_surcharge + accepted extensions`, `locked=true`.
- **TS-QR-03** Rider's active trip is with another driver → `warning='different_driver'`; `initiate` without `confirm_other_driver=true` → `VALIDATION`.
- **TS-QR-04** Dynamic token: tampered HMAC or expired → `CANDIDATE_EXPIRED`; valid → amount locked to token; token for a trip of a different driver → `FORBIDDEN`.
- **TS-QR-05** `initiate` writes `driver_amount + commission_amount = amount` to the minor unit; commission rate from `trips.commission_rate` when attached, else city config; `fee_bearer` from config; driver without subaccount or `accepts_digital=false` → `STATE_INVALID`; amount < `min_digital_amount` → `VALIDATION`.
- **TS-QR-06** Webhook success on a completed cash trip that already has `cash_commission_debit` → `payment_method='digital'` and an offsetting `digital_settlement_credit` (`trip:{id}:digital_offset`); balance delta for the trip = 0; webhook replay → no second row.
- **TS-QR-07** Webhook success before completion → completion posts no `cash_commission_debit`.
- **TS-QR-08** Second `initiate` for an already-paid trip → `CONFLICT` with the existing `payment_id`; unique index blocks a second `succeeded` row.
- **TS-QR-09** Anonymous web payment → `payments(rider_id null, source='web_anonymous', channel='web')`; no ledger rows; driver receives `payment_received` Broadcast + push.
- **TS-QR-10** `rotate_driver_code` → old code resolves `404`, new code resolves; audit row; sticker request created.
- **TS-QR-11** `rider_payment_methods` view never exposes `authorization_code` (RLS test as rider); Edge charges a saved authorisation only for its owning rider.
- **TS-QR-12** Daily reconciliation: provider split settlement totals per subaccount equal `sum(driver_amount)` of succeeded payments for the day; mismatch → finance alert row.

### Config-not-code (all phases)
- **TS-CFG-01** Zaria-Test fixture: planner, fares, thresholds all use overrides; no code branch references a city slug (grep gate for `'abuja'`).
- **TS-CFG-02** Migrations alone (no seed applied): every key in doc 02 §2.3 resolves via `cfg()`; fresh `supabase db reset` exits 0; no `insert into app_config … do update` exists in any migration (ADR-0016).

### Ops (Phase 9)
- **TS-OPS-01** Restore drill: ledger invariant + row counts match.
- **TS-OPS-02** k6: 200 rps `plan-trip` mixed with 1,000 presence pings/s for 10 min within budgets.
- **TS-OPS-03** Realtime: 5,000 concurrent `trip:*` subscribers, message latency p95 ≤ 1 s.

## 4. Review checklist mapping
The Reviewer's per-task checklist = spec §6 checklist + the TS-IDs named in the task + doc 05/06 grep gates (`TS-DS-01`, string keys) + "no new dependency without ADR" (diff `pubspec.yaml`/`package.json`/`deno.json`).
