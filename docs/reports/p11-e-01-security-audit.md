# P11-E-01 Security Audit Report

**Task:** P11-E-01 — External pen test coordination; remediation; dependency audit; secret scanning; semgrep ruleset  
**Branch:** `task/p11-e-01`  
**Date:** 2026-09-07  
**Gate:** No open **critical** or **high** findings in-repo

## Executive summary

| Area | Result |
|---|---|
| Gitleaks (secret scan) | **PASS** — config wired; no live secrets in tracked tree |
| Semgrep (Along ruleset) | **PASS** — 6 custom rules; CI gate added |
| pnpm audit | **PASS** — 0 critical / 0 high after remediations (1 low open) |
| Dart pub outdated | **INFORMATIONAL** — CI step records; no Dart CVE gate tool |
| External pen test | **DEFERRED** — coordination runbook only; no vendor PASS |
| In-repo remediations | OTP logging fixed; dependency bumps + overrides |

## Scans run

| Scan | Command / workflow | When |
|---|---|---|
| Gitleaks | `.gitleaks.toml` + `gitleaks/gitleaks-action@v2` in `.github/workflows/security.yml` | PR + push to master |
| Semgrep | `.semgrep/along-rules.yml` + `semgrep/semgrep-action@v1` | PR + push to master |
| pnpm audit | `pnpm audit --audit-level=high` in `security.yml` | PR + push to master |
| Dart outdated | `melos exec -- dart pub outdated …` (informational, non-blocking) | PR + push to master |
| Manual secret grep | `sk_live_*`, `AKIA*`, `whsec_*` on tracked sources | 2026-09-07 — no matches |

## Along-specific Semgrep rules

| Rule ID | Covers | Severity |
|---|---|---|
| `along-pii-otp-in-logs` | OTP in log payloads (doc 12 §2) | ERROR |
| `along-pii-phone-in-logs` | Full phone in logs | WARNING |
| `along-pii-plate-or-token-in-logs` | Plate/token in logs | WARNING |
| `along-postgres-current-user-bypass` | `current_user in ('postgres', 'supabase_admin')` in SQL | WARNING |
| `along-digital-enabled-migration-flip` | `payments.digital_enabled` set true in migrations | ERROR |
| `along-driver-presence-rider-select` | Rider SELECT policy on `driver_presence` | ERROR |

## Findings (open)

| ID | Severity | Finding | Status |
|---|---|---|---|
| — | — | No open critical/high | **CLOSED** |

### Resolved during P11-E-01

| ID | Was | Remediation |
|---|---|---|
| F-01 | **CRITICAL** — Next.js 15.1.12 middleware auth bypass (GHSA) | Bumped `next` + `eslint-config-next` → **15.5.21** |
| F-02 | **CRITICAL** — Vitest 3.2.1 UI arbitrary file read | Bumped `vitest` → **3.2.6** (admin, jobs, data-collection) |
| F-03 | **HIGH** — Playwright &lt; 1.55.1 browser install integrity | Bumped `@playwright/test` → **1.55.1** |
| F-04 | **HIGH** — style-dictionary prototype pollution | Bumped → **5.4.4** (ADR-0013 updated) |
| F-05 | **HIGH** — transitive `postcss` / `sharp` via Next | Root `pnpm.overrides` → `postcss>=8.5.18`, `sharp>=0.35.0` |
| F-06 | **HIGH** — OTP logged by `send-sms` log provider | Removed `otp` from structured log; test updated |
| F-07 | **INFO** — No gitleaks/semgrep CI | Added `.github/workflows/security.yml` |

### Accepted / informational (not gate-blocking)

| ID | Severity | Finding | Notes |
|---|---|---|---|
| I-01 | LOW | `@supabase/auth-js` path routing advisory | Transitive; track Dependabot; no exploit path in Along SSR usage reviewed |
| I-02 | — | Dart `pub outdated` may list available upgrades | No `dart pub audit` equivalent; Melos packages reviewed manually |
| I-03 | — | `mobile-*/env/*.json` committed with placeholders | Values are placeholders only; live secrets via Vault / local untracked copies |
| I-04 | — | `current_user postgres` in `protect_*` triggers | Intentional migration/service bypass; semgrep WARNING for review |

## SQL / authz spot checks

| Check | Result |
|---|---|
| Rider SELECT on `driver_presence` | **None** — policies: own driver + admin only (`p11-a-01` MATCH) |
| `digital_enabled` default in migrations | **`false`** via `config_default` (00021); not flipped |
| `digital_enabled` in e2e seed SQL | Test fixture only (`admin-console/e2e/seed-w04-pay.sql`); not a migration |

## External penetration test

**Status: DEFERRED (human evidence required)**

- Coordination runbook: `docs/runbooks/pen_test_coordination.md`
- Scope aligned with doc 12 §8 (mobile APIs, admin, webhooks, Realtime, RLS, tokens, rate limits)
- Vendor contacts: placeholders — fill before engagement
- **Do not record external pen-test PASS until vendor report + retest attached to ledger**

## Remediation checklist

- [x] Gitleaks config + CI
- [x] Semgrep Along ruleset + CI
- [x] pnpm audit gate (high+)
- [x] Dependency bumps for critical/high npm advisories
- [x] OTP never logged (send-sms)
- [x] Pen-test coordination runbook
- [ ] External pen test execution — **DEFERRED**

## Related artifacts

- `docs/runbooks/pen_test_coordination.md`
- `docs/reports/p11-a-01-authz-matrix.md`
- `.gitleaks.toml`, `.semgrep/along-rules.yml`, `.github/workflows/security.yml`
- ADR-0013 (pinned version updates for security bumps)
