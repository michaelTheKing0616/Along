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
