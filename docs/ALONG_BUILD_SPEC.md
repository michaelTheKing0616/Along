# ALONG — Full-Product Engineering Build Specification
### For execution by Cursor (or any AI coding agent), using an Orchestrator / Worker / Reviewer workflow

**Status:** Master build document. This is the single source of truth for scope, architecture, sequencing, and quality gates for building Along end-to-end — not just an MVP, but every phase through to a national-scale, multi-modal, asset-light transport platform.

**Companion document:** `Along_Business_Plan.docx` (product vision, market, business model, commission strategy, data-acquisition methodology). This spec assumes that document as context and does not repeat its market/business reasoning — it translates it into buildable software.

---

## 0. How to use this document

This document is written to be pasted into Cursor **once**, at the start of the project, exactly like a constitution. It is long by design — the point is that you should not need to re-explain vision, architecture, or quality bar ever again. From here on, you operate the three-role workflow in Section 2, and only ever paste **task-sized instructions**, not new vision.

If you are working solo (one person, one Cursor account), you still run all three roles — Orchestrator, Worker, Reviewer — but as **three distinct passes**, ideally in separate chat threads/sessions so each role stays uncontaminated by the others' context. If your Cursor plan supports background/parallel agents or multiple concurrent sessions, map each role onto a separate session directly. The discipline matters more than the tooling: never let the same context window that just wrote code also grade that code as "reviewed."

Do not skip the gates in Section 6 "to save time." Every failure mode documented in Section 8 of this spec is a failure mode precisely *because* someone skipped a gate under time pressure.

### 0.1 This is a critical, continuous build — operate at maximum sustainable velocity, never at reduced rigor

Along is being built as a top-priority, continuous campaign — phase after phase, without idle gaps waiting for "a good time" to continue. Concretely:

- The moment a phase's exit criterion is met (every task in it holding a Reviewer PASS), the Orchestrator issues the first task of the next phase immediately — there is no scheduled pause between phases.
- Where the phase plan's dependency structure genuinely allows it (e.g., backend schema work and mobile UI scaffolding within the same phase, once the API contract between them is settled), run independent task streams in parallel across separate Worker sessions rather than strictly one task at a time — the Orchestrator's job includes identifying which upcoming tasks have no dependency on each other and can proceed concurrently.
- **"Build excellently in the first go" is the reason for velocity, not a reason to trade it away against Section 6's gates.** A rushed task that fails Reviewer and needs rework costs more total time than the same task done right once — the gates in this document exist to make the *fastest* real path to a working product also the correct one, not to slow it down. Velocity comes from continuous operation and parallelization, never from skipping a Reviewer pass, weakening acceptance criteria, or treating a "PASS WITH NOTES" as good enough to move on without resolving the notes.
- See FM30 if this directive is ever misread as license to cut a corner.

---

## 1. Product Constitution (locked — do not renegotiate mid-build)

**What Along is:** A two-sided marketplace (rider app + driver app) that makes Nigeria's existing informal, multi-modal shared-transport network (shared taxis/"along," keke, okada, minibus) discoverable, routable, fairly priced, and safe — without owning any vehicles.

**Non-negotiable principles:**

1. **Asset-light, always.** Along never owns, leases, or dispatches its own fleet. Every vehicle belongs to an independent operator. No feature may assume Along-owned inventory of any kind.
2. **The along graph is the product.** The proprietary dataset of parks, routes, legs, modes, and fares (see Section 4) is the core asset. The app is a UI on top of it. Treat schema changes to this graph as architecturally significant, not routine.
3. **Multi-modal by default.** Every trip-planning feature must consider car/along-taxi, keke, okada, and minibus as first-class, independently-priced options — never hardcode a single-mode assumption.
4. **Fare transparency, not fare-setting.** Along surfaces the existing standard fare for a route/leg/mode; it does not invent surge pricing or platform-set fares. Any pricing feature must distinguish "platform commission" from "fare," and never blend them in a way that misleads the rider.
5. **Low-data, low-end-device first.** Every screen and API response must be designed for intermittent connectivity and low-end Android devices before being polished for high-end use. This is a product requirement, not a "nice to have," and applies to every phase.
6. **Cash-first payments.** Cash is the default; digital payment is additive, never required to use the app.
7. **Nationwide/multi-country scalability by architecture, not by rewrite.** Every corridor, city, state, and country must be a *data configuration*, not a code fork. If adding a new city requires touching application code rather than seeding new along-graph data, that is an architecture defect.
8. **Security and safety are launch-blocking, not polish-phase.** RLS, input validation, driver/vehicle verification, and SOS/trip-sharing are part of the MVP definition of done, not deferred to a later phase.
9. **Speed and minimal-interaction design for recurring, in-the-moment actions.** Along trips are fast, spontaneous, on-the-go decisions. Every recurring rider/driver action performed in the moment of an actual trip (search, accept/decline, status toggle, trip-state confirmation) must be reachable in one tap wherever the underlying decision is unambiguous, with defaults and auto-confirmation preferred over forms or confirmation dialogs — see Section 4.6. This does not relax the deliberately thorough one-time trust steps (driver/vehicle verification, onboarding) covered elsewhere in this spec; speed applies to the recurring trip-taking loop, not to trust-establishment.
10. **Build velocity comes from continuous, uninterrupted execution and correct-the-first-time work — never from weakening this document's gates.** This is a critical, top-priority build intended to be completed phase-by-phase without unnecessary idle time between phases (Section 0.1). Speed and rigor are not in tension here: skipping a gate to move faster produces rework, which is slower overall, not faster.

**Explicitly out of scope for the entire build (do not implement without a new, explicit decision from the human product owner):**
- Owning, leasing, or financing vehicles
- In-house payment processing (always via a licensed Nigerian payment aggregator/partner)
- Surge/dynamic pricing that raises fares above the standard along-graph fare
- Any feature that requires Along to hold funds beyond a pass-through wallet integrated with a licensed processor

---

## 2. Agent Architecture — Orchestrator / Worker / Reviewer

This is a role-based discipline layered on top of Cursor, designed to prevent the two most common AI-coding-agent failure modes: silent scope creep and self-graded work.

### 2.1 Roles

**ORCHESTRATOR**
- Owns the roadmap (Section 7) and the build ledger (Section 3).
- Breaks the current phase into single, reviewable tasks (never more than one cohesive unit of work — e.g., "implement the fare-verification endpoint," not "build the backend").
- Issues one task at a time to the Worker, with the acceptance criteria from this spec attached.
- Never writes production code itself.
- Reads the Reviewer's verdict and either (a) issues the next task, (b) sends the same task back to the Worker with the Reviewer's findings, or (c) escalates to the human product owner if a task reveals an architecture or scope question this spec doesn't answer.
- Updates the build ledger after every task, pass or fail.

**WORKER**
- Receives exactly one task from the Orchestrator, plus the relevant sections of this spec.
- Implements the task, writes the tests specified in the task's gate criteria, and runs them locally.
- Produces a **task report** (format in Section 2.3) — not just code, but a statement of what was built, what was tested, what was deliberately left out, and any assumption made.
- Does not review its own work as final — it self-tests, but the Reviewer's pass is the actual gate.
- Never expands scope beyond the assigned task. If the Worker believes the task is under-specified or reveals a bigger issue, it stops and reports back to the Orchestrator rather than improvising.

**REVIEWER**
- Receives the Worker's task report and diff, plus the original task and acceptance criteria — but *not* the Worker's own narrative framing as the basis for judgment; the Reviewer re-derives whether criteria are met from the code and tests directly.
- Runs the full gate checklist for the task (Section 6).
- Produces a **review verdict**: PASS, PASS WITH NOTES, or FAIL, with specific, itemized reasons tied to the acceptance criteria — never a vague "looks good."
- Is the only role permitted to authorize moving to the next task. A task with no Reviewer PASS is not done, regardless of how confident the Worker's report sounds.

### 2.2 The build ledger

Maintain a single file, `BUILD_LEDGER.md`, at the repo root, append-only. The Orchestrator is the only role that writes to it. Format per entry:

```
## [Phase X / Task Y] <short task title>
- Status: IN PROGRESS | PASS | FAIL | BLOCKED
- Assigned: <date>
- Worker report summary: <1-3 lines>
- Reviewer verdict: <PASS/FAIL + 1-3 line reasoning>
- Rework count: <n>
- Notes/escalations: <anything the human product owner needs to weigh in on>
```

This ledger is what lets you resume work in a fresh Cursor session weeks later without re-explaining anything — read the last 10-15 entries before issuing a new task.

### 2.3 Task report format (Worker → Reviewer/Orchestrator)

Every Worker task report must follow this structure, no exceptions:

```
TASK: <task as assigned>

FILES CHANGED:
- <path>: <what changed, one line>

WHAT WAS BUILT:
<2-5 sentences>

TESTS ADDED/RUN:
- <test name>: <what it verifies> — PASS/FAIL locally

ACCEPTANCE CRITERIA SELF-CHECK:
- [x]/[ ] <criterion from the task, copied verbatim> — <evidence>

ASSUMPTIONS MADE:
- <anything not explicitly specified that had to be decided>

EXPLICITLY NOT DONE (and why):
- <scope deliberately left for a later task>

OPEN QUESTIONS FOR ORCHESTRATOR:
- <anything genuinely ambiguous>
```

A Worker report missing any section is automatically sent back by the Reviewer without a substantive review — incomplete reporting is itself a gate failure.

### 2.4 Copy-paste role prompts

**Orchestrator session opener:**
```
You are the ORCHESTRATOR for the Along build. You have read ALONG_BUILD_SPEC.md and BUILD_LEDGER.md in full.
Your job: break the next incomplete item in the current phase (Section 7) into exactly one Worker-sized task,
with explicit acceptance criteria drawn from this spec's gate checklist (Section 6). Do not write code.
Output the task in a form ready to paste into a fresh Worker session, then stop and wait for the Worker's report.
```

**Worker session opener (paste per task):**
```
You are the WORKER for the Along build. You have read ALONG_BUILD_SPEC.md.
Here is your one task, assigned by the Orchestrator: <paste task + acceptance criteria>
Implement only this task. Write and run the tests specified in the acceptance criteria.
When done, output your Task Report in the exact format specified in Section 2.3 of the spec. Do not expand scope.
If anything is ambiguous, stop and list it under "Open Questions" rather than guessing.
```

**Reviewer session opener (paste per task):**
```
You are the REVIEWER for the Along build. You have read ALONG_BUILD_SPEC.md.
Here is the original task + acceptance criteria: <paste>
Here is the Worker's task report and diff: <paste>
Independently verify each acceptance criterion against the actual code and tests — do not take the Worker's
self-check at face value. Run/trace the tests yourself where possible. Check against the relevant gate
checklist in Section 6 (security, data-integrity, multi-modal, low-data, and phase-specific items).
Output a verdict: PASS / PASS WITH NOTES / FAIL, with itemized reasoning per criterion. Be specific about
what would need to change for a FAIL to become a PASS.
```

---

## 3. Repository Structure

```
along/
├── mobile-rider/          # Rider app (Flutter)
├── mobile-driver/         # Driver app (Flutter) — separate app from rider, shared packages where sensible
├── backend/
│   ├── db/                 # Schema, migrations, RLS policies
│   ├── functions/          # Edge functions / API layer
│   ├── routing/             # Self-hosted OSRM/Valhalla config + along-graph integration
│   └── jobs/                # Background jobs (graph ingestion, fare recomputation, etc.)
├── admin-console/          # Ops/admin web dashboard (Next.js)
├── data-collection/        # Field data-collection tooling and along-graph ingestion pipeline
├── shared/                  # Shared types/contracts between apps and backend (e.g., OpenAPI/schema)
├── docs/
│   ├── ALONG_BUILD_SPEC.md  # This document
│   ├── BUILD_LEDGER.md
│   ├── adr/                 # Architecture Decision Records — one file per significant decision
│   └── runbooks/            # Ops runbooks (incident response, SOS escalation, etc.)
└── README.md
```

**Rule:** no phase may introduce a new top-level directory without an ADR (`docs/adr/NNN-title.md`) explaining why. This keeps the Orchestrator from letting the Worker's structure drift phase over phase.

---

## 4. Core Data Model (reference — extend, do not fork)

This is the backbone of the along graph and the rest of the schema. Treat changes here as requiring an ADR.

**Core entities:**
- `parks` — id, name, geo point, city, state, country, verified boolean, source (field-collected / driver-submitted / rider-corrected), created/updated timestamps
- `routes` — id, origin_park_id, destination_park_id, mode (enum: car, keke, okada, minibus), is_direct boolean
- `route_stages` — id, route_id, sequence, geo point, name (optional — e.g. a named junction), is_official_park boolean (distinguishes a formal park from a recognized informal stopping point), verification_status (enum: field_verified, crowd_verified, candidate), confidence_score, independent_confirmation_count. A route is modeled as an ordered sequence of stages, not just its two endpoints — see Section 4.3 and Section 4.5.
- `route_legs` — id, route_id, from_stage_id, to_stage_id (must be sequentially adjacent stages on the route), mode, fare (this specific stage-hop's fare), fare_currency, fare_last_verified_at, frequency_estimate, operating_hours, avg_wait_time_estimate, boarding_walk_distance_m (walking distance from the previous point to this leg's boarding point), verification_status, confidence_score, independent_confirmation_count (see Section 4.5)
- `route_through_fares` — id, route_id, from_stage_id, to_stage_id (any pair on the route, not necessarily adjacent), mode, fare, fare_currency, fare_last_verified_at, source, verification_status, confidence_score, independent_confirmation_count. An optional override for a verified known price on a specific stage-pair that does not equal the sum of intermediate `route_legs` fares — see Section 4.3 and Section 4.5.
- `price_negotiations` — id, driver_id, rider_id, candidate_reference (route/leg or roaming-match context), anchor_amount, status (open/agreed/lapsed/declined), agreed_amount, expires_at, created_at. A bounded, pre-commit fare exchange for genuine Tier 3 gaps — see Section 4.3.1.
- `price_negotiation_rounds` — id, negotiation_id, round_number, proposed_by (rider/driver), amount, responded_at.
- `driver_route_profiles` — id, driver_id, route_id (nullable — set once/if the driver's stops are matched to a canonical route; a profile is fully usable before that match happens), mode, active, created_at, updated_at. A driver's own, self-authored route + price schedule — see Section 4.7.
- `driver_route_stops` — id, driver_route_profile_id, sequence, route_stage_id (nullable — snapped to an existing canonical stage if one is found within a small radius at setup time, else null until reconciled), custom_location (geo point, used until/unless snapped to a canonical stage), custom_label (optional, driver's own name for the stop before snapping), price_to_end, currency. See Section 4.7.
- `transfer_points` — park_id, connects route_ids — used by the multi-leg planner
- `mode_comfort_weights` — mode, comfort_score (config-driven, admin-editable — never hardcoded in application logic; see Section 4.2)
- `drivers` — id, verified_status, NIN reference (hashed/never raw-stored beyond verification need), license reference, vehicle_id, rating
- `vehicles` — id, mode, plate_number, verification_status, owner_id
- `riders` — id, account_age, trip_count, account_trust_weight (derived, used to weight crowdsourced confirmations per Section 4.5 — not a general-purpose reputation/social feature, scoped strictly to correction-trust weighting)
- `trips` — id, rider_id, driver_id (nullable if unmatched/self-reported), route_leg_ids (ordered array for multi-leg), boarding_stage_id, alighting_stage_id (the rider's actual boarding/alighting points, per leg where a trip spans more than one route — see Section 4.3), fare_shown, fare_reported_paid, status, started_at, ended_at, driver_live_path (geo trace, sourced from `driver_presence`), rider_live_path (geo trace, sourced independently from the rider's own device during the active trip), id_signal_color, id_signal_shape (assigned at match time, generated once and cached client-side — see Section 4.8)
- `fare_corrections` — id, route_leg_id or route_through_fare_id, submitted_by (driver/rider), proposed_fare, status (pending/approved/rejected), reviewed_by, reviewed_at
- `incidents` — id, trip_id, type, status, reported_by, reported_at, resolved_at
- `data_sources` — every along-graph record traceable to who/what created or last verified it, per the versioning requirement in the business plan's data-acquisition methodology
- `coverage_gap_reports` — id, rider_id, searched_location (geo point), searched_at, nearest_known_stage_id (nullable), nearest_known_stage_distance_m (nullable) — a logged record of a rider search with no usable along-graph coverage; see Section 4.9.
- `itineraries` — id, rider_id, status (enum: active, completed, abandoned), created_at
- `itinerary_stops` — id, itinerary_id, sequence, destination_description, destination_location (nullable — may be a named place resolved later), status (enum: pending, in_progress, completed, skipped), linked_trip_id (nullable — populated once this stage's trip is actually requested/matched). See Section 4.10.
- `driver_presence` — id, driver_id, vehicle_id, status (enum: offline, at_park, roaming_available, roaming_full), current_location (geo point, high-write-frequency), heading, declared_route_leg_id (nullable — a roaming driver may optionally declare the route/leg they're effectively running), nearest_stage_id (nullable — inferred or declared, used to resolve a real fare for roaming pickups per Section 4.3), seats_available, last_ping_at. This is an ephemeral, high-frequency-write presence stream, architecturally distinct from `trips.live_path` (which is per-trip and durable) — see Section 4.1 below.
- `driver_ledger_entries` — id, driver_id, trip_id (nullable — a deposit or manual adjustment may not tie to a trip), entry_type (enum: cash_commission_debit, digital_settlement_credit, onboarding_deposit, deposit_drawdown, manual_adjustment), amount, currency, balance_after, created_at, created_by (system/admin/agent-settlement). This is the append-only source of truth for a driver's outstanding commission balance — see Section 4.4.
- `guarantors` — id, driver_id, guarantor_type (enum: fellow_driver, vehicle_owner), guarantor_reference_id, acknowledged_at — see Section 4.4.4.

**Non-negotiable schema rules:**
- Every `route_leg` and `route_through_fare` must carry mode + verification metadata — never a bare number with no provenance.
- `city`/`state`/`country` must be first-class columns on `parks` from Phase 0 onward, even though the MVP only serves Abuja — this is what makes expansion a data operation, not a schema migration, per Constitution principle 7.
- No table may model a vehicle or driver as "owned by Along."
- `driver_presence` rows may only exist while a driver has actively opted into `at_park` or `roaming_available`/`roaming_full` status — there is no status representing continuous background tracking, and the row (or its live broadcast) is cleared immediately on going offline.
- `driver_ledger_entries` is append-only — a balance is always derived by summing entries, never stored and mutated directly, so it is fully auditable (this matters as much for dispute resolution with drivers as for fraud detection).

### 4.1 Live driver presence & roaming discovery

Not every along-registered driver operates from a fixed park — a meaningful share of real "along" and kabu-kabu activity happens on the move. Along supports two discovery modes, and both must be modeled distinctly:

- **Parked/at-park** — a driver stationed at a known park. This feeds the durable along-graph (`parks`, `route_legs`) described in Section 4 above, and is what the Phase 0/Phase 2 trip planner queries by default.
- **Roaming/on-route** — a driver actively driving, not stationed anywhere, broadcasting live position via `driver_presence` while opted into `roaming_available`. Nearby riders see these as live map pins, filtered by whether the driver's `heading`/`declared_route_leg_id` plausibly serves the rider's destination — never shown as raw undirected proximity, and never shown at all while `status = offline`.

**Rules specific to this feature:**
- Presence broadcast is strictly opt-in per session — a driver must actively set `roaming_available`; there is no default-on or passive tracking state, and this must be enforced server-side, not just hidden in the UI.
- A rider may hail a roaming vehicle directly from the live map; this creates a `trips` row in a `requested` state pending the driver's accept/decline, using the exact same accept/decline state machine as a parked-vehicle route option (Section 7, Phase 1) — do not build a second, divergent matching flow for roaming vehicles.
- Fare for a hailed roaming vehicle resolves via Section 4.3's tiered resolution logic, using `nearest_stage_id` (or `declared_route_leg_id`, if set) as the effective boarding point; if neither can be resolved to a known stage, the fare falls through to Section 4.3 Tier 3 and must be explicitly flagged in the UI as unconfirmed/to-be-agreed rather than silently defaulting to any number, and any post-trip fare paid still flows into the `fare_corrections` review pipeline like any other trip.
- `driver_presence.current_location` writes are high-frequency and should not be retained indefinitely at full resolution — define and document a retention/downsampling policy in the Phase 3 implementation (full resolution only needed live; anything older than the current session can be discarded or downsampled for analytics).

#### 4.1.1 What counts as an "in-app trip"

This must be a precise, checkable definition, not an assumption: **a trip is "in the app" from the moment a `trips` row is created**, which happens only via a one-tap commit action — a rider's request/hail, or a driver's accept of a rider's option — never merely from both parties being able to see that the other exists nearby. Every downstream mechanism in this spec that depends on "the trip entered the app" (commission accrual in Section 4.4, ranking metrics in Section 4.2, fraud detection in Section 4.4.2) is anchored to this definition. Section 4.1.2 exists specifically to protect this definition from being bypassed.

#### 4.1.2 The discovery-to-commitment boundary (preventing disintermediation)

The roaming-discovery feature above is valuable precisely because it shows riders and drivers real, live information about who's nearby — but that same information, if shown with full precision before either party has committed to anything, is exactly what a rider and driver need to coordinate a pickup entirely outside the app, generating real usage of Along's discovery layer with zero commission and no `trips` row ever created. The fix is not to detect and penalize this after the fact (Section 4.4.1 already establishes that nothing can force logging of a trip that never touches the app) — it is to make an uncommitted connection with precise, actionable information structurally impossible, the same way Uber and Bolt never show a specific nearby driver's exact position, plate, or identity until a request has been made.

**Two-tier disclosure, enforced server-side, applies symmetrically to both directions:**

- **Tier A — ambient view (no commitment, shown freely):** a rider sees that roughly N vehicles of a given mode are operating within a given radius, heading in a generally useful direction — enough to answer "is it worth waiting here" without providing enough to walk up and identify a specific car. No plate number, no precise live coordinate, no driver name/photo. Symmetrically, a driver sees aggregate/heatmap-style rider demand ("riders nearby are looking for trips toward X") — Section 4.5 of the business plan's "route and demand insights" feature — without a specific rider's precise location or identity.
- **Tier B — committed view (unlocked only by a `trips` row):** the instant a one-tap request/accept action creates a `trips` row (Section 4.1.1), the specific vehicle's precise live position, plate, mode, and driver identity become visible to that rider — and the specific rider's precise pickup location becomes visible to that driver. This is the same precision Sections 4.1 and 4.6 already assume exists for an active match; Section 4.1.2 clarifies that this precision is unavailable *before* that match exists, not just irrelevant before it.
- This boundary is enforced server-side (the ambient endpoint literally does not return plate/identity/precise-coordinate fields), not hidden client-side — a client-side-only restriction is not a real restriction.

**Why this doesn't fight the one-tap/speed principle — it reinforces it:** because Section 4.6 already makes the commit tap itself nearly free (single tap, optimistic UI, GPS auto-confirm on boarding), there is close to zero cost to using the real flow versus attempting to coordinate around it — the gating removes the *reward* for skipping the tap rather than adding friction to discourage it. This is a deliberate design choice: raise the cost of bypassing gently through what information withholds, not through added steps.

**Honest limits:** this closes the specific loophole where Along's own discovery feature hands over enough detail to disintermediate a *specific* signal it generated. It does not (and cannot) stop a driver from independently reverting to purely analog operation unprompted by anything Along showed them — that residual gap is the same one described in Section 4.4.1 and is addressed by incentives (Section 4.4.2 of the business plan), not by this mechanism.

**Diagnostic signal, not an automatic penalty:** the admin console (Phase 6) should track an ambient-view-to-commit conversion rate per corridor and per driver. A low rate is a signal worth ops attention — it may indicate attempted disintermediation, but it may just as easily indicate a UX problem causing drop-off, an ambient view that's too sparse to be useful, or ordinary browsing behavior. Route it to admin review, never to an automatic consequence, consistent with the review-not-auto-punish discipline established in Section 4.4.2/4.4.3.

### 4.2 Trip-option ranking model (cheapest / fastest / least strenuous)

#### 4.2.1 Direct-match-first search strategy

Before the ranking model below runs at all, the planner's *search* — not just its ranking — must be structured to never let an inferior multi-leg decomposition crowd out a genuinely available direct match. Concretely: if a driver is currently available (parked, roaming, or via an active `driver_route_profile`, Section 4.7) whose route or declared destination covers the rider's exact requested destination with zero transfers, that direct option must be found and included in the candidate set — it must never be silently omitted because the planner already found a valid multi-leg decomposition through an intermediate stage and stopped looking.

**Search staging (in order):**
1. **Direct-match search.** Query for any available driver — parked-at-park, roaming, or with a `driver_route_profile` — whose route covers origin-to-exact-destination directly. This must check all three source types; a driver's self-declared route (Section 4.7) covering the destination is exactly as valid a direct match as a canonical along-graph route, and must not be skipped because it's driver-specific rather than shared-graph data.
2. **Multi-leg decomposition search.** Runs regardless of whether Stage 1 found something — both searches always execute, never short-circuit each other — via Section 4's transfer-point decomposition.
3. **Merge and rank.** Both result sets feed the same ranking model (Section 4.2.2) together. A viable direct match is never held back from the rider to "simplify" the result set.

**Viability bound (a direct match is preferred, not blindly forced):** a direct option only earns priority treatment in the "Recommended" default when it is *viable* — within a configurable wait-time/detour bound of the best alternative, not merely technically existing. A direct driver 90 minutes away does not automatically outrank a 20-minute multi-leg option; the bound exists precisely to stop "technically direct" from meaning "actually worse." This threshold is admin-config, tunable per corridor, consistent with how other thresholds in this spec (Section 4.4.1's ledger threshold, Section 4.5.1's confirmation counts) are handled.

**Ranking rule:** within the viability bound, the "Recommended" default (Section 4.2.2) must never rank a multi-leg decomposition above a viable direct option to the same destination. This is a hard rule on the default, not a soft weighting nudge — `transfer_count` already factors into `strenuousness_score` as one input among several, which is not strong enough on its own to guarantee this outcome, so the direct-match-first rule sits above and constrains the general ranking formula rather than trusting the formula to reliably produce it. A rider who explicitly sorts by "cheapest" or "fastest" may still see the multi-leg option ranked first if it genuinely wins on that specific criterion — this rule governs the *default*, not every possible explicit sort.

**Applies identically inside the day planner (Section 4.10):** when chaining a stage's next leg, the same direct-match-first search must run — a day-planner stage should never insert an unnecessary transfer stop when a direct match to that stage's destination is genuinely available and viable.

#### 4.2.2 Ranking metrics

The trip planner must compute and attach a consistent set of metrics to **every** candidate route option it returns, so that ranking/filtering is a deterministic sort over real data — never a client-side guess or a planner-time collapse to one "best" answer.

**Required metrics per candidate option (single-leg or multi-leg):**
- `total_fare` — the resolved fare per Section 4.3's tiered resolution logic, summed across all legs (plus any unconfirmed-fare flag per Section 4.3 Tier 3 if a segment has no verified stage data)
- `total_time_estimate` — sum of in-vehicle time, `avg_wait_time_estimate` per leg, and inter-leg transfer time; never in-vehicle time alone
- `transfer_count` — number of mode/vehicle changes required
- `total_walking_distance_m` — sum of `boarding_walk_distance_m` across all legs, plus any walk to/from a roaming pickup point
- `strenuousness_score` — a computed score combining `transfer_count`, `total_walking_distance_m`, and each leg's `mode_comfort_weights` value; the exact weighting formula is an implementation detail to be tuned, but the inputs and their config-driven (not hardcoded) nature are not

**Rules:**
- The planner returns the full viable candidate set (bounded to a sane maximum, e.g., top N by each individual metric merged) with all metrics attached — ranking/filtering by cheapest/fastest/least-strenuous/recommended is a query/sort over this set, not a separate planner code path per criterion.
- `mode_comfort_weights` is admin-editable config (Section 4 data model), not a hardcoded ordering in application code — this keeps the ranking model mode-agnostic per Constitution principle 3, and lets ops tune it (e.g., if local rider feedback says keke is perceived as more strenuous than the default assumption).
- "Recommended" (the balanced default) must be an explicit, documented blend of the above metrics — not an unexplainable black-box score — since Phase 6 admin tooling and future tuning depend on being able to see why a given option ranked where it did.
- A rider-selected sort/filter criterion must be preserved across a single search session but must never silently persist as a global default without the rider explicitly saving it as a preference (Phase 2 MVP: session-only; saved default preference is explicitly a post-MVP feature per the business plan's Section 4.2).

### 4.3 Stage-based partial-route fare resolution

In practice, drivers on a fixed route commonly reduce the fare the further along the route a passenger boards, rather than charging a single flat origin-to-destination price. Modeling routes as atomic origin-to-destination fares (an earlier, simpler version of this schema) cannot represent this correctly and would either overcharge mid-route boarders or force every non-origin boarding into an unconfirmed-fare state. Routes are therefore modeled as an ordered sequence of `route_stages`, with fares resolved between whichever two stages a rider actually boards and alights at.

**Tier 0 — driver-declared price (checked first, before the standard resolution order below):** if the specific driver a rider is matched or hailing with has an active `driver_route_profile` (Section 4.7) covering both the boarding and alighting stops, that driver's own declared price governs, computed as `price_to_end(boarding stop) − price_to_end(alighting stop)`. A driver's own declared price for their own vehicle is the most authoritative fare available — it is literally what that driver intends to charge — and is used ahead of the shared/consensus graph below. Only when no covering `driver_route_profile` exists (an unmatched search, a driver who hasn't set one up, or a stop outside their declared route) does resolution fall through to Tiers 1-3.

**Resolution order for the shared/consensus along-graph (check in sequence, use the first that resolves):**
1. **Known through-fare** — query `route_through_fares` for a verified fare on this exact `(from_stage_id, to_stage_id)` pair. Used for common combinations that don't follow simple addition (a frequent real-world pattern where a well-known pair has its own established price rather than being priced as the sum of its parts).
2. **Summed stage-hops** — if no through-fare is recorded, sum the verified `route_legs` fares for each consecutive stage-hop between the boarding and alighting stage. This is the workhorse case and requires no additional data beyond what Section 5.2.1's field methodology already collects stage-by-stage.
3. **Proportional estimate, resolved via Along Pricing** — only if there is no verified stage or hop data covering the boarding point at all (e.g., a genuinely new or undocumented stop), the system proposes a distance/time-proportional estimate as an anchor and resolves the final fare through Along Pricing (Section 4.3.1) — a fast, bounded negotiation, not an open-ended one. The agreed fare feeds back into the `fare_corrections` pipeline (Section 4.5) so the gap closes over time.

**Rules:**
- This resolution logic is shared by the trip planner (Phase 2) and the roaming-driver discovery flow (Section 4.1) — a roaming driver whose live position resolves to a `nearest_stage_id` should get a real Tier 0/1/2 fare wherever possible, not default straight to Tier 3, since Tier 3 should be the exception, not the common case.
- The ranking model (Section 4.2)'s `total_fare` metric must always be computed from this resolution logic, never from a route's full origin-to-destination fare regardless of actual boarding point — a "cheapest" ranking built on the wrong fare is worse than no ranking at all, since it actively misleads the rider.
- Commission (Section 4.4) is always calculated as a percentage of the resolved fare from this section, never of the route's full listed fare — this matters directly for driver trust, since a driver who boarded a rider mid-route and is charged commission on the full-route fare has a legitimate grievance.
- Field data collection (Section 5.2.1 of the business plan) must capture fare at each intermediate stage, not only at a route's two endpoint parks, for Tier 2 to function from launch rather than defaulting most trips to Tier 3 — though Tier 0 (Section 4.7) and Section 4.5's crowdsourced promotion both reduce reliance on exhaustive upfront field collection over time.

#### 4.3.1 Along Pricing — fast, anchored fare negotiation for Tier 3

Researched directly against inDrive's own documented model, since it is the closest real-world precedent (used by 75-80% of trips on that platform in comparable emerging markets, per a January 2026 Oxford Economics study conducted with inDrive): a rider proposes a fare, drivers see it and accept, decline, or counter, and the rider picks from whatever offers arrive. That model is broadcast-and-wait by design — a rider posts a price and multiple strangers respond over some open-ended window before a choice is made. That fits a pre-planned ride booked before departure; it does not fit Along's context, where a rider is often standing at the roadside as a specific vehicle is already visible and passing by, with seconds, not minutes, to decide.

**Along Pricing is deliberately not a broadcast auction. It is a fast, anchored, one-on-one exchange attached to a single already-visible candidate — never a new mechanism layered on top of what this spec already builds, but a formalization of the "flagged, unconfirmed estimate both parties agree to" pattern referenced throughout Sections 4.1, 4.3, and 4.12.**

**What makes it faster than inDrive's model:**
- **Anchored, not blind.** inDrive's own flow already shows a suggested range before the rider guesses; Along's anchor is materially stronger, because Along actually has a structured along-graph most of the time. The Tier 3 proportional estimate (Section 4.3, item 3) is always shown first, prominently, as the starting reference — negotiation is framed as a small adjustment around a data-informed number, not a guess from nothing. This alone should converge faster than a blind-bid system, and reduces the range of implausible opening offers on both sides.
- **One-on-one, not broadcast-and-wait.** Pricing attaches to a specific candidate the rider or driver already sees — a specific roaming vehicle on the live map, or a specific park-based driver — reusing the two-tier disclosure boundary from Section 4.1.2 exactly as-is. There is no pool of strangers' offers to wait on and compare; if this specific negotiation doesn't land, the rider moves to the next candidate the planner already surfaced (Section 4.2), which is faster than waiting for more offers to trickle in.
- **Structured, one-tap controls, not free-text entry.** The UI is preset adjustment chips (e.g., "-100", "-50", "Accept", "+50", "+100" relative to the anchor) rather than a numeric keypad — faster to operate one-handed while a vehicle is slowing down, and consistent with Constitution principle 9 and Section 4.6's one-tap discipline.
- **Time-boxed, with a bounded round count.** Each round carries a short, visible countdown (configurable; short enough to match a vehicle actually passing by) and the exchange is capped at a small number of rounds. If the cap is reached without agreement, the system offers a single one-tap "split the difference" resolution rather than allowing indefinite back-and-forth. Either party can also simply let the countdown lapse and move on — nothing about Pricing may block or slow down the rest of the app while it's pending.
- **Self-improving, which inDrive's model structurally cannot be.** Every agreed Pricing outcome posts as a candidate fare data point into Section 4.5's crowdsourced promotion pipeline for that exact stage pair. Unlike inDrive — where each negotiation is a one-off, disconnected event with no underlying map to feed — enough Along Pricing agreements on the same under-covered stretch will, over time, promote that stretch out of Tier 3 into Tier 1/2, reducing how often negotiation is even needed on that route going forward. Negotiation here is a bridge to better data, not a permanent parallel system.

**Park-based vs. roaming vehicles are physically different negotiation contexts, and the round/timeout parameters must adapt accordingly rather than using one fixed setting for both:**

- **Park-based (the strong case).** A parked or at-park driver isn't moving and routinely waits for passengers anyway — bargaining before boarding is already the cultural norm at a park. The full multi-round exchange described above fits this context cleanly and should use the more generous end of the configured round-cap/timeout range.
- **Roaming vehicles (needs adaptation, not a straight port).** A moving vehicle will physically pass a rider's location within seconds if it doesn't stop — a multi-round exchange with a generic fixed timeout does not fit this reality, and either lets a negotiation persist after the vehicle is already gone or cuts off a negotiation that had more real time available. The fix uses data already collected for roaming discovery (Section 4.1): **derive the negotiation's time budget from the vehicle's actual live ETA to the rider's position, not a fixed constant.**
  - If the live ETA is below a configured minimum (the vehicle is already essentially at the rider's location), Pricing skips negotiation entirely and shows only the anchor estimate with a single accept-or-skip choice — there is no realistic time for back-and-forth, and pretending otherwise would be worse than not offering it.
  - If the ETA allows a short window, Pricing permits exactly one counter-offer round, not the full multi-round exchange.
  - If the vehicle is genuinely still some way off (a longer approach window), the fuller multi-round exchange from the bullets above is available, since there's real time for it.
  - **Safety valve:** regardless of remaining round or time budget, if the driver's live position moves beyond a configured reasonable-pickup radius from the rider before the negotiation resolves, it auto-lapses immediately — an "agreed" price for a vehicle that has already driven past is worse than no agreement at all. See FM37/FM38.
  - This applies only to a roaming vehicle with no declared route (Section 4.7) — a roaming vehicle running a declared route already resolves a transparent Tier 0 fare (Section 4.3) and never enters Pricing at all.
  - Nothing here formally requires a driver to slow down or wait during a negotiation; a driver retains exactly the same discretion to slow for a potential fare that already exists in the informal system today, at their own judgment about traffic conditions — Along adapts its own timing to that reality rather than instructing driving behavior.

**Data model:** `price_negotiations` — id, candidate_reference (driver_id, rider_id, route/leg or roaming-match context — attached before a `trips` row exists, per Section 4.1.1's definition, since negotiation is part of reaching the one-tap commit, not a separate post-commit state), anchor_amount (the Tier 3 proportional estimate), context (park/roaming — governs which round/timeout parameters apply), status (open/agreed/lapsed/declined), agreed_amount, expires_at (derived from live ETA for roaming, per the rules above), created_at; `price_negotiation_rounds` — id, negotiation_id, round_number, proposed_by (rider/driver), amount, responded_at.

**Rules:**
- Along Pricing must never appear on a trip with a resolved Tier 0, 1, or 2 fare — Constitution principle 4 (fare transparency, not fare-setting) governs those cases absolutely, and negotiation is scoped strictly to genuine Tier 3 gaps and the explicit mid-trip extension flow (Section 4.12), never offered as a general alternative to a known fare. See FM31.
- The final "lock in" action — either party accepting the other's last offer, or the split-the-difference resolution — is the same one-tap commit that creates the `trips` row (Section 4.1.1); Pricing does not introduce a new trip-lifecycle state, only a bounded pre-commit exchange.
- Round count and per-round timeout are admin-configurable, consistent with every other threshold in this spec, and for roaming vehicles must be derived from live ETA rather than fixed — see FM32/FM37.
- An agreed amount is always submitted to Section 4.5's `fare_corrections` pipeline as a candidate data point for that stage pair — never used once and discarded. See FM33.



### 4.4 Cash-commission enforcement

Cash is the default payment method (Constitution principle 6), which means most trips are not natively visible to Along at the moment of payment. This is architecturally significant, not a Phase 4 afterthought: the ledger and detection primitives below must exist before Phase 4 can be considered done, and the Worker/Reviewer roles should treat any shortcut here as a launch-blocking gap, not a nice-to-have.

**Strategic framing (read before implementing anything below):** no technical mechanism can force logging of a trip that never enters the app — that is a business/incentive problem (see the business plan, Section 10.4.2), not an engineering one. The engineering job is narrower and more tractable: (a) once a trip **is** in the app, make the commission owed unambiguous, auditable, and enforceable; and (b) detect the specific, documented pattern where a driver enters a trip in-app and then manipulates its status to avoid paying on it.

#### 4.4.1 The driver ledger (debt/balance model)

- Every cash trip's commission is written as a `cash_commission_debit` entry in `driver_ledger_entries` at trip completion — never collected synchronously, since the driver has already received the cash directly from the rider.
- A driver's current balance is always the sum of their ledger entries — never a mutable stored field — so it is fully reconstructable and auditable for dispute resolution.
- Digital-trip earnings and manual agent-settlements post as `digital_settlement_credit`/`deposit_drawdown` entries against the same ledger, per the same model used in principle by Uber and Bolt's published driver documentation (commission owed as a running balance, not point-of-sale collection).
- **Settlement channel:** a settlement service abstraction must support both self-service in-app payment (bank transfer/USSD/wallet, per Section 5.1's payment aggregator integration) and **agent-assisted settlement** (a driver pays cash to a POS/mobile-money agent, who confirms the ledger credit) — do not build only the app-based path, since cash-to-digital conversion friction is a real, documented adoption barrier in this market.
- **Threshold enforcement:** a driver whose negative balance exceeds a configurable threshold is blocked from receiving new trip matches (both park-based and roaming-hail) until settled or partially settled below the threshold — implemented as a check in the same matching path used by Phase 1/3, not a separate gate that can be bypassed by a different entry point.
- **Onboarding deposit:** an optional, configurable refundable deposit recorded as an `onboarding_deposit` entry, automatically drawn down (`deposit_drawdown`) if a grace period on an outstanding debt lapses.

#### 4.4.2 Detecting trip-status manipulation ("premature trip conversion")

A documented ride-hailing fraud pattern: a driver reaches pickup, negotiates a lower off-app price directly with the rider, then marks the trip cancelled in-app before actually completing it, to keep the trip invisible to the platform.

- **GPS/status reconciliation job:** any trip marked `cancelled` after a driver-rider match must be checked against **both** `driver_live_path` and `rider_live_path` — a "cancelled" trip whose trace(s) show continued movement consistent with completing the route (reaching within a defined radius of the destination, for a duration consistent with the route) is flagged for admin review, not auto-reversed (avoid false-positive punishment; a genuine cancellation can look similar in edge cases). This check must trigger on any cancellation after a `requested`/matched state, not only after an explicit `boarded` confirmation — a driver intent on avoiding detection will simply avoid ever confirming boarding, and the check must not have a loophole there.
- **Independent rider-side corroboration:** `rider_live_path` is sourced from the rider's own device, independently of anything the driver's app reports, using the same location access already granted for the rider's live map/ETA/safety features (Section 4.1/Phase 3) — no new permission scope, but the trace is stored and evaluated as a distinct signal the driver cannot influence. This is materially more reliable for this specific fraud type than driver-GPS-only detection, because the rider has no incentive to help a driver hide a real trip to avoid commission (unlike collusion-based fraud, where driver and rider jointly benefit from a fabricated trip).
- **Multi-rider corroboration:** because Along trips typically carry multiple simultaneous riders in one shared vehicle, a single driver's cancelled-trip claim can be checked against several independent riders' traces at once, not just one — a detection advantage single-passenger ride-hailing platforms structurally do not have. The reconciliation job should treat multi-rider agreement as a stronger signal than a single trace and surface the corroboration count to the admin reviewer.
- **Rider-side cross-check:** extend the existing post-trip fare-confirmation prompt (Phase 4) to also implicitly surface whether a "cancelled" trip actually occurred, from the rider's side — an independent signal the driver does not control.
- **Anomaly scoring:** a scheduled job computing each driver's cancel-after-match rate (especially cash trips), surfaced in the Phase 6 admin console as a sortable/filterable driver-risk view — not a black-box auto-suspension, since the ops team makes the final call per the escalation ladder in Section 4.4.3.
- **Degraded-signal handling:** `rider_live_path` is not guaranteed — riders on low-end devices, in battery-saver mode, or with location permission declined will have partial or no trace. The reconciliation job must treat a missing rider trace as inconclusive, not as evidence either way, and fall back to `driver_live_path` and anomaly scoring alone in that case (Constitution principle 5 — this is exactly the kind of low-end-device reality the low-data design principle exists for).
- This detects manipulation of trips that entered the app. It has no visibility into a trip that never touched the app at all — do not oversell this as solving cash leakage generally; it is one layer among several (see the business plan's Section 10.4 for the full strategy, including the incentive and community-leverage layers that matter more in aggregate).

#### 4.4.3 Escalation ladder

Implement as an explicit state machine on the driver record, not an ad hoc admin action: `good_standing` → `warned` (balance over threshold, grace period active) → `matching_paused` (grace period lapsed, new trip matching blocked) → `deactivated` (balance materially exceeds cap or repeated cycles) → `guarantor_referred` (Section 4.4.4). Every transition is logged with actor (system/admin) and reason, visible in the Phase 6 admin console.

#### 4.4.4 Guarantor model

- At onboarding, a driver may optionally (or, per a later business decision, mandatorily) register a guarantor — a fellow verified driver or the vehicle owner if the driver is not the owner — recorded in `guarantors`.
- On reaching `guarantor_referred` status, the guarantor is notified (in-app and/or SMS) per a defined runbook (`docs/runbooks/`) — this is a business-process integration point, not a payment-collection mechanism the app enforces automatically; do not build automatic deduction from a guarantor's own balance without an explicit, separate consent flow, since that is a materially different (and more legally sensitive) feature than a notification.

### 4.5 Confidence-based crowdsourced verification (reducing field-collection cost)

Section 5.2.1 of the business plan requires exhaustive paid field-mapping before a stage is trusted. That is the right way to seed a corridor's **backbone** (major parks and well-known transfer points), but requiring the same paid, redundant-scout process for every minor stage along every route is not cost-effective at scale, and directly conflicts with Constitution principle 9's speed requirement if every unmapped stage forces a slow, form-heavy "unconfirmed fare" flow. Along should instead promote most of the long tail of stages and stage-hop fares through **weighted crowdsourced confirmation**, reserving paid field agents for backbone seeding and periodic audits.

**Verification lifecycle for a `route_stage` / `route_leg` / `route_through_fare`:**
1. **`candidate`** — created the first time any rider or driver reports a boarding/alighting point or fare that isn't yet in the graph (e.g., via the one-tap "not quite right, I'm actually here" correction from Section 4.6). A candidate is usable immediately (Section 4.3 Tier 3, flagged unconfirmed) but does not affect ranking metrics as if it were reliable.
2. **`crowd_verified`** — promoted automatically once **independent_confirmation_count** reaches a configurable threshold (default: 3) from sufficiently trusted, distinct accounts (Section 4.5.1), with proposed values (fare, location) within a configurable tolerance of each other. This is the everyday path for the long tail of stages and unlocks Section 4.3 Tier 1/2 resolution for that stage/fare.
3. **`field_verified`** — the highest-trust tier, reserved for backbone stages seeded via Phase 0's paid, two-scout field methodology, or any `crowd_verified` record later spot-audited by ops. Not required for a stage/fare to be usable — `crowd_verified` is sufficient for normal operation — but weighted more heavily wherever confidence matters (e.g., resolving a conflict between two disagreeing `crowd_verified` proposals).

#### 4.5.1 Anti-gaming: trust-weighted confirmation, not majority vote

A naive "N confirmations promotes it" rule is gameable (e.g., a driver and a few low-activity accounts colluding to inflate a fare). Confirmations must be weighted, not simply counted:
- Each confirming account's contribution is weighted by `account_trust_weight` (riders, Section 4 data model) or driver `verified_status`/rating/tenure — a brand-new, never-active account's confirmation counts for materially less than an established one's.
- A proposed value that deviates sharply from nearby already-`crowd_verified` or `field_verified` stage-hop fares triggers extra scrutiny (held at `candidate` past the normal threshold, or routed to admin review) rather than being promoted on trust-weighted volume alone — an outlier is a signal, not just a vote to be outvoted.
- `crowd_verified` records are not permanent: a periodic re-validation job should decay confidence for stages/fares not reconfirmed within a configurable window (fares drift with fuel prices; informal stops shift), consistent with the living, versioned nature of the graph already required in Section 4 data model rules.

#### 4.5.2 Phase 0 scope implication

This changes what Phase 0 must deliver: exhaustive per-stage field mapping of every corridor stop is **no longer the target**. Phase 0 delivers backbone seeding (major parks, primary transfer points, and enough stage density to make Tier 1/2 resolution work for the most common trips on the pilot corridors) plus the confidence-based promotion pipeline itself — the long tail of minor stages is expected to reach `crowd_verified` through real usage in Phase 1/2, not through further paid field work. See the revised Phase 0 scope in Section 7.

#### 4.5.3 Inferring candidate parks from driver location clustering

A third source of candidate stages, alongside field agents and driver/rider corrections: `driver_presence` data (Section 4.1), already collected from opted-in drivers for the live map, can passively reveal parks nobody has explicitly declared. If multiple *distinct* drivers' live positions repeatedly cluster at the same location across multiple separate days, that location is very likely functioning as an informal park, whether or not anyone has told Along so directly. This requires no new data collection or permission — it is an inference job run over presence data already gathered for an unrelated purpose.

**Detection job (scheduled, not real-time):**
- Cluster recent `driver_presence` location pings spatially (a density-based clustering approach — e.g., DBSCAN or an equivalent classical algorithm — is appropriate here; this is deterministic statistical clustering, not a machine-learning model, consistent with Section 5.3's principle of using AI only where it is genuinely warranted).
- A cluster only qualifies as a candidate park if it meets **both** a distinct-driver-count threshold and a multi-day recurrence threshold (both admin-configurable, in keeping with every other threshold in this spec) — a handful of vehicles stopped at a red light or queued at a fuel station is not a park; the same several distinct drivers returning to the same spot across multiple separate days is.
- A qualifying cluster is written to `route_stages` as a `candidate` (Section 4.5's lifecycle applies identically from here — it is promoted to `crowd_verified` the same way any other candidate stage is, through independent trust-weighted confirmation, never auto-published purely from clustering).

**Gate/test requirement:** the detection job must be tested against an explicit false-positive scenario (e.g., a fuel station, mechanic's row, or checkpoint queue that produces a dense but non-recurring or single-purpose cluster) and correctly withhold candidate-park status until both thresholds are met — see FM26.

#### 4.5.4 Turning trip and presence traces into map and route intelligence

The same `driver_live_path`/`rider_live_path` traces already collected for live tracking and the co-location fraud check (Section 4.4.2), and the `driver_presence` breadcrumbs already collected for the live map (Section 4.1), are a substantial, already-available resource for improving the map and routing layer itself — not just the along-graph's parks and fares. This is a natural extension of the "reuse existing data, no new permission" discipline established in Section 4.5.3, applied to three further outputs.

**Required preprocessing — map-matching, always first:** raw GPS traces are noisy and must never be used directly for geometry or route inference. Every trace is map-matched to the underlying road graph before any downstream use — OSRM's built-in Match service (or an equivalent Hidden-Markov-Model-based map matcher) is the appropriate tool, reusing infrastructure already in the stack (Section 5.1) rather than building a new matching algorithm. See FM27.

**Three outputs built on matched traces:**

1. **Road-geometry correction.** Where a statistically significant number of independent matched traces consistently diverge from the base OSM road geometry (a road extended, realigned, or never digitized), that divergence is a correction candidate. It feeds an internal supplementary road-segment layer for Along's own routing immediately, and — as a mature-phase, explicitly human-reviewed activity, never an automated submission — can be contributed back to OpenStreetMap itself, benefiting the wider map and Along's own long-term routing quality alike. See FM29.
2. **Route/corridor inference.** The linear counterpart to Section 4.5.3's point-based park clustering: where many independent trips consistently traverse the same corridor with a similar origin/destination pattern, that pattern is evidence of an informal route running there, even before any driver has explicitly declared it via Section 4.4's self-service setup. A qualifying pattern is written to the along-graph as a `candidate` route/stage sequence, subject to the exact same promotion lifecycle as any other candidate (Section 4.5) — this is a new *source* of candidates, not a new trust tier.
3. **Segment speed-profile calibration.** Aggregated, time-of-day-bucketed travel times per road segment, derived from matched traces, calibrate the routing engine's cost function with real local conditions instead of generic default speeds — directly improving the accuracy of `total_time_estimate` (Section 4.2.2) and every ETA the app shows. This is a *historical baseline* data product, distinct from but complementary to Section 5.3's *live/current-conditions* traffic layer — the two should be combined at query time (baseline expectation adjusted by current conditions), not conflated into one system.

**Rules:**
- No new location permission or tracking scope is introduced for this capability — it operates entirely on data already collected under Section 4.1 (presence) and Section 4 (trip traces) for their original purposes.
- Road-geometry corrections and route-inference candidates are reviewed before being treated as reliable, exactly like every other crowdsourced input in this spec — no automated publication, and no automated submission to OpenStreetMap.
- This capability is genuinely valuable once real trip volume exists (meaningfully more so from Phase 7's multi-corridor scale onward) and is not MVP-critical — see the Phase 7 deliverable note.

### 4.6 Interaction latency & one-tap design requirements

Along trips are fast, spontaneous, on-the-go decisions — a rider deciding whether to board a passing shared taxi, or a driver deciding whether to accept a hail, has seconds, not minutes. Constitution principle 9 makes this a first-class, launch-blocking product requirement, not a polish-phase concern, and it applies specifically to **recurring, in-the-moment actions** — it does not relax the deliberately thorough one-time trust steps (driver/vehicle verification, onboarding) covered elsewhere in this spec.

**Actions that must be reachable in a single tap, with no intermediate form or confirmation dialog, wherever the underlying decision is unambiguous:**
- Rider: viewing nearby options (parked + roaming) on opening the app, with destination search as a secondary refinement, not a blocking first step
- Rider: accept / decline / request-alternative on any presented route or roaming-vehicle option
- Rider: default post-trip close-out ("yes, that fare/trip was correct") as the fast path, with detailed dispute/correction as an optional deeper flow reached only if something was actually wrong
- Driver: status toggle between offline / at-park / roaming-available / roaming-full
- Driver: accept / decline an incoming trip request

**Auto-confirmed state transitions using existing infrastructure, to remove taps entirely where possible:** when a matched rider's and driver's live traces (`rider_live_path`/`driver_live_path`, Section 4.4.2) converge within a configurable radius for a sustained short duration, the trip should auto-transition to `boarded` without requiring either party to tap a confirmation — with a manual tap available as a fallback/override, not the primary path. This reuses the co-location infrastructure built for fraud detection for a second purpose (removing a required tap during a moment when a driver should not be handling their phone), and strengthens rather than weakens Section 4.4.2's detection value, since an auto-confirmed boarding is itself a strong, independently-derived signal.

**Performance budgets (apply from Phase 1 onward, not deferred to the Phase 11 audit):**
- Trip-search and fare-resolution endpoints: target p95 response time low enough that a tap-to-result feels instantaneous on a typical low-end Android device over a 3G-equivalent connection — this must be defined as a concrete number (e.g., a specific millisecond target) and load-tested per Phase 7, not left as a vague aspiration.
- Accept/decline/status-toggle actions: optimistic UI update on tap (immediate visual feedback) with server confirmation reconciled asynchronously — the rider/driver should never be staring at a spinner for a one-tap action.
- Any flow requiring more than one tap for a recurring action (Section 4.6 list above) is treated as a design defect to be justified explicitly in the task report, not a default.

### 4.7 Driver self-service route & fare setup

Rather than routes being seeded only by field agents or built up slowly through crowdsourced correction, a driver can directly author their own route and per-stop pricing — the most authoritative source available, since it is literally what that driver intends to charge — through a setup flow designed around Constitution principle 9 (one-tap/minimal-friction) as strictly as any rider-facing flow.

**Data model:** covered in Section 4 (`driver_route_profiles`, `driver_route_stops`). Each stop carries a single `price_to_end` value — the price from that stop to the end of the driver's declared route — mirroring how drivers already think about pricing in practice ("after this junction, it's ₦300 to town"), rather than requiring the driver to price every possible stop-to-stop pair explicitly. Fare between any two of a driver's declared stops is `price_to_end(boarding) − price_to_end(alighting)` (Section 4.3, Tier 0).

**Setup flow (target: under a minute for a new route, one tap for an already-known one):**
1. **Fast path — known route:** if the driver's declared park/corridor already matches an existing canonical `route` (via their park registration or `driver_presence` history), the setup flow opens with that route pre-drawn and asks a single yes/no: "Is this your route?" — a one-tap confirm is enough to activate a working `driver_route_profile` using the canonical stages, with default prices pre-filled from the existing consensus `route_legs`/`route_through_fares` data (Section 4.3, Tiers 1-2) as smart defaults the driver can then adjust.
2. **Manual path — new/undocumented route:** the driver draws their route by tapping stops directly on a full-screen map (or searching an address per stop), scrolling and tapping as they go. Each tap either snaps to an existing nearby `route_stage` within a small radius — surfaced as a single-tap confirm chip, "Use existing stop: `<name>`?" — or drops a new candidate stop pin if nothing nearby matches.
3. **Pricing each stop:** a large, thumb-friendly numeric entry pre-populated with a smart default (interpolated from the previous stop's price and known nearby fare data where available) so confirming a sensible guess is normally a single tap, with typing a different number as the fallback — the same "confirm-the-best-guess, tap-to-adjust" pattern already used for post-trip fare confirmation (Section 4.6), applied here for consistency rather than inventing a new interaction pattern.
4. **Publish:** a single "Publish route" tap. No separate review or submission screen — the route is immediately live and usable (Tier 0 authoritative for this driver), consistent with driver-declared prices needing no crowdsourced corroboration to take effect (Section 4.5's promotion pipeline governs *shared/consensus* graph data, not an individual driver's own declared price).
5. **Editing:** the same map view, always — drag a stop to adjust its location, tap its price chip to change the fare, tap a stop to remove it. Never a separate multi-page settings flow for what is fundamentally the same map-and-price-list view as setup.

**Rules:**
- Snapping to existing canonical stages (rather than always creating new driver-specific ones) is required, not optional — without it, many drivers running the same physical route would fragment the graph into near-duplicate stops, undermining the shared along-graph's value (Constitution principle 2). A genuinely new/unmatched stop still becomes a `candidate` per Section 4.5's lifecycle, open to promotion into the shared graph over time.
- A driver's own declared price is authoritative for trips matched to that driver without requiring crowdsourced confirmation first (Section 4.5 governs promotion of *shared* data, not an individual's own pricing) — but the existing post-trip fare-confirmation flow and commission-integrity anomaly review (Section 4.4.2) remain the safety net against a driver publishing a misleadingly low price to attract bookings and then attempting to charge more in person; repeated rider-flagged mismatches against a specific `driver_route_profile` route through the same review path as any other fraud signal, not a new mechanism.
- Multiple drivers' declared prices for the same canonical stage-hop are a natural, valuable input to the shared/consensus `route_legs`/`route_through_fares` data (e.g., a median across active drivers can inform or refine the consensus fare) — this is a one-way enrichment of the shared graph from driver setups, not a requirement that drivers agree with each other before publishing their own price.

### 4.8 On-the-road mutual identification ("Na Me")

Road-level confusion — several people converging on one vehicle, a rider unsure which of several similar cars is theirs, a driver unsure which waiting person is the one who actually booked through the app — is a real, physical-world failure mode a purely digital match cannot resolve on its own. "Na Me" is a low-tech-first, offline-capable identification signal both matched parties can trigger to resolve it instantly and visually, with no argument required.

**Design:**
- At match time (the moment a `trips` row is created, Section 4.1.1), the server assigns a random `id_signal_color` and `id_signal_shape` pairing (e.g., a color plus a simple geometric shape) and pushes it to both the rider's and driver's devices immediately, where it is cached locally. Generation and delivery happen once, while both devices are online at match time — not at the moment of use.
- Both parties see this pairing persistently on their active-trip screen (e.g., "Look for: Green Diamond") from the moment of match, so it is often enough on its own without ever needing to press anything further.
- A single, prominent "Na Me" button escalates it: the pressing device's screen strobes the assigned color at a fast, highly visible interval, the device vibrates in a matching pattern, and — on devices that support it — plays a short audio chime or spoken announcement and/or strobes the camera flash/torch for visibility in low light or from a distance. The matched party's screen simultaneously surfaces a directional indicator toward the strobing device, built on the same live GPS co-location data already established in Section 4.1.1/4.4.2, not a separate positioning mechanism.
- **The action of pressing "Na Me" requires no network call.** Because the identification pairing was already delivered and cached at match time, triggering it is a pure local-device action (screen, vibration motor, optionally torch/audio) — this is a deliberate design choice, since road-level confusion is exactly the kind of moment likely to coincide with poor connectivity, and a safety-adjacent feature that depends on a live network round-trip at the moment it's needed is a fragile one.
- **Device-tier graceful degradation, by design, not as a fallback bolted on later:** the core mechanic (color/shape code, screen strobe, vibration) requires only a screen and a vibration motor — present on virtually any smartphone Along will realistically encounter in this market. Audio and torch-flash are progressive enhancements layered on top for capable devices, never load-bearing for the feature to function.
- This directly resolves the dispute case it's named for: if two people near a vehicle both claim to have booked it, the driver's app is already showing the correct pairing for their actual matched rider — asking both people to trigger "Na Me" (or simply checking whose phone shows the matching color/shape) resolves the ambiguity visually, without an argument.
- "Na Me" is a companion to, not a replacement for, the GPS co-location/auto-boarding-confirmation mechanism (Section 4.1.1/4.4.2) and the broader Phase 5 safety feature set — it solves the narrower, physical "which person/vehicle is which" problem those mechanisms don't address on their own.

### 4.9 Serving areas outside Phase 0's field-mapped coverage

Phase 0 seeds a deliberately small backbone (Section 4.5.2) — most of Nigeria, let alone the eventual pan-African footprint (business plan Section 8), will never be reached by paid field agents directly. Coverage in an unmapped area comes from mechanisms already established elsewhere in this spec, applied together, plus two small additions specific to the cold-start case:

**Already-established mechanisms that do most of the work:**
- **Driver self-service route setup (Section 4.7)** is the primary answer: any verified driver, anywhere, including well outside any field-mapped corridor, can declare their own route and stop pricing directly. This is not limited to pre-selected corridors — a driver in an entirely unmapped city can set up a working route on day one of Along being installed there, immediately creating real, driver-authoritative (Tier 0, Section 4.3) along-graph data for that area.
- **Live roaming presence (Section 4.1)** provides value even before any structured route exists for an area: a rider searching an unmapped location can still see the ambient signal (Section 4.1.2, Tier A) that vehicles are operating nearby, even if Along cannot yet offer a structured route/fare answer — genuinely useful ("it's worth waiting here") even in the absence of graph data.
- **Confidence-based crowdsourced promotion (Section 4.5)** means any candidate stage or fare created in a new area — whether from a driver's self-service setup or a rider's post-trip correction — accumulates trust and detail through ordinary use, the same way it does in an originally-seeded corridor.

**Two additions specific to genuinely cold-start areas:**
- **Coverage-gap logging:** when a rider searches a location with no usable route data and no nearby driver presence to even offer an ambient signal, the search is logged to `coverage_gap_reports` rather than simply failing silently. This turns unmapped-area demand into a concrete, prioritizable signal for expansion planning (feeding directly into the Phase 7/9 corridor-onboarding and multi-city playbooks) and, at a local level, into targeted driver-recruitment outreach in that area.
- **Graceful fallback UX, never a dead end:** a search with no coverage at the exact requested location should still surface the nearest known stage or corridor edge within a reasonable walking distance, with directions to it (Section 4.11), rather than an empty result. "Nothing here yet, but here's the nearest place Along can help from" is materially better than a blank screen, and costs nothing extra to compute once `coverage_gap_reports.nearest_known_stage_id` is being tracked anyway.

**What this deliberately does not include:** a general-purpose "any rider can add a stop they merely know about, without having taken a trip there" contribution path was considered and set aside for now — it would extend Section 4.5's crowdsourcing further than driver setups and post-trip corrections already do, and needs its own anti-spam/trust calibration (an unbounded, trip-independent submission path is a materially larger gaming surface than corrections tied to an actual completed trip). Worth revisiting once Section 4.5's promotion pipeline has real operating data to calibrate against, not before.

### 4.10 Day planner — chained, multi-stage itineraries

Section 4.2's trip planner already decomposes *one* destination search into multiple legs and modes. The day planner is a layer above that: a rider enters some or all of a day's stops up front (e.g., drop a child at school, go to work, run an errand, go home), and Along manages the transitions between them, so the rider's own moment-to-moment effort collapses toward "tap to confirm" at each stage rather than re-deciding and re-searching from scratch every time.

**What this is not:** a reservation system that guarantees a specific driver hours in advance. Along's supply is live and on-demand by nature (Constitution principles 1 and 9), not a scheduled resource pool — the day planner eliminates the rider's *coordination and decision* burden at each transition, it does not (and should not claim to) eliminate the fundamentally real-time nature of matching itself. Overpromising "your 3pm ride is booked" when what's actually true is "Along will start matching you the moment you're ready to leave" would damage trust the first time real-world availability doesn't cooperate.

**Design:**
- An `itinerary` groups an ordered sequence of `itinerary_stops`, each eventually linked to its own `trips` row once that stage is actually requested/matched (Section 4 data model) — the day planner is an orchestration layer over existing trip-booking primitives, not a new booking mechanism, and must reuse Section 4.2's ranking/planning and Section 4.6's one-tap commit flow rather than duplicating them.
- Stops can be entered all at once at the start of the day or added incrementally as the day unfolds — both are first-class, not a "simple mode vs. power mode" split.
- Matching for a given stage is initiated at the real-time-appropriate moment — when the rider completes (or is nearing completion of) the previous stage — not pre-committed hours ahead; the planner's job before that moment is to have the plan ready, not to have already booked it.
- On completing a stage, Along proactively surfaces the next stage's best option (already computed, ready to show) with a single confirm tap to initiate matching — reusing Section 4.6's accept/decline pattern exactly, not a new interaction to learn.
- A persistent "today's plan" view shows the full sequence, the current stage highlighted, and the next stage previewed — always one tap away from editing, reordering, or cancelling a remaining stage, since plans change and the rider must never feel locked in.
- The stress this feature is explicitly designed to remove is decision fatigue and uncertainty at each transition (where do I go next, how long will I wait, is anything even coming) — not the live, on-demand nature of the underlying trips, which stays exactly as real-time as everywhere else in the product.

### 4.11 Multi-modal wayfinding guidance (text / map / audio)

Getting to a boarding point — especially a park-based one that requires walking, as opposed to a roaming vehicle coming to the rider — deserves the same care as the trip itself, and should be available in whichever presentation mode actually suits the rider's device and situation, not a single fixed format:
- **Text** — a simple turn-by-turn list. Works on any device, costs almost no data, and is the required baseline every device must support.
- **Map** — the visual route line and pin on the existing vector-tile map (Section 5.2.4), for devices and moments where glancing at a map is the fastest way to orient.
- **Audio** — spoken turn-by-turn cues, opt-in, for devices that support it and moments where looking at a screen isn't practical (hands full, moving quickly to catch a shared vehicle, or simply a rider's own preference) — this is also a meaningful accessibility benefit for riders who find visual navigation harder to use, achieved as a natural extension of this feature rather than a separate accessibility-specific build.
- The mode is a persistent, fast-to-change preference set once (in profile/settings) rather than a per-trip choice — asking "which mode do you want?" on every single walk to a park would itself violate the one-tap/speed principle (Section 4.6) this entire spec is built around.
- This guidance system is shared infrastructure: it serves ordinary walking directions to a boarding point (Section 4.1), the "nearest known stage" fallback in an unmapped area (Section 4.9), and every transition in the day planner (Section 4.10) — implement it once, reuse everywhere, rather than building park-finding directions separately in each of those three contexts.

### 4.12 Mid-trip destination extensions

A rider books a trip to one destination; partway there, the driver offers — for an increased price — to take them further. Left unhandled, this is a natural opening for the extended portion to be negotiated and paid by word of mouth, invisible to Along even though the trip started in the app. The design deliberately reuses existing machinery rather than introducing a parallel fare or commission system for this case.

**Data model:** `trip_extensions` — id, trip_id, previous_alighting_stage_id, new_alighting_stage_id (or a raw location if the new destination isn't yet a known stage), proposed_by (driver/rider), status (proposed/accepted/declined), fare_delta, proposed_at, accepted_at. Append-only, mirroring the audit discipline already established for `driver_ledger_entries` (Section 4 data model rules) — a trip's fare/commission history must be reconstructable, not just its current value.

**Flow:**
- Either party proposes a new, further destination mid-trip via a single tap (Section 4.6's one-tap discipline applies here as much as anywhere else) — no form, just a map tap or a short list of plausible extensions along the current route.
- The fare delta is computed by the exact same Section 4.3 tiered resolution logic already used for the original trip, simply re-run against the new alighting point — this requires no new pricing logic, only a mechanism to capture the changed endpoint.
- The other party accepts or declines with a single tap, mirroring the existing accept/decline state machine (Phase 1) rather than a new one.
- On acceptance, `trips.alighting_stage_id` updates, a `trip_extensions` row records the change with its fare delta, and a corresponding `driver_ledger_entries` debit is posted for the incremental commission (Section 4.4.1) — the extension is not a separate trip, it is an amendment to the existing one, and commission accrues on it exactly as it would have on the original fare.
- **Why this should get used rather than negotiated around:** using the in-app flow is faster and more transparent than negotiating a price on the roadside (a fair, pre-calculated fare beats haggling), and it keeps the rider's live-tracking, trip-sharing, and SOS coverage (Phase 5) extended to the new destination automatically — tapping accept is strictly better for both parties than going around it, consistent with the carrot-over-friction philosophy established in Section 4.4.2 of the business plan.

**Detecting an undeclared extension:** the same GPS reconciliation job from Section 4.4.2 extends naturally to this case — a completed trip whose recorded `alighting_stage_id` falls well short of where the rider's independent `rider_live_path` trace actually ends is a detectable mismatch, surfaced to admin review alongside the existing cancellation-pattern checks, never an automatic penalty (Section 4.4.2's false-positive caution applies identically here — GPS imprecision or a legitimate reason for continued movement, like the rider running a separate errand on foot after alighting, must not be treated as proven evasion).

**Honest limit:** exactly as with Section 4.4.1's core constraint, a rider and driver who agree to an extension entirely by word of mouth, with no app interaction at all, cannot be technically prevented from doing so — this mechanism works by making the in-app path clearly the easier, better option, and by detecting the gap afterward, not by making the workaround impossible.

### 4.13 Flagging load — luggage that needs boot space or special handling

A common real-world scenario in shared informal transport: a rider has luggage or goods ("load") too large for the passenger cabin, needing boot/trunk space or other accommodation a given vehicle may or may not have. Left unhandled, this becomes an on-the-spot surprise and refusal after a rider has already committed to a specific vehicle — exactly the kind of friction Along's speed-first design should prevent rather than create.

**Design:**
- At request time, a rider can flag load status with a single tap, then optionally a size preset (small / medium / large) and a short, length-capped free-text note — structured-first, free text as an optional add-on, never a required form field, consistent with Constitution principle 9.
- The load flag is part of the request information shown to the driver **before** they accept, not revealed only after commitment — a driver deciding whether to accept must see it up front. See FM35.
- The driver can accept or decline the request with the load flag visible; a decline may optionally carry a one-tap reason ("no room for load") distinct from a generic decline, which is useful data in its own right (see the proactive warning below).
- **Mode-suitability warning, before the request is even sent:** vehicle modes have a config-driven (never hardcoded, per Constitution principle 3) load-capacity attribute — a keke or okada structurally has little or no boot space, a car or minibus typically does. If a rider flags load against a mode unlikely to accommodate it, the app warns before sending the request, saving a round-trip of request-then-decline. See FM36.
- **Fare treatment reuses existing machinery, rather than inventing a third pricing mechanism:** if a driver has declared a standard load surcharge as part of their route setup (Section 4.7, an optional field), it applies transparently, exactly like any other Tier 0-2 fare component. Where no standard surcharge exists, the surcharge amount (not the whole fare) is a legitimate, narrowly-scoped use of Along Pricing (Section 4.3.1) — negotiating a small, well-defined delta rather than the base fare. A surcharge must never be charged ad hoc outside one of these two paths. See FM34.
- **Day planner integration:** a rider carrying load for an entire outing (Section 4.10) can set the flag once at the itinerary level rather than re-flagging it at every stage, consistent with the set-once-not-every-time pattern already used for wayfinding mode (Section 4.11) and sort preference (Section 4.2.2).

**Data model:** extend `trips` with `load_flagged` (boolean), `load_size` (enum: small/medium/large, nullable), `load_note` (short, length-capped, nullable), `load_surcharge_amount` (nullable — sourced from a driver's declared surcharge or an Along Pricing negotiation on the surcharge only), `decline_reason` (nullable, extended to include a load-specific value alongside existing generic decline reasons). Mode load-capacity metadata lives in existing mode configuration (Section 4 data model rules — config-driven, not hardcoded).

### 4.14 Revenue-architecture technical hooks (operator SaaS, advertising, data API, white-label)

The business plan's Section 10.5/10.6 sets out a wider revenue architecture researched against TfL, Citymapper, and Google Maps as reference platforms — an operator/union B2B SaaS layer, contextual advertising, a packaged data/analytics product, and eventual white-label licensing. None of this is MVP-critical, but each stream needs a specific, narrow data-model and privacy hook decided now so it doesn't require retrofitting later. This section is intentionally scoped tighter than the core product mechanics elsewhere in Section 4 — these are hooks to build toward, sequenced into Phases 8 and 10 below, not a new subsystem to build immediately.

- **Operator/union B2B SaaS** — extends the existing `driver_route_profiles`/park-relationship model (Section 4.7, Section 9) rather than introducing a parallel concept: an `operator_accounts` entity (id, type — park/union/vehicle-owner/corporate, name, linked driver_ids, subscription_tier, billing_status) gives park leadership or a multi-vehicle owner a scoped view over their own drivers' aggregated data (fare-dispute records, demand patterns, digital records) through the same admin-console infrastructure already built for Phase 6, not a separate product.
- **Contextual advertising** — a `sponsored_placements` entity (id, context_type — destination/park/corridor, target_reference, advertiser, content, active_window) surfaces placements keyed to aggregate context (a destination, a park, a corridor) never to an individual rider's personal trip history. This is a hard privacy boundary, not a preference: see FM39.
- **Data/analytics API product** — an `api_keys` entity (id, owner_organization, scope, rate_limit, created_at, revoked_at) gates access to the aggregated data products already defined in Section 4.5.4 and the business plan's Section 10.6.3 — the API surfaces the same anonymized, aggregated outputs already gated by human review elsewhere in this spec, never raw trip or identity data. See FM40.
- **White-label / multi-tenancy** — a `deployments` entity (id, tenant_name, branding_config, region_config, active) formalizes what Constitution principle 7 and Phase 9/10 already require architecturally (no hardcoded city, country, or currency) into an explicit tenant boundary, so licensing the platform to an operator in a new city or country (business plan Section 10.6.5) is a configuration and data exercise, consistent with everything else in this spec, not a fork of the codebase.

---

## 5. Technology Stack (locked)

### 5.1 Core stack

Reuse decisions already made in the business plan; do not re-litigate per phase.


| Layer | Choice | Notes |
|---|---|---|
| Mobile (rider + driver) | Flutter | Cross-platform from Phase 1 onward — both Android and iOS are first-class targets, not iOS-deferred; Android is prioritized for testing given local device mix, which affects test-device allocation, not platform scope |
| Backend | Postgres + PostGIS, via a managed backend-as-a-service (e.g., Supabase) for MVP velocity | Migrate specific hot paths to dedicated services only when a measured bottleneck justifies it — not preemptively |
| Routing | Self-hosted OSRM or Valhalla on OpenStreetMap data | Commercial map APIs used only for geocoding gaps, as a variable cost |
| Map rendering | Vector-tile renderer (e.g., MapLibre GL — the open-source, no-per-request-fee fork of Mapbox GL) over OSM-derived vector tiles | Not a raster/static map fallback — see Section 5.2.4. This is what makes pan/zoom/live-marker movement feel smooth even on low-end Android devices, and is a distinct decision from the routing engine choice above |
| Admin console | Next.js | |
| Payments | Nigerian payment aggregator (e.g., Paystack/Flutterwave) — integration only, never custody of funds beyond pass-through | |
| Data collection tooling | ODK Collect / KoboToolbox for field agents; custom ingestion pipeline into Postgres | |
| Live tracking | Real-time channel (e.g., WebSocket/Supabase Realtime) | |

### 5.2 Design system & UI/UX foundations

Excellent UI/UX is a stated product requirement, not a subjective preference, and it needs the same kind of concrete, checkable rules as everything else in this spec — "make it beautiful" is not a testable acceptance criterion, but the rules below are. These are informed by how Uber's own public Base design system and Bolt's design system describe their approach, adapted for Along's specific context (multi-leg, multi-modal, low-end-device-first), not copied as brand assets.

#### 5.2.1 A locked design-token system, built before the first screen

A shared, versioned set of design tokens — not a Figma file nobody references, an actual token source (e.g., a JSON/Dart constants file) both apps and the admin console import from — covering:
- **Color:** a deliberately tight palette (2-3 neutrals, one primary accent reserved for primary actions, and a small fixed set of semantic colors for success/warning/error/mode-identity — see Section 5.2.3) rather than an open-ended palette any Worker session might quietly expand.
- **Type scale:** one modular scale with a small number of named roles (display/heading/body/label), large sizes favored for primary numbers (fare, ETA, ranking-sort values) per the "go big, legibility first" principle — directly reinforcing the one-tap/glanceable requirement in Section 4.6, not a separate concern from it.
- **Numeral treatment:** fares, countdowns, and ETAs render in a tabular/monospaced numeral style so digits don't jitter or reflow as values update live — a small detail with an outsized effect on an interface built around live-updating numbers.
- **Spacing:** a single baseline grid (e.g., 4pt) that all padding/margins snap to, so screens built by different Worker sessions in different tasks still feel like one coherent product.
- **Motion:** a small fixed set of durations and one easing curve for equivalent interaction types (e.g., a short duration for taps/toggles, a slightly longer one for screen/sheet transitions) rather than per-screen, ad hoc animation choices — motion should read as fast and precise, reinforcing reliability, not as playful or bouncy.

#### 5.2.2 Component-driven build discipline (this is also an Orchestrator/Worker/Reviewer tool)

Build a small internal shared component library (buttons, fare chips, stop pins, mode icons/badges, bottom sheets, status toggles) from Phase 1 onward, used by every subsequent task rather than each screen styling elements ad hoc. This matters more for Along's build process specifically than it would for a single-team project: many independent Worker sessions, each seeing only one task, are exactly the condition under which visual drift happens fastest without a shared component source of truth to pull from. Treat the component library the same way Section 3's repo structure treats `shared/` — a dependency every UI task must build on, not a nice-to-have refactor for later.

#### 5.2.3 Legibility for multi-leg, multi-modal trips specifically

Along's trips are structurally more complex to visualize than a single-leg Uber/Bolt ride (the business plan's Section 3.2 describes the multi-modal, multi-leg itinerary flow), so the lesson of clear sequencing and consistent color-coding for trip stages matters even more here, not less:
- Each mode (car/along-taxi, keke, okada, minibus) gets one consistent color+icon pairing, used identically everywhere it appears (search results, the live map, trip history, receipts) — never re-skinned per screen.
- Every stage of a multi-leg trip shows a timestamp/ETA at each leg and transfer point, not just at the final destination, so a rider (or someone checking on them via trip-sharing, Phase 5) can always see exactly where in the sequence the trip currently stands.
- The live map uses a bottom sheet over the persistent map view for trip details/options (never a full-screen navigation away from the map for a common action) — keeps spatial context visible at all times and reduces perceived navigation depth, reinforcing Section 4.6's speed requirement.

#### 5.2.4 Why vector-tile rendering is a locked requirement, not a nice-to-have

Section 5.1 locks a vector-tile map renderer specifically because raster/static map tiles cannot deliver smooth 60fps pan/zoom/rotate and live-marker movement — the single biggest visible driver of whether a map-heavy app *feels* premium versus sluggish, independent of how good the routing/fare logic underneath it is. This is a distinct decision from the choice to self-host OSRM/Valhalla for routing cost reasons (Section 5.1) — do not let routing-cost-consciousness bleed into rendering-quality-consciousness; render OSM-derived vector tiles through a vector-tile client renderer regardless of which routing backend computes the underlying paths.

#### 5.2.5 Skeleton states, not spinners

Any map- or list-based screen shows a skeleton/placeholder matching the eventual layout while data loads, not a blank screen or a bare spinner — this keeps perceived speed high even on the 3G-equivalent, low-end-device conditions Constitution principle 5 already requires designing for, and is consistent with (not a departure from) the low-data-first requirement.

### 5.3 Where AI/ML genuinely belongs in this system — and where it deliberately doesn't

This is a calibrated answer, not a default "add AI everywhere." Along's core transactional integrity — fare resolution, commission, matching, trip state — is deterministic business logic by design (Sections 4.2-4.4), and should stay that way: a driver disputing a blocked account or a commission charge needs an explainable, auditable answer, not "the model decided." The review-not-auto-punish discipline running through Sections 4.4.2, 4.5.1, and 4.1.2 exists precisely so no automated system — ML or otherwise — makes a final adverse call against a driver or rider without a human in the loop. Nothing below changes that.

**Where AI/ML is genuinely warranted — each scoped, bounded, and explicitly not load-bearing for correctness:**

- **Natural-language destination and itinerary entry.** Parsing a rider's loosely-structured input ("drop the kids at school, then work, then market") into structured `itinerary_stops` (Section 4.10), or a driver describing their route stops in natural speech during setup (Section 4.7), is a genuine NLP/entity-extraction problem — the kind of messy-input-to-structured-output task language models handle well and hand-written parsing rules handle poorly. This is close to *necessary* for hitting the "few clicks, excellent UX" bar already set for both features, not merely a nice-to-have. **Guardrail:** the model's output is always a structured, human-reviewable proposal the rider/driver confirms with a tap (Section 4.6) before it becomes real data — never silently committed.
- **Speech-to-text and text-to-speech.** Underlies the audio wayfinding mode (Section 4.11) and voice-based route/itinerary entry above. Mature, well-bounded, off-the-shelf technology — not a research problem for this product.
- **OCR/computer-vision-assisted document verification.** Driver onboarding (NIN, license, vehicle particulars, Section 4 data model) benefits substantially from automated document capture and face-match-to-ID at scale — a manual-only review process will not hold up once driver volume moves beyond a pilot corridor. **Guardrail:** this assists and accelerates human verification, it does not replace the human approval step for a driver's final onboarding decision.
- **Anomaly-detection signal quality.** The cancel-after-match and GPS-mismatch anomaly scoring in Section 4.4.2 is specified as heuristic/threshold-based, which is the right MVP baseline — deterministic, explainable, easy to reason about. As real operating data accumulates, a proper statistical/ML anomaly model (not deep/generative AI — classical outlier-detection techniques) will likely outperform fixed thresholds at distinguishing genuine fraud patterns from noise. **Guardrail:** this improves what gets *surfaced* for admin review; it must never be wired to an automatic account action, per the existing FM13 rule.
- **Demand forecasting.** `coverage_gap_reports` (Section 4.9) and general trip-search data are exactly the input a time-series/demand-forecasting model needs to get meaningfully better than simple counting at predicting where and when to prioritize field mapping, driver recruitment, or corridor expansion (Sections 7-9). Genuinely valuable, not necessary for MVP.
- **Learning-to-rank refinement of the "Recommended" default.** Section 4.2.2's ranking blend is specified as a hand-tuned, explainable formula, which is correct for launch. Once there's real data on which options riders actually choose when shown several, a bounded learning-to-rank model can refine those weights over time. **Guardrail:** the direct-match-first rule (Section 4.2.1) and the metric definitions themselves stay fixed, hard constraints — learning is scoped to tuning weights within them, never to overriding them, and any such model's behavior must remain explainable enough for Phase 6 admin tooling to show why an option ranked where it did (Section 4.2.2's existing rule against black-box scores applies to a learned model exactly as it does to a hand-tuned one).

**Where AI/ML is deliberately not used, even though it's fashionable to reach for it:**
- Core fare/commission calculation (Section 4.3, 4.4.1) — deterministic and auditable by requirement, not by omission.
- The base routing/decomposition algorithm (Section 4.2.1's search staging, Phase 2's transfer-point decomposition) — classical graph search on good data is the right tool here; the excellence this product needs comes from correct algorithms and a well-maintained along-graph, not from a model layered on top of an otherwise weak foundation.
- Any final account-status decision (blocking, deactivation, escalation) — always a human admin action per the escalation ladder (Section 4.4.3), regardless of what signal prompted the review.

---

## 6. Universal Gate Checklist

**Every task, every phase, must pass all of these before a Reviewer may issue PASS — in addition to the task-specific acceptance criteria the Orchestrator attaches.**

**Security & data integrity**
- [ ] Row Level Security (or equivalent) enforced on every table holding user, trip, driver, or financial data — no table is publicly writable by default
- [ ] Every input validated server-side, not just client-side
- [ ] No secrets, API keys, or NIN/license numbers committed to the repo or logged in plaintext
- [ ] Ownership checks enforced server-side wherever a driver/rider modifies their own data (a driver cannot edit another driver's vehicle, etc.)

**Asset-light / architecture conformance**
- [ ] No new code assumes Along owns or dispatches a vehicle
- [ ] No hardcoded single-mode assumption in any trip-planning or fare logic
- [ ] No hardcoded city/corridor assumption outside of seed/config data

**Data provenance**
- [ ] Any along-graph write (route, fare, park) carries source + timestamp + verifier fields per Section 4
- [ ] Any crowdsourced correction enters a `candidate` state and is promoted only via the trust-weighted rules in Section 4.5 (or explicit admin review) — never auto-published on a single unweighted submission

**Commission-ledger integrity** (applies to any task touching `driver_ledger_entries`, matching/blocking logic, or trip status transitions)
- [ ] Any balance shown or acted on is derived by summing ledger entries, never read from a separately-mutated field
- [ ] Any automated fraud/anomaly signal is surfaced for admin review, never wired to an automatic status or balance change

**Interaction speed** (applies to any rider/driver-facing recurring action per Constitution principle 9 / Section 4.6)
- [ ] Every action in Section 4.6's one-tap list remains a single interaction with no new intermediate screen, form, or confirmation dialog introduced
- [ ] Any new required confirmation step for a recurring action is explicitly justified in the task report against Section 4.6, not added by default

**Design consistency** (applies to any UI-facing task)
- [ ] New UI elements draw from the Section 5.2 design-token system and shared component library — no new one-off colors, type sizes, or spacing values introduced ad hoc
- [ ] Map-based screens use the vector-tile renderer per Section 5.2.4, never a static/raster map fallback

**Discovery/commitment boundary** (applies to any task touching presence, discovery, or demand-signal endpoints — Section 4.1.2)
- [ ] An ambient/pre-commitment view never returns a specific vehicle's plate, driver identity/photo, a specific rider's identity, or precise live coordinates
- [ ] Precise position/identity fields are only reachable through an endpoint gated behind an existing `trips` row

**Low-data / device reality**
- [ ] New screens/flows function acceptably in a simulated low-bandwidth/high-latency condition
- [ ] No unbounded payloads — pagination or limits present on any list-returning endpoint

**Testing**
- [ ] Unit tests cover new business logic (fare calc, route decomposition, verification workflows)
- [ ] Integration test covers the new endpoint(s)/screen(s) against a realistic seeded dataset
- [ ] Regression: existing test suite still passes in full

**Documentation**
- [ ] Any new architecturally significant decision has an ADR
- [ ] BUILD_LEDGER.md entry completed by the Orchestrator

**A single unchecked box in a launch-blocking category (Security & data integrity, Asset-light conformance) is an automatic FAIL, regardless of how good the rest of the task looks.**

---

## 7. Full Phase Plan (all phases — MVP through national/multi-country readiness)

Each phase below lists: objective, key deliverables, phase-specific gate additions (on top of Section 6, which always applies), and the exit criterion the Orchestrator must confirm before opening the next phase.

### Phase 0 — Data & Graph Foundation
**Objective:** Stand up the along-graph schema, the backbone field-data ingestion pipeline, and the confidence-based crowdsourced promotion pipeline (Section 4.5); seed the backbone of 2-3 Abuja pilot corridors — exhaustive per-stage field mapping is explicitly not the target (Section 4.5.2).
**Deliverables:** Core schema (Section 4) migrated, including `route_stages` and stage-hop `route_legs` with `verification_status`/`confidence_score`/`independent_confirmation_count` fields (Section 4.3, 4.5) — routes must be seeded as stage sequences from the start, not retrofitted later; ODK/Kobo form templates for field agents capturing backbone per-stage fares; ingestion pipeline (raw field data → reviewed → published as `field_verified`); the trust-weighted promotion pipeline from Section 4.5.1 (candidate → crowd_verified) including the anti-gaming outlier/scrutiny logic and the periodic confidence-decay job; redundancy/verification workflow (two-scout reconciliation) for backbone stages, implemented as an admin-console review queue, not a spreadsheet.
**Phase-specific gates:** A backbone route/fare cannot reach `field_verified` status without two independent source records reconciled; every seeded record has full provenance metadata; every seeded backbone route has at least the major transfer-point stages needed for Tier 1/2 resolution on the most common trips (not necessarily every minor stop — see Section 4.5.2); the promotion pipeline is tested against a simulated collusion scenario (several low-trust accounts confirming an outlier value) and correctly withholds promotion or routes to admin review.
**Exit criterion:** 2-3 corridors have backbone seeding sufficient for Tier 1/2 fare resolution on their primary trips; a query can return a walkable multi-leg path between any two seeded backbone parks; a fare query between two intermediate backbone stages resolves correctly via Section 4.3's summed-hop tier; a simulated `candidate` stage correctly promotes to `crowd_verified` once trust-weighted confirmations cross the configured threshold, and correctly does not promote when confirmations are too few, too low-trust, or too divergent.

### Phase 1 — Core Booking MVP (single corridor)
**Objective:** Rider can search a destination and get a route+fare+boarding point; driver can mark availability (at-park or roaming) and self-author their own route/fare schedule; no full live GPS trip-tracking yet, no payments yet.
**Deliverables:** Rider app: destination search, route/fare/boarding-point display, mode selection with one-tap accept/decline/request-alternative (Section 4.6), and the load-flagging feature from Section 4.13 (one-tap flag, optional size/note, pre-request mode-suitability warning). Driver app: onboarding + verification flow (deliberately not one-tap — Constitution principle 9 exempts trust-establishment), one-tap availability toggle covering both `at_park` and `roaming_available`/`roaming_full` states (Section 4.1), the driver self-service route & fare setup flow from Section 4.7 (both the fast known-route path and the manual map-drawing path, including the optional load-surcharge field), and the pre-accept request view surfacing any load flag (Section 4.13). Backend: trip-request/match endpoints implementing the full Tier 0-3 fare resolution from Section 4.3, plus a minimal real-time channel sufficient to broadcast `driver_presence` pings to nearby riders (the fuller live in-trip tracking build-out happens in Phase 3, but the underlying channel is introduced here since roaming discovery is core MVP scope, not post-MVP). The Section 5.2 design-token system and shared component library are built as part of this phase's first tasks, not deferred — every screen in this phase and after draws from it.
**Phase-specific gates:** Multi-modal option display works even with only one mode seeded (must not crash/hide the UI pattern for future modes); driver verification (NIN/license/vehicle) enforced before a driver can appear as available in either mode; a driver going offline immediately stops appearing on any rider's live map — tested explicitly, not assumed; roaming vehicles only surface to riders whose destination is plausibly served by the vehicle's heading/declared route, never as undirected proximity; every action listed in Section 4.6's one-tap list is implemented as a single interaction with optimistic UI feedback, not a multi-step flow — verified against the Section 4.6 list explicitly in the task report, not asserted generally; the route-setup flow's fast known-route path is demonstrably completable in one tap on a test account with a pre-matched route, and the manual path correctly snaps to an existing nearby stage rather than always creating a duplicate; a trip matched to a driver with an active `driver_route_profile` correctly resolves fare via Tier 0, not the shared-graph tiers; a load-flagged request against a low-capacity mode (keke/okada) triggers the pre-request warning (FM36), and the load flag is visibly present in the driver's pre-accept view, not only after acceptance (FM35).
**Exit criterion:** A real test rider can, end-to-end, search a destination on a pilot corridor and see both an accurate park-based route/fare/boarding-point result sourced from the Phase 0 graph, and any currently-roaming test vehicle heading the right direction on the live map; a test driver can publish a new route with per-stop pricing in well under a minute, and a rider matched to that driver sees the correct Tier 0 fare for a mid-route boarding; a rider flagging load on a request sees the correct mode-suitability warning where applicable, and a test driver sees the load flag before deciding whether to accept.

### Phase 2 — Multi-Leg, Multi-Modal Trip Planning, Ranking, Stage-Based Fares & Pricing
**Objective:** Full trip decomposition across transfer parks and mixed modes, with cost/time/effort ranking over the resulting candidate set, correct fare resolution for any actual boarding/alighting point, and the Along Pricing negotiation flow for genuine Tier 3 gaps.
**Deliverables:** Trip-planner service that decomposes a destination into 1-3 legs across modes via `transfer_points`; the direct-match-first search staging from Section 4.2.1, checked against parked, roaming, and driver-declared-route sources before any multi-leg decomposition is presented as the default; the stage-based fare resolution logic from Section 4.3 (all three tiers) wired into every fare the planner returns; the Along Pricing negotiation flow from Section 4.3.1 (`price_negotiations`/`price_negotiation_rounds`, the anchored proposal UI, round cap and timeout, split-the-difference fallback, and the feed into `fare_corrections`) for Tier 3 cases; the ranking model and metrics from Section 4.2.2 (total_fare, total_time_estimate, transfer_count, total_walking_distance_m, strenuousness_score) attached to every returned candidate, with `total_fare` always sourced from Section 4.3's resolution logic; rider UI for multi-leg itineraries with per-leg fare/mode, plus sort/filter controls for cheapest / fastest / least strenuous / recommended; accept/decline/request-alternative per leg, not just per trip.
**Phase-specific gates:** Planner must correctly refuse to fabricate a route across parks with no verified connecting leg (no silent guessing); a leg's mode-specific fare must never be conflated with another mode's fare in the total; the planner must return the full viable candidate set with metrics attached rather than pre-collapsing to a single "best" route (tested explicitly — a query with multiple genuinely different viable options must return more than one candidate); each of the four sort/filter criteria must produce a demonstrably different ordering on a test dataset engineered to have a cheapest option, a fastest option, and a least-strenuous option that are three different routes; a mid-route boarding test case (boarding stage other than the route's origin park) must return a correctly reduced fare via Tier 1 or Tier 2, not the full-route fare and not an unconfirmed-fare flag, when stage data exists; a boarding point with genuinely no stage data must correctly fall back to Tier 3 and trigger Along Pricing, never a silent guess; a direct-match-first test case (a viable direct driver to the exact destination exists alongside a valid multi-leg decomposition) must confirm the direct option is both present in the candidate set and ranked first in "Recommended," including a variant where the only direct match comes from a driver-declared route profile rather than the canonical along-graph; a non-viable-direct-match test case (the only direct driver is far outside the configured wait/detour bound) must confirm the multi-leg option correctly wins "Recommended" instead; a Pricing test case must confirm it never appears on a Tier 0-2 fare (FM31), that a negotiation lapses correctly at the round cap into the split-the-difference fallback (FM32), and that an agreed amount posts to `fare_corrections` (FM33); a roaming-context Pricing test suite must cover all three ETA bands from Section 4.3.1 (very short → accept-or-skip only, moderate → single counter-offer round, longer → full multi-round exchange) and confirm the auto-lapse safety valve fires when the driver's live position exceeds the pickup radius mid-negotiation (FM37/FM38).
**Exit criterion:** A destination requiring a real transfer on a pilot corridor returns a correct multi-leg, multi-modal itinerary, and sorting that same result set by each of the four criteria produces correct, verifiably different orderings; a rider boarding at a known intermediate stage on a seeded route is quoted the correct reduced fare, verified against the Phase 0 seeded stage-hop data; a rider requesting a destination directly covered by an available driver's route is shown that direct option as the top-ranked recommendation, not a multi-leg alternative, whenever it is viable; a genuinely undocumented boarding point correctly triggers a bounded Along Pricing exchange, resolves within the configured round cap, and the agreed fare is both used for the trip and posted as a candidate correction; a simulated roaming vehicle at each of the three ETA bands produces the correct negotiation behavior for that band.

### Phase 3 — Live Tracking, Trip Lifecycle & Full Presence Infrastructure
**Objective:** Real-time GPS tracking during a trip; trip status lifecycle (requested → boarded → in-transit → transfer → completed); harden the `driver_presence` broadcast infrastructure introduced in Phase 1 to full scale and retention-policy compliance.
**Deliverables:** Real-time location channel (production-hardened); rider-facing live map + ETA, covering both in-trip tracking and pre-trip roaming-vehicle discovery on the same infrastructure; trip-state machine enforced server-side (no illegal state transitions) including a hailed-roaming-vehicle path that reuses the same accept/decline states as a park-based route option; the co-location-based auto-confirmation of the `boarded` state transition from Section 4.6, with manual tap as fallback; the "Na Me" identification pairing (Section 4.8) — id-signal generation and delivery at match time, plus the strobe/vibrate/audio trigger UI; driver-side passenger manifest; `driver_presence.current_location` retention/downsampling policy implemented per Section 4.1.
**Phase-specific gates:** State machine has explicit tests for every valid and invalid transition, including the roaming-hail path and the auto-confirmation path; auto-confirmation must be tested against a false-trigger scenario (e.g., a driver and rider briefly co-located without an actual match/boarding) to confirm it does not fire outside a genuine pending match; location data access is scoped — a rider can only see the driver/vehicle they are matched to during an active trip, and only directionally-relevant roaming vehicles pre-trip, never all active trips/drivers city-wide; "Na Me" is explicitly tested in airplane mode after match (id-signal already cached) to confirm the trigger itself requires no network call, per Section 4.8.
**Exit criterion:** A live test trip on a pilot corridor shows accurate real-time position and correct state transitions end-to-end, including a transfer and an auto-confirmed boarding requiring no manual tap; a separate live test confirms a roaming vehicle can be discovered, hailed, and accepted entirely through the same infrastructure; a simulated "Na Me" trigger correctly strobes/vibrates and shows a correct directional indicator on the matched device, including when triggered with the device offline.

### Phase 4 — Fare Transparency, Commission Enforcement & Payments
**Objective:** Post-trip fare confirmation/dispute flow feeding graph corrections; optional cashless payment; the driver ledger, threshold enforcement, and trip-manipulation detection from Section 4.4.
**Deliverables:** Post-trip "did you pay the shown fare?" flow → `fare_corrections` pipeline into the Phase 0 review queue; payment aggregator integration (wallet, bank transfer, USSD) as an *optional* path alongside cash; commission calculation service implementing the 5-10% target commission from the business plan, with commission and fare kept as clearly separate line items end-to-end; the `driver_ledger_entries` model and settlement service (self-service + agent-assisted) from Section 4.4.1; threshold-based match-blocking wired into the same matching path used by Phase 1/3; the GPS/status reconciliation job and rider-side cross-check from Section 4.4.2; the escalation-ladder state machine from Section 4.4.3; the guarantor notification flow from Section 4.4.4; the mid-trip extension propose/accept flow and `trip_extensions` model from Section 4.12, including its extension of the Section 4.4.2 reconciliation job to detect undeclared extensions.
**Phase-specific gates:** Commission must never be silently bundled into the displayed fare; a cash trip must complete with zero required payment-API calls; a driver's ledger balance must always be independently reconstructable by summing `driver_ledger_entries` (test this by asserting the derived sum matches any cached/displayed balance, never trusting a stored mutable field); match-blocking on threshold breach must be tested against **both** the park-based and roaming-hail matching paths (Section 4.1) — a driver blocked in one path must not be reachable through the other; the reconciliation job's flagging must be reviewable by an admin, never auto-punitive (test that a flagged trip does not automatically change driver status without an explicit admin/escalation-ladder action); the reconciliation job must be tested against a missing/partial `rider_live_path` case and correctly treat it as inconclusive rather than as evidence of anything; a multi-rider trip test case must confirm the reconciliation job surfaces corroboration count rather than evaluating each rider trace in isolation; a trip extension must be tested end-to-end confirming the fare delta reuses Section 4.3's resolution logic unmodified and posts a correct incremental ledger entry, and the reconciliation job must be tested against an undeclared-extension scenario (trip completed short of where the rider trace actually ends) and correctly flag it for review only.
**Exit criterion:** A rider can complete a trip entirely in cash with no payment integration invoked, and separately, a rider can complete a trip via the payment aggregator with commission and fare itemized correctly in both the rider and driver views; a simulated over-threshold driver is correctly blocked from new matches across both matching paths and correctly unblocked immediately on settlement (self-service or agent-assisted); a simulated premature-trip-conversion scenario (cancelled status + driver and/or rider trace showing completion) is correctly flagged for admin review without an automatic status change, including a variant where the driver never confirms "boarded" at all, and a variant with multiple riders in one vehicle where the corroboration count is correctly surfaced; a test rider extends an in-progress trip and the resulting fare, commission, and ledger entry are all correct.

### Phase 5 — Safety & Trust
**Objective:** SOS, trip-sharing, ratings, incident handling — treated as launch-blocking per Constitution principle 8.
**Deliverables:** In-app SOS routed to a defined incident-response process (Section "Runbooks"); live trip-sharing to a trusted contact via link; two-way ratings; incident-reporting flow into `incidents` table with admin-console triage; women-only route/vehicle option (matching-logic addition, not a cosmetic filter).
**Phase-specific gates:** SOS action must function under the low-data conditions defined in Section 6, not just on a fast connection; incident data access restricted to authorized admin roles only, tested explicitly.
**Exit criterion:** A simulated SOS trigger correctly reaches the incident pipeline end-to-end within defined latency, and a trip-share link correctly restricts access to only the intended contact.

### Phase 6 — Admin/Ops Console Maturity
**Objective:** Full operational tooling for the team running pilot corridors.
**Deliverables:** Route/park/fare-graph management UI (not raw SQL); driver/vehicle verification queue; incident and SOS monitoring dashboard; corridor-level analytics (demand, fulfillment, wait time, fare-discrepancy rate).
**Phase-specific gates:** Every admin action that changes rider/driver-facing data is logged with actor + timestamp (auditability); analytics queries must be paginated/bounded per Section 6.
**Exit criterion:** The ops team can run a full pilot-corridor day (verify a driver, resolve a fare dispute, review an incident, pull a demand report) without touching the database directly.

### Phase 7 — Abuja Scale-Out (multi-corridor)
**Objective:** Generalize from 2-3 corridors to full FCT coverage as a configuration/data exercise.
**Deliverables:** Corridor-onboarding runbook + tooling that mirrors the Phase 0 pipeline, made repeatable without new code; load-tested backend for full-city concurrency; caching strategy for frequently-requested routes; the trace-to-map-intelligence pipeline from Section 4.5.4 (map-matching, road-geometry correction, route inference, segment speed-profile calibration) — genuinely valuable once multi-corridor trip volume exists, not before, so this phase is its natural home rather than the MVP phases.
**Phase-specific gates:** Adding a new corridor must require zero application-code changes — only new along-graph data and config; explicit load test results attached to the task report; the Section 4.5.4 pipeline must be tested against a raw-trace-without-map-matching regression case (FM27) and produce zero geometry/route proposals from it.
**Exit criterion:** A new corridor can be onboarded by the ops team (not engineering) using only the Phase 0/7 tooling, end-to-end, and the system holds under a defined concurrent-user load test; a controlled test with a simulated batch of trip traces along an undeclared corridor correctly produces a reviewable route-inference candidate, and a segment speed-profile measurably improves ETA accuracy against a baseline of generic map defaults.

### Phase 8 — B2B & B2G Layer
**Objective:** Corporate account structures; anonymized data-partnership exports; the operator/union B2B SaaS, contextual advertising, and data-API hooks from Section 4.14.
**Deliverables:** Corporate/organization account model (staff roster, subsidized-trip billing); anonymized origin-destination data export pipeline with explicit PII-stripping tests; `operator_accounts` and the scoped operator view into the admin console (Section 4.14); the `sponsored_placements` model and contextual (never individual-history-based) placement logic; the `api_keys` model and rate-limited access to Section 4.5.4's aggregated data products.
**Phase-specific gates:** Anonymization pipeline has dedicated tests proving no individual trip is re-identifiable from the export at the aggregation level shipped; corporate billing reconciles against actual trip records, tested against discrepancy cases; a sponsored-placement test must confirm targeting logic has no path back to an individual rider's identity or trip history (FM39); an API-access test must confirm only aggregated outputs are reachable through any API key, never raw trip records (FM40).
**Exit criterion:** A test corporate account can provision staff, run subsidized trips, and receive a correct reconciled invoice; a sample anonymized export passes the re-identification test suite; a test operator account can view their own drivers' aggregated data through the admin console; a test API key can retrieve an aggregated data product and cannot retrieve anything below that aggregation threshold.

### Phase 9 — Multi-City / Multi-State Generalization
**Objective:** Prove the "config not code" claim at the next level — a second Nigerian city.
**Deliverables:** City/region-scoping added to every relevant query and UI surface that assumed Abuja-only implicitly; localization scaffolding (currency already generic, but language/labels reviewed for portability); city-level admin roles.
**Phase-specific gates:** An explicit audit task confirming no remaining Abuja-hardcoded assumption exists in code (grep-and-verify, attached to the task report).
**Exit criterion:** A second Nigerian city can be stood up using only the Phase 0/7 onboarding tooling plus this phase's generalization work — no bespoke code branch per city.

### Phase 10 — Pan-African Portability
**Objective:** Generalize beyond Nigeria-specific assumptions (currency formatting, ID-verification document types, regulatory config) so a first non-Nigerian market is a configuration and data exercise, not a rewrite; formalize the `deployments`/multi-tenancy model from Section 4.14 so white-label licensing (business plan Section 10.6.5) is achievable without a code fork.
**Deliverables:** Externalized configuration for currency, driver-verification document types, and any Nigeria-specific regulatory logic (e.g., NIN checks become a pluggable verification-provider interface); country-level feature flags where local regulation genuinely requires behavior differences; the `deployments` entity and tenant-scoped branding/region configuration, with data isolation between tenants verified explicitly.
**Phase-specific gates:** A documented "new country checklist" exists and has been dry-run against a hypothetical second country in code review, without shipping that country; a white-label dry run — standing up a second, differently-branded `deployments` record against the same codebase — confirms no cross-tenant data leakage and no hardcoded branding/region assumption blocks it.
**Exit criterion:** Architecture review (Reviewer + human product owner) confirms no remaining Nigeria-only assumption blocks a first international pilot from being primarily a data/ops exercise; a second test tenant can be configured and demonstrated end-to-end without any application-code change, only configuration and data.

### Phase 11 — Hardening, Performance & Security Audit
**Objective:** Dedicated pass, not a rushed afterthought, before any major public/investor-facing launch milestone.
**Deliverables:** Full security audit against the Section 6 checklist across the entire codebase (not just new code); performance budget review (app size, cold-start time, API p95 latency under load); dependency/vulnerability audit.
**Phase-specific gates:** Every table/endpoint explicitly re-verified against the authorization matrix (who can read/write what) — produced as an artifact, not just asserted.
**Exit criterion:** A written audit report with no open critical/high findings, signed off by the Reviewer role and the human product owner.

### Phase 12 — Documentation & Deployment Readiness
**Objective:** Anyone (a new engineer, a new city-ops lead) can onboard from the docs alone.
**Deliverables:** Updated README and ADRs; deployment runbook; incident-response runbook (referenced from Phase 5); environment/config reference; final `BUILD_LEDGER.md` review and archive of superseded entries.
**Exit criterion:** A new engineer unfamiliar with the project can, using only `docs/`, get the full stack running locally and understand the current architecture without a live walkthrough.

---

## 8. Failure-Mode Playbook (Along-specific)

Use these as immediate corrective prompts when a Worker session drifts. Each corresponds to a real pattern AI coding agents fall into.

**FM1 — Asset ownership creep.** Symptom: code that assumes a fleet, dispatch queue, or Along-owned vehicle inventory. Fix: *"This violates Constitution principle 1 (asset-light). Remove any assumption of Along-owned vehicles. Every vehicle must trace to an independent driver/owner record. Report what you removed."*

**FM2 — Single-mode collapse.** Symptom: trip-planning or fare code that only handles one mode "for now" in a way that hardcodes assumptions rather than defaulting gracefully. Fix: *"This must remain mode-agnostic per Constitution principle 3, even with only one mode currently seeded. Refactor so adding a second mode requires no code change, only data. Show the diff."*

**FM3 — Fare/commission conflation.** Symptom: commission silently folded into the fare shown to the rider, or vice versa. Fix: *"Fare and commission must be itemized and traceable separately end-to-end per Phase 4. Show me the exact field(s) each is stored and displayed in."*

**FM4 — Unverified graph writes.** Symptom: a route/fare/park write path that skips the review-queue/provenance requirement from Section 4. Fix: *"Every along-graph write needs source + timestamp + verifier and a review-queue state per Section 4 — this cannot auto-publish. Fix and show the new state machine."*

**FM5 — Hardcoded locality.** Symptom: "Abuja," a specific corridor name, or a specific park literally hardcoded into logic rather than pulled from config/data. Fix: *"This violates Constitution principle 7 — no city/corridor may be hardcoded outside seed data. Refactor to be data-driven and prove it by pointing to a different (even fictional) city's config."*

**FM6 — Self-graded review.** Symptom: a Worker's task report claims criteria are met without independently-runnable evidence (test output, specific file/line references). Fix: *"Your task report doesn't meet the format in Section 2.3 — every acceptance-criteria checkbox needs evidence, not an assertion. Resubmit."*

**FM7 — Silent scope expansion.** Symptom: a Worker implements more than the assigned task ("while I was in there, I also added…"). Fix: *"Remove everything outside the assigned task scope. List what you removed. Anything genuinely necessary gets proposed to the Orchestrator as a separate task, not silently bundled."*

**FM8 — Gate skipping under time pressure.** Symptom: a Reviewer (or the human operator) is tempted to wave through a task because "it's probably fine." Fix: this is a process failure, not a code failure — re-run the Section 6 checklist item by item before proceeding. No exceptions for launch-date pressure on the Security & data integrity or Asset-light categories.

**FM9 — Low-data blind spot.** Symptom: a feature that works well on a fast connection but was never tested under the low-bandwidth condition required by Section 6. Fix: *"Test this under simulated high-latency/low-bandwidth conditions per Constitution principle 5 before this can pass review."*

**FM10 — Presence broadcast turning into passive tracking.** Symptom: `driver_presence` location writes continue after a driver goes offline, or a client caches/displays a driver's last-known position after their status changes away from `roaming_available`/`at_park`. Fix: *"Presence broadcast must stop immediately on status change per Section 4.1 — this is an opt-in live-availability signal, not a location history. Verify no stale pin persists client-side and no server write continues after status flips to offline."*

**FM11 — Single-best-route collapse.** Symptom: the planner internally scores candidate routes and returns only its own "best" pick, leaving nothing for sort/filter to actually operate on — silently defeating the ranking feature in Section 4.2/Phase 2. Fix: *"The planner must return the full viable candidate set with metrics attached, per Section 4.2. Ranking/filtering is a query over that set, not a planner-time decision. Show me a test case with at least two genuinely different candidates returned."*

**FM12 — Mutable ledger balance.** Symptom: a driver's commission balance is implemented as a directly-updated field rather than derived from summing `driver_ledger_entries`. Fix: *"This violates Section 4.4.1 — the balance must always be reconstructable from the append-only ledger, not stored and mutated directly. This is both an audit requirement and a dispute-resolution requirement when a driver challenges a balance. Refactor and show the derivation."*

**FM13 — Auto-punitive fraud detection.** Symptom: the GPS/status reconciliation job (Section 4.4.2) automatically changes a driver's status or balance on a flagged mismatch, rather than surfacing it for admin review. Fix: *"Flagging is not the same as punishing — Section 4.4.2 requires this to be reviewable, not automatic, to avoid false-positive harm to a driver from an edge-case GPS trace. Route this through the escalation ladder (Section 4.4.3) with an explicit admin action, and show the test proving no automatic status change occurs."*

**FM14 — Driver-only trip verification.** Symptom: the reconciliation job in Section 4.4.2 only checks `driver_live_path`, ignoring `rider_live_path` as an independent corroborating signal, or triggers detection only after an explicit `boarded` confirmation the driver could simply avoid tapping. Fix: *"Section 4.4.2 requires independent rider-side corroboration, not driver-GPS-only verification — a driver who wants to hide a trip controls their own trace but not the rider's, and controls whether they tap 'boarded' but not whether the cancellation check runs. Wire in `rider_live_path` and trigger the check on any post-match cancellation, not only post-boarding. Show the test covering a driver that never confirms boarding."*

**FM15 — Flat leg-fare assumption.** Symptom: a route or leg is priced as a single fixed origin-to-destination fare regardless of where a rider actually boards, ignoring the stage-based resolution required by Section 4.3 — either overcharging a mid-route boarder or defaulting every non-origin boarding to an unconfirmed-fare flag even where real stage data exists. Fix: *"This violates Section 4.3 — fares must resolve from the rider's actual boarding/alighting stages through the three-tier resolution order (known through-fare, summed stage-hops, proportional estimate), not from a route's full listed fare. Show a test case with a mid-route boarding that correctly returns a reduced, non-estimated fare."*

**FM16 — Unweighted crowdsourced promotion.** Symptom: a `candidate` stage/fare is promoted to `crowd_verified` by simple confirmation count, without trust-weighting by account history or outlier scrutiny, per Section 4.5.1. Fix: *"This is gameable — a handful of low-trust or colluding accounts could promote a false fare. Weight confirmations by account_trust_weight/driver standing, and route sharp outliers to admin review instead of promoting on volume alone. Show the test with a simulated low-trust collusion attempt that correctly fails to promote."*

**FM17 — Unjustified friction on a recurring action.** Symptom: a new screen, form, or confirmation dialog is added to one of Section 4.6's one-tap actions (search, accept/decline, status toggle, trip-state confirmation) without explicit justification. Fix: *"This violates Constitution principle 9 — recurring, in-the-moment actions must stay one-tap. If this step is genuinely necessary, justify it explicitly against Section 4.6 in the task report; otherwise collapse it back to a single interaction with optimistic UI feedback."*

**FM18 — Unsnapped driver-declared stops fragmenting the graph.** Symptom: the route-setup flow (Section 4.7) creates a new stage for every stop a driver places, without checking for and offering an existing nearby canonical stage first, so multiple drivers running the same physical route end up with duplicate, disconnected stop records instead of converging on shared ones. Fix: *"This violates Section 4.7 — a new stop must first check for an existing nearby route_stage and offer a one-tap 'use existing stop' confirmation before creating a new candidate. Show the snapping logic and its radius/tolerance."*

**FM19 — Raster map fallback.** Symptom: a map screen renders static/raster tile images instead of the vector-tile renderer locked in Section 5.1/5.2.4 — often introduced because it seemed like the simpler integration path for a given task. Fix: *"This violates Section 5.2.4 — raster tiles cannot deliver the smooth pan/zoom/live-marker motion this product requires, independent of routing-cost decisions. Use the vector-tile renderer already established for this codebase."*

**FM20 — Ad hoc styling drift.** Symptom: a UI task introduces a new color, type size, or spacing value not defined in the Section 5.2 design-token system, because it was faster than checking what already exists. Fix: *"This violates Section 5.2.1/5.2.2 — every UI value must come from the shared token system and component library, precisely because many separate Worker sessions building this product need a common source of truth to stay visually consistent. Replace the one-off value and, if the token system is genuinely missing something this task needs, add it to the shared source first, not inline."*

**FM21 — Precise info leaked pre-commitment.** Symptom: an ambient/discovery endpoint or screen returns a specific vehicle's plate, a driver's identity/photo, a specific rider's identity, or a precise live coordinate before a `trips` row exists — silently defeating the discovery-to-commitment boundary in Section 4.1.2 and reopening the disintermediation risk it exists to close. Fix: *"This violates Section 4.1.2 — ambient views must stay aggregate/anonymized; precise identity and position unlock only through a path gated behind an existing trips row. Show which fields the ambient endpoint returns and strip anything precise."*

**FM22 — "Na Me" requiring a live network call.** Symptom: the "Na Me" trigger (Section 4.8) fetches the identification pairing or performs any network round-trip at the moment of use, rather than using data already cached from match time. Fix: *"This violates Section 4.8 — the identification pairing must be delivered and cached at match time, and the trigger itself must be a pure local-device action. Test this in airplane mode after a match has already been made; it must still work."*

**FM23 — Day planner overpromising a guaranteed future ride.** Symptom: the day planner (Section 4.10) UI or copy implies a specific future stage is "booked" with a committed driver/time before that stage's real-time matching has actually started, or a stage silently auto-commits a rider to a trip without an explicit tap. Fix: *"This violates Section 4.10 — the planner may have the next stage ready and may proactively surface it, but matching only starts at the real-time-appropriate moment, and committing to a specific trip still requires the rider's one-tap confirmation like any other trip. Correct the copy/logic so nothing is implied or executed as booked before it actually is."*

**FM24 — Silent alighting-point change bypassing the ledger.** Symptom: a trip's `alighting_stage_id` is updated directly (e.g., by a support tool, a GPS auto-adjustment, or an ad hoc script) without going through the Section 4.12 propose/accept flow, without a `trip_extensions` record, and without a corresponding `driver_ledger_entries` debit for the incremental commission. Fix: *"This violates Section 4.12 — any change to a trip's destination after boarding must go through the explicit propose/accept flow and post an auditable ledger entry for the fare delta. A direct field update with no audit trail is exactly the kind of change Section 4's append-only ledger rule exists to prevent. Route this through the proper flow instead."*

**FM25 — Multi-leg decomposition crowds out an available direct match.** Symptom: the planner returns or defaults to a transfer-based itinerary while a viable direct-to-destination driver was available — either because the direct-match search (Section 4.2.1) was never run, was skipped once a multi-leg decomposition was found, or excluded driver-declared routes (Section 4.7) from consideration. Fix: *"This violates Section 4.2.1 — the direct-match search must run independently of and alongside the decomposition search, checking parked, roaming, and driver-declared-route sources, and a viable direct match must win the Recommended default. Show a test case with both a viable direct match and a valid decomposition present, confirming the direct option is surfaced and ranked first."*

**FM26 — Park inferred from non-park clustering.** Symptom: the driver-location clustering job (Section 4.5.3) flags a location as a candidate park based on spatial density alone — a fuel station, mechanic's row, or checkpoint queue where vehicles congregate for an unrelated reason gets treated as a park. Fix: *"This violates Section 4.5.3 — a candidate park requires both a distinct-driver-count threshold and a multi-day recurrence threshold, not spatial density in a single time window. Show the test case with a dense but non-recurring or single-purpose cluster and confirm it is correctly withheld from candidate-park status."*

**FM27 — Raw, unmatched GPS used for map or route inference.** Symptom: road-geometry correction or route-corridor inference (Section 4.5.4) runs directly on raw GPS traces instead of map-matched ones, producing corrupted geometry or phantom route proposals from ordinary GPS noise. Fix: *"This violates Section 4.5.4 — every trace must be map-matched (via OSRM's Match service or equivalent) before any geometry or route inference runs on it. Show where map-matching happens in this pipeline before the inference step."*

**FM28 — New tracking introduced for map-building instead of reusing existing traces.** Symptom: a new location-permission scope, background-tracking mode, or data-collection mechanism is added specifically to support Section 4.5.4's map/route intelligence, rather than reusing `driver_live_path`, `rider_live_path`, and `driver_presence` data already collected for trip tracking and live discovery. Fix: *"This violates Section 4.5.4's explicit reuse requirement — no new permission scope may be introduced for this capability. Rework this to operate on data already collected under Section 4.1 and Section 4 for its original purpose."*

**FM29 — Automated submission to OpenStreetMap.** Symptom: a road-geometry correction (Section 4.5.4) is submitted to OpenStreetMap automatically, without human review, risking low-quality edits and damage to Along's standing in the OSM community. Fix: *"This violates Section 4.5.4 — any external OSM contribution must be human-reviewed before submission, exactly like every other candidate correction in this spec. Internal use of the correction (Along's own supplementary layer) does not require this review gate; external publication does."*

**FM30 — Treating build urgency as license to skip a gate.** Symptom: a Worker or Orchestrator reads Section 0.1's continuous-execution directive as permission to skip a Reviewer pass, weaken acceptance criteria, or move on from a "PASS WITH NOTES" without resolving the notes, in the name of speed. Fix: *"Section 0.1/Constitution principle 10 are explicit that velocity comes from continuous operation and parallelization, never from weakening Section 6's gates — a skipped gate produces rework, which costs more total time than doing it right once. Re-run the full gate checklist properly before proceeding."*

**FM31 — Pricing offered on an already-resolved fare.** Symptom: the Along Pricing negotiation UI (Section 4.3.1) appears on a trip with a resolved Tier 0, 1, or 2 fare, contradicting Constitution principle 4 (fare transparency, not fare-setting) and undermining the trust that a known route has one honest price. Fix: *"This violates Section 4.3.1 — Pricing is scoped strictly to genuine Tier 3 gaps and the explicit mid-trip extension flow, never offered as an alternative to a resolved fare. Confirm the fare tier before deciding whether Pricing applies, and remove it from this path."*

**FM32 — Unbounded or open-ended negotiation.** Symptom: an Along Pricing exchange has no enforced round cap or per-round timeout, allowing it to drag on in a way that doesn't fit the on-the-go context it was built for. Fix: *"This violates Section 4.3.1 — every negotiation round needs a short, visible countdown, and the exchange as a whole needs a hard round cap with a one-tap split-the-difference fallback. Add the missing bound rather than allowing indefinite back-and-forth."*

**FM33 — Negotiated fare not fed back into the along-graph.** Symptom: an agreed Along Pricing amount is used for its own trip but never submitted to Section 4.5's `fare_corrections` pipeline as a candidate data point, wasting the opportunity to reduce future reliance on negotiation for that stage pair. Fix: *"This violates Section 4.3.1 — every agreed negotiation must post as a candidate fare data point. Without this, Pricing never improves the map the way it's designed to; it just repeats the same negotiation indefinitely on the same route."*

**FM34 — Ad hoc load surcharge outside the fare/commission pipeline.** Symptom: a driver charges extra for load on the spot, outside both a declared standard surcharge and an Along Pricing negotiation, so the surcharge never enters the fare/commission calculation in Section 4.4. Fix: *"This violates Section 4.13 — any load surcharge must be either a declared standard fare component or resolved via Along Pricing, and must be included in commission like any other part of the fare. An undocumented on-the-spot charge is exactly the kind of commission leakage Section 4.4 exists to prevent."*

**FM35 — Load flag hidden from the driver until after acceptance.** Symptom: a rider's load flag (Section 4.13) is not shown to the driver as part of the request they're deciding on, only surfacing after the driver has already accepted — producing an on-road refusal after commitment instead of an informed decision beforehand. Fix: *"This violates Section 4.13 — the load flag must be part of the information a driver sees before accepting, not revealed afterward. Move this field into the pre-accept request view."*

**FM36 — No proactive mode-suitability warning for load.** Symptom: a rider flags load against a mode with little or no boot capacity (e.g., okada, keke) and the app sends the request without warning, producing an avoidable decline. Fix: *"This violates Section 4.13 — check the mode's load-capacity configuration before sending the request and warn the rider first. This is a config lookup, not a hardcoded per-mode rule per Constitution principle 3."*

**FM37 — Fixed timeout used for roaming Pricing regardless of vehicle ETA.** Symptom: a roaming-vehicle Pricing negotiation (Section 4.3.1) uses the same fixed round count/timeout as the park-based case, rather than deriving its time budget from the vehicle's actual live ETA to the rider. Fix: *"This violates Section 4.3.1's roaming-adaptation rules — derive the negotiation's time budget from live ETA data already available from Section 4.1, degrading to accept-or-skip only when ETA is very short. A fixed generic timeout doesn't reflect the physical reality of a moving vehicle."*

**FM38 — Negotiation not auto-lapsed when the vehicle moves out of pickup range.** Symptom: a roaming Pricing negotiation resolves as "agreed" even though the driver's live position has moved beyond a reasonable pickup radius from the rider during the exchange, producing a committed trip the driver can no longer actually fulfill at that location. Fix: *"This violates Section 4.3.1's safety valve — the negotiation must auto-lapse the moment the driver's live position exceeds the configured pickup radius, regardless of remaining round or time budget. Add this check independently of the round-cap/timeout logic."*

**FM39 — Advertising targeted from individual trip history.** Symptom: a sponsored placement (Section 4.14) is selected or targeted using an individual rider's personal trip history or identity, rather than aggregate context (a destination, park, or corridor). Fix: *"This violates Section 4.14's hard privacy boundary — sponsored placements key to aggregate context only, never to an individual's history, mirroring the same aggregation discipline already required for data exports in Section 4.5.4. Rework the targeting logic to remove any dependency on individual identity or trip history."*

**FM40 — API product exposing raw or individually-identifiable data.** Symptom: the data/analytics API (Section 4.14) returns raw trip records, individual driver/rider identities, or insufficiently aggregated data, rather than the same anonymized outputs already gated by human review elsewhere in this spec. Fix: *"This violates Section 4.14 — the API must surface only the anonymized, aggregated data products already defined in Section 4.5.4, through the same review discipline, not a new, less-guarded path to the underlying data. Add the missing aggregation/anonymization step before this ships."*

---

## 9. Definition of Done — Full Product

The "full product" (as distinct from the MVP) is done when:
- [ ] All phases in Section 7 have an exit-criterion PASS logged in `BUILD_LEDGER.md`
- [ ] The Phase 11 security/performance audit has zero open critical/high findings
- [ ] A second Nigerian city has been onboarded using only ops tooling (proving Phase 7/9's "config not code" claim in practice, not just in principle)
- [ ] The Phase 10 pan-African portability review has been signed off, even if no international market has launched yet
- [ ] Documentation (Phase 12) allows a new engineer to onboard without a live walkthrough

This is intentionally a high bar — it is the bar for "the platform is built the way the business plan says it will scale," not merely "the app works in Abuja."
