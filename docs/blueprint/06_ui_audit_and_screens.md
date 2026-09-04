# 06 — UI Audit & Screen Inventory

Spec references: §4.6 (one-tap), §4.1.2 (disclosure), §4.8, §4.9, §4.10, §4.11, §4.12, §4.13, §5.2, FM19–FM24, FM29–FM38. Tokens/components: doc 05. Reference screenshots: `docs/design/stitch-reference/<name>.png`.

Part A audits what Stitch produced. Part B is the complete, binding screen inventory. Where Part B says "Stitch ref", the Worker uses that screenshot for *layout intent only* — colours, type, copy and semantics come from doc 05 and this document.

---

## Part A — Audit of the Stitch screens

Verdicts: **ADOPT** (structure is world-class; re-skin to tokens) · **UPGRADE** (keep the idea, fix listed defects) · **REJECT** (wrong model or out of scope; design fresh per Part B).

| Stitch screen | Verdict | What's right | What's wrong (and the fix) |
|---|---|---|---|
| `trip_options_final_quality_pass` | **UPGRADE** | Card-per-option, mode chip, big right-aligned fare, meta row (walk/shared), sort chips, multi-leg "1 transfer" marker | Global "Confirm Ride" button forces select-then-confirm = 2 taps (violates §4.6). Fix: per-card `Request` (one tap) + undo snackbar. Missing "Least strenuous" chip, `TierPill` on every fare, "why recommended" explain, leg breakdown on multi-leg. |
| `trip_options_kinetic_sharp` | **REJECT** | Strong type hierarchy | "Along Premium / Along Keke / Along Okada" is Uber product-tier naming — Along has no fleet or tiers (FM1). Fare clipped ("₦4,5"). Yellow card + black text is good and reused for the *recommended* highlight. |
| `rider_home_final_quality_pass` | **UPGRADE** | Peek sheet with "Where to?" + recents; ambient cluster count badge; bottom nav Home/Trips/Account | Abstract gradient instead of a real map; "YOU ARE HERE" label; asterisk FAB overlapping the search field; SOS not appropriate on home (belongs to active trip). Fix: real vector map, `AmbientCluster` discs with heading ticks, no FAB, puck only. |
| `rider_home_sharp_edition` | **REJECT** | Greeting, clean search, real map | "Ride / Keke" mode cards *before* destination import the private-hire mental model; the planner returns all modes after destination (§4.2). Mode is never pre-selected. |
| `rider_home_nairobi_simulation` | **REJECT** | Demonstrates locale/currency formatting | Mode picker labelled "NA ME SIGNAL" (misuse); mode-first again. Keep only the lesson: currency formatting is locale-driven from `countries`. |
| `driver_incoming_request_final_quality_pass` | **UPGRADE** | Pickup/dropoff rows, fare, distance, Accept/Decline pair, ETA | Broken icon ligature text in header; rider photo (drop — safety/privacy; name + rating suffice); no **load flag** row (FM35); no countdown; no seats; "EST FARE" must be itemised fare vs "Along fee" (FM3); no women-only badge. |
| `driver_request_high_impact` | **UPGRADE** | Huge type, strong green Accept, black Decline — excellent glanceability while driving | "EST. EARNINGS" conflates fare and earnings (FM3). Accept colour: use `brand.yellow` (brand "go" colour) not green, so success semantics stay reserved. Keep proportions (Accept ≥ 60% width). |
| `rider_driver_na_me_signal_final_quality_pass` | **ADOPT** | Full-bleed shape+colour, "Look for this / show to driver", hold-to-strobe, "No signal required", plate visible post-match | "#42" number identifier → replace with text label ("GREEN DIAMOND"); direction should be a compass-rotating arrow, not text only. |
| `rider_active_trip_na_me` | **UPGRADE** | Map + SOS top-right + "In transit" sheet + Extend/Share actions | Missing persistent `NaMeChip`, per-leg `LegTimeline` with transfer ETAs (§5.2.3), driver+plate line, fare with tier. |
| `rider_multi_modal_itinerary` | **UPGRADE** | Per-leg cards (mode, board→alight, fare, "NEXT" badge, pickup time) | Olive CTA; add tier pills, transfer wait estimates, walk legs as dashed rows. |
| `rider_transfer_next_leg_refined` | **UPGRADE** | "Walk 3 mins to Ikeja Underbridge" hero; current/next leg cards; live availability skeleton | Asterisk FAB; add wayfinding mode switch (text/map/audio) and ambient count at the transfer park. |
| `rider_day_planner_final_quality_pass` | **ADOPT** | Timeline of stops: Completed / Next stage "Match now" / Pending; correct copy (not "booked") | Move "Add stop" to bottom; header consistency. |
| `driver_fast_route_setup` | **ADOPT** | "Is this your route? We detected your usual morning path"; stops with editable price chips; "Yes, publish" / "No, draw manually" — matches §4.7 exactly | Price semantics: show `price_to_end` ("to end: ₦400" at origin … ₦0 at last stop), not cumulative-from-origin. |
| `route_setup` | **UPGRADE** | Map-first, stop list, price per stop | Same price semantics fix; add snap chip ("Matched: Berger Junction ✓ / New stop") and the single "Publish" CTA. |
| `driver_verification_final_quality_pass` | **UPGRADE** | Document list, capture, save draft | Add OCR-assist review step, step indicator, per-document status chips, resubmission flow. |
| `driver_performance_ledger_detailed` | **UPGRADE** | Negative-balance yellow card with "Settle now"; entry list | Raw enum text (`cash_commission_debit`) shown to users → human labels; "Trust score" is just rating — label it "Rating". |
| `driver_ledger_precision` | **REJECT (semantics) / ADOPT (layout)** | Clean balance hero + grouped-by-day rows | "+₦850 Trip income" in the *ledger* is wrong: on cash trips the driver already holds the cash; only the commission debit posts (§4.4.1). Fix: two clearly separated sections — "Along balance" (ledger) and "Trips" (informational fares). |
| `driver_ledger_settlement` (black render) | **UPGRADE** | HTML content: balance, "Matching block limit −₦5,000", "Guarantor active", recent transactions | Render fresh from Part B D-19/D-20. |
| `driver_business_insights_final_quality_pass` | **UPGRADE** | Route-level metrics (avg wait) — demand insights (post-MVP §4.5) | "Ledger balance +12% today" mislabels earnings; charts must be tabular-friendly and load-light. |
| `rider_sos_active_alert_refined` | **UPGRADE** | Big status, hold-to-cancel, live location note | Copy overpromises ("Emergency services have been dispatched"). Along alerts its *safety line*, not the state's emergency services. Honest copy in R-23; add "Call 112" button. |
| `rider_report_incident` | **ADOPT** | Category grid, description, attach | Colours only. |
| `rider_route_setup_correction` | **ADOPT** | Adjust pickup pin + nearby parks list + confirm | Reuse as R-06b "Adjust pickup / snap to stage". |
| `rider_phone_entry_enhanced` | **ADOPT** | Clean field, country code, T&Cs, single CTA | Drop rocket icon; make this the *first* screen (welcome merged). |
| `rider_welcome_get_started` | **REJECT** | — | Olive; adds a step. Merged into phone entry. |
| `rider_otp_verification` (blank) | design fresh | | R-03. |
| `rider_enable_location` | **UPGRADE** | Clear rationale; manual alternative | Ask contextually at first search, not during onboarding. |
| `rider_splash_screen_enhanced` | **UPGRADE** | Logo on plain field | Use real logo on white; ≤ 800 ms; no cream. |
| `help_support_center` | **UPGRADE** | Categories, recent tickets, search | Bottom nav shows "Deliveries/Wallet" (out of scope, inconsistent). "Call Emergency" belongs to active trip; here it's "Safety centre". |
| `rider_refer_earn` | **UPGRADE (post-MVP)** | Code, share buttons, progress | AI illustration banner (off-brand; §5.2 no decoration); inconsistent nav. |
| `rider_cross_border_itinerary` | **REJECT** | — | Lagos→Nairobi with a "ticketed flight shuttle" is not a product feature; Along doesn't book flights or inter-city itineraries. |
| `admin_fraud_review_final_quality_pass` | **ADOPT** | Flag queue; side-by-side driver/rider traces; correlation callout; confidence score; Clear / Warn / Escalate actions | Add corroborating-rider count, event timeline, and make "Escalate" open the standing dialog (never automatic). |
| `admin_deployment_playbook_seed_data` | **ADOPT** | Foundation checklist, geofence, CSV drop, two-scout reconciliation queue with variance | Exactly the Phase 0 tooling. |
| `admin_corridor_operations_console` (`admin_ops_console`) | **UPGRADE** | Left rail: overlays (verified/candidate routes, live vehicles), pending corrections list | Map tiles repeated 4× (broken render); rebuild on MapLibre with our style. |
| `admin_pan_african_portability_config` | **ADOPT (taxonomy)** | Sidebar: Markets · Currency & rates · Identity verification · Reg & tax · i18n status | Page body mostly empty; A-18 fills it. |
| `corporate_staff_manager_final_quality_pass` | **UPGRADE** | Standard B2B overview, live trips, roster | Remove employee "Trust score" (surveillance smell, no data basis) → "Subsidy used MTD". |
| Logos | see doc 05 §1 | | Use the real `main_logo_along_*`. |

**Cross-cutting defects to never reproduce:** olive primary; asterisk placeholder FAB; inconsistent bottom navs (rider nav is exactly Home · Trips · Account; driver nav is Home · Routes · Earnings · Account); mode-before-destination; product-tier names; fare/earnings conflation; overpromising safety copy; decorative illustrations.

---

## Part B — Screen inventory

Format per screen: **Purpose** · **Entry** · **Anatomy** (top→bottom) · **Data** (endpoints) · **Actions** (tap count) · **States** (loading / empty / error / offline) · **Rules** (spec refs) · **Stitch ref**.

Global rules for every mobile screen: safe-area aware; back gesture always works unless a modal explicitly blocks it (SOS); every network wait > 300 ms shows a `Skeleton`; every action shows optimistic state immediately (§4.6); offline banner (`surface.inverse`, 32 dp) appears under the status bar when `connectivity=none`; text scale to 1.3× verified.

### B1. Rider app (R)

**R-01 Launch** — Purpose: brand + auth check. Anatomy: white, centred logo (`main_logo_along_black`, 60% width). ≤ 800 ms then route. No animation beyond fade. States: if session valid → R-05; else R-02.

**R-02 Phone entry (= welcome)** — Purpose: start OTP. Anatomy: logo small top-left; `heading.1` "Move around. Your way."; `body` "Enter your number to continue"; `PhoneField` (country picker limited to `countries.active`); legal line with links; `AlongButton primary` "Continue". Data: Auth `signInWithOtp`. Actions: 1 tap after typing. States: error inline (invalid number, rate-limited with retry-after). Stitch ref: `rider_phone_entry_enhanced`.

**R-03 OTP** — Anatomy: back; "Enter the 6-digit code sent to +234…"; `OtpField` (auto-advance, SMS retriever autofill on Android); resend (countdown 30 s); "Wrong number?". Auto-submits at 6 digits (0 extra taps). Errors: wrong code, expired.

**R-04 Name (optional)** — First launch only: "What should drivers call you?" single field, "Skip" allowed. Writes `complete_rider_onboarding`.

**R-05 Home** — Purpose: ambient awareness + start a search (§4.1.2, §4.6 options-first). Anatomy: full-bleed `AlongMap` (puck, `AmbientCluster` discs, parks at zoom ≥ 13); top-left menu → Account; top-right recenter (44) ; `BottomSheet` peek (96): `SearchField` "Where to?" + recents row (3 chips: Home/Work/last) ; half state adds "Nearby" list: per mode "3–5 kekes nearby · heading NE · ~3 min" rows (tap → R-07 prefilled with "hail" intent); bottom nav Home · Trips · Account. Data: `ambient_vehicles` + Broadcast `ambient:*`; `walking-directions` not yet. Actions: tap search (1) → R-06; tap nearby row (1) → R-07. States: location denied → banner "Enable location to see nearby vehicles" + manual pin; no vehicles → discs absent, no message (silence is honest); stale (> 60 s) → discs grey. Rules: never SOS here; never show a specific vehicle (Tier A). Stitch ref: `rider_home_final_quality_pass` (layout only).

**R-06 Destination search** — Anatomy: full sheet; `SearchField` focused with keyboard; below: recents, saved places, then autocomplete from `POST /functions/v1/places-search` (doc 03 §3: our own parks/stages via trigram match ranked first, then a self-hosted Photon/Nominatim index built from the same OSM extract — no Google Places, for cost and data-sovereignty reasons); each result shows name, area, distance. Also "Choose on map" → R-06b. Actions: tap result (1) → R-07. Voice mic button (post-MVP, STT → text). States: offline → recents only.

**R-06b Adjust pickup / choose on map** — Centre pin, "Adjust pickup"; nearby parks/stages list with distance; `Confirm location`. Snaps to a stage when within `graph.snap_radius_m` (shows "Boarding at: Berger Junction"). Stitch ref: `rider_route_setup_correction`.

**R-07 Trip options** — Purpose: the planner's full candidate set (§4.2.2). Anatomy: top map (40%) with origin/destination and the highlighted candidate's polyline (active leg solid, walk dashed); sheet: title "Choose how to go" + `SortChips` (Recommended · Cheapest · Fastest · Least strenuous; default from `saved_sort`); list of `OptionCard`s. Each card: mode chip column; title "Board at Lugbe Park → Area 1 Park"; meta "4 min walk · ~6 min wait · direct" or "1 transfer at Berger"; right: fare `numeric.l` + `TierPill`; `viable_direct=false` → subtle "Slower than transfer options" caption; load warning row if applicable; footer `Request ₦450` (48, primary). Recommended card has yellow border + "Recommended" badge + tappable "Why?" → explain popover (fare/time/effort bars). Multi-leg card expands (tap header, 1) to `LegTimeline` with per-leg fares and transfer waits. Data: `plan-trip`. Actions: Request (1) → R-10; change sort (1); flag load (1) → R-09. States: loading skeleton (3 cards); degraded → "~" on times + banner "Live times unavailable"; empty → R-18; expired quotes (10 min) → "Refresh options". Rules: `unconfirmed` fares show "Agree price" instead of a number-only Request → opens R-16 (FM8, FM31). Stitch ref: `trip_options_final_quality_pass`.

**R-08 (reserved)** — option detail is the in-place expansion of an `OptionCard` on R-07, not a separate screen; number kept so later inserts don't renumber.

**R-09 Load flag sheet** — "Carrying load?" size chips (small/medium/large), optional 140-char note, remember-for-day toggle (writes to itinerary/journey). If selected mode can't take it → inline warning + "Request anyway" (FM36). 1–2 taps.

**R-10 Requesting** — Anatomy: map with pulsing puck; sheet "Requesting a keke…" + countdown (`expires_at`) + `Cancel` (secondary). Roaming cascade shows "Finding another vehicle…" (never who declined). On `accepted` → R-11 automatically. States: expired → "No driver responded — see other options" back to R-07 with the list preserved.

**R-11 Meet your vehicle (accepted, pre-boarding)** — Purpose: get rider and driver together (§4.8, §4.11). Anatomy: map with live vehicle marker (Tier B) + walking polyline to boarding point; sheet: `NaMeChip` row ("Show this to your driver — GREEN DIAMOND") + big `Na Me` `HoldButton` (also tap); driver line: name · rating · trips; vehicle line: **plate large** (`numeric.l`), colour, make; ETA "Arriving in ~2 min" or "Walk 3 min to Lugbe Park"; wayfinding mode switch (text/map/audio) ; actions row: Share trip · Call driver (masked via provider, post-MVP) · Cancel. `I've boarded` tertiary (manual fallback). Data: `TripView`, Broadcast `trip:{id}`, `walking-directions`. Actions: Na Me (1), boarded override (1). States: driver offline > 45 s → "Driver signal lost" + cancel allowed without penalty. Stitch ref: `rider_driver_na_me_signal_final_quality_pass` (for R-12), `rider_transfer_next_leg_refined`.

**R-12 Na Me fullscreen** — Full-bleed colour, 240 dp shape, label `display.l`, "Hold to strobe" hint, compass arrow to counterpart when bearing known, plate at bottom. Tap = one 8 s cycle; hold = continuous. Works offline (cached pairing). Back gesture exits.

**R-13 Active trip** — Anatomy: map following vehicle; top-right `HoldButton SOS` (danger, always visible, 56); sheet peek: "In transit · ETA 14 min · ₦450 Standard fare"; half: `LegTimeline` compact (multi-leg shows next transfer ETA), driver/plate, `NaMeChip` (until boarded), actions: Extend trip · Share · Report. Data: `TripView` + Broadcast. Actions: SOS hold (600 ms), extend (1 → R-15), share (1 → R-25). Stitch ref: `rider_active_trip_na_me`.

**R-14 Transfer / next leg** — Shown at `journey.transfer`. Hero "Walk 3 min to Berger Park"; `StepList` or map or audio per preference; next leg card with live supply ("2–3 buses loading") and `Request next leg` (1) — pre-computed so tap is instant; "Change plan" tertiary → R-07 for the remaining segment. Stitch ref: `rider_transfer_next_leg_refined`.

**R-15 Extend trip** — "Where to now?" search (R-06 embedded) → result shows `FareHero` "+₦150 · Standard fare" and new total; `Send to driver` (1). Driver-initiated proposals arrive as a sheet: "Driver proposes continuing to Wuse for +₦150" Accept/Decline (1). Tier 3 delta → R-16 (context extension). Rules: FM24 — never an in-vehicle number typed.

**R-16 Along Pricing (negotiation)** — Variants: park (full rounds), roaming none/single/full, extension, load surcharge. Anatomy: "No standard fare for this trip yet" caption; anchor `display.l` "≈ ₦600"; chips from `chip_steps` (−100 −50 +50 +100); `Offer ₦550` primary; countdown ring from `expires_at`; round indicator "Round 2 of 4"; driver responses appear inline; at cap: `Split the difference → ₦575` yellow button; roaming 'none' band shows only `Accept ₦600` / `Skip`. Data: `open_negotiation`, `negotiation_round`, `negotiation_split`, Broadcast `negotiation:{id}`. States: lapsed → "No agreement — try another vehicle"; out of range → "Vehicle has passed". Rules: FM31–FM38.

**R-17 Trip complete** — Two-step single sheet: (1) "Did you pay ₦450?" → `Yes` (primary, default) / `Different amount` (opens 3 quick chips: ₦400 · ₦500 · Other keypad); Tier 3 trips ask "What did you pay?" with chips around the agreed amount (FM33). (2) Rating: 5 large stars + tag chips (config vocabulary) + optional comment; `Done`. Total 2 taps for the default path. Data: `confirm_fare`, `rate_trip`. Receipt available in R-22.

**R-18 Coverage gap** — `EmptyState`: "No mapped routes here yet"; "Nearest known boarding point: Dutse Junction · 1.2 km" + `Walk there` (1 → R-19); "Vehicles nearby: none/1–2" honest line; "Tell us about this area" (submits nothing more than the report already logged; shows thanks). Rules: §4.9, FM29/FM30 — no fake options.

**R-19 Wayfinding** — Segmented text / map / audio (default from prefs); text: `StepList`; map: polyline + puck; audio: play/pause big button + current step text; "Arrived" auto when within 25 m. Data: `walking-directions`. Offline: last fetched steps persist.

**R-20 Day planner (itinerary)** — Timeline of stops (`LegTimeline full` style): done (check), current ("In progress · ETA 12 min"), next ("Ready — Match now" yellow 48 button when `prepared_plan` exists; else "Prepare"), pending. Drag to reorder; swipe to remove; "Add stop" bottom. Load-for-the-day toggle in header. Copy never says "booked/reserved" (FM23). Data: `itinerary_state`, `itinerary_match_next`. Stitch ref: `rider_day_planner_final_quality_pass`.

**R-21 Itinerary entry** — Structured: repeated `SearchField` rows with drag handles; NL: text box "Describe your day" + mic (STT) → `parse-itinerary` → proposal list with resolved/unresolved markers → "Looks right" confirm (1) or edit rows. Never auto-saves an unconfirmed parse (§5.3).

**R-22 Trips (history)** — Grouped by day; row: date/time, mode chip(s), "Lugbe → Area 1", fare, status pill. Detail: map with materialised path, leg list, fare itemised (fare, load surcharge, tier), driver first name + plate, receipt share (PDF later; text now), "Report an issue" → R-24, "Fare was different" → `submit_correction` if not yet confirmed.

**R-23 SOS active** — Full-screen danger tint: "Along safety team alerted" + "We're sharing your live location and trip details with our safety line"; big `Call 112` (tel:) button (number from `cfg.sos.emergency_number`); "Share with a contact" (1 → R-25); `Hold to cancel` (600 ms). Cannot be dismissed by back. Data: `raise_sos`, `update_sos`. Rules: honest copy; works with ≤ 300 B payload.

**R-24 Report incident** — Category grid (6 icons + labels), description (2000), attach photo (optional), submit. Stitch ref: `rider_report_incident`.

**R-25 Share trip** — Sheet: "Share live trip" → creates link; share sheet (WhatsApp/SMS/copy); list of active shares with revoke; expiry note. **W-01** (public web page): rider first name, vehicle plate/colour, mode, live marker (≤ 30 s old), destination label, ETA, leg progress; auto-expires.

**R-26 Account & settings** — Profile (name, phone), Preferences: wayfinding mode (text/map/audio), default sort, women-only (visible when `regulatory_flags.women_only_matching`), language; Payment (cash default; add card/bank — post-MVP); Safety centre (trusted contacts, how SOS works); Help (R-28); Legal; Sign out.

**R-27 Digital payment (post-MVP)** — After completion when `payment_method='digital'`: amount, Paystack sheet (card/transfer/USSD), status. Cash remains default; this sheet never appears on cash trips.

**R-28 Help & support** — Search, categories (Fares, Safety, Account, How Along works), recent tickets, chat/WhatsApp support link. Stitch ref: `help_support_center` (nav fixed).

**R-29 Refer & earn (post-MVP)** — Code, share buttons, progress; no illustration.

### B2. Driver app (D)

**D-01–D-03 Auth** — Same as R-01–R-03 with driver branding line "Drive with Along".

**D-04 Driver profile & city** — Name, city (from active cities), gender (optional; enables women-only eligibility review), photo (optional). `start_driver_onboarding`.

**D-05 Vehicle** — Mode chips (from `mode_config`, with icons), plate (validated per country pattern), seats, colour, make/model; "Is this your vehicle?" yes/no → owner name/phone if no (owner may be a guarantor later). `register_vehicle`.

**D-06 Documents** — Checklist from `countries.verification_schema` (e.g., NIN, driver's licence, vehicle particulars, selfie); each row: status chip (Not started / Pending / Approved / Rejected + reason) → capture screen: camera frame with guide overlay, OCR-assist shows extracted fields for the driver to *confirm* (never auto-submitted, §5.3), retake, submit. "Save and continue later". `submit_verification`. Stitch ref: `driver_verification_final_quality_pass`.

**D-07 Verification pending** — Status hero, expected time, what happens next, "Set up your route while you wait" (D-10) — allowed pre-verification (routes activate on verification).

**D-08 Home** — Purpose: presence control + demand awareness (§4.1, §4.1.2 symmetric). Anatomy: top `BalanceCard` compact strip (balance, standing chip; tap → D-19); map with puck and `ambient_demand` heat discs ("4 searches near Lugbe → NE"); `StatusToggle` (Offline · At park · Roaming — available · Roaming — full) 56 high, yellow on active; when `at_park` → D-09 park picker inline chip "At: Lugbe Park ▾"; when roaming → "Seats: 3 ▾" stepper chip + "Direction: on my route / none ▾"; bottom nav Home · Routes · Earnings · Account. Data: `set_presence`, `presence_ping` (foreground service), `ambient_demand`. Actions: change status (1); seats (1–2). States: not verified → toggle disabled with reason; `LEDGER_BLOCKED` → toggle disabled, red card "Matching paused — balance ₦−5,200 below ₦−5,000 limit" + `Settle now` (yellow) (Phase 4 gate). Foreground notification "Along — you're visible to riders" while non-offline.

**D-09 Park picker** — Sheet: nearby parks (≤ 500 m) with distance, "I'm somewhere else" → creates candidate stage via `report_stage_here`-equivalent for drivers.

**D-10 Routes list** — Cards per profile: name, mode, stops count, active toggle, load surcharge; "Add route" → D-11. Empty: "Set up your route in a few taps" + suggested-route card if `suggest_known_route` returns one.

**D-11 Fast route setup** — Card: "Is this your route?" map preview + stops list with `price_to_end` chips (prefilled) ; "Yes, publish" (yellow) / "Edit prices" / "No, draw manually" (→ D-12). Publishing = 1 tap. Stitch ref: `driver_fast_route_setup`.

**D-12 Draw route** — Map-first; tap to add stop → snap chip appears ("Matched: Berger Junction ✓" or "New stop — name?" optional); stop list sheet at bottom with drag reorder; each stop has price chip (suggested) → tap opens D-13 keypad; validation inline (prices must not increase along the route; last stop ₦0 auto); `Publish` primary. Load surcharge optional field. Edit later = same screen (§4.7 step 6). Stitch ref: `route_setup`.

**D-13 Price keypad** — Large numeric keypad with currency, suggested chips (e.g., ₦300 · ₦350 · ₦400), `Set`. 1–3 taps.

**D-14 Incoming request** — Full-screen sheet over map (map dimmed): header "New request" + countdown ring (`expires_at`); rider line (name · rating · trips); pickup row (stage name + distance/ETA to driver); drop-off row; **Load row** when flagged ("Medium load — 1 bag, needs boot") (FM35); women-only badge if applicable; fare block: "Rider pays ₦450 · Standard fare" and beneath in `caption` "Along fee ₦34 (7.5%) — added to your balance at completion" (FM3); seats after accept; `Decline` (secondary, 40%) `Accept` (yellow, 60%) both 56. Decline opens reason chips incl. "No room for load" (1 extra tap). Data: Broadcast `driver:{id}` + FCM; `respond_to_trip`. Stitch ref: `driver_request_high_impact` for proportions, `driver_incoming_request_final_quality_pass` for rows.

**D-15 Manifest / active trips** — List of accepted/boarded riders with `NaMeChip`, boarding stage, drop-off, fare; per row: "Boarded" (manual, 1) when not auto, "No-show" after timer; tap → D-16.

**D-16 Active trip (driver)** — Map with route; sheet: rider name, boarding/alighting, `NaMeChip` + Na Me button (until boarded), fare + Along fee lines, `Start trip` (boarded→in_transit, if not auto), `Complete trip` (primary), Extend (D-17), Report, SOS hold top-right. Completion (1) → D-18.

**D-17 Extend trip (driver)** — Search destination → `FareHero` "+₦150" → `Propose to rider` (1); rider's response toast. Rider-initiated arrives as sheet Accept/Decline (1).

**D-18 Trip complete summary** — "Trip complete" · Fare ₦450 (rider pays you in cash) · Along fee −₦34 (posted to your balance) · New balance ₦−1,234 · "Confirm cash received" default `Yes` / `Different amount` chips (mirror of R-17) · Rate rider (stars + tags). 2 taps.

**D-19 Earnings & balance** — Two sections, visually separated by a heading and background: **Along balance** (`BalanceCard`: balance, threshold line "Matching pauses below ₦−5,000", standing chip, `Settle` yellow when < 0; ledger list grouped by day with `LedgerRow` human labels: "Along fee · Trip to Area 1" −₦34; "Settlement · Paystack" +₦5,000; "Deposit" +₦2,000; balance_after per row) and **Trips** (informational: today's trips count, fares collected in cash — clearly captioned "Cash you collected directly"; not part of balance). Stitch ref: `driver_ledger_precision` layout, `driver_performance_ledger_detailed` balance card.

**D-20 Settle** — Amount (prefilled to bring balance to 0; editable ≥ ₦100); channels: Bank transfer (shows account + reference, auto-confirms via webhook), USSD code, Card, **Pay an agent** (generates 6-char code + nearby agents list with distance). Status screen polls `settlements` → "Settled — balance ₦0" success. Errors: provider down → other channels remain.

**D-21 Standing** — Shown from banners: explains current standing, the exact reason and balance at transition, grace deadline, what restores good standing (settle to above ₦−3,000), guarantor status, history list (`my_standing_history`). No dark patterns; one primary action: Settle.

**D-22 Guarantor** — Add fellow driver (search by phone) or vehicle owner (prefilled from D-05 if owner ≠ driver); explain "Your guarantor is notified if your balance stays unsettled after the grace period. Nothing is ever deducted from them." Acknowledgement status. **W-02** public acknowledgement page (token from SMS).

**D-23 Insights (post-MVP)** — Where riders searched near your routes (aggregate cells), your routes' avg wait/fulfilment, best hours; tabular + tiny bars, no heavy charts. Stitch ref: `driver_business_insights_final_quality_pass` (semantics fixed).

**D-24 Account** — Profile, vehicle(s) (switch active), documents (D-06 statuses), payout bank (for positive balances), language, safety centre, help, legal, sign out.

### B3. Admin console (A) — Next.js, desktop-first (min 1280), also usable at 1024

Global: left sidebar (role-filtered), top bar (city selector scoped to `admin_can_access_city`, search, notifications, user), audit drawer on every detail page ("History" tab reading `audit_log`).

**A-01 Sign-in** — Supabase Auth email+password + TOTP (required for `superadmin/finance/safety`). Role landing per `admin_users.role`.

**A-02 Ops dashboard** — City KPIs (24 h): searches, ambient→commit conversion, requests, accept rate, completed trips, median wait, fare-discrepancy rate, open SOS, open flags, verification queue depth, drivers online (by status). Each tile links to its queue. Data: `admin_corridor_analytics` + counts.

**A-03 Live map** — MapLibre with layers: verified/candidate routes, parks/stages, live presence (Tier I: precise positions, status colours), active trips (rider→driver links), open SOS (pulsing red), coverage-gap heat. Filters per layer; click → side panel (driver/trip detail). Stitch ref: `admin_corridor_operations_console` (rail concept).

**A-04 Verification queue** — Table (pending first, age); detail: document viewer (signed URL, expires 10 min, watermarked with reviewer id), OCR extract (redacted ids), face-match score, duplicate-hash hit warning, vehicle info; actions Approve (with `women_only_eligible` checkbox when gender=female) / Reject (reason required). Two docs side-by-side compare mode.

**A-05 Graph editor** — Map + tree (corridor → route → stages → legs/through-fares). Edit forms with tier badges and confidence; every save writes `graph_revisions`; "Publish" for field-verified only via A-07 path; drag stage on map; adjacency validation; bulk CSV import (dry-run diff first). Stitch ref: `admin_deployment_playbook_seed_data` (checklist idea).

**A-06 Fare corrections** — Queue with proposed vs current, delta %, submitter trust, trip link, MAD outlier badge; Approve/Reject (1 click each + optional note); bulk approve for auto-merged review.

**A-07 Field reconciliation** — Two-scout queue: entity key, scout A/B status, variance (m / %), Merge / Review / Reject; third-scout request button; publish → `field_verified`. Stitch ref: `admin_deployment_playbook_seed_data`.

**A-08 City deployment playbook** — Checklist per city: geofence polygon (draw/upload), backbone parks CSV, routes, fares, config overrides, tile coverage check, OSRM extract check, seed dry-run → "Initialize" (creates rows with `import` source). Status `pre_seed → alpha → …`.

**A-09 Config** — `app_config` editor by key with scope tabs (global/country/city/corridor), JSON-schema-validated inputs, effective-value preview per city, diff + reason required, history.

**A-10 Integrity review** — Flags queue (score desc, filters by type/city/driver); detail: side-by-side driver & rider traces on map with destination radius circle, event timeline (accepted → cancelled with timestamps), evidence JSON rendered as bullets, corroborating riders count with links, driver risk summary (30 d); actions: Clear · Action → opens Standing dialog (A-11) — never automatic. Stitch ref: `admin_fraud_review_final_quality_pass`.

**A-11 Driver detail** — Header (name, phone masked, city, verified, standing, rating); tabs: Overview, Ledger (entries + balance + manual adjustment form with dual control), Standing (ladder visual + transition form with reason), Trips, Flags, Routes, Documents, Guarantor (notify button → runbook), Audit.

**A-12 Safety board** — Open SOS list (age, rider/driver, trip, location, ack button) with live map and trip context; incident queue with triage form; runbook link; SLA timers.

**A-13 Finance** — Pending/confirmed settlements, agents CRUD, payouts for positive balances, manual adjustments queue (dual control approvals), reconciliation with Paystack (daily import diff), exports (CSV).

**A-14 Intelligence review** — Tabs: Candidate parks (map cluster + stats; Promote → creates candidate stage/park; Dismiss), Route inference candidates, Geometry corrections (before/after overlay). All actions audited.

**A-15 Corridor analytics** — Time series & tables per corridor: searches, conversion, candidates per search (direct vs multi-leg), fulfilment, wait, fare discrepancy, coverage gaps map. Export CSV.

**A-16 Audit log** — Filterable table; JSON before/after diff viewer.

**A-17 Admin users** — Invite, role, deployment, city scope, disable; TOTP enforcement status.

**A-18 Markets & portability** — Countries (currency, phone prefix, locale, timezone, active), verification schema editor (document types/patterns/providers), regulatory flags, i18n coverage table (strings translated per locale), payment provider per country. Stitch ref: `admin_pan_african_portability_config` (sidebar).

**A-19 Revenue hooks (Phase 8)** — Sponsored placements (context type, target, content, schedule; impressions/taps aggregate), API keys (scope, rate, usage), operator/corporate accounts management, anonymized export jobs with k threshold.

### B4. Corporate & operator portals (Phase 8)

**C-01 Overview** (subsidy used MTD vs budget, active staff trips, enrolled staff; live trips list) · **C-02 Roster** (invite by phone, department, policy assignment, status) · **C-03 Policies** (subsidy %, cap per trip, hours, zones) · **C-04 Trip history** (allocations, export) · **C-05 Billing** (invoices, download). Stitch ref: `corporate_staff_manager_final_quality_pass` (minus trust score).
**O-01 Operator overview** (drivers in the operator's park/union: online counts, trips/day aggregate, fare-discrepancy rate; no per-rider data).

### B5. Public web (W)
**W-01 Shared trip** (R-25) · **W-02 Guarantor acknowledgement** · **W-03 Legal** (terms, privacy — NDPR notice).

---

## Part C — One-tap compliance table (spec §4.6, checked by Reviewer on every UI task)

| Interaction | Taps | Screen |
|---|---|---|
| Request a presented option | 1 (+ undo) | R-07 |
| Accept / decline a request | 1 (decline reason +1 optional) | D-14 |
| Change presence status | 1 | D-08 |
| Confirm fare paid as shown | 1 | R-17 / D-18 |
| Rate | 1 (star) + Done | R-17 |
| Na Me | 1 | R-11/R-12/D-16 |
| SOS | hold 600 ms | R-13/D-16 |
| Publish suggested route | 1 | D-11 |
| Match next itinerary stop | 1 | R-20 |
| Accept an extension | 1 | R-15/D-17 |
| Negotiation counter | 1 (chip) + 1 (offer) | R-16 |
| Boarding | 0 (auto) / 1 manual | R-11/D-15 |
| Flag load | 1–2 | R-09 |
