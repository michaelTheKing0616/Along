# 08 — Admin Console (Next.js)

Spec references: §4.4.2–4.4.4 (review-only integrity), §4.5 (graph tooling), §4.14 (B2B/operator), Phase 0 and Phase 6 gates (two-scout reconciliation, audit log). Screens: doc 06 §B3–B4.

## 1. Stack

- Next.js (App Router, TypeScript strict), React Server Components for data reads, Server Actions **not** used for mutations (all mutations go through Supabase RPC so the audit trigger and RLS apply identically to every client).
- Supabase JS with `@supabase/ssr` cookie sessions; admin auth = email + password + TOTP (Supabase MFA) — TOTP enforced for `superadmin`, `finance`, `safety`, `ops_lead` at sign-in via `aal2` check in middleware.
- UI: Tailwind preset from `shared/design-tokens` + shadcn/ui (re-themed), TanStack Table, TanStack Query for client caches, `react-hook-form` + `zod` (schemas generated from `shared/contracts`), MapLibre GL JS with `along-light` style.
- Hosting: Vercel (or any Node host); env: Supabase URL/anon key (public), *no* service-role key in the web app — ever. Privileged operations that genuinely need service role (none identified) would be Edge Functions.

## 2. Structure

```
admin-console/
  src/app/(auth)/sign-in
  src/app/(console)/[city]/dashboard | live | verification | graph | corrections | field | deploy | config | integrity | drivers/[id] | safety | finance | intelligence | analytics | audit | admins | markets | revenue
  src/app/(portal)/corporate/[accountId]/... ; operator/[accountId]/...
  src/components/ui (shadcn) ; src/components/along (AdminDataTable, AdminMap, EvidencePanel, QueueList, AuditDrawer, TierBadge, StandingBadge, MoneyCell)
  src/lib/supabase (server/client factories) ; src/lib/rpc (typed wrappers generated from shared/contracts) ; src/lib/authz (role → route allowlist)
  src/styles/tokens.css (generated)
```

## 3. Authorization

- Route allowlist by `admin_users.role` in `src/lib/authz/routes.ts`; middleware redirects unauthorized roles. This is UX only — RLS is the enforcement.
- City selector lists `cities` visible to the admin (RLS-filtered); every query includes `city_id` filter; `admin_can_access_city` guards on the server side.
- Corporate/operator portals use the same app with `corporate_admin`/`operator_viewer` roles and RLS scoping to their account.

## 4. Data access patterns

- Lists: PostgREST with `range` pagination (50/page), server-side filters, `abortSignal` on navigation.
- Detail pages: RSC fetch + client `useQuery` for live parts (SOS board, live map subscribe to Realtime `admin:{city}` Broadcast published by `presence-fanout` with precise positions — Tier I, RLS-authorized to admin roles).
- Mutations: `rpc.admin_*` only; UI disables the button while pending; success toast includes the audit id; conflicts (`CONFLICT`, `STATE_INVALID`) shown inline with refresh.
- Every detail page renders `AuditDrawer` listing `audit_log` rows for `target_id`.

## 5. Key page behaviours (complements doc 06)

- **Verification (A-04)**: document images fetched via short-lived signed URLs from a server route that logs the access to `audit_log` (`action='view_document'`); the image is rendered with a CSS watermark of the reviewer id + timestamp. Duplicate identity hash hit shows a red banner with the other driver's id (masked) — approval then requires `ops_lead`.
- **Graph editor (A-05)**: optimistic map edits with a "pending changes" tray; save = one RPC per entity; CSV import runs `admin_import_dry_run` (returns diff) before `admin_import_apply`.
- **Integrity (A-10)**: the "Action" button opens the standing dialog prefilled with the flag reason; the dialog calls `admin_transition_standing`; the flag is then marked `actioned` with the transition id — nothing happens without the human click (FM13).
- **Finance (A-13)**: manual adjustments above `cfg.ledger.dual_control_threshold` create a pending request that a *different* finance user approves (`admin_approve_adjustment`) — enforced in SQL, not just UI.
- **Config (A-09)**: JSON-schema per key from `shared/contracts/config-schemas/`; the form shows the effective value at each scope and a diff; reason required and stored in `audit_log.after.reason`.
- **Safety (A-12)**: SOS rows escalate visually at 60 s / 180 s unacknowledged; acknowledging pushes `sos_ack` to the rider's app. Links to `docs/runbooks/sos_escalation.md` inline.

## 6. Testing

Playwright E2E against the local Supabase stack with seeded admin users per role: role route guards, verification approve/reject, two-scout reconcile + publish, config edit with audit row, integrity flag → standing dialog, finance dual control. Component tests with Vitest + Testing Library for tables and forms. Accessibility: axe checks on every page.

## 7. Performance
RSC streaming for dashboards; tables virtualised over 200 rows; map layers as vector sources updated by diff; bundle ≤ 300 KB gzipped first load.
