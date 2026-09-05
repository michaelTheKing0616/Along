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
- Notes/escalations: Hard gate before Phase 3. Attach screenshots + notes to the ledger when run.

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
- Status: BLOCKED — needs human
- Assigned: 2026-09-05
- Worker report summary: Playwright A-04 PASS (14/14 via check_playwright.sh). Patrol OTP FAIL — no emulator/device. ios-compile FAIL — Xcode.app missing (`Application not configured for iOS`). Podfiles + pod-install committed on `task/p2-e-02` @ eeabf0a. Not reviewed.
- Reviewer verdict: n/a — OPEN QUESTIONS; not sent to Review
- Rework count: 0
- Notes/escalations: See Decision below. Branch left unmerged.

## [Phase 2 / Decision] P2-E-02 toolchain
**Date:** 2026-09-05
Answers (from spec / doc 11 — criteria not lowered):
- Patrol stays on P2-E-02. Do not absorb into closed P1-E-04 or P1-G-01 (Redmi corridor). Need a booted Android emulator (or attached device) on this Mac; then re-run with `--dart-define=PATROL_HAS_EMULATOR=true`.
- ios-compile: need full Xcode.app + `xcode-select` **or** a git remote + working `gh` so the macos `ios-compile` job can prove green. Local Podfile wiring is already on `task/p2-e-02`.
- Patrol invocation: `flutter test integration_test/otp_flow_patrol_test.dart --dart-define=PATROL_HAS_EMULATOR=true` is acceptable. `patrol_cli 3.14.1` missing from pub.dev is not a blocker.
Phase 2 continues with tasks that do not depend on P2-E-02. P1-G-01 still depends on P2-E-02 PASS.

## [Phase 2 / P2-A-02] Negotiation tables + RPCs + clock
- Status: IN PROGRESS
- Assigned: 2026-09-05
- Worker report summary: (pending)
- Reviewer verdict: (pending)
- Rework count: 0
- Notes/escalations: Unblocks P2-A-03, P2-B-02, P2-C-01, P2-D-01.
