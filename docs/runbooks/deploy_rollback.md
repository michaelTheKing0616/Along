# Deploy & Rollback

**Owner:** Platform · **Last reviewed:** 2026-09-07 · **Pager/rota:** ops on-call (staging auto-deploy; prod via release approval)

## When to use

Deploy a validated `main` commit to **staging**, or promote a **tagged release** to **prod**, after CI is green. Use the rollback section when a deploy causes elevated errors, data-integrity failures, or safety incidents — not for routine config tuning.

## Preconditions & access

| Environment | Who | Access |
|---|---|---|
| **staging** | any merge to `main` (GitHub Actions) | Supabase `along-staging` dashboard, Vercel staging project, GitHub Environment `staging` |
| **prod** | platform lead + release approver | Supabase `along-prod`, Vercel production, GitHub Environment `production`, PagerDuty/Opsgenie |

Required: Supabase CLI (pinned in root `package.json`), `gh` CLI, Vercel team access, release tag matching `v*` semver.

**Config reference:** `docs/CONFIG_REFERENCE.md` — especially `payments.digital_enabled` (default `false`, read-only in admin).

## Severity / triage

| Level | Signal | Response target |
|---|---|---|
| S1 | Ledger invariant fail, SOS pipeline broken, open-data leak | Stop traffic shift; rollback or hotfix within 15 min; page safety + platform |
| S2 | Error rate > 2% or plan-trip p95 > 2× baseline | Roll back failing layer or forward-fix within 30 min |
| S3 | Admin-only regression, no rider impact | Forward-fix preferred; rollback optional |
| S4 | Staging smoke fail on auto-deploy | Block prod promotion; fix on branch |

## Steps — Staging deploy (`main`)

1. Confirm PR merged with all required checks green (`db.yml`, `functions.yml`, `admin.yml`, `mobile.yml`, `tokens.yml`, `seed-fixture.yml`).
2. **Database — dry run:**
   ```bash
   supabase link --project-ref <along-staging-ref>
   supabase db push --dry-run
   ```
   **Expected:** only forward migrations listed; no destructive surprises. **Stop** if diff includes unexpected drops.
3. **Database — apply:**
   ```bash
   supabase db push
   ```
   **Expected:** migrations applied; `app_config` defaults unchanged except new keys from the migration.
4. **Edge Functions:**
   ```bash
   supabase functions deploy --project-ref <along-staging-ref>
   ```
   **Expected:** all functions report deployed; smoke `curl` to `/functions/v1/health` if present.
5. **Admin console:** Vercel auto-deploys staging from `main`. Verify preview URL loads A-01 login.
6. **Smoke:** run Playwright staging suite or manual TS-* smokes from doc 10. **Expected:** pass. Log result in deploy ticket.

## Steps — Production deploy (tagged release)

1. **Stop** unless staging smokes passed on the same commit and release notes reviewed.
2. Create GitHub Release from tag `vX.Y.Z` with changelog; obtain platform-lead approval on GitHub Environment `production`.
3. **Database — dry run** against `along-prod` (same as staging step 2). **Stop** on any unexpected DDL.
4. **Database — apply** during low-traffic window (WAT 02:00–05:00 preferred):
   ```bash
   supabase db push --project-ref <along-prod-ref>
   ```
5. **Edge Functions** deploy to prod project (same command, prod ref).
6. **Admin console:** promote Vercel production deployment tied to the release tag.
7. **Mobile:** fastlane staged rollout 10% → 50% → 100% with crash-free ≥ 99.5% gate (doc 09 §2). Rollback via store console if needed — independent of backend rollback.
8. Post-deploy: watch `docs/runbooks/observability.md` alerts for 30 min. Run nightly ledger invariant early if finance-impacting migration.

## Rollback — Staging

1. Identify failing layer: **DB migration**, **Edge Function**, **admin**, or **mobile**.
2. **Edge Functions / admin:** redeploy the last known-good commit:
   ```bash
   git checkout <previous-sha>
   supabase functions deploy --project-ref <along-staging-ref>
   # Vercel: rollback deployment in dashboard to previous production/staging build
   ```
3. **Database:** migrations are forward-only. Prefer a **forward-fix migration** on `main` over reversing DDL. Emergency `down` SQL exists in migration comments for platform-lead use only — run manually in a scratch project first (`docs/runbooks/db_restore_drill.md`).
4. **Config rollback:** if a bad `admin_set_config` change caused the incident, restore the prior value via A-09 with audit reason — query `audit_log` for the last `app_config` row.
5. **Never** set `payments.digital_enabled` to `false` (or `true`) as a deploy rollback shortcut. That switch gates legal/compliance posture (P4-E-02); toggling it during incident response hides payment bugs and breaks audit expectations. Fix the underlying payment/webhook/ledger issue instead.
6. Record incident in ticket + `audit_log` notes; link runbook steps taken.

## Rollback — Production

1. **Stop traffic shift** — pause mobile rollout; if admin serves public pages W-01…W-04, consider Vercel rollback first for user-facing regressions.
2. Page platform + on-call per severity table above.
3. **Edge / admin:** same redeploy/rollback as staging, using prod refs. Prefer Vercel instant rollback for admin before touching DB.
4. **Database:** forward-fix only unless S1 data-integrity event and platform lead approves PITR restore to scratch project for validation (`db_restore_drill.md`). **Never** restore prod backup into live prod project.
5. **Config:** restore via audited `admin_set_config`; never flip `payments.digital_enabled` as a rollback lever (see staging §5).
6. Post-incident: after-action within 48 h; update this runbook if steps were wrong.

## Communication

**Internal (Slack `#ops`):**
> Deploy `vX.Y.Z` to prod complete / rolled back. Layer: \<db|functions|admin|mobile\>. Impact: \<rider/driver/admin/none\>. Current status: monitoring / resolved.

**Rider/driver (only if user-visible outage > 5 min):**
> Along is experiencing a temporary issue with \<booking|payments|maps\>. Cash trips and SOS remain available. We're working on it.

## After-action

- Record deploy/rollback in change ticket with commit SHAs (before/after).
- If DB touched: confirm `check_ledger_invariant()` and TS-OPS-01 row counts on scratch if restore considered.
- Update `docs/BUILD_LEDGER.md` only via Orchestrator for phase-gate notes — Workers log evidence in `docs/reports/`.

## Related

- Blueprint doc 09 §2 (CI/CD, deploy policy)
- `docs/runbooks/db_restore_drill.md` — backup/PITR validation
- `docs/runbooks/incident_response.md` — safety incidents
- `docs/runbooks/secrets_rotation.md` — if rollback involved key compromise
- `docs/CONFIG_REFERENCE.md` — config keys and defaults
