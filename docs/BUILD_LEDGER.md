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

## [Phase 0 / P0-E-01] Bootstrap repo
- Status: FAIL
- Assigned: 2026-09-04
- Worker report summary: Layout, Melos/pnpm/FVM/Supabase, CI skeletons, CODEOWNERS, PR template, ADR-0013 (`eu-west-2`) delivered on `task/p0-e-01` (4 commits). Open questions cleared on rework 1 (region + CODEOWNERS placeholders).
- Reviewer verdict: FAIL — criterion "CI skeleton green on empty projects" NOT MET: `admin.yml` typecheck fails TS2835 (NodeNext relative imports need `.js` extension) in `admin-console/src/index.test.ts` and `backend/jobs/src/index.test.ts`.
- Rework count: 2
- Notes/escalations: CODEOWNERS uses placeholder `@along-ng/*` team slugs — confirm real GitHub org team names when available (non-blocking). Model policy (human): Workers + Reviewers use Cursor models only (`composer-2.5-fast`); never resume a non-Cursor Reviewer session (resume keeps prior model).

## [Phase 0 / P0-E-01] Bootstrap repo
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Repo layout (doc 01 §3), Melos/pnpm/FVM, Supabase CLI init, lint configs, CODEOWNERS (placeholder teams), PR template §2.3, six CI skeletons, ADR-0013 (`eu-west-2`). TS2835 NodeNext import fix on rework.
- Reviewer verdict: PASS WITH NOTES — all four acceptance criteria MET; prior typecheck FAIL fixed and re-verified. Notes: melos/deno not re-executed in reviewer PATH (CI wired); skeleton `db lint || true` and missing Playwright intentional until later tasks.
- Rework count: 2
- Notes/escalations: Confirm real GitHub CODEOWNERS team slugs (`@along-ng/*` placeholders). Formal Lagos/Abuja RTT before cloud provision remains P1-E-04. Autopilot model policy: Workers and Reviewers must use Cursor models only (`composer-2.5-fast`); never Claude/GPT; never `resume` a non-Cursor Reviewer (resume preserves model).

## [Phase 0 / P0-E-02] CI workflows + RLS coverage
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Six PR workflows upgraded with doc 09 §2 fail-when-missing gates; RLS coverage SQL + regression test proves fail on table without RLS.
- Reviewer verdict: PASS WITH NOTES — both acceptance criteria MET; intentional red placeholders OK until downstream tasks. Notes: seed gate presence-only; pgTAP RLS heuristic loose; Playwright script always exits 1 until P0-D-01.
- Rework count: 0
- Notes/escalations: none blocking. Follow-ups absorbed by P0-A-01 / P0-D-01 / P0-E-04 / P0-E-05 as named in gate scripts.

## [Phase 0 / P0-A-01] Migrations 0001/0002 geo & config
- Status: FAIL
- Assigned: 2026-09-04
- Worker report summary: 0001/0002 + seed_core + cfg/city_for_point + pgTAP suites; RLS coverage excludes PostGIS catalogs; open questions cleared on rework.
- Reviewer verdict: FAIL — pgTAP tests call `plan()` before `create extension pgtap`, so fresh `supabase db reset` / CI path fails with `function plan(integer) does not exist`. Logic and seed MET when pgtap pre-installed.
- Rework count: 2
- Notes/escalations: Doc 09 `\ir` vs Supabase CLI — interim pattern (inline in migration + canonical `policies/`) accepted; human should amend doc 09 or add ADR. CODEOWNERS placeholders still pending.

## [Phase 0 / P0-A-01] Migrations 0001/0002 geo & config
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: 0001 extensions/helpers (+ admin_users stub), 0002 geo/config with cfg()/city_for_point(), seed_core all §2.3 keys, pgTAP suites, RLS on all Along tables; PostGIS catalogs excluded from RLS gate; pgTAP extension ordered before plan().
- Reviewer verdict: PASS WITH NOTES — all three acceptance criteria MET on fresh db reset (13/13 assertions). Notes: local tests via psql (pg_prove in CI); admin_users stub intentional for P0-A-02; db lint not run in review session.
- Rework count: 2
- Notes/escalations: Amend doc 09 `\ir` guidance (inline+canonical policies/ accepted interim). CODEOWNERS real team slugs still needed (human).

## [Phase 0 / P0-A-02] Migration 0003 identity
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Full §3 identity DDL; admin_users stub replaced; profiles auto-create; protect_driver_columns; private.identity_hashes; identity_rls 16/16.
- Reviewer verdict: PASS WITH NOTES — all acceptance MET on fresh reset. Notes: rating_count/women_only_eligible untested in pgTAP (same trigger path); profiles/vehicles column triggers per doc 12 deferred; psql not pg_prove locally.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 0 / P0-A-03] Migration 0004 along-graph
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Full §4 along-graph DDL; adjacency/order triggers; graph_revisions; data_sources; drivers.home_park_id FK; along_graph pgTAP 6/6; RLS on all new tables.
- Reviewer verdict: PASS WITH NOTES — all three acceptance criteria MET on fresh reset. Notes: psql vs pg_prove; target_type naming inconsistency; INSERT revision path untested.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 0 / P0-A-04] snap_stage + resolve_fare Tier 1–2 + fare_quotes
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 0005; snap_stage (cfg radius); resolve_fare Tier 1–2; fare_quotes + RLS; Tier 0/3 raise deferred to P1-A-03; TS-FARE-01/02/03/08 10/10 on minimal fixture.
- Reviewer verdict: PASS WITH NOTES — all four TS-FARE criteria MET. Notes: TS-FARE-08 minimal fixture (Abuja re-run → P0-E-04); no fare_quotes RLS behavioral pgTAP; snap_stage enum-order tie-break fragile.
- Rework count: 1 (open-questions clear only)
- Notes/escalations: P0-E-04 must re-assert TS-FARE-08 against seed_abuja_pilot.

## [Phase 0 / follow-up] TS-FARE-08 on Abuja seed
- Status: BLOCKED — follow-up
- Assigned: 2026-09-04
- Worker report summary: n/a
- Reviewer verdict: absorb into P0-E-04 acceptance when seeding Abuja pilot.
- Rework count: 0
- Notes/escalations: Re-run TS-FARE-08 p95 ≤ 150 ms over 1,000 pairs on seed_abuja_pilot.

## [Phase 0 / P0-A-05] Promotion pipeline
- Status: FAIL
- Assigned: 2026-09-04
- Worker report summary: Migration 0006 pipeline + collusion cfg; TS-GRAPH 12/12 when seeded.
- Reviewer verdict: FAIL — (1) fresh `supabase db reset` fails: duplicate `promotion.collusion_downweight` in migration and seed_core; (2) `promote_candidates` sustained-disagreement path references CTE out of scope (db lint).
- Rework count: 2
- Notes/escalations: none beyond fix list.

## [Phase 0 / P0-A-05] Promotion pipeline
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 0006; trust weights, confirm_graph_value, promote_candidates, MAD guard, decay_confidence, pg_cron; collusion_downweight in seed_core via cfg; TS-GRAPH-01..05 12/12; reset+CTE fixes on rework.
- Reviewer verdict: PASS WITH NOTES — prior FAIL fixed on fresh reset; Phase 0 collusion gate MET. Notes: add `promotion.collusion_downweight` to doc 02 §2.3 table (doc drift); unused-var lint warnings; sustained-disagreement path untested.
- Rework count: 2
- Notes/escalations: **Human/planner:** amend doc 02 §2.3 to list `promotion.collusion_downweight` default 0.25 (algorithm param from doc 04 §6.2). Autopilot model policy locked: Workers+Reviewers = `composer-2.5-fast` only; never resume non-Cursor Reviewer sessions.

## [Phase 0 / P0-A-06] planner_decompose MVP
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 0007 planner_decompose (cfg-bounded recursive multi-leg); triangle backbone fixture; 9/9 pgTAP; every park pair has a path.
- Reviewer verdict: PASS WITH NOTES — acceptance MET. Notes: single shortest path (Yen → P2-A-01); silent fare null on resolve_fare errors; Abuja re-validation → P0-E-04.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 0 / P0-A-07] Field tables + reconciliation + ingestion contract
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 0008 field_* tables; admin_reconcile/publish (park-only); TS-GRAPH-07 8/8; shared/contracts field-ingestion + db.types.
- Reviewer verdict: PASS WITH NOTES — acceptance MET. Notes: tighten reconcile_field_submission caller check in P0-E-03; unused v_currency; discrepant-status publish assert optional.
- Rework count: 1 (open-questions clear only)
- Notes/escalations: none blocking.

## [Phase 0 / P0-A-08] Audit log + Phase 0 admin write triggers
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 0009 audit_log + audit_admin_write on 15 Phase 0 tables; append-only; seed_admin_dev.sql manual; pgTAP 5/5.
- Reviewer verdict: PASS WITH NOTES — acceptance MET. Notes: ip/user_agent deferred; seed manual-only; remaining §15 tables → P6-A-01.
- Rework count: 1 (open-questions clear only)
- Notes/escalations: none blocking.

## [Phase 0 / Decision] Autopilot model policy (human)
- Status: PASS
- Assigned: 2026-09-04
- Worker report summary: n/a
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Workers and Reviewers MUST use Cursor model `composer-2.5-fast` only. Never Claude/GPT/API models. Never `resume` a Reviewer that was started on a non-Cursor model (resume preserves model). Always spawn a fresh Reviewer Task with `model: composer-2.5-fast`.

## [Phase 0 / P0-E-03] ODK forms + ingest + PROTOCOL
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Park/route XLSForms, export_choices, ingest.ts (service-role), PROTOCOL, round-trip vitest 2/2 with correct variance.
- Reviewer verdict: PASS WITH NOTES — acceptance MET. Notes: GPX upload deferred; round_trip not in CI; route form missing new_park group; entity_keys duplication.
- Rework count: 1 (open-questions clear only)
- Notes/escalations: none blocking. Follow-ups absorbable by later field/ops tasks.

## [Phase 0 / P0-E-04] Abuja pilot + Zaria-Test + scenario seeds
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: seed_abuja_pilot (3 corridors), seed_testcity_fixture (Zaria-Test), seed_test_scenarios; apply_seeds.sh; TS-CFG-01 8/8; phase0_exit 6/6; TS-FARE-08 Abuja p95 0.101ms; CI runs TS-CFG-01.
- Reviewer verdict: PASS WITH NOTES — all acceptance MET. Notes: synthetic two-scout exemplar only; apply_seeds idempotency; exit/perf tests not all in CI.
- Rework count: 1 (open-questions clear only)
- Notes/escalations: none blocking.

## [Phase 0 / follow-up] TS-FARE-08 on Abuja seed
- Status: PASS
- Assigned: 2026-09-04
- Worker report summary: Closed by P0-E-04 TS-FARE-08-abuja.sql (p95 0.101 ms).
- Reviewer verdict: PASS — ledger follow-up from P0-A-04 resolved.
- Rework count: 0
- Notes/escalations: none.

---

## [Phase 0 / Decision] Planner resolution of blueprint gaps raised in session 1
**Date:** 2026-09-04
1. **doc 02 §2.3** now lists `promotion.collusion_downweight` (`0.25`); doc 04 §6.2 references it via `cfg()` instead of a literal.
2. **`\ir` vs Supabase CLI → ADR-0015:** RLS policies are defined inline in migrations (single source of truth); `backend/db/policies/` becomes a generated, CI-checked snapshot from `pg_policies`. Docs 01 §3, 02 §16, 09 §3 amended. New task **P0-A-09** (S, depends P0-A-08) performs the conversion and adds the CI check; the interim "canonical policies/" comments are removed by that task.
3. **CODEOWNERS:** no git remote/GitHub org exists yet, so the file has no effect. Keep `@along-ng/*` placeholders; revisit when the repo is pushed (record under the task that creates the remote). Non-blocking.
**Escalations:** none.

## [Phase 0 / P0-D-01] Admin console bootstrap
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Next.js 15 App Router; Supabase SSR email+TOTP; middleware role routing; AuditDrawer; tokens.css placeholder; Playwright 10/10 (sign-in per role + unauthorized redirect).
- Reviewer verdict: PASS WITH NOTES — both acceptance criteria MET (independently re-run). Notes: hardcoded abuja defaults; safety/ops_lead MFA not E2E-seeded; sign-out link stub; check_playwright port conflict handling.
- Rework count: 0
- Notes/escalations: Follow-ups non-blocking; city slug hardcode cleanup before multi-city (P9). Do not raise CODEOWNERS again until remote exists (Decision 2026-09-04).

## [Phase 0 / P0-D-02] A-07/A-05/A-08 admin screens
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Field reconciliation, graph editor (basic), city playbook CSV dry-run/apply; migration 00011 SELECT grants; Playwright 13/13 including publish to field_verified without SQL.
- Reviewer verdict: PASS WITH NOTES — exit criterion MET. Notes: E2E publishes pre-matched row only; graph save untested; import confidence 0.3 literal note; blueprint map/third-scout deferred per scope.
- Rework count: 1 (open-questions + grants migration)
- Notes/escalations: none blocking.

## [Phase 0 / P0-E-05] Design tokens + along_design theme
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: tokens.json (doc 05 §2 vibrant palette), Style Dictionary → Dart/CSS/Tailwind, along_design theme, stale gate; rework loaded Inter for ₦ golden.
- Reviewer verdict: PASS (recheck) — flutter test 3/3; golden visually shows ₦450; check_stale PASS; colours match doc 05 §2 vibrant/high-contrast.
- Rework count: 1 / 2
- Notes/escalations: Prior FAIL was Ahem tofu box; fixed in 1d720ae. Style Dictionary collision warnings non-blocking; Inter full files larger than subset ideal. Product-owner colour direction (vibrant/high-contrast, not muted) encoded in tokens.

## [Phase 0 / P0-E-06] Brand assets (SVG logos, icons, splash)
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: SVG wordmarks (#0A0A0A/#F7D117), Android adaptive+legacy all densities, iOS AppIcon set, splash assets; brand_assets paths + 6 asset tests; flutter test 9/9.
- Reviewer verdict: PASS WITH NOTES — acceptance MET; vibrant fills confirmed; no Stitch logo. Notes: iOS 1024 may need safe-zone inset later; potrace not hand-optimized.
- Rework count: 0
- Notes/escalations: none blocking. Colour direction (vibrant/high-contrast) preserved in SVG fills.

## [Phase 0 / P0-A-09] ADR-0015 policies snapshot + CI regenerate-and-diff
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: dump_policies.sh + check_policies_stale.sh; 31 GENERATED snapshots; migration canonical-comment cleanup; db.yml stale step after reset.
- Reviewer verdict: PASS WITH NOTES — acceptance MET; stale tamper test fails as designed. Notes: identity_hashes pgTAP gap pre-existing; 00002 comment cleanup beyond literal 0003–0010 range (correct per ADR).
- Rework count: 0
- Notes/escalations: none blocking for this task.

## [Phase 0 / Gate]
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: n/a (gate Reviewer only)
- Reviewer verdict: PASS WITH NOTES — all 17 P0-* tasks PASS/PASS WITH NOTES; Phase 0 gates + exit criteria MET; independently re-ran 87/87 self-contained pgTAP. Abuja exit harnesses not re-run (partial local seed; reset blocked). No product blockers.
- Rework count: 0
- Notes/escalations: STOP for human before Phase 1. Recommend fresh `supabase db reset` + full pgTAP before Phase 1 kickoff. Colour direction (vibrant/high-contrast) locked in tokens/brand assets.

## [Phase 0 / Verification] Fresh db reset + full pgTAP (pre–Phase 1)
- Status: PASS
- Assigned: 2026-09-04T20:25Z
- Worker report summary: Orchestrator ran `supabase db reset --yes` then all 13 `backend/db/tests/*.sql` on clean DB (tests load seeds inside txn).
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations:
  - 13/13 files PASS; ~94 ok assertions; 0 not-ok; policies stale check PASS (31 files).
  - phase0_exit_criteria: 6/6; TS-FARE-08 Abuja: ok (p95 ≤ 150 ms); TS-CFG-01: 8/8; promotion_pipeline TS-GRAPH-01..05: 12/12.
  - Human approved continue into Phase 1 after optional verification.

## [Phase 1 / Decision] Human continue
- Status: PASS
- Assigned: 2026-09-04T20:25Z
- Worker report summary: n/a
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Human: do optional verification then continue Phase 1. Autopilot PHASE_LIMIT = Phase 1; stop at Phase 1 gate.

## [Phase 1 / P1-A-01] Migrations: driver routes, presence, planner support, journeys/trips
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00012 §5–8; TS-TRIP-03 11/11; rework: partition RLS exclusion, dump relkind p + snapshots, ensure_partitions grant, P1-A-01-rls-smoke.
- Reviewer verdict: PASS WITH NOTES (recheck) — run_rls_coverage PASS; policies 44 current; full suite 109/109. Note: PUBLIC still has EXECUTE on ensure_partitions (follow-up revoke).
- Rework count: 1 / 2
- Notes/escalations: none blocking.

## [Phase 1 / P1-A-02] shared/contracts OpenAPI + JSON Schemas + generated types
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: OpenAPI 3.1 (10 paths), RPC schemas, TS/Dart codegen, contracts.yml drift gates, ADR-0016; rework fixed Dart toJson + 2 RPCs.
- Reviewer verdict: PASS WITH NOTES (recheck) — check_compile/check_stale PASS; acknowledge_guarantor + my_standing_history present.
- Rework count: 1 / 2
- Notes/escalations: none blocking.

## [Phase 1 / P1-A-03] resolve_fare Tier 0/3 + route profile RPCs
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00013; resolve_fare Tier 0/3 + load surcharge; upsert/my/suggest route profile RPCs; TS-FARE-04–07 + TS-GRAPH-06.
- Reviewer verdict: PASS WITH NOTES — all named TS PASS (10+6+10). Notes: hardcoded ±50 and 14 days in auxiliary RPCs → cfg follow-up; some RPCs lack dedicated pgTAP.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 1 / P1-A-04] Presence RPCs + ambient + stale job
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00014; set_presence/presence_ping/ambient_*/presence_plausible/presence_stale; driver_is_matchable stub; TS-PRES/DISC/PLAN-10.
- Reviewer verdict: PASS WITH NOTES — 18/18 named assertions PASS. Notes: ambient_demand untested; presence_ping accuracy>500 not rejected yet; LEDGER_BLOCKED for unverified OK.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 1 / P1-A-05] Trip request/respond/cancel + Na Me + TripView
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00015; request/respond/cancel/expire/trip_transition subset; TripView; Na Me; TS-TRIP-02/06 + TS-DISC-03.
- Reviewer verdict: PASS WITH NOTES — 10/10 new assertions. Notes: Na Me same-color deconfliction incomplete vs §16; hardcoded 15m planner TTL; expire_requests untested.
- Rework count: 0
- Notes/escalations: none blocking for merge; follow-ups before Phase 3 Na Me UX.

## [Phase 1 / P1-A-06] Edge plan-trip v1 (direct candidates)
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00016 + Edge plan-trip; OSRM degrade; ranking; Deno 7/7; TS-PLAN-01/05/06/08 + p95; ADR-0017; 2 reworks (lint/asserts/handler tests; assert-6 role fix).
- Reviewer verdict: PASS WITH NOTES (final) — SQL 6/6 + p95 + Deno 7/7. Notes: quote TTL/OSRM fallback literals; driver_profile untested; full deno lint pre-existing verify_openapi issue.
- Rework count: 2 / 2
- Notes/escalations: none blocking.

## [Phase 1 / P1-A-07] Edge places-search + walking-directions
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00017 places_search_graph + places.* cfg; places-search (parks-first) + walking-directions (OSRM foot + degrade); routing compose + stub scripts; Deno 12/12.
- Reviewer verdict: PASS WITH NOTES — parks-first test PASS; lint clean on changed files. Notes: routing stub path typo; Photon-degrade untested; places.* keys not in doc 02 §2.3 (planner follow-up).
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 1 / P1-A-08] Realtime broadcast + presence-fanout + FCM notify
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00018 realtime RLS + register_device_token + fanout/notify; TS-DISC-04 5/5; Deno 17/17; rework removed seed fanout dups + require-await lint.
- Reviewer verdict: PASS (recheck) — both FAIL items fixed. Notes: pre-existing seed vs migration 14 `presence.ping_min_interval_s` still breaks fresh db reset (P1-A-04 follow-up); pg_cron fanout deferred to P1-E-04.
- Rework count: 1 / 2
- Notes/escalations: Follow-up: make seed_core ON CONFLICT or drop keys already inserted by migrations 14/17/18 so `supabase db reset` is green.

## [Phase 1 / P1-A-09] Verification RPCs + OCR + identity hash
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: Migration 00019 verification RPCs + storage bucket + identity hash; verification-ocr Edge with redaction; TS-VERIF-01 8/8; TS-PRES-03; Deno 7/7.
- Reviewer verdict: PASS WITH NOTES — all acceptance MET. Notes: driver_verifications SELECT broader than doc 02 §3 (pre-existing); admin_reject untested; defaultOcr mock contains sample digits (never persisted).
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 1 / P1-E-01] along_core + along_data + realtime/location/notifications skeletons
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: along_core 96.1% coverage; along_data repos + Drift queue; skeletons for realtime/location/notifications; ADR-0018.
- Reviewer verdict: PASS WITH NOTES — coverage 96.1%; 36+6+2+2+2 tests. Notes: auth/routes repos untested; flutter_foreground_task deferred to P1-C-02.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 1 / P1-E-02] along_map MapLibre + along-light + PMTiles
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: AlongMap + along-light overlays from tokens; 127 B Abuja fixture + offline cache tests; build_tiles.sh; MapPanBenchmark (device skipped in CI); ADR-0018 maplibre_gl 0.22.0.
- Reviewer verdict: PASS WITH NOTES — flutter test 11 pass / 1 skip. Notes: no Tecno Spark 8C 60 fps run yet; fixture is structural stub; sprites/glyphs CDN; heading ticks missing.
- Rework count: 0
- Notes/escalations: Hardware 60 fps before Phase 1 exit. Tiles-only offline sufficient for MVP.

## [Phase 1 / P1-E-03] along_design components batch 1
- Status: PASS WITH NOTES
- Assigned: 2026-09-04
- Worker report summary: 16 batch-1 components; 104 goldens + TS-DS-03 1.3× on fare surfaces; flutter test 113/113 including TS-DS-02.
- Reviewer verdict: PASS WITH NOTES — visual ₦/fares/colours MET. Notes: BalanceCard stub (Phase 4); TS-DS-02 DEBUG ribbon cosmetic.
- Rework count: 0
- Notes/escalations: none blocking.

## [Phase 1 / P1-B-01] Rider app shell + R-01..R-04 onboarding
- Status: IN PROGRESS
- Assigned: 2026-09-05T13:45Z
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: none yet.

## [Phase 1 / P1-B-01] Rider app shell + R-01..R-04 onboarding
- Status: FAIL
- Assigned: 2026-09-05
- Worker report summary: Rider shell (flavours, Riverpod, go_router, ARB, Sentry) + R-01–R-04; widget tests 2/2; Patrol authored but SKIP (no emulator); claimed `flutter analyze` PASS.
- Reviewer verdict: FAIL — `flutter analyze` fails (`otp_flow_patrol_test.dart:65` skip type Object vs bool?); hardcoded OTP resend `30` and rate-limit `60` (gate a). Patrol not run (no device). Strings keyed MET.
- Rework count: 0 / 2
- Notes/escalations: Do not add a new `app_config` DB key — doc 02 §2.3 only defines `otp.rate_limit_per_hour`. Client UX timers belong on flavour `AppConfig` / env JSON. Honest Patrol SKIP remains NOTES after analyze is clean.

## [Phase 1 / P1-B-01] Rider app shell + R-01..R-04 onboarding
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Rider shell (flavours, Riverpod, go_router, ARB, Sentry) + R-01–R-04; AppConfig OTP/Sentry knobs; widget tests 2/2; analyze clean; Patrol SKIP (no emulator). Rework 1.
- Reviewer verdict: PASS WITH NOTES — all AC MET except Patrol emulator run (honest SKIP; widget + analyze cover). Strings keyed. No new DB keys.
- Rework count: 1 / 2
- Notes/escalations: Follow-up: run Patrol OTP on CI/emulator with `PATROL_HAS_EMULATOR=true` (absorb in P1-E-04 device smoke or Phase 1 gate). Cosmetic: `MaterialApp.title` not l10n; phone `onChanged` does not clear validation errors.

## [Phase 1 / P1-B-02] R-05 Home + R-06/R-06b search & pickup
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: R-05 AlongMap + ambient discs + peek/recents; Broadcast `ambient:{city}:{gh5}` after initial RPC; stale from `presence.stale_after_s`; location-denied banner; R-06/R-06b; client-side snap. Rework 1 (open Qs → Broadcast + no 15s poll).
- Reviewer verdict: PASS WITH NOTES — all three AC MET; 14 tests pass. Notes: R-06b map is a static placeholder; analyze unused-import warnings; no R-06 widget tests.
- Rework count: 1 / 2
- Notes/escalations: Follow-up: `rpc.snap_stage(p_lat, p_lng)` wrapper never shipped (P0-A-04 geography-only) — absorb in a later A-stream/planner task. R-06b interactive AlongMap polish before Phase 1 live corridor test.

## [Phase 1 / P1-B-03] R-07 options + R-09/R-10/R-18 request flow
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: R-07 plan-trip OptionCards + one-tap request/undo; R-09 load sheet; R-10 expires_at countdown; R-18 EmptyState; Tier 3 Agree price placeholder. Tests 14/14 rider + TS-UI-01/03.
- Reviewer verdict: PASS WITH NOTES — TS-UI-01/03 MET; FM36 inline warning MET but R-09 “Request anyway” `showCapacityWarning` never true (dead path). No R-11/negotiation/SQL.
- Rework count: 0
- Notes/escalations: Follow-up: wire `showCapacityWarning` when a candidate has load capacity none; add FM36/Tier 3 widget tests; l10n `option_card_mapper` meta strings; R-07/R-10 AlongMap placeholders.

## [Phase 1 / P1-C-01] Driver app shell + D-01..D-07 onboarding
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Driver shell + D-01–D-07; OCR confirm-before-fill; widget upload→pending; Patrol SKIP. 8/8 driver tests.
- Reviewer verdict: PASS WITH NOTES — both AC MET. Notes: along_data test fakes do not implement new `selectRows`/`uploadStorageObject` (suite compile-fails); Patrol SKIP; one `Text('${seatCapacity}')`.
- Rework count: 0
- Notes/escalations: Follow-up absorbed by P1-C-02: repair `along_data` test fakes. Backend: `start_driver_onboarding` listed in doc 03 but never migrated — later A-stream.

## [Phase 1 / P1-C-01] along_data test fakes after AlongSupabase change
- Status: BLOCKED — follow-up
- Assigned: 2026-09-05
- Worker report summary: P1-C-01 extended AlongSupabase; along_data FakeAlongSupabase / ConfigRepository test gateway not updated.
- Reviewer verdict: n/a — absorb in P1-C-02 (must compile `flutter test` in along_data).
- Rework count: 0
- Notes/escalations: none.

## [Phase 1 / P1-C-02] D-08 Home status, park, pings, demand
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: D-08 StatusToggle + demand discs + D-09 (at_park_radius_m); ping scheduler; battery guard; FG notification. along_data 8/8 compile fix absorbed. Rework 1 (open Qs: radius + drop 30s poll).
- Reviewer verdict: PASS WITH NOTES — all three AC MET. Notes: pings on main thread not isolate; hardcoded English on balance strip; no D-08 widget test.
- Rework count: 1 / 2
- Notes/escalations: P1-C-01 along_data fake follow-up absorbed (suite green). Isolate pings + D-08 l10n polish later.

## [Phase 1 / P1-C-03] D-10..D-13 route setup + publish
- Status: FAIL
- Assigned: 2026-09-05
- Worker report summary: D-10–D-13 + 1-tap/snap/monotone tests; 13/13 PASS.
- Reviewer verdict: FAIL — gate (a): hardcoded ₦300 fare fallback in `draw_route_controller.dart`. AC otherwise MET. Also load surcharge dropped on edit (`initialLoadSurcharge` always null).
- Rework count: 0 / 2
- Notes/escalations: none.

## [Phase 1 / P1-C-03] D-10..D-13 route setup + publish
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: D-10–D-13 + 1-tap/snap/monotone tests. Rework 1: removed ₦300 fallback; load surcharge parsed on edit. 8/8 route tests.
- Reviewer verdict: PASS WITH NOTES — all three AC MET; gate (a) closed. Notes: snapRadiusM=60 until config loads; no seeded integration test.
- Rework count: 1 / 2
- Notes/escalations: none blocking.

## [Phase 1 / P1-C-04] D-14 incoming request + Accept
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: D-14 sheet + load row pre-accept; commission from `commission.rate`; 1-tap Accept; Broadcast `driver:{id}`; StubPushService FCM. 22/22 driver tests.
- Reviewer verdict: PASS WITH NOTES — FM35 + 1-tap MET. Notes: FCM is stub-only (no FirebaseMessaging / background full-screen intent).
- Rework count: 0
- Notes/escalations: Follow-up: real FCM wake + push→present test (absorb in P1-E-04 device smoke).

## [Phase 1 / P1-D-01] A-04 verification queue + document viewer
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: A-04 queue + signed/watermarked viewer; migration 00020 `admin_log_view_document`; vitest 9/9; pgTAP 3/3; Playwright spec SKIP (Chromium hang).
- Reviewer verdict: PASS WITH NOTES — view_document audit MET (pgTAP). Playwright approve/reject specified but not executed. ADR-0015 policies untouched.
- Rework count: 0
- Notes/escalations: Run `admin-console/scripts/check_playwright.sh` when Chromium is available. Known: seed_core vs migration `app_config_pkey` still breaks `supabase db reset`.

## [Phase 1 / P1-E-04] Staging environment
- Status: BLOCKED — human
- Assigned: 2026-09-05
- Worker report summary: not started — requires paid/cloud accounts (Supabase project, routing VM, tiles CDN, Termii sandbox, FCM, Sentry) and secrets.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Autopilot stop (§6.3). Human must provision: Supabase staging (eu-west-2), OSRM/Photon VM, tiles CDN, Termii sandbox, FCM project, Sentry DSN. Then “continue” for Worker to wire env + smoke plan-trip from a device. Phase 1 gate also still needs: Tecno Spark 8C 60 fps (P1-E-02), Patrol OTP on emulator (P1-B-01), live corridor screenshots.

---

## [Phase 1 / Decision] Planner resolution: config defaults, staging provisioning, gate evidence
**Date:** 2026-09-05
1. **`seed_core` vs migration `app_config_pkey` is a Phase 1 gate blocker, not "known, non-blocking" → ADR-0016.** Root cause is a blueprint error (P0-A-01 put config defaults in the seed; `seed.sql` never runs on `db push`, so staging would have had no config). Migrations now own defaults via `config_default()` (`on conflict do nothing`); seeds own data only; migration 0014's `do update` is a defect. New task **P1-A-10** (S, depends P1-A-08) implements it, plus `TS-CFG-02`. Docs 02 §2.3/§17, 10, 11 amended. P1-A-10 must PASS before P1-E-04 wiring (staging needs the baseline migration).
2. **P1-E-04 provisioning** is the product owner's (autopilot §6.3 — correct stop). Scope trimmed for staging: OSRM car+foot on one VM now; **Photon deferred** to the first Phase 2 task that needs `places-search` (P1-A-07's Photon compose entry stays local-only until then); tiles = object bucket with range requests (no CDN product needed at staging volume).
3. **Gate evidence rules restated:** Tecno Spark 8C 60 fps needs the physical reference device (emulator numbers are not evidence); Patrol OTP runs against Supabase auth *test OTP* numbers in `config.toml`, never real SMS; a Reviewer may not PASS a task whose acceptance evidence is a Playwright/Patrol run that was skipped — mark PASS WITH NOTES + follow-up, and the phase gate stays open until the run exists.
**Escalations:** none.

---

## [Phase 1 / Decision] Staging provisioning outcomes and no-VM interim architecture
**Date:** 2026-09-05
1. **Provisioned by product owner:** Supabase staging project (PostGIS, pg_cron, btree_gist enabled); Termii account (sender-ID approval in progress); Firebase project with Android + iOS apps; Sentry org with projects mobile-rider (Flutter), mobile-driver (Flutter), admin-console (Next.js), functions (Deno).
2. **Not provisioned, worked around (doc 09 §1 amended):** no routing VM — OSRM stays in the local `backend/routing` compose, exposed for staging smokes via a free `cloudflared` quick tunnel (`OSRM_URL` secret set per smoke session); Edge Functions degrade per doc 01 §9 when unreachable. No Cloudflare — staging PMTiles served from a public Supabase Storage bucket `tiles-staging` (Range requests supported). Photon remains deferred (Phase 2). Oracle Cloud Always Free ARM VM noted as the permanent free option.
3. **Reference device = Xiaomi Redmi A2+** (owned; Android Go class), replacing the Tecno Spark 8C for all performance gates (doc 07 §device matrix amended). P1-E-02's 60 fps gate runs on it.
4. **Defect flagged during wiring review:** `backend/functions/_shared/fcm.ts` reads a static `FCM_ACCESS_TOKEN` env — Google OAuth access tokens expire in ~1 h, so push would die in staging. P1-E-04 wiring must mint tokens from the FCM service-account key (JWT → oauth2 exchange) with in-memory caching; the service-account JSON lives in Edge Function secrets, never in the repo.
5. **Secrets handling:** no secret is ever pasted into an agent chat. Shareable identifiers (Supabase URL/anon key, Firebase project id/package names, Sentry DSNs) go into gitignored env files; API keys and the FCM service account go in via `supabase secrets set` run by the human. P1-E-04 stays BLOCKED — human until the owner confirms the named files/secrets exist.
**Escalations:** none.

---

## [Phase 1 / Decision] App identifiers, SMS build-around, provisioning identifiers
**Date:** 2026-09-05
1. **Canonical app identifiers** (repo already uses them on Android): rider `ng.along.rider`, driver `ng.along.driver`, with `.dev`/`.staging` flavour suffixes; staging builds are `ng.along.rider.staging` / `ng.along.driver.staging`. iOS bundle ids must be **normalised to match** (`ng.along.rider` / `ng.along.driver`) — the rider Xcode project currently says `ng.along.mobileRider`; follow-up for the next mobile task. The `com.topmost.along` apps registered in Firebase are unused and may be deleted. **Open product question (before store release / doc 14 universal links):** confirm ownership of the `along.ng` domain, which both the reverse-DNS ids and `along.ng/p/*` QR links assume.
2. **Termii deferred (no CAC/business documents yet) — build around per ADR-0012, which already isolates SMS behind the Supabase Auth "Send SMS" hook:** staging runs the hook in **log mode** (`cfg sms.provider='log'`): the OTP is written to structured function logs / a private table instead of being sent; the owner reads it from the dashboard during device smokes; Patrol/CI keep using local test-OTP numbers. Swapping in Termii later is a config flip + secret, zero code rework. Real-user pilots (Phase 7) remain blocked on Termii sender-ID approval — product-owner action, not engineering.
3. **iOS push deferred** until an Apple Developer account exists (APNs key). Android-first matches the market; the staging smoke runs on the Redmi A2+.
4. **Provisioned identifiers:** Supabase staging ref `upqeypbdegteofwvekie`; Firebase project `along-32c0e`; Sentry org `along-a3` (DSNs pending — dashboard URLs are not DSNs). Firebase Android apps to register: `ng.along.rider.staging`, `ng.along.driver.staging`; `google-services.json` goes to the **flavour source set** (`android/app/src/staging/google-services.json`), placed by the wiring Worker from `env/`.
**Escalations:** along.ng domain ownership question to product owner.

---

## [Phase 1 / Decision] iOS compile-always; domain deferred; staging identifiers landed
**Date:** 2026-09-05
1. **iOS is first-class in the tree, deferred only for device/store.** Both apps must have an `ios/` project; CI on macOS runs `flutter build ios --no-codesign --flavor staging` for rider **and** driver every PR (doc 07 §1). Patrol iOS specs are written and `skip` unless `PATROL_IOS=true`. No Apple Developer account, certificates, TestFlight, or APNs until the owner has one. Hiding a feature behind `Platform.isAndroid` is a FAIL. New task **P1-E-05** (M, depends P1-E-01) — Phase 1 gate blocker. `mobile-driver` currently has no `ios/` directory; that is the first hole P1-E-05 closes. Bundle ids: `ng.along.rider` / `ng.along.driver` (normalise the rider Xcode project away from `ng.along.mobileRider`).
2. **No custom domain in scope until investment.** `cfg public.origin` (new doc 02 §2.3 key) is the only hostname clients/QR/share/W-04 use. Intended prod value `https://along.ng` when purchased; empty until then. Package IDs `ng.along.*` stay — they do not require owning the domain. Printed QR stickers and App/Universal Links stay gated while origin is empty; in-app `along://p/<code>` still works (doc 14 §2). Do not rename identifiers when a domain is later bought — only set `public.origin` and well-known files.
3. **Staging env files (gitignored except `*.example.json`):** `env/staging.json` written with Supabase URL/anon/publishable, project ref `upqeypbdegteofwvekie`, Firebase `along-32c0e`, four Sentry DSNs. Owner also placed `env/google-services.staging.json` (contains `ng.along.rider.staging` + `ng.along.driver.staging` + leftover `com.topmost.along`) and `env/fcm-service-account.staging.json`. P1-E-04 may wire from these files; still BLOCKED on the human running `supabase secrets set` for the FCM service-account JSON (do not paste into chat). SMS remains log-mode.
**Escalations:** none.

---

## [Phase 1 / Decision] Staging secrets ready — P1-E-04 unblocked
**Date:** 2026-09-05
- Product owner confirmed `npx supabase secrets set` succeeded for `FCM_SERVICE_ACCOUNT` on project `upqeypbdegteofwvekie`.
- Wiring inputs now present: `env/staging.json` (URL, anon, publishable, Sentry DSNs, Firebase project id), `env/google-services.staging.json`, `env/fcm-service-account.staging.json` (local only), Edge secret `FCM_SERVICE_ACCOUNT`.
- P1-E-04 is **unblocked**. Scope remains: no VM (OSRM via optional cloudflared + degrade), no Termii (SMS log-mode), `public.origin` empty, Android smoke on Redmi A2+, FCM token minting from the service-account key (not a static access token). iOS compile stays on P1-E-05; iOS device/push still deferred.
**Escalations:** none.

## [Phase 1 / P1-A-10] Config defaults → migrations (ADR-0016)
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: `config_default()` in 0002; baseline 00021 all §2.3 keys; seed globals removed; 0014/17/18 converted; TS-CFG-02 2/2; `db reset --yes` exit 0; CI grep + TS-CFG-02.
- Reviewer verdict: PASS WITH NOTES — all AC MET; 90/90 keys; live reset exit 0. Notes: local `pg_prove` missing (psql verified); sos.emergency_number duplicated in 00021 + seed (idempotent).
- Rework count: 0
- Notes/escalations: none blocking. Safe to `db push` baseline to staging.

## [Phase 1 / P1-E-04] Staging wiring
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: FCM JWT mint from FCM_SERVICE_ACCOUNT; send-sms log hook; wire_staging.sh; tiles-staging 00022; PostGIS search_path fixes; db push through 00022; Deno 33/33. Redmi smoke SKIP + runbook.
- Reviewer verdict: PASS WITH NOTES — no secrets in diff; FCM minting MET. Notes: device smoke human; .gitignore dropped supabase/.temp/.branches.
- Rework count: 1 / 2
- Notes/escalations: Human: enable Auth Send SMS hook + SEND_SMS_HOOK_SECRETS in dashboard; run `docs/runbooks/staging_android_smoke.md` on Redmi A2+. Restore supabase/.temp gitignore (absorb P1-E-05 if touching .gitignore).

## [Phase 1 / P1-E-05] iOS compile parity
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Driver ios/ scaffolded; rider bundle ids ng.along.rider; macos ios-compile CI for both apps; Patrol iOS skip; gitignore restored. Local xcodebuild missing.
- Reviewer verdict: PASS WITH NOTES — trees + IDs + CI job MET. Notes: CI green and local compile not verified; no Podfile committed (first CI risk).
- Rework count: 0
- Notes/escalations: Confirm `ios-compile` green on first remote CI run.

## [Phase 1 / Gate] Core Booking MVP
- Status: IN PROGRESS
- Assigned: 2026-09-05
- Worker report summary: n/a — gate review against master
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Stop after gate. Do not start Phase 2.

## [Phase 1 / Gate] Core Booking MVP
- Status: FAIL
- Assigned: 2026-09-05
- Worker report summary: n/a — all 23 Phase 1 tasks have PASS / PASS WITH NOTES; exit evidence not run.
- Reviewer verdict: FAIL — code/automated tests in place; §7 exit criterion NOT MET (no live corridor screenshots). Skipped: Redmi 60 fps, Patrol OTP, Playwright A-04, Redmi staging smoke, ios-compile CI green. FM36 `showCapacityWarning` still dead.
- Rework count: 0
- Notes/escalations: Human/device list to close the gate: (1) Auth Send SMS hook + secret; (2) Redmi A2+ smoke runbook; (3) Patrol OTP emulator; (4) Playwright A-04; (5) Redmi 60 fps; (6) ios-compile CI green; (7) live corridor E2E + screenshots (search, roaming map, publish <1 min, Tier 0 mid-route, FM35/36); (8) offline drop on rider map. Do not start Phase 2.

---

## [Phase 1 / Gate] PASS WITH DEFERRED EVIDENCE — Phase 2 authorised
**Date:** 2026-09-05
Product-owner decision: do not block engineering on human/device evidence. Spec §7 live-corridor exit is **not waived** — it is retargeted.

**Starts now (code, not evidence):**
- P1-B-04 — FM36 `showCapacityWarning` is a dead path (`false` literal). Defect, not a screenshot. Must PASS before anyone can claim FM36 on corridor day.
- P2-E-02 — Patrol OTP, Playwright A-04, ios-compile CI green. Automated; run in the Phase 2 stream.

**Deferred to P1-G-01 (human + Redmi A2+). Hard gate: Phase 3 must not start until PASS:**
- Dashboard Send-SMS hook + `SEND_SMS_HOOK_SECRETS`
- Staging Android smoke (logged OTP, plan-trip or honest degrade)
- MapPanBenchmark 60 fps
- Live corridor E2E + screenshots (graph fare/boarding, roaming on map, driver publish < 1 min, Tier 0 mid-route, FM35, FM36 after P1-B-04)
- Driver offline → gone from rider map

**Phase 2 is open.** First Worker task: P1-B-04 (unblocks a constitution failure), then P2-A-01 / P2-E-01 / P2-E-02 per dependencies. Do not open Phase 3 without P1-G-01.
**Escalations:** none.

## [Phase 1 / P1-G-01] Corridor evidence day
- Status: BLOCKED — human
- Assigned: 2026-09-05
- Worker report summary: not started — human + Redmi A2+ only.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Hard gate before Phase 3 *gate* and all Phase 4 (Phase 3 code may land). Now also includes Patrol OTP + ios-compile (absorbed from P2-E-02). Attach screenshots + notes when run.

## [Phase 1 / P1-B-04] FM36 live path (showCapacityWarning)
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Live R-09 derives warning from cfg load.warn_capacities + mode_config.load_capacity; Request anyway sets acknowledged_warning; 5/5 widget+unit tests; no dead `showCapacityWarning: false`.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Sheet uses recommended candidate mode, not the card later requested (server still rejects). Config fetch failure swallows warning (server backstop). Merged 9d0a6f0.

## [Phase 2 / P2-A-01] planner_decompose prod + plan-trip v2
- Status: PASS
- Assigned: 2026-09-05
- Worker report summary: Production k-shortest decompose + plan-trip v2 merge; Deno 10/10; pgTAP TS-PLAN-v2 + p95. Rework 1: TS-PLAN-03 four distinct sorts.
- Reviewer verdict: PASS (after 1 rework)
- Rework count: 1
- Notes/escalations: Merged 95c8004. Unblocks P2-A-05 and P2-B-01 (still needs P2-A-04).

## [Phase 2 / P2-E-01] along_design batch 2 goldens
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: NegotiationSheet, LegTimeline, FareHero, StepList, AmbientCluster + 25 goldens; full suite 129/129. AlongToast already covered snackbar matrix.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: AmbientCluster goldens omit some bucket×stale combos; LegTimeline no 1.3× golden. Merged ea515cd.

## [Phase 2 / P2-E-02] Phase 1 automated residuals
- Status: PASS WITH DEFERRED EVIDENCE
- Assigned: 2026-09-05
- Worker report summary: Playwright A-04 PASS (14/14). Patrol OTP and ios-compile not re-run — absorbed into P1-G-01 (owner 2026-09-06).
- Reviewer verdict: file review of iOS Podfile wiring only (standard Flutter CocoaPods, iOS 15). ios-compile is NOT green.
- Rework count: 0
- Notes/escalations: Did not merge whole `task/p2-e-02` (00024 audit_log would collide with 00024 negotiation). iOS Podfile/xcconfig/pbxproj/lock taken onto master only.

## [Phase 2 / Decision] P2-E-02 toolchain
**Date:** 2026-09-05
Answers (from spec / doc 11 — criteria not lowered):
- Patrol stays on P2-E-02. Do not absorb into closed P1-E-04 or P1-G-01 (Redmi corridor). Need a booted Android emulator (or attached device) on this Mac; then re-run with `--dart-define=PATROL_HAS_EMULATOR=true`.
- ios-compile: need full Xcode.app + `xcode-select` **or** a git remote + working `gh` so the macos `ios-compile` job can prove green. Local Podfile wiring is already on `task/p2-e-02`.
- Patrol invocation: `flutter test integration_test/otp_flow_patrol_test.dart --dart-define=PATROL_HAS_EMULATOR=true` is acceptable. `patrol_cli 3.14.1` missing from pub.dev is not a blocker.
Phase 2 continues with tasks that do not depend on P2-E-02. P1-G-01 still depends on P2-E-02 PASS.

## [Phase 2 / P2-A-02] Negotiation tables + RPCs + clock
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Migration 00024 RPCs + negotiation-clock Edge + Broadcast authz; pgTAP 26/26 TS-NEG-01..06; Deno clock test PASS.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Used registered key negotiation.roaming.pickup_radius_m (not doc 02's shorter name). Radius lapse needs rider_location lat/lng. Merged 4c5bfc5.

## [Phase 2 / P2-A-03] Roaming hail + dispatch cascade
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Migration 00025 HMAC tokens + hail_roaming + dispatch cascade; TS-DISC-05 4/4; TS-DISC-06 7/7; Deno 3/3.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Restrict sign_candidate_token to service_role in a follow-up. Merged 4652fbb.

## [Phase 2 / P2-A-04] Journeys multi-trip
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Migration 00026 journey SM + transfer-prefetch Edge; TS-TRIP-07 5/5; Deno 2/2.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Partial trip_transition (boarded/in_transit/completed) for journey advance — P3-A-01 must not duplicate. journey.* keys not in doc 02 §2.3. Merged b8092f9.

## [Phase 2 / P2-A-05] Speed-profile hook
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: Migration 00027 empty segment_speed_profiles + planner calibrateInVehicleS; 5/5 Deno unit tests (600s→1200s).
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: New test reused TS-PLAN-09 id (collision with p95). Merged ebd7e29.

## [Phase 2 / P2-B-01] Multi-leg rider UI
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: R-07/14/19 + TTS ADR-0020; widget TS-UI-01; R-14 auto-present; config poll + boarding radius. 2 reworks (literals; TS-CFG-02 list).
- Reviewer verdict: PASS WITH NOTES (after 2 reworks)
- Rework count: 2
- Notes/escalations: R-19 map mode is a placeholder (follow-up). Merged fccb2e2.

## [Phase 2 / P2-B-02] Along Pricing sheet + hail-from-cell
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: R-16 wired to negotiation RPCs; hail R-05→R-06→R-07→R-16; 8 widget tests. Rework: hail skip-to-pricing removed.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Terminal states tested via setTerminalForTest. Merged 024af3a.

## [Phase 2 / P2-C-01] Driver negotiation + roaming D-14
- Status: PASS
- Assigned: 2026-09-05
- Worker report summary: Driver NegotiationSheet + roaming D-14 cascade; identity tests strip phone; 7/7 tests.
- Reviewer verdict: PASS
- Rework count: 0
- Notes/escalations: Merged 3f47c9a.

## [Phase 2 / P2-D-01] Admin fare corrections queue
- Status: PASS WITH NOTES
- Assigned: 2026-09-05
- Worker report summary: A-06 /corrections + admin_review_fare_correction; Playwright A-06 1/1 (approve → confirmation + crowd_verified).
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: check_playwright.sh still loses to .env.local remote URLs if sourced after local exports. Merged 651663e.

## [Phase 2 / Gate] NOT OPEN — P2-E-02 still BLOCKED
**Date:** 2026-09-05
All other Phase 2 implementation tasks are PASS / PASS WITH NOTES. Phase 2 gate Reviewer not spawned: P2-E-02 is automated (not a human row) and is not PASS. Phase 3 not started. P1-G-01 remains the hard gate before Phase 3 once E-02 is PASS and corridor evidence is attached.

Remaining before Phase 2 gate can run:
- P2-E-02 — booted Android emulator + PATROL_HAS_EMULATOR=true; full Xcode.app or git remote + gh for ios-compile. Plumbing on `task/p2-e-02` @ eeabf0a (unmerged).
**Escalations:** none besides the two toolchain items already recorded.

---

## [Phase 2 / Gate] PASS WITH DEFERRED EVIDENCE — Phase 3 implementation authorised
**Date:** 2026-09-06
Product-owner: leave emulator / real-device / Xcode testing; keep building.

1. **P2-E-02** closed: Playwright A-04 already PASS (14/14). Patrol OTP and ios-compile **move into P1-G-01**. Do not re-block the loop on them. Merge Podfile-only commits from `task/p2-e-02` if they compile-check cleanly as files; do not claim `ios-compile` green.
2. **Phase 2 gate** = PASS WITH DEFERRED EVIDENCE. Spec §7 live transfer/sort/Pricing exit rides with P1-G-01.
3. **Phase 3 implementation is OPEN** (P3-A-01 first). The previous "Phase 3 must not start" line is amended: Phase 3 *code* may land; the **Phase 3 gate Reviewer and all Phase 4 tasks stay closed until P1-G-01 is PASS** (corridor + Redmi + Patrol OTP + ios-compile).
4. P3-B-01 / P3-C-01 acceptance still names live/airplane Na Me — Workers write the code and unit/widget tests; they record "live observation deferred to P1-G-01" instead of failing the task for lack of a device.
**Escalations:** none.

## [Phase 3 / P3-A-01] Full trip_transition + location + boarding
- Status: PASS
- Assigned: 2026-09-06
- Worker report summary: Migration 00031 lifecycle RPCs + auto-boarding; TS-TRIP-01/02/04/05 + false-trigger + TS-TRIP-07 all PASS. Commission stubbed.
- Reviewer verdict: PASS
- Rework count: 0
- Notes/escalations: New boarding.* keys not yet in doc 02 §2.3. Merged e097b7c.

## [Phase 3 / P3-A-02] Presence retention + stale hardening
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00032 presence_retention + stale broadcast; TS-PRES-02 3/3; retention fixture 5/5.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: stale_job_interval_s and realtime.* keys registered but not all wired. Merged 5800694.

## [Phase 3 / P3-A-03] Realtime location channel hardening
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00033 admin:{city} RLS + payload guard + trip_snapshot live; TS-DISC-04 7/7; TS-OPS-03 pilot 7/7.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Full 5k TS-OPS-03 deferred to P3-E-01. Merged be2061b.

## [Phase 3 / P3-B-01] Rider meet / Na Me / active trip
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: R-11/12/13 + TS-UI-02 widget (cached Na Me, no RPC); wayfinding CTA → R-19; 5/5 live_trip tests. Live/airplane deferred to P1-G-01.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: TS-CFG-02.sql missing motion.naMe.* / sos.hold_duration_ms (in app_config_keys + 00034). Map placeholder. Merged 94b8565.

## [Phase 3 / P3-C-01] Driver manifest + active trip
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: D-15/D-16 + shared NaMeFullscreen + TripLocationPublisher; 5/5 driver widget tests. Live deferred to P1-G-01.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Manifest missing drop-off/fare/no-show rows. Location publisher untested. Merged 01a1a1c.

## [Phase 3 / P3-E-01] Realtime/presence load test v1
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: k6 local pilot 10+10+5 VUs; ping p95 59.7 ms; fan-out p95 59.2 ms. Results in backend/load/results/.
- Reviewer verdict: PASS WITH NOTES
- Rework count: 0
- Notes/escalations: cells E2E latency not measured; presence-fanout ok check 0/13. Staging 5k waived. Merged b930227.

## [Phase 3 / Gate] NOT OPEN — waiting on P1-G-01
**Date:** 2026-09-06
All Phase 3 implementation tasks are PASS / PASS WITH NOTES. Phase 3 gate Reviewer **not spawned** (owner hard gate). Phase 4 **not started**.

To open the Phase 3 gate and Phase 4, attach P1-G-01 evidence (corridor + Redmi + Patrol OTP + ios-compile) and say continue.
**Escalations:** none.

---

## [Phase 3 / Gate] PASS WITH DEFERRED EVIDENCE — Phase 4 implementation authorised
**Date:** 2026-09-06
Product-owner: unblock Phase 4; continue deferring P1-G-01 (emulator / device / corridor / Xcode).

1. Phase 3 gate = PASS WITH DEFERRED EVIDENCE. Live trip, roaming hail, airplane-mode Na Me ride with P1-G-01 (checklist extended to include those Phase 3 observations).
2. **Phase 4 is OPEN** from P4-A-01. Do not spawn a Phase 3 gate Reviewer that would FAIL for missing screenshots.
3. **Hard gates from this point (do not move again without a new human decision):**
   - Do not start **Phase 7** (Abuja scale-out / real multi-corridor usage) until P1-G-01 is PASS.
   - Do not flip `cfg payments.digital_enabled` until **both** P4-E-02 (legal) **and** P1-G-01 are PASS.
   - P4-E-02 remains a human stop when reached — that is law, not a device.
4. Phase 4–6 implementation tasks: unit/pgTAP/widget/Playwright-against-local are enough; live-device clauses in acceptance are noted "deferred to P1-G-01", not FAIL.
**Escalations:** none.

## [Phase 4 / P4-A-01] Ledger + commission posting
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00036 — append-only driver_ledger_entries, ledger_post (advisory lock + idempotency), driver_balances, balance-aware driver_is_matchable, complete_trip cash_commission_debit. TS-LEDGER-01/02/04/05/06 all PASS locally (15 pgTAP + concurrency harness).
- Reviewer verdict: PASS WITH NOTES — all TS-LEDGER-01/02/04/05/06 independently re-run after supabase db reset. settlement_id FK deferred to P4-A-03; run_ts_ledger_04.sh leaves Zaria fixture (run after reset); multi-currency sum is NGN-pilot-safe.
- Rework count: 0
- Notes/escalations: Merged d7745a9. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-A-02] Threshold policy + standing + guarantors
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00037 — transition_standing, apply_threshold_policy (cron 10 min), notifications, guarantors RPCs, admin RPCs, my_standing_history, flags schema-only. TS-LEDGER-07 9/9 PASS.
- Reviewer verdict: PASS WITH NOTES — independently re-ran TS-LEDGER-07; FM13 honored; no auto-deactivate; guarantor notification-only. SMS delivery deferred.
- Rework count: 0
- Notes/escalations: Merged b3fff55. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-A-03] Settlements + Paystack webhook
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00038 — settlements, settlement_agents, webhook raw, agent RPCs, PaymentProvider + Paystack HMAC-SHA512, Edge settlement/initiate + webhooks/paystack. TS-LEDGER-03/08/09 PASS. digital_enabled unchanged.
- Reviewer verdict: PASS WITH NOTES — pgTAP + Deno independently verified. Deno cash-trip fetch-spy is vacuous (SQL+pgTAP still prove zero payment rows). Deploy webhooks/paystack with --no-verify-jwt.
- Rework count: 0
- Notes/escalations: Merged 01bb655. Live-device: deferred to P1-G-01. P4-E-02 legal stop still ahead.

## [Phase 4 / P4-A-04] Rider digital payment + confirm_fare + ratings
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00039 — payments, ratings, confirm_fare (FM33), rate_trip, complete_trip itemisation, payments/initiate fail-closed, webhook payment_id. digital_enabled remains false.
- Reviewer verdict: PASS WITH NOTES — TS-UI-04 SQL 5/5 + Deno 4/4 independently re-run. Notes: db.types.ts stale; OpenAPI still requires driver_code (deferred P4-A-09); rate_trip negatives untested.
- Rework count: 0
- Notes/escalations: Merged 3615eee. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-A-05] Trip extensions
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00040 — propose_extension / respond_extension; complete_trip posts base + accepted ext commissions (ext:{id}); resolve_fare unmodified. TS-TRIP-08 9/9 PASS.
- Reviewer verdict: PASS WITH NOTES — independently re-ran TS-TRIP-08; resolve_fare hard gate clean; no ledger_post on accept. Tier-3 negotiation path client-triggered, not in pgTAP.
- Rework count: 0
- Notes/escalations: Merged 433bcf8. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-A-06] Reconciliation + risk scores
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00041 — reconcile_cancelled_trips, undeclared_extension, compute_risk_scores, driver_risk_scores. TS-INTEG-01..05 9/9 PASS. FM13: flags do not change standing.
- Reviewer verdict: PASS WITH NOTES — independently re-ran TS-INTEG-01..05 + TS-LEDGER-07. Score formula matches §13. TS-INTEG-06 correctly deferred.
- Rework count: 0
- Notes/escalations: Merged 58af5e0. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-A-07] Dual-control adjustments + payouts
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00042 — pending_ledger_adjustments (SQL dual control), driver_payouts, admin RPCs, transfer.success → payout_debit. TS-LEDGER-10 13/13 PASS.
- Reviewer verdict: PASS WITH NOTES — independently re-ran 13/13. initiatePayoutTransfer not wired to an edge caller (P4-D-01); recipient placeholder until P4-A-08.
- Rework count: 0
- Notes/escalations: Merged 2d658ff. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-B-01] Rider complete / extend / history / pay sheet
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: R-17 2-tap complete (confirm_fare+rate_trip), R-15 embed R-06 + 1-tap accept, R-22 history+itemised receipt, R-27 hidden when digital_enabled=false. Widget tests 12/12.
- Reviewer verdict: PASS WITH NOTES — independently re-ran 12/12. Pay submit is placeholder snackbar; R-22 omits map/leg list; R-27 full states deferred to P4-B-02 while flag is off.
- Rework count: 0
- Notes/escalations: Merged cb9579c. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-C-01] Driver earnings / settle / standing
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migrations 00043/00044, D-08 banner (TS-UI-05), D-17–22, LedgerRow, nearby agents. Rework: Money import + fake defaults. mobile-driver 37/37.
- Reviewer verdict: PASS WITH NOTES (recheck) — prior FAIL items gone; full suite 37/37; unused_import warning on standing_screen.
- Rework count: 1 / 2
- Notes/escalations: Merged e6e3c94. Live-device: deferred to P1-G-01.

## [Phase 4 / P4-D-01] Admin integrity + finance
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00045 admin_review_flag; A-10/11/13; TS-INTEG-06 6/6; Playwright dual-control 1 passed (Node 22). Safety cannot transition standing.
- Reviewer verdict: PASS WITH NOTES — TS-INTEG-06 independently 6/6; FM13 holds; Playwright ledger-count flaky on reused DB (fresh reset via check_playwright.sh).
- Rework count: 0
- Notes/escalations: Merged 18964f2. Live-device map: deferred to P1-G-01.

## [Phase 4 / P4-E-01] Agent settlement page
- Status: PASS
- Assigned: 2026-09-06
- Worker report summary: /agent page gated on settlement_agents.profile_id; confirm_agent_settlement; Playwright redeem + replay + admin forbidden 2/2.
- Reviewer verdict: PASS — independently re-ran Playwright 2/2. digital_enabled unchanged. No QR/CRM.
- Rework count: 0
- Notes/escalations: Merged 5328abb. Live-device: deferred to P1-G-01. Next: P4-A-08 (subaccounts). P4-E-02 remains a human legal stop after A-08/A-09.

## [Phase 4 / Decision] P4-A-08 money path locked
- Status: PASS
- Assigned: 2026-09-06
- Worker report summary: Owner continue: start P4-A-08 then P4-A-09; stop and escalate at P4-E-02; do not flip payments.digital_enabled.
- Reviewer verdict: n/a (owner decision)
- Rework count: 0
- Notes/escalations: Split at source (ADR-0010). Persist payout_subaccount_code + payout_bank_last4 only. set_payout_bank requires OTP re-auth. Driver without subaccount → digital option hidden. Split amounts equal fare − commission / commission to the minor unit. Live-device deferred to P1-G-01. P1-G-01 still blocks Phase 7 only.

## [Phase 4 / P4-A-08] Paystack subaccounts
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: payouts/set-bank + persist last4/subaccount; split kobo tests; reconcile_split_settlements. Deno 14/14, pgTAP 9/9. digital_enabled unchanged.
- Reviewer verdict: PASS WITH NOTES (recheck) — prior db.types.ts pollution gone; typecheck clean; AC MET. Notes: Edge adapter vs rpc.set_payout_bank; Flutter D-24 deferred.
- Rework count: 1 / 2
- Notes/escalations: Merged 5240c67. Live-device: deferred to P1-G-01. Next: P4-A-09 (QR backend). Then stop at P4-E-02 (human legal). Do not flip digital_enabled.

## [Phase 4 / P4-A-09] QR scan-to-pay backend
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: Migration 00047; qr/resolve, initiate extension, methods, receipt; HMAC tokens; expire_payments; payment_received notify. pgTAP 35/35, Deno 10/10. digital_enabled unchanged. Zero card data at rest.
- Reviewer verdict: PASS WITH NOTES — TS-QR-01..12 MET; flag still false. Notes: expired-token pgTAP missing; CONFLICT body omits existing payment_id; saved-auth Edge test thin.
- Rework count: 0
- Notes/escalations: Merged 3e07ecf. Live-device: deferred to P1-G-01. Follow-ups absorb into P4-B-02 (CONFLICT payment_id + expired-token test).

## [Phase 4 / P4-A-09 follow-up] Initiate CONFLICT + expired token tests
- Status: BLOCKED — follow-up
- Assigned: 2026-09-06
- Worker report summary: n/a
- Reviewer verdict: P4-A-09 notes — absorb into P4-B-02
- Rework count: 0
- Notes/escalations: (1) Return existing payment_id on second initiate CONFLICT. (2) pgTAP expired HMAC token → CANDIDATE_EXPIRED. (3) Optional: Deno min_digital_amount / missing subaccount / chargeAuthorization ownership.

## [Phase 4 / P4-E-02] Legal review checkpoint (human)
- Status: BLOCKED — human
- Assigned: 2026-09-06
- Worker report summary: n/a — human legal stop. Orchestrator did not attempt.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: STOP. Confirm no-funds-held posture under CBN rules with split payments; subaccount KYC obligations; VAT on commission; driver/rider terms; fee-bearer economics (`payments.fee_bearer`) vs current Paystack schedule. Written sign-off must attach to this ledger. Do NOT flip `payments.digital_enabled` until BOTH this sign-off AND P1-G-01 are PASS. Digital/QR stay behind the flag. Next implementation tasks after sign-off (not before flag flip): P4-B-02 / C-02 / D-02 / E-03.

---

## [Phase 4 / P4-E-02] NOT SIGNED OFF — remaining Phase 4 UI authorised, flag stays false
**Date:** 2026-09-06
Product-owner asked the planner to "grant the sign-offs." **Refused.** P4-E-02 is a Nigerian-counsel checkpoint (CBN payments/super-agent questions, KYC on Paystack subaccounts, VAT on marketplace commission, contract terms, fee-bearer economics). An AI session and a founder chat are not that memo. Recording a PASS here would be a false gate.

**Engineering posture (unchanged, ADR-0010):** digital path is split-at-source; Along is not intended to hold rider or driver funds; `payments.digital_enabled` remains **false** in all environments until counsel's memo is attached to this ledger **and** P1-G-01 is PASS.

**Authorised now:** P4-B-02, P4-C-02, P4-D-02, P4-E-03. UI may exist behind the flag / cash-only states. Do not enable the flag, do not print QR stickers for production use, do not take a real rider card payment.

**Still required before any live digital payment (owner action, not Orchestrator):**
1. Instruct Nigerian fintech/payments counsel with ADR-0010, doc 12 §7, doc 14, and the Paystack split/subaccount contract.
2. Attach their written opinion to this ledger as `[Phase 4 / P4-E-02] PASS` (or FAIL with required architecture changes).
3. Separately: P1-G-01.

P1-G-01 still blocks Phase 7 only.
**Escalations:** none — this *is* the escalation outcome.

## [Phase 4 / Decision] Continue remaining Phase 4 UI; E-02 still refused
- Status: PASS
- Assigned: 2026-09-06
- Worker report summary: Owner continue through B-02 → C-02 → D-02 → E-03 then Phase 4 code gate then Phase 5. P4-E-02 remains NOT PASS.
- Reviewer verdict: n/a (owner decision)
- Rework count: 0
- Notes/escalations: Flag stays false. Cash-only / flag-gated UI only. No production QR stickers. No real rider charge. Do not flip digital_enabled until counsel memo as P4-E-02 PASS AND P1-G-01 PASS. Do not start Phase 7 until P1-G-01 PASS.

## [Phase 4 / P4-B-02] Rider pay / scan / methods
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: R-27 states + R-31 typed/fake scan + R-32 methods + app_links. Flutter 20/20, Deno initiate 7/7. digital_enabled unchanged. A-09 CONFLICT payment_id absorbed.
- Reviewer verdict: PASS WITH NOTES — TS-UI-06 MET. Notes: Save receipt missing; R-26→R-32 unlinked; no keypad Other; deep-link untested; live camera stub.
- Rework count: 0
- Notes/escalations: Merged 9a9aaf2. Live-device camera: deferred to P1-G-01. Follow-ups: Save receipt / R-26 link / Other keypad absorb into P5-B-01 account or later polish.

## [Phase 4 / P4-A-09 follow-up] Initiate CONFLICT + expired token tests
- Status: PASS
- Assigned: 2026-09-06
- Worker report summary: Absorbed in P4-B-02 — CONFLICT returns payment_id; expired HMAC pgTAP added.
- Reviewer verdict: covered under P4-B-02 PASS WITH NOTES
- Rework count: 0
- Notes/escalations: Closed by 9a9aaf2.

## [Phase 4 / P4-C-02] Driver QR / payment request
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: D-25/D-26, D-16/D-18 request+digital-paid (rework 1 wired), D-19 section, D-08 toast. qr_flutter 4.1.0. Migration 00048 sticker RPC. Widget 8/8, suite 44/44. digital_enabled unchanged.
- Reviewer verdict: PASS WITH NOTES (recheck) — ACs MET; D-18 wired. Notes: no haptic/sound; no full ActiveTripScreen integration test.
- Rework count: 1 / 2
- Notes/escalations: Merged 5c99872. Live-device camera: deferred to P1-G-01. No production stickers printed.

## [Phase 4 / P4-D-02] W-04 web pay + admin QR ops
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: W-04 /p/[code], A-11/A-13, STAGING PDF, ADR-0021. Rework: PostgREST reload, local env after .env.local, pdfkit, driver_vehicles RLS.
- Reviewer verdict: PASS WITH NOTES (recheck) — W-04 #20–23 PASS independently; 22/23 overall. Note: verification.spec.ts heading collision (pre-existing). Flag still false. Paystack mocked.
- Rework count: 1 / 2
- Notes/escalations: Merged (this commit). Live-device: deferred to P1-G-01. Do not print production stickers. Do not flip digital_enabled.

---

## [Planning] Spec §4.1.2/4.1.3 wait-decision + FM41–43 — parked for after P4-D-02
**Date:** 2026-09-07
Product-owner: coarse pre-accept approach band + post-accept walking-route ETA / one-tap release / rider no-show review.

**Do not fold into in-flight P4-D-02 (W-04 / A-11 / A-13).** Finish that task, merge, then issue:
- **P3-A-04** wait-decision backend (TS-DISC-07, TS-WAIT-01..05)
- **P3-C-02** D-14 band + D-16 ETA/Release

Critical implementation split (Workers will get this wrong if they only read "trips row = Tier B"):
- `requested` → driver sees `approach_band` only (FM42). A trips row exists; GPS still withheld.
- `accepted` → walking-route `wait.walk_eta_s` (FM41), not haversine.
- `release_match` → `released_before_arrival`, excluded from `reconcile_cancelled_trips` (not `cancel_trip`).
- Missing GPS → `approach=unknown`, never stalled.
- FM43 = admin flag only.

Config keys: `disclosure.approach_band_s`, `wait.stalled_*`, `wait.release_pickup_radius_m`, `rider.no_show_*`.
**Escalations:** none.

## [Phase 4 / P4-E-03] Universal links + sticker spec + runbook
- Status: PASS WITH NOTES
- Assigned: 2026-09-06
- Worker report summary: AASA + assetlinks well-known routes; print spec ≥70 mm EC-H; runbook qr_sticker_lifecycle. Vitest 5/5. Flag unchanged. No production print.
- Reviewer verdict: PASS WITH NOTES — server files MET; native iOS/Android App Link config documented not committed. Device camera gate deferred to P1-G-01.
- Rework count: 0
- Notes/escalations: Merged e6b3bb7. Absorb native entitlements into store-release / P1-G-01.

## [Phase 4 / Gate] Code gate (implementation only)
- Status: FAIL
- Assigned: 2026-09-06
- Worker report summary: n/a (gate Reviewer)
- Reviewer verdict: FAIL — rider `payments_test.dart` does not compile (duplicate `QrPayloadParser` after along_core export in d1599e1). Flag still false; cash/Paystack isolation PASS; split-at-source PASS.
- Rework count: 0
- Notes/escalations: Blocking for Phase 5 only. Does not block P3-A-04. Absorb: one-line import hide/remove in mobile-rider tests. Residuals: P4-E-02, P1-G-01, verification.spec.ts flake.

## [Phase 4 / Decision] D-02 merged; wait-decision spec already on master
- Status: PASS
- Assigned: 2026-09-07
- Worker report summary: Owner: do not interrupt P4-D-02; do not add wait-ETA application code to that branch. After D-02 merge, cherry-pick 1340bbc + 85abb67 if missing, then P3-A-04 → P3-C-02.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: D-02 already merged `e5e2908`. Commits 1340bbc and 85abb67 are already ancestors of master (docs/spec only — no wait-ETA application code on the D-02 product branch). Cherry-pick skipped. Issuing P3-A-04.

## [Phase 3 / P3-A-04] Wait-decision backend
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00050 — approach_band, refresh_wait, release_match → released_before_arrival, rider_no_show_review. TS-DISC-07 6/6, TS-WAIT-01..05 9/9.
- Reviewer verdict: PASS WITH NOTES — hard rules MET (grep-clean pre-accept; release_match never cancel_trip; OSRM foot; unknown≠stalled; FM43 review-only). Notes: wait null until first sample; parked request not separately tested.
- Rework count: 0
- Notes/escalations: Merged aed000b. Next: P3-C-02.

## [Phase 3 / P3-C-02] D-14 band + D-16 ETA/Release
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: D-14 approach_band labels only (FM42). D-16 walk_eta_s + stalled caption + one-tap release_match. Widget tests 16/16.
- Reviewer verdict: PASS WITH NOTES — hard rules MET (grep-clean D-14; release_match never cancel_trip; stalled never when unknown; Release hidden after boarded). Notes: unused incomingRequestPickupMeta l10n; no widget tap on Release; wait Realtime not wired (trip_snapshot only).
- Rework count: 0
- Notes/escalations: Merged 1cc6f3e. Wait-decision backend+UI complete (P3-A-04 + P3-C-02). Phase 5 still blocked on Phase 4 gate compile FAIL. P4-E-02 remains human counsel.

## [Phase 4 / Decision] Absorb gate compile break; re-run code gate; stop
- Status: PASS
- Assigned: 2026-09-07
- Worker report summary: Owner: absorb the Phase 4 gate compile break (`payments_test.dart` duplicate `QrPayloadParser`), re-run the Phase 4 code gate, then stop. Phase 5 stays closed until that gate is PASS. Do not re-implement wait-decision. Do not grant P4-E-02. Do not flip `payments.digital_enabled`.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Issuing P4-GATE-01. Next after absorb+gate: if PASS / PASS WITH DEFERRED EVIDENCE → P5-A-01 on resume (not this session). If still FAIL → Reviewer's exact compile/test fix.

## [Phase 4 / P4-GATE-01] Absorb rider payments_test QrPayloadParser clash
- Status: PASS
- Assigned: 2026-09-07
- Worker report summary: Removed local `qr_payload_parser.dart` import (and unused drift import) from `mobile-rider/test/payments_test.dart`. `QrPayloadParser` resolves via along_core. Production parser untouched. dart analyze clean; flutter test 8/8.
- Reviewer verdict: PASS — 1 file, 2 deletions; analyze clean; 8/8 tests independently re-run. Production parser still present.
- Rework count: 0
- Notes/escalations: Merged 3b4a481. Re-running Phase 4 code gate on master. Phase 5 still closed until that gate is PASS.

## [Phase 4 / Gate] Code gate re-run (implementation only)
- Status: PASS WITH DEFERRED EVIDENCE
- Assigned: 2026-09-07
- Worker report summary: n/a (gate Reviewer after P4-GATE-01 absorb)
- Reviewer verdict: PASS WITH NOTES on implementation — prior compile FAIL fixed (`payments_test.dart` analyze clean, 8/8). Flag still false. Cash trip zero Paystack (Deno TS-UI-04 7/7; pgTAP cash complete_trip / cash-no-payment). TS-LEDGER-01..06 15/15. TS-LEDGER-06 park+roaming block. TS-INTEG-01..05 9/9. TS-TRIP-08 9/9. Split-at-source wired. Notes: TS-QR-01-12 plan(35)/ran 36 (all ok); pg_prove missing (psql used).
- Rework count: 0
- Notes/escalations: Residuals (not code defects): **P4-E-02** human counsel — never PASS; **P1-G-01** device/corridor; native App Link entitlements not in repo; camera stub; verification.spec.ts flake not re-run. Do not flip `payments.digital_enabled`. Do not start Phase 7. Next implementation task when resumed: **P5-A-01**. Not started this session.

## [Phase 5 / Decision] Continue — open Phase 5 implementation
- Status: PASS
- Assigned: 2026-09-07
- Worker report summary: Owner: continue. Phase 4 code gate is PASS WITH DEFERRED EVIDENCE. Issue P5-A-01. Do not grant P4-E-02. Do not flip `payments.digital_enabled`. Do not start Phase 7. Do not re-implement wait-decision.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Issuing P5-A-01.

## [Phase 5 / P5-A-01] SOS, trip share, incidents RLS
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00051 SOS/shares/incidents + notify kind=sos. Rework 1: shared_trip_view ETA uses cfg planner.baseline_speed_mps. TS-SOS-01 9/9, TS-SOS-02 6/6, Deno SOS 1/1.
- Reviewer verdict: PASS WITH NOTES — prior 8.0 FAIL fixed. RLS + hashed tokens + no SOS rate-limit MET. Notes: SMS log-provider path; incidental policy snapshot regen.
- Rework count: 1
- Notes/escalations: Merged 235c680. Next: P5-A-02.

## [Phase 5 / P5-A-02] Women-only matching
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00052 — request_trip/hail_roaming women_only eligibility + regulatory_flags gating. TS-PLAN-07-request-enforcement 5/5; planner TS-PLAN-07 ok 6–7 still pass.
- Reviewer verdict: PASS WITH NOTES — acceptance MET. Note: TS-PLAN-v2 TS-PLAN-01/02 decompose 3/8 FAIL is pre-existing (planner/decompose, not this diff).
- Rework count: 0
- Notes/escalations: Merged 3e80c97. Residual planner decompose failures are not P5-A-02. Next: P5-A-03.

## [Phase 5 / P5-A-03] Day planner itineraries
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00053 itineraries/RPCs; parse-itinerary stub never writes; itinerary-prepare + match_next store prepared_plan. Deno 4/4, pgTAP 5/5. FM23 flags on payloads.
- Reviewer verdict: PASS WITH NOTES — acceptance MET. Notes: parse is bounded stub not LLM; itinerary-prepare Edge has no Deno tests (SQL path covered).
- Rework count: 0
- Notes/escalations: Merged 5890db0. Next: P5-B-01.

## [Phase 5 / P5-B-01] Rider SOS, report, share, account
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: R-23–R-26 + W-01 `/s/[token]`. Flutter 4/4 (2G SOS gate); vitest 2/2. Rework 1: ADR-0019 url_launcher 6.3.1; W-01 CSS tokens only.
- Reviewer verdict: PASS WITH NOTES — prior ADR + FM20 FAIL fixed. SOS 2G ≤ 10 s MET. W-01 minimal data MET. Notes: Drift warnings; Playwright W-01 not independently run.
- Rework count: 1
- Notes/escalations: Merged 6db0e7a. Next: P5-B-02. P4-E-02 still human. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 5 / Decision] Continue — remaining Phase 5 implementation then code gate
- Status: PASS
- Assigned: 2026-09-07
- Worker report summary: Owner: start at P5-B-02; finish remaining Phase 5 implementation (B-02, C-01, D-01, E-01); run Phase 5 code gate; then stop. Do not open Phase 6. Do not re-implement SOS, women-only, itinerary backend, or R-23–R-26 / W-01. Do not grant P4-E-02. Do not flip payments.digital_enabled. Do not start Phase 7.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Issuing P5-B-02. After E-01 merge, spawn Phase 5 code gate Reviewer against master. Next after this session if gate PASS / PASS WITH DEFERRED EVIDENCE: P6-D-01 (do not start it here).

## [Phase 5 / P5-B-02] R-20 Day planner, R-21 itinerary entry
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P5-A-03 PASS. FM23 copy; Match now = 1 tap reusing request_trip. Do not absorb TS-PLAN-v2 decompose 3/8.

## [Phase 5 / P5-B-02] R-20 Day planner, R-21 itinerary entry
- Status: FAIL
- Assigned: 2026-09-07
- Worker report summary: R-20/R-21 UI; FM23 copy tests; Match now → request_trip; parse confirm gate; load via create_itinerary(p_load); Add stop via update_itinerary_stops. Flutter 8/8. Open-Q rework then Reviewer FAIL.
- Reviewer verdict: FAIL — home_bottom_sheet.dart uses context.push(AppRoutes.itineraryEntry) without go_router / AppRoutes imports (analyze errors). AC otherwise MET (FM23, Match now 1 tap). Notes: itinerary_stop_id on plan-trip only, not request_trip payload; swipe-to-remove is ✕ icon.
- Rework count: 1
- Notes/escalations: Rework 2/2 — add missing imports; flutter analyze clean on that file. Do not invent update_itinerary_load. Do not absorb TS-PLAN-v2.

## [Phase 5 / P5-B-02] R-20 Day planner, R-21 itinerary entry
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: R-20/R-21 UI; FM23 copy; Match now → request_trip 1 tap; parse confirm gate; p_load at create; Add stop via update_itinerary_stops. Rework 2: home_bottom_sheet go_router imports. Flutter 8/8.
- Reviewer verdict: PASS WITH NOTES — prior compile FAIL fixed (analyze clean). FM23 and Match now MET. Notes: itinerary_stop_id not on RequestTripRequest; swipe is ✕; hardcoded Abuja origin; R-20 load toggle read-only (create-time persist).
- Rework count: 2
- Notes/escalations: Merged 4e54379. Follow-ups not Phase 5 blockers. Next: P5-C-01. P4-E-02 still human. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 5 / P5-C-01] Driver SOS, incident, D-18 rating, D-24
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P5-A-01 PASS. Same SOS gates as P5-B-01 (2G ≤ 10 s). Reuse raise_sos/update_sos/report_incident. Do not redo rider SOS.

## [Phase 5 / P5-C-01] Driver SOS, incident, D-18 rating, D-24
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Driver SOS active + 2G gate; incident report; D-18 rating tags; D-24 account. url_launcher 6.3.1 (ADR-0019). Flutter 52/52.
- Reviewer verdict: PASS WITH NOTES — SOS gates MET. Notes: D-24 vehicle switch deferred (no RPC); ADR-0019 Used-in lists rider only; hold-to-cancel untested.
- Rework count: 0
- Notes/escalations: Merged 8728828. Next: P5-D-01. P4-E-02 still human. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 5 / P5-D-01] A-12 Safety board + sos_escalation runbook
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P5-A-01 PASS. admin_ack_sos / admin_resolve_sos named in doc 03 but missing from 00051 — in scope for ack-pushes-to-rider. SLA 60s/180s via app_config.

## [Phase 5 / P5-D-01] A-12 Safety board + sos_escalation runbook
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00054 admin_ack_sos/resolve/triage; notify sos_ack; A-12 board; runbook rota. pgTAP 8/8, Deno 2/2, Vitest 2/2. Playwright spec written not run.
- Reviewer verdict: PASS WITH NOTES — AC MET independently. Notes: Playwright not run (admin-console down); no embedded MapLibre (OSM link); ops_agent RPC vs route allowlist.
- Rework count: 0
- Notes/escalations: Merged db016e1. Next: P5-E-01. P4-E-02 still human. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 5 / P5-E-01] along_design batch 3 goldens
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P2-E-01 PASS. Scope: NaMeScreen polish, StepList audio state, itinerary timeline, SOS styles. Goldens required.

## [Phase 5 / P5-E-01] along_design batch 3 goldens
- Status: FAIL
- Assigned: 2026-09-07
- Worker report summary: NaMeScreen, StepList audio, LegTimeline full, HoldButton SOS; 13 task goldens PASS. Claimed full golden suite PASS — Reviewer found 6 BalanceCard pixel failures.
- Reviewer verdict: FAIL — flutter test test/golden/ 126 pass / 6 fail (balance_card_*). Task goldens MET. along_core path dep made BalanceCard tests compile (they do not even load on master).
- Rework count: 1
- Notes/escalations: Rework 1/2 — regenerate BalanceCard goldens so full test/golden/ is 0 failures. Do not rewrite BalanceCard unless required. Do not claim full suite PASS until the command exits 0.

## [Phase 5 / P5-E-01] along_design batch 3 goldens
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: NaMeScreen, StepList audio, LegTimeline full, HoldButton SOS; 13 task goldens + along_core path dep. Rework 1: regenerate 6 BalanceCard PNGs. Full golden suite 132/132.
- Reviewer verdict: PASS WITH NOTES — prior FAIL fixed (132/132 independently). Note: along_core path dep formalizes existing import.
- Rework count: 1
- Notes/escalations: Merged c027b3b. All Phase 5 implementation tasks PASS. Issuing Phase 5 code gate. Do not start Phase 6 until gate recorded. P4-E-02 still human. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 5 / Gate] Code gate (implementation-checkable)
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: n/a (gate Reviewer against master 8853086 after P5-E-01)
- Reviewer verdict: PASS WITH NOTES — SOS pipeline MET (raise_sos→notify sos; admin_ack_sos→sos_ack Deno 2/2). Share-token TS-SOS-02 6/6. Incidents RLS authorization MET (finance/non-reporter blocked). Rider+driver 2G widget gates PASS. FM23 day_planner 9/9 rider tests. Women-only TS-PLAN-07 5/5. Flag still false. Notes: TS-SOS-01 7/9 (count 2 vs 1 from leftover E2E incident row, not auth bypass); Playwright safety-board / W-01 not run (admin-console down).
- Rework count: 0
- Notes/escalations: Residuals: **P4-E-02** human counsel — never PASS; **P1-G-01** live-device/corridor/2G field — deferred, not a code-gate fail. Do not flip payments.digital_enabled. Do not start Phase 7. Next implementation when resumed: **P6-D-01**. Not started this session.

## [Phase 6 / Decision] Continue — open Phase 6 implementation then code gate
- Status: PASS
- Assigned: 2026-09-07
- Worker report summary: Owner: open Phase 6 from P6-D-01; finish remaining Phase 6 tasks; run Phase 6 code gate; then stop. Do not open Phase 7. Do not re-implement Phase 5. Do not grant P4-E-02. Do not flip payments.digital_enabled. Do not absorb Phase 5 residuals.
- Reviewer verdict: n/a
- Rework count: 0
- Notes/escalations: Issuing P6-D-01. After E-01 merge, spawn Phase 6 code gate Reviewer against master. Next after this session if gate PASS / PASS WITH DEFERRED EVIDENCE: escalate — Phase 7 stays CLOSED until P1-G-01 PASS.

## [Phase 6 / P6-D-01] A-02 Ops dashboard + A-15 Corridor analytics
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P4-A-06 PASS. admin_corridor_analytics missing — implement here, bounded/paginated, conversion metric review-not-punish (FM13). No live map (P6-D-02).

## [Phase 6 / P6-D-01] A-02 Ops dashboard + A-15 Corridor analytics
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00055 admin_corridor_analytics (bounded, conversion diagnostic_only). A-02 KPI tiles; A-15 series/gaps table/CSV. pgTAP 11/11; Vitest 25/25.
- Reviewer verdict: PASS WITH NOTES — AC MET independently. Notes: city-wide fare-discrepancy tile null when multi-corridor; coverage gaps table not map (P6-D-02).
- Rework count: 0
- Notes/escalations: Merged a299038. Next: P6-D-02. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 6 / P6-D-02] A-03 Live map
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P3-A-03 PASS. Precise positions admin-role only (RLS). FM19 vector tiles. FM21 no leak to non-admin. No Phase 5 redo.

## [Phase 6 / P6-D-02] A-03 Live map
- Status: FAIL
- Assigned: 2026-09-07
- Worker report summary: A-03 /live MapLibre+PMTiles; TS-OPS-04 9/9; ADR-0013 maplibre-gl 5.6.1 + pmtiles 4.3.0.
- Reviewer verdict: FAIL — AC MET (admin-only precise positions). Gates FAIL: (a) hardcoded 5000 ms poll in AdminLiveMap.tsx; (f) ~20 inline hex in MapLibre paint (FM20).
- Rework count: 1
- Notes/escalations: Rework 1/2 — cfg ops.live_map_poll_s; resolve paint colors from CSS tokens. Do not expand scope.

## [Phase 6 / P6-D-02] A-03 Live map
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: A-03 /live MapLibre+PMTiles; TS-OPS-04 9/9; ADR-0013 pins. Rework 1: ops.live_map_poll_s + token paint.
- Reviewer verdict: PASS WITH NOTES — prior FAIL fixed. AC MET. Notes: TS poll fallback 5; Abuja default center; SOS pulse 800 ms animation.
- Rework count: 1
- Notes/escalations: Merged 836a8c1. Next: P6-D-03. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 6 / P6-D-03] A-05 Graph editor + A-09 Config editor
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P0-D-02 PASS. Playwright required: graph edit → revision+audit; config change → audit with reason. Reuse MapLibre from P6-D-02. Do not redo live map.

## [Phase 6 / P6-D-03] A-05 Graph editor + A-09 Config editor
- Status: PASS WITH NOTES
- Assigned: 2026-09-07
- Worker report summary: Migration 00057 graph/config RPCs; A-05 pending tray + MapLibre drag; A-09 schema+reason. Playwright graph-config 2/2.
- Reviewer verdict: PASS WITH NOTES — AC MET independently. Notes: missing dump_policies snapshot for app_config_keys (absorb in P6-A-01); share.css/live-map-client compile wrappers.
- Rework count: 0
- Notes/escalations: Merged 765016f. Follow-up: P6-A-01 dump_policies app_config_keys.sql. Next: P6-D-04. Do not flip digital_enabled. Do not start Phase 7.

## [Phase 6 / P6-D-04] A-16 Audit log + A-17 Admin users
- Status: IN PROGRESS
- Assigned: 2026-09-07
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Depends P0-D-01 PASS. AC: grep RPC list vs audited tables. Do not attach remaining audit triggers (P6-A-01). Do not redo graph/config editors.

## [Phase 6 / P6-D-04] A-16 Audit log + A-17 Admin users
- Status: FAIL
- Assigned: 2026-09-07
- Worker report summary: A-16/A-17 UI; 00058 invite/disable RPCs; coverage 21 OK / 7 GAP. Open-Q: already matched answers.
- Reviewer verdict: FAIL — AC MET (grep). Gate FAIL: fetchAuditLogPage hardcodes page size 50 instead of cfg_num('audit.page_size').
- Rework count: 1
- Notes/escalations: Rework 2/2 — wire audit.page_size in fetchAuditLogPage. Nothing else.
