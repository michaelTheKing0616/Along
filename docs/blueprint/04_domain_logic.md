# 04 — Domain Logic (algorithms & state machines)

Spec references in each section. Pseudocode is language-neutral; the *layer* column says where it is implemented (doc 01 §4). Every algorithm here has at least one `TS-*` scenario in doc 10; a Worker implementing a section must implement its scenarios in the same task.

Config values are written `cfg.<key>` and resolve through `cfg(key, city_id, corridor_id)` (doc 02 §2.3). No literal thresholds in code.

---

## 1. Geometry helpers (SQL)

```
distance_m(a, b)            = ST_Distance(a::geography, b::geography)
bearing_deg(a, b)           = degrees(ST_Azimuth(a::geometry, b::geometry)) normalised to [0,360)
angle_diff(h1, h2)          = min(|h1-h2|, 360-|h1-h2|)
geohash(p, precision)       = ST_GeoHash(p::geometry, precision)
sector8(bearing)            = floor(((bearing + 22.5) mod 360) / 45)      -- 0=N,1=NE,…,7=NW
walk_s(distance_m)          = distance_m / cfg.planner.walk_speed_mps     -- fallback when OSRM absent
```

## 2. Stage snapping (SQL `snap_stage`) — §4.7, FM18

```
snap_stage(p, radius = cfg.graph.snap_radius_m, city = city_for_point(p)):
  candidates = route_stages s join routes r on r.id=s.route_id
               where r.city_id = city and r.active and ST_DWithin(s.location, p, radius)
  order by (s.verification_status desc: field_verified > crowd_verified > candidate), distance_m(s.location, p)
  return first or null
```
Tie-breaking prefers verified stages so drivers snap onto the canonical graph rather than another driver's candidate. Creating a new stage when `null`: dedupe against *candidate* stages within `cfg.graph.stage_merge_radius_m` (reuse if found) before inserting.

---

## 3. Fare resolution — §4.3 (SQL `resolve_fare`)

Signature:
```
resolve_fare(route_id?, profile_id?, from_stage_id?, to_stage_id?, from_point?, to_point?, mode_code, city_id, load?)
  → { amount, currency, tier, confidence, components[], unconfirmed }
```
Exactly one of `(route_id, from_stage, to_stage)` or `(profile_id, from_point|stage, to_point|stage)` or `(from_point, to_point, mode)` (Tier 3 anchor only) is required.

```
resolve_fare(...):
  components = []

  -- Tier 0: driver-declared price on their own route profile (§4.3 Tier 0, §4.7 step 5)
  if profile_id:
     stops = driver_route_stops for profile ordered by sequence
     b = stop nearest to from (matching stage id, else within cfg.graph.snap_radius_m of from_point)
     a = stop nearest to to   (same rule)
     if b and a and b.sequence < a.sequence:
        amount = b.price_to_end - a.price_to_end             -- always ≥ 0 by trigger invariant
        components += {kind:'profile', ref_id: profile_id, amount}
        tier = 0; confidence = 1.0
        goto SURCHARGE

  if route_id:
     -- Tier 1: known through-fare for exactly this pair
     tf = route_through_fares where (route_id, from_stage_id, to_stage_id) and verification_status <> 'candidate'
     if tf: components += {kind:'through_fare', ref_id: tf.id, amount: tf.fare_amount}
            tier = 1; confidence = tf.confidence_score; goto SURCHARGE

     -- Tier 2: sum of adjacent legs between the stages
     legs = route_legs on route where from_stage.sequence ≥ seq(from) and to_stage.sequence ≤ seq(to), ordered
     if legs cover every hop and none missing:
        components += one {kind:'leg', ref_id, amount} per leg
        tier = 2; confidence = min(legs.confidence_score); goto SURCHARGE

     -- candidate through-fare exists (unverified) → use as Tier 3 anchor, still unconfirmed
     tfc = route_through_fares candidate for pair
  
  -- Tier 3: proportional estimate, explicitly unconfirmed (§4.3 Tier 3, FM8)
  d = distance along route path between stages if route.path else straight-line distance_m(from_point,to_point) × 1.3
  ref = nearest verified legs on same mode within 3 km of the midpoint (limit 20):
        rate_per_km = median(fare_amount / (distance_m/1000)) with fallback cfg.fare.default_rate_per_km[mode]
  anchor = round_to_minor(max(cfg.fare.min_fare[mode], rate_per_km × d/1000))
  if tfc: anchor = tfc.fare_amount                           -- a candidate price beats a model
  components += {kind:'estimate', amount: anchor}
  tier = 3; confidence = 0.3; unconfirmed = true

SURCHARGE:
  if load.flagged:
     if profile_id and profile.load_surcharge_amount is not null:
        components += {kind:'load_surcharge', amount: profile.load_surcharge_amount}     -- §4.13 standard add-on
     else: load_surcharge_pending = true      -- resolved by negotiation context='load_surcharge' or waived; never silent

  amount = sum(components.amount)
  insert fare_quotes(...) ; return with quote_id
```

Invariants (TS-FARE-*): mid-route boarding never yields the full-route price when a Tier 1/2 value exists; Tier 3 output always has `unconfirmed=true`; Tier 0 requires `b.sequence < a.sequence` (direction matters); currency is the city's.

Commission at completion (§4.4): `commission_amount = round_to_minor((fare_shown + load_surcharge_amount) × commission_rate)`, where `commission_rate` was snapshotted at request time. Extensions: `commission_delta = round_to_minor(fare_delta × commission_rate)`.

---

## 4. Planner — candidate generation (SQL functions called by Edge `plan-trip`) — §4.2

Inputs: `origin`, `destination`, `filters{women_only, load, modes}`, `city = city_for_point(origin)`.

### 4.1 Destination coverage set
```
dest_stages = route_stages within cfg.planner.dest_radius_m of destination (any route, active)
origin_stages = route_stages within cfg.planner.walk_radius_m of origin
```

### 4.2 Direct candidates (`planner_direct_candidates`) — §4.2.1 explicit direct-first search
Runs three sources; all results are `kind='direct'`:

```
-- (a) parked at a park/stage near origin whose route reaches a dest stage downstream
for p in driver_presence where status='at_park' and nearest_stage_id in origin_stages and driver_is_matchable(driver):
   for r in routes serving p.nearest_stage_id (via route_stages) with mode filter:
      a = first stage on r after p.stage with a ∈ dest_stages
      if a: emit {source:'parked', route_id: r, board: p.stage, alight: a, mode: r.mode, supply: count bucket of matchable parked drivers at that stage for r}

-- (b) roaming vehicle heading toward destination (§4.1 plausibility, doc 04 §7.2)
for v in driver_presence where status='roaming_available' and ST_DWithin(v.location, origin, cfg.planner.walk_radius_m) and driver_is_matchable(v.driver) and seats_available ≥ 1:
   if plausible(v, destination):
      emit {source:'roaming', board: nearest stage to origin on v's declared route or origin point itself, alight: dest stage on declared route or destination point,
            mode: v.vehicle.mode, eta_band_s: distance_m(v.location, origin)/max(v.speed_mps, 3) rounded 60, candidate_token: sign(v.driver_id, v.session_id, 60s)}

-- (c) driver route profile covering both ends, driver online (present) or recently active
for s in driver_route_stops joined to profiles where active:
   b = stop within walk_radius of origin, a = stop later in sequence within dest_radius of destination
   if b and a: emit {source:'driver_profile', profile_id, board: b, alight: a, mode: profile.mode, profile_present: exists presence row}

-- (d) graph-only direct (no live supply signal, but a verified route connects the two)
for r in routes where a stage ∈ origin_stages precedes a stage ∈ dest_stages: emit {source:'graph', ...}
```
Dedupe on `(route_id|profile_id, board, alight)`, preferring sources with live supply (parked/roaming > profile_present > graph).

### 4.3 Multi-leg decomposition (`planner_decompose`) — up to `cfg.planner.max_legs`
```
G = directed graph: nodes = route_stages; edges = route_legs (weight = in_vehicle_time_estimate_s + wait) + transfer edges at transfer_points (park_id → stages of connected routes, weight = transfer_time_s + walk)
start set = origin_stages (edge weight = walk_s from origin); goal set = dest_stages (+ walk to destination)
run k-shortest-paths (Yen, k = cfg.planner.max_candidates) with constraint transfers ≤ max_legs-1 using a recursive CTE bounded by depth and a visited-routes set (no route reused)
group paths into legs by route change; each leg → resolve_fare(route, first_stage, last_stage)
emit {kind:'multi_leg', legs[], transfers[]}
```
Also runs when direct candidates exist (§4.2.1 both searches always run).

### 4.4 Metrics per candidate (Edge `plan-trip`, pure TS, unit-tested)
```
walk_total_m   = origin walk + Σ transfer walks + final walk       (OSRM foot table; fallback straight-line×1.3)
wait_s         = Σ legs: parked → mode.default_dwell_s/2 ; roaming → eta ; profile/graph → route_leg.avg_wait_time_estimate_s or cfg.planner.default_wait_s
in_vehicle_s   = Σ legs: route_leg.in_vehicle_time_estimate_s (calibrated by segment_speed_profiles for hour/dow when available) else OSRM car route duration × cfg.planner.shared_vehicle_factor (1.25)
total_time_s   = walk_s(walk_total_m) + wait_s + in_vehicle_s + Σ transfer_s
total_fare     = Σ legs.fare.amount (+ load surcharge components)
transfer_count = legs.length - 1
strenuousness  = W.transfer×transfer_count + W.walk_per_100m×(walk_total_m/100) + W.mode×max(legs.mode.comfort_weight)/10       (W = cfg.planner.strenuous_weights)
```

---

## 5. Ranking — §4.2.2

```
normalise(x, set) = (x - min(set)) / max(max(set)-min(set), ε)      -- per criterion across the candidate set
recommended_score = w.fare×norm(total_fare) + w.time×norm(total_time_s) + w.strenuous×norm(strenuousness)     (lower is better; w = cfg.planner.recommended_weights)
explain = {fare: w.fare×norm(fare), time: ..., strenuous: ...}         -- surfaced to the UI as "why recommended"

sort_orders:
  cheapest        = by total_fare, then total_time_s
  fastest         = by total_time_s, then total_fare
  least_strenuous = by strenuousness, then transfer_count, then total_fare
  recommended     = by recommended_score, then total_time_s
```

**Direct-first constraint (§4.2.1, FM6):**
```
best_alt = min total_time_s over multi_leg candidates (∞ if none)
for d in direct candidates:
   d.viable_direct = d.total_time_s ≤ cfg.planner.direct_viability_factor × best_alt + cfg.planner.direct_viability_slack_s
if any viable_direct: recommended[0] must be the viable direct with the lowest recommended_score (stable-move to front)
```
Unviable directs stay in the set (rider may still choose them) but are labelled `viable_direct=false`.

**Load filter (§4.13, FM36):** candidates whose max mode `load_capacity` is in `cfg.load.warn_capacities[load.size]` are *kept* but carry `load_warning`; UI warns before request.

**Women-only filter:** when `filters.women_only`, drop parked/roaming/profile candidates whose driver lacks `women_only_eligible`; graph-only candidates remain with `supply.kind='graph'` (the eventual driver must be eligible at `request_trip`).

---

## 6. Promotion pipeline — §4.5 (SQL, pg_cron `promote_candidates`)

### 6.1 Trust weights (`compute_trust_weights`)
```
rider:  w = 0 if account_age_days < cfg.trust.rider_min_age_days
        else min(cfg.trust.rider_cap, cfg.trust.rider_base + cfg.trust.rider_per_trip × completed_trips)
driver: w = cfg.trust.driver_verified if verified else cfg.trust.driver_unverified
field_agent: 3.0 ; admin: 3.0 (admin confirmations are still logged, never bypass the pipeline silently)
```
Weight is snapshotted into `graph_confirmations.trust_weight` at confirmation time.

### 6.2 Independent confirmation (§4.5.1)
A confirmation counts once per `(target, confirmer_profile_id)` (unique constraint). Confirmations from accounts sharing a device fingerprint or phone-prefix cluster flagged by doc 12 §6 are down-weighted × `cfg('promotion.collusion_downweight')` (default 0.25; recorded in `meta`).

### 6.3 Promotion
```
for each target (route_stage | route_leg | route_through_fare | park) with status='candidate':
   confs = graph_confirmations for target
   canonical = candidate's current value (fare or location)
   agreeing = confs where |proposed - canonical| within tolerance:
        fare: ≤ cfg.promotion.fare_tolerance_pct × canonical ; location: ≤ cfg.promotion.location_tolerance_m
   W = Σ agreeing.trust_weight ; N = count(distinct confirmer) among agreeing
   if W ≥ cfg.promotion.threshold_weight and N ≥ cfg.promotion.min_distinct_accounts:
        set verification_status='crowd_verified', confidence_score = min(0.9, 0.5 + 0.1×N), independent_confirmation_count = N
        write graph_revisions(reason='promotion')
   disagreeing = confs not agreeing
   if Σ disagreeing.trust_weight ≥ cfg.promotion.threshold_weight:
        -- sustained disagreement: update canonical to weighted median of ALL confirmations, keep 'candidate', flag for review
        insert fare_corrections(status='pending', submitter_role='system', proposed=weighted_median)
```
`field_verified` is set only by `admin_publish_field_entity` after two-scout reconciliation — never by this job.

### 6.4 Outlier guard (§4.5.1 "sharp deviation")
Before accepting a *rider/driver* confirmation into the pipeline, compare its fare to neighbours: `neighbours = verified fares on same route ± 2 stages`; `mad = median absolute deviation`; if `|proposed - median| > cfg.promotion.outlier_mad_k × mad` → store confirmation with `meta.outlier=true`, exclude from W, and enqueue a `fare_corrections` review row.

### 6.5 Decay (`decay_confidence`, daily)
```
for crowd_verified targets where fare_last_verified_at (or last agreeing confirmation) < now() - cfg.promotion.decay_window_days:
   confidence_score -= cfg.promotion.decay_step
   if confidence_score < 0.5: verification_status = 'candidate' (re-validation required), write graph_revisions(reason='decay')
```
Every Tier 1/2 quote used in a completed trip whose `confirm_fare='as_shown'` counts as an agreeing confirmation from that rider (weight per §6.1), so live routes self-refresh.

---

## 7. Presence — §4.1

### 7.1 Status rules (`set_presence`, `presence_ping`)
- `set_presence(offline)` → `delete from driver_presence` (row gone = not visible anywhere; FM10).
- Non-offline requires: `verified_status='verified'`, `driver_is_matchable()`, an active vehicle; `at_park` requires `park_id` within 150 m of location.
- `presence_ping` updates location/heading/speed/`nearest_stage_id = snap_stage(location, 2×snap_radius)` and appends history. Interval violation (< 2 s) → drop silently (no error storm).
- Staleness: `last_ping_at < now() - cfg.presence.stale_after_s` → excluded from ambient/planner; `< now() - offline_after_s` → row deleted, `driver:{id}` channel receives `{type:'presence_dropped'}`.

### 7.2 Direction plausibility (`plausible(v, destination)`)
```
if v.declared_route_profile_id or v.declared_route_leg_id:
    return exists stage downstream of v.nearest_stage on that route within cfg.planner.dest_radius_m of destination
else:
    b = bearing_deg(v.location, destination)
    return v.speed_mps < 1 or angle_diff(v.heading, b) ≤ cfg.planner.heading_tolerance_deg
```
A stationary roaming vehicle (speed < 1 m/s) is plausible for any direction (it can turn), which mirrors real hailing.

### 7.3 Ambient aggregation (`ambient_vehicles`, `presence-fanout`)
```
rows = driver_presence where fresh and matchable and ST_DWithin(location, p, radius)
group by geohash(location, cfg.presence.ambient_cell_precision), mode_code:
   count_bucket = bucket(count): 1-2 | 3-5 | 6+
   heading_sectors[8] += 1 per vehicle sector8(heading) (stationary → sector of nearest stage bearing or omitted)
   eta_band_s = min over rows of (distance_m(location, p) / max(speed, 3)) rounded up to 60
   serves_destination = any plausible(row, destination) when destination supplied
```
Never emit a cell for a single vehicle whose cell centroid is < 80 m from its true location *and* the rider is > 200 m away? — No special case: the cell centroid is a fixed grid point, never the vehicle's position, so `1-2` in a ~1.2 km × 0.6 km cell reveals nothing actionable. (Precision 6 is the minimum allowed; config validation rejects precision > 6.)

### 7.4 Ambient demand (driver side)
`planner_queries` in the last 15 min grouped the same way; `top_destination_directions` = sector8(bearing(origin, destination)) top-2. No rider ids.

---

## 8. Along Pricing — negotiation state machine — §4.3.1 (SQL state + Edge clock)

### 8.1 Eligibility gate (FM31)
`open_negotiation` first runs `resolve_fare`. If `tier ≤ 2` → `STATE_INVALID` ("standard fare exists"). Only `tier = 3` (or `context ∈ {extension, load_surcharge}` whose delta resolved to tier 3) proceeds; the tier-3 anchor is the opening amount.

### 8.2 Parameters by context
```
park:       round_cap = cfg.negotiation.park.round_cap ; round_timeout = cfg.negotiation.park.round_timeout_s ; eta_band = null
roaming:    eta_s = distance_m(v.location, rider) / max(v.speed_mps, 3)
            eta_band = 'none'   if eta_s ≤ cfg.negotiation.roaming.eta_none_s      → round_cap = 0  (accept/skip only)
                     = 'single' if eta_s ≤ cfg.negotiation.roaming.eta_single_s    → round_cap = 1
                     = 'full'   otherwise                                           → round_cap = cfg.negotiation.roaming.round_cap
            round_timeout = cfg.negotiation.roaming.round_timeout_s ; pickup_radius_m = cfg.negotiation.pickup_radius_m
            requires: driver has NO declared route profile covering the pair (FM39-adjacent; §4.3.1 "only roaming without route")
extension / load_surcharge: park parameters, attached to an existing trip
expires_at = now() + (round_cap+1) × round_timeout  (min 1×timeout)
```

### 8.3 Transitions
```
open --counter(amount)--> open        if rounds < round_cap and amount = last ± step, step ∈ cfg.negotiation.chip_steps, and now < expires_at
open --accept-------------> agreed     agreed_amount = last amount; create fare_quote(tier 3, negotiated) ; create/attach trip ; fare_corrections(pending, system)
open --decline------------> declined
open --timeout------------> lapsed     (clock) ; UI shows "No agreement — skip or try nearby"
open --split--------------> open       only when rounds = round_cap: system round at midpoint; next accept → agreed
open --vehicle_out_of_range-> lapsed   roaming only: distance_m(v.location, rider) > pickup_radius_m and v moving away (FM38)
agreed/declined/lapsed = terminal
```
Rider and driver alternate; a party cannot counter twice in a row. Every round is a row in `price_negotiation_rounds`. The Broadcast channel mirrors each change; the client derives the countdown from `expires_at` (never a client-side timer as source of truth).

---

## 9. Auto-boarding by co-location — §4.6 (SQL `auto_boarding_check`, invoked from `trip_location_sample`)

```
given trip in status accepted, latest rider sample R and driver sample D (both ≤ 15 s old, accuracy ≤ 50 m):
   colocated = distance_m(R, D) ≤ cfg.boarding.colocation_radius_m
   track window in trips.meta.colocated_since (set on first colocated, cleared when not)
   if colocated for ≥ cfg.boarding.colocation_duration_s
      and (D.speed_mps ≥ cfg.boarding.min_speed_mps or R.speed_mps ≥ cfg.boarding.min_speed_mps)   -- both moving together, not both waiting
      → trip_transition(accepted → boarded, actor=system, boarded_via='auto_colocation')
in_transit auto: boarded + driver speed ≥ 3 m/s for 30 s → in_transit (actor=system)
```
Manual override `mark_boarded` is always available (dense indoor pickups). If the rider has no location permission, only manual/driver boarding applies.

---

## 10. Trip state machine (SQL `trip_transition(trip_id, to_status, actor_type, actor_id, reason, meta)`)

```
requested  → accepted              driver (respond accept) ; requires driver_is_matchable(); sets driver_id/vehicle_id if roaming cascade
requested  → declined              driver (respond decline) ; roaming: dispatch cascade may re-point trip (new dispatch_attempt) instead of terminal
requested  → expired               system (clock)          ; roaming cascade as above
requested  → cancelled_by_rider    rider
accepted   → boarded               system(auto) | rider | driver
accepted   → cancelled_by_rider    rider  (reconciliation-relevant: no)
accepted   → released_before_arrival  driver via `release_match` only; rider never entered pickup radius; **not** reconciliation-relevant
accepted   → cancelled_by_driver   driver (reconciliation-relevant: yes, §4.4.2 candidate for premature_conversion)
accepted   → no_show               driver, after cfg.dispatch.no_show_after_s at pickup
boarded    → in_transit            system(auto) | driver
boarded    → cancelled_by_driver   driver (reconciliation: yes)
boarded    → cancelled_by_rider    rider
in_transit → completed             driver ; posts commission (cash) ; materialises paths ; journey advance
in_transit → cancelled_by_driver   driver (reconciliation: yes — strongest signal)
in_transit → cancelled_by_rider    rider  (reconciliation: driver trace still checked for undeclared completion)
terminal: completed, declined, expired, cancelled_*, no_show, released_before_arrival
```
Implementation rules: the function sets `along.in_transition=on` so the guard trigger permits the status write; writes `trip_events`; sets timestamp columns; any other path raises `ALONG:STATE_INVALID`. Completion inside the same transaction: `commission_amount` computed; if `payment_method='cash'` → `ledger_post(cash_commission_debit, -commission_amount, idempotency 'trip:{id}:commission')`; if `payment_method='digital'` (a succeeded `payments` row already exists) → no ledger entry, commission was collected at source. **Late digital payment** (webhook after completion, doc 14 §4.3): the webhook handler sets `payment_method='digital'` and posts `ledger_post(digital_settlement_credit, +commission_amount, 'trip:{id}:digital_offset')` so the earlier cash debit nets to zero — never delete or edit the debit (append-only); `driver_live_path`/`rider_live_path` = `ST_MakeLine(samples ordered by ts)`; `journeys.current_trip_sequence++` or `journeys.status='completed'`; `riders.trip_count++`.

**Roaming dispatch cascade (Edge `dispatch`):** on `declined|expired` for `dispatch_attempt < cfg.dispatch.max_cascade` and `source='roaming'`, pick next plausible driver in the same cell (excluding already-tried), set `trips.driver_id/vehicle_id`, `dispatch_attempt++`, `expires_at = now()+ttl`, back to `requested` (recorded as `trip_events requested→requested` with `meta.retarget=true`), notify new driver. Otherwise terminal `expired` and rider is told to replan.

## 11. Journey state machine
```
planning → active      first trip accepted
active   → transfer    trip k completed and k < legs
transfer → active      trip k+1 accepted
active   → completed   last trip completed
any      → abandoned   rider cancels journey or 60 min without activity
```
Wayfinding for the transfer walk is issued at `active→transfer` (pre-fetched when trip k is `in_transit` with ETA ≤ 5 min).

### 10.5 Wait / approach (spec §4.1.2–4.1.3)

`approach_band(walk_s)`: if `walk_s < cfg.disclosure.approach_band_s[0]` → `under_2`; elif `< [1]` → `m2_5`; else `over_5`. `walk_s` from Edge `walking-directions` (OSRM foot) between rider last-known point (or pickup pin) and driver last-known point. **Never return `walk_s` on a `requested` TripView.**

After accept, `refresh_wait(trip)` (on each rider/driver sample, throttled 10 s): `walk_eta_s` = same OSRM foot duration; `approach` = `unknown` if rider samples in `wait.stalled_window_s` < 2; `stalled` if progress toward vehicle `< wait.stalled_progress_m`; else `approaching`. Broadcast `{type:wait,...}` on `trip:{id}`. Fixture for FM41: two points 80 m apart with a blocked canal in the extract → straight-line ~80 m, foot route > 8 min; driver UI must show the foot figure.

`release_match`: `accepted` only; reject if any rider sample within `wait.release_pickup_radius_m`; status `released_before_arrival`.

`rider_no_show_review` (nightly): riders with ≥ `rider.no_show_review_count` of `{no_show, released_before_arrival}` in `rider.no_show_window_days` → flag `rider_no_show_pattern` (admin only, FM43).

---

## 12. Ledger, thresholds, standing — §4.4.1, §4.4.3

### 12.1 `ledger_post(driver_id, entry_type, amount, currency, refs, idempotency_key, actor)`
```
perform pg_advisory_xact_lock(hashtext(driver_id::text))
if exists entry with idempotency_key → return existing (IDEMPOTENT_REPLAY)
prev = coalesce((select balance_after from entries where driver_id order by id desc limit 1), 0)
insert entry(balance_after = prev + amount)
return entry
```
The advisory lock serialises per driver so `balance_after` is exact; the `driver_balances` view is the authoritative read, and TS-LEDGER-01 asserts the two agree.

### 12.2 `driver_is_matchable(driver_id)` — single choke point (§4.4.1)
```
d = drivers ; b = driver_balances.balance (0 if none)
return d.verified_status = 'verified'
   and d.standing in ('good_standing','warned')
   and b > cfg.ledger.block_threshold(city)
```
Called by: `request_trip` (parked/profile target), `dispatch`, `respond_to_trip(accept)`, `set_presence(non-offline)`, `planner_direct_candidates` (so counts are honest), `ambient_vehicles`. Same function for park and roaming paths (FM11).

### 12.3 Threshold policy (`apply_threshold_policy`, system actor, every 10 min)
```
for each driver with balance b:
  if b ≤ cfg.ledger.block_threshold and standing='good_standing'|'warned' → transition_standing(matching_paused, reason='balance_below_block_threshold')
  elif b ≤ cfg.ledger.warn_threshold and standing='good_standing' → transition_standing(warned, reason='balance_below_warn_threshold'); notify with grace deadline = now()+grace_period_hours
  elif b > cfg.ledger.warn_threshold and standing in ('warned','matching_paused') and standing_since reason was balance-based → transition_standing(good_standing, reason='balance_restored')
  deposit drawdown: if standing='matching_paused' for > grace_period_hours and deposit_held > 0 → ledger_post(deposit_drawdown, -min(deposit_held, -b))
  if b ≤ cfg.ledger.deactivate_threshold or (matching_paused for > cfg.ledger.deactivate_after_days) → queue for human review (NOT automatic deactivation); notify ops_lead; guarantor referral is a manual runbook step
```

### 12.4 Standing ladder (`transition_standing`) — §4.4.3
```
good_standing → warned → matching_paused → guarantor_referred → deactivated
downward by system only for the first two steps and only on ledger balance; every downward step ≥ matching_paused→guarantor_referred requires an admin actor with reason
upward: any → good_standing when balance restored (system) or admin decision
reactivation from deactivated: admin only, requires settlement to ≥ 0 and reason
every transition → driver_standing_transitions + notification (driver sees the reason and the settle CTA — Phase 4 gate)
```
Flags from §13 never call `transition_standing` (FM13).

---

## 13. Cash-integrity reconciliation — §4.4.2 (pg_cron `reconcile_cancelled_trips`)

Input: trips with `status ∈ {cancelled_by_driver}` from `accepted|boarded|in_transit`, or `cancelled_by_rider` from `in_transit`, ended in the last 24 h, not yet flagged. **`released_before_arrival` is never a candidate** (spec §4.1.3).

```
for t in candidates:
  D = driver samples for t (and driver_presence_history for the 30 min after cancel, same session)
  R = rider samples for t
  dest = coalesce(t.alighting_location, alighting_stage.location)
  route_path = route.path or matched_trace or straight line board→alight

  driver_reached_dest = min distance_m(D.location, dest) ≤ cfg.reconciliation.dest_radius_m within 45 min after cancel
  driver_route_fraction = fraction of route_path within 60 m of D (Hausdorff-style coverage)
  rider_quality = none if |R| < 3 ; partial if last R older than 5 min before cancel ; good otherwise
  rider_reached_dest = rider_quality ≠ none and min distance_m(R, dest) ≤ dest_radius_m

  -- corroboration by other riders on the same driver in an overlapping window
  peers = trips where driver_id = t.driver_id and tstzrange overlaps t's window and id ≠ t.id
  corroborating = count(peers whose rider trace reaches within 200 m of dest around the same time)

  score = 0
  if driver_reached_dest and driver_route_fraction ≥ cfg.reconciliation.min_route_fraction: score += 0.5
  if rider_reached_dest: score += 0.3
  if corroborating ≥ 1: score += 0.2 × min(corroborating, 2)/2   -- capped
  if rider_quality = none and corroborating = 0: score = min(score, 0.5)   -- inconclusive band (FM15)

  if score ≥ 0.5: insert trip_reconciliation_flags(premature_conversion, score, evidence, rider_quality, corroborating)

-- undeclared extension (§4.12): completed cash trips where driver trace continues ≥ cfg.reconciliation.extension_gap_m beyond alight with the rider trace co-located → flag 'undeclared_extension'
```
Outcome is a *flag*, surfaced in admin (A-10) with all evidence; humans decide. `compute_risk_scores` aggregates per driver over 30 days for the review UI only.

---

## 14. Candidate parks from presence (`cluster_candidate_parks`, daily) — §4.5.3

```
pts = driver_presence_history where status in ('at_park','roaming_available') and speed_mps < 0.5 and ts > now() - cfg.clustering.window_days
      and not ST_DWithin(location, any existing park/stage, cfg.graph.stage_merge_radius_m)   -- exclude known
clusters = ST_ClusterDBSCAN(geometry, eps := cfg.clustering.eps_m (metres via projected SRID for the city), minpoints := cfg.clustering.min_points) over pts
for c in clusters:
   drivers = count(distinct driver_id) ; days = count(distinct date(ts))
   if drivers ≥ cfg.clustering.min_distinct_drivers and days ≥ cfg.clustering.min_distinct_days:
       insert candidate_park_clusters(status='new', centroid = ST_Centroid, ...)
       insert route_stages? — NO. Only on admin promote (A-14) does a stage/park get created with source_type='presence_cluster' and verification_status='candidate'.
```
Distinct-driver and distinct-day thresholds are what stop a single idle driver's home from becoming a park (FM26).

## 15. Trace intelligence (`backend/jobs`) — §4.5.4
- **Map-matching**: for each completed trip with ≥ 10 samples, call OSRM `match` (car profile, `radiuses` = accuracy) → `matched_traces` with `confidence`; drop matches < 0.6. Raw samples remain for reconciliation; graph work uses matched traces only (FM27).
- **Geometry corrections**: matched-trace segments with `confidence < 0.6` but ≥ `cfg.geometry.min_supporting_traces` (default 15) distinct trips within 20 m → `road_geometry_corrections(candidate)`; admin reviews before internal application; OSM contribution is a separate manual step.
- **Route inference**: cluster matched traces by (mode, origin cluster, destination cluster) with Fréchet distance ≤ 150 m; ≥ `cfg.inference.min_trips` (default 20) → `route_inference_candidates(new)`; admin promotes to `routes(candidate)` with `source_type='trace_inference'` (FM28).
- **Speed profiles**: per `osm_way_id:direction` × dow_bucket × hour_bucket, median speed from matched traces (≥ 8 samples). Planner uses them to scale `in_vehicle_time_estimate_s`; when live presence speed for the same segment exists in the last 10 min it takes precedence (real-time first, historical as fallback).

---

## 16. Na Me pairing — §4.8

Generation (in `request_trip`, before the row is returned):
```
palette = cfg.name.colors (8 token names) ; shapes = cfg.name.shapes (6)
in_use = id_signal pairs on the driver's trips in status accepted|boarded|in_transit  ∪  pairs on the rider's active trips
pick uniformly from palette×shapes minus in_use ; also avoid same color as any in_use pair (different shapes of one colour are hard to tell apart at a glance)
label = "{Color} {Shape}" localised (e.g. "Green Diamond" / "Kore Daya…" via i18n)
```
Delivery: part of `TripView` at request/accept time → both clients persist to local storage immediately (FM22). Trigger is entirely local: fullscreen fill in the colour with the shape, strobe at 4 Hz for 8 s, haptic pattern, optional torch strobe and TTS/sound where supported; a `{type:'na_me'}` Broadcast is best-effort informational only. Persistently visible as a compact chip on the active-trip screen for both parties until `boarded`.

## 17. Mid-trip extension — §4.12
`propose_extension` = `resolve_fare(route|profile, from = current alight (or current nearest stage), to = new)`; `fare_delta = new_quote.amount` (delta from current alight, not a re-price of the whole trip); `commission_delta = round(fare_delta × trip.commission_rate)`. On accept: `trips.alighting_* = new`, `trip_extensions.status='accepted'`, `ledger_post(cash_commission_debit, -commission_delta, 'ext:{id}')` if cash at completion time (posted at completion together with the base commission so a cancelled extension never bills). Tier 3 delta → negotiation `context='extension'` before accept.

## 18. Load flag — §4.13
- Journey-level (`journeys.load_*`) or itinerary-level (`itineraries.load_*`) once; copied to each trip at request.
- Warn (not block) when `mode.load_capacity ∈ cfg.load.warn_capacities[size]`; request requires `acknowledged_warning=true`.
- Driver pre-accept view always includes `load` (FM35). Decline reason `no_room_for_load` exists and is neutral to risk scores.
- Surcharge resolution order: profile standard surcharge → negotiation `context='load_surcharge'` → none. Never an unaccounted extra (FM36/§4.13).

## 19. Coverage gap — §4.9
`plan-trip` with zero candidates **and** no ambient cells within `walk_radius_m` → insert `coverage_gap_reports` and return `coverage_gap{nearest_stage, distance_m}` → client renders "No mapped routes here yet" + walking guidance to nearest stage (§4.11 shared) + "Set up your route" prompt in the driver app for drivers who go online in gap cells (A-side sees `ambient_demand`).

## 20. Wayfinding step model — §4.11
Steps from OSRM foot `route` with `steps=true`; instructions templated per locale (`turn.left`, `continue`, `arrive`) → text list, map polyline, and TTS script from the same array. Preference `riders.wayfinding_mode` decides the default renderer; all three are one tap apart.
