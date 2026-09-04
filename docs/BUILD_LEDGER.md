# BUILD_LEDGER.md — Along

Append-only. Orchestrator writes; Workers and Reviewers read. Format per spec §2.4. Newest entries at the bottom.

---

## [Pre-Phase 0 / Planning] — Blueprint authored
**Date:** 2026-09-04
**Task:** Produce the implementation blueprint beneath `ALONG_BUILD_SPEC.md` (v11) so Worker models can build every phase without design ambiguity.
**Outcome:** `docs/blueprint/00–13` written; ADR-0001…0012 accepted, ADR-0013 proposed (to pin at bootstrap); Stitch UI set audited (doc 06 Part A); design system resolved (doc 05); full DDL (doc 02); contracts (doc 03); algorithms (doc 04); WBS with ~130 tasks (doc 11).
**Decisions recorded outside the spec (all with ADRs or doc 11 notes):**
1. Supabase committed; SQL-first for correctness-critical logic (ADR-0001).
2. `mode_config` table replaces the mode enum (ADR-0002).
3. `journeys` container above `trips`; `transfer` is a journey state; itinerary stops link to journeys (ADR-0003).
4. Tenant scoping via city → country → deployment, from Phase 0 (ADR-0004).
5. Design system: ink primary, yellow surface, Inter only, no cream/olive; Stitch screens are layout references only (ADR-0005).
6. OSRM + PMTiles + MapLibre + Photon, weekly rebuild (ADR-0006).
7. Presence: row per driver, aggregate Broadcast for Tier A, trip channels for Tier B, opaque candidate tokens for roaming hails (ADR-0007).
8. Flutter packages under `shared/flutter`, Riverpod/go_router/Drift (ADR-0008).
9. Raw location samples table; path columns materialised (ADR-0009).
10. `payout_debit` ledger type; Paystack behind an interface; agent codes (ADR-0010).
11. FCM for background wake (ADR-0011). 12. Supabase Auth phone OTP + Termii hook (ADR-0012).
13. Scheduling: wayfinding + coverage gap in Phases 1–2; day planner in Phase 5 stream B; tokens/components start in Phase 0 (doc 11 end).
**Open items for the human product owner (not blockers for Phase 0):**
- Confirm commission default 7.5% within the 5–10% band; confirm threshold defaults (−₦3,000 warn / −₦5,000 block / 48 h grace) — all `app_config`, changeable without code.
- Confirm the Abuja pilot corridors list in doc 13 §5 against the field team's plan.
- Confirm women-only feature is enabled for NG at launch (`regulatory_flags.women_only_matching`).
- Legal review timing for payouts/stored-value posture (doc 12 §7) before Phase 8.
**Escalations:** none.

---

## [Pre-Phase 0 / Planning] — Product-owner decisions on open items
**Date:** 2026-09-04
1. **Commission 7.5%** confirmed. Lives in `app_config.commission.rate` (global default; city override possible), edited only via admin console A-09 → `admin_set_config` (validated, reason required, audited). No code change to alter it.
2. **Abuja pilot corridors** chosen by planning (owner delegated): Nyanya/Mararaba–AYA–Berger/CBD; Lugbe–Area 1/Berger; Kubwa–Wuse/Berger. Rationale and deferred alternatives in doc 13 §5.
3. **Women-only matching enabled at launch** for NG: `countries.regulatory_flags.women_only_matching = true` in `seed_core.sql`.
4. **Payments posture (ADR-0010 amended):** digital rider payments split at source via Paystack subaccounts so Along never holds funds; `payout_debit` reduced to exceptional use. Legal review checkpoints added as human tasks P4-E-02 (before enabling digital payments in prod; `payments.digital_enabled` defaults false) and P8-E-01 (before B2B contracts). New RPC `set_payout_bank`, new driver columns, new task P4-A-08.
**Escalations:** none.

---

## [Pre-Phase 0 / Planning] — QR scan-to-pay added (product-owner request)
**Date:** 2026-09-04
- New blueprint doc 14 + **ADR-0014**: each verified driver gets a random 8-char `driver_code`; QR encodes `https://along.ng/p/<code>` (universal link → rider app when installed, otherwise the new public page **W-04**). Static printed sticker primary, dynamic per-trip QR (HMAC token) secondary.
- Payments split at source on the driver's subaccount (ADR-0010 unchanged); `payments` becomes driver-centric with optional `trip_id`/`rider_id` so non-app riders can pay and commission is still collected. Fee bearer is config (`payments.fee_bearer`, default Along) pending P4-E-02 economics.
- Tap budgets: in-app matched trip + saved method = **1 tap** after scan (and the same `Pay` button exists on R-17 without a QR); no matched trip = 2; web = 2 + provider checkout.
- Ledger: a digital payment on an already cash-debited trip posts an offsetting `digital_settlement_credit` — the ledger stays the single source of truth.
- Sticker-swap fraud: plate shown before paying; hard warning when the rider's active trip is with another driver; driver "Verify my sticker"; code rotation.
- Schema deltas in doc 02 (`drivers.driver_code`, `accepts_digital`, `payments` columns, `rider_payment_methods`, 5 config keys); contracts in doc 03 §7; screens R-27 (upgraded), R-31, R-32, D-25, D-26, W-04, A-11/A-13 additions; tests TS-QR-01..12, TS-UI-06; tasks P4-A-09, P4-B-02, P4-C-02, P4-D-02, P4-E-03; P4-E-02 scope extended.
- Deferred: NQR (NIBSS) as an additional QR payload — evaluate in Phase 8 once the aggregator path is confirmed; does not change the resolver design.
**Escalations:** none.
