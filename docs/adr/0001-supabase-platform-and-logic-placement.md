# ADR-0001 — Supabase as the backend platform; logic placement SQL vs Edge vs client

**Status:** Accepted (planning) · **Date:** 2026-09-04 · **Spec:** §5.1, §1 (Constitution 4, 5, 6)

## Context
The spec names "Postgres + PostGIS (e.g., Supabase)". Along's hardest guarantees are transactional: fare shown = fare resolved, ledger append-only with exact balances, state machine with no illegal transitions, disclosure tiers enforced server-side. We also need auth (phone OTP), realtime, storage and scheduled jobs, with a small team and cost discipline.

## Decision
- Commit to **Supabase** (managed Postgres 15 + PostGIS, Auth, Realtime, Storage, Edge Functions, pg_cron, Vault).
- **Correctness-critical logic in SQL** (`security definer` functions, triggers, RLS): fare resolution, ledger posting, trip transitions, matching eligibility, presence enforcement, promotion pipeline, disclosure shaping.
- **Orchestration and external I/O in Edge Functions (Deno/TS)**: planner assembly + OSRM, dispatch cascade, negotiation clock, payments/webhooks, SMS/push, LLM/STT.
- **Heavy batch in a small TS worker** (`backend/jobs`): map-matching, speed profiles, inference, exports.
- Clients are thin; only Na Me trigger, wayfinding rendering and the offline queue are client logic.

## Alternatives considered
- Custom Node/Go API over Postgres: more control, but re-implements auth/realtime/storage and loses RLS-as-enforcement; higher ops cost for a small team.
- Firebase/Firestore: no PostGIS, weak transactional model for ledger/graph.
- All logic in Edge Functions: loses atomicity across ledger + state + audit; RLS bypass risk with service role everywhere.

## Consequences
- pgTAP becomes a first-class test tool; Workers must be comfortable with PL/pgSQL.
- Vendor coupling to Supabase primitives is acceptable: everything is standard Postgres + open-source components (PostgREST, Realtime, GoTrue) and can be self-hosted if needed.
- Migration to a dedicated planner service is explicitly deferred until a *measured* bottleneck (spec §5.1).
