# P12-E-02 — Store readiness gate

**Task:** P12-E-02 — Store readiness: listings, privacy labels, data-safety forms, W-03 legal pages, staged rollout config  
**Branch:** `task/p12-e-02`  
**Date:** 2026-09-07  
**Gate:** Store review passes (checklist below) · **Live store submission:** DEFERRED

## Executive summary

| Area | Status |
|---|---|
| W-03 legal pages (`/legal/terms`, `/legal/privacy`) | **READY** — product drafts, public, no auth |
| Google Play listing + data safety | **READY** — `docs/store/play_listing.md` |
| App Store listing + privacy labels | **READY** — `docs/store/app_store_listing.md` |
| Staged rollout runbook (10→50→100%, 99.5% gate) | **READY** — `docs/runbooks/store_rollout.md` |
| Fastlane lanes | **STUB** — no store credentials in repo |
| Counsel-approved legal text | **BLOCKED** — P4-E-02 / P8-E-01 human |
| Live Play/App Store submission | **DEFERRED** |

---

## Store review checklist

### Legal & policy

| # | Item | Evidence | Status |
|---|---|---|---|
| L1 | Public Terms of Service URL | `/legal/terms` · draft banner | ✅ |
| L2 | Public Privacy / NDPA notice URL | `/legal/privacy` | ✅ |
| L3 | Plain language; digital payments OFF by default stated | `data-testid="w03-digital-off-notice"` on both pages | ✅ |
| L4 | Not presented as counsel-approved | Draft notice on W-03 | ✅ |
| L5 | Privacy policy URL in store forms | `https://along.ng/legal/privacy` in listing docs | ✅ |
| L6 | Final legal review (human) | P4-E-02 / P8-E-01 | ⏸ BLOCKED |

### Google Play

| # | Item | Evidence | Status |
|---|---|---|---|
| G1 | Short + full description | `docs/store/play_listing.md` | ✅ |
| G2 | Data safety form answers | Same doc § Data safety | ✅ |
| G3 | Category & content rating notes | Same doc | ✅ |
| G4 | Target API / bundle requirements | Existing `mobile.yml` release build gate | ✅ (CI) |
| G5 | Production AAB uploaded | — | ⏸ DEFERRED |
| G6 | Staged rollout 10→50→100% | `docs/runbooks/store_rollout.md` | ✅ (process) |

### App Store

| # | Item | Evidence | Status |
|---|---|---|---|
| A1 | Name, subtitle, description, keywords | `docs/store/app_store_listing.md` | ✅ |
| A2 | App Privacy nutrition labels | Same doc § App Privacy | ✅ |
| A3 | Support / privacy URLs | Same doc | ✅ |
| A4 | Phased release / rollout policy | `store_rollout.md` | ✅ |
| A5 | Build submitted to App Store Connect | — | ⏸ DEFERRED |

### Technical / privacy alignment (doc 12 §5)

| Class | Store declaration | Along handling | Match |
|---|---|---|---|
| Restricted (ID docs) | Driver verification only | Private bucket, not public | ✅ |
| Confidential (phone, location, ledger) | Declared in data safety / App Privacy | RLS, retention per doc 12 | ✅ |
| Public (legal pages) | Linked from stores | CDN/Vercel, no auth | ✅ |
| No third-party ad SDKs | Tracking = No (iOS) | Confirmed in listing docs | ✅ |
| Digital payments | Disclosed as off by default | `payments.digital_enabled` unchanged | ✅ |

### Auth / public web

| # | Item | Evidence | Status |
|---|---|---|---|
| T1 | `/legal/*` in `isPublicPath` | `admin-console/src/lib/authz/routes.ts` | ✅ |
| T2 | Vitest for public-path helper | `routes.test.ts` | ✅ |
| T3 | Playwright optional skip | `PLAYWRIGHT_SKIP_LEGAL=1` in `w03-legal.spec.ts` | ✅ |

### Rollout gates

| Stage | Crash-free gate | Documented |
|---|---|---|
| 10% | ≥ 99.5% | ✅ |
| 50% | ≥ 99.5% | ✅ |
| 100% | ≥ 99.5% + sign-off | ✅ |

---

## Tests run (Worker)

| Test | Result |
|---|---|
| `pnpm --filter @along/admin-console exec vitest run src/lib/authz/routes.test.ts` | Run at commit |
| Playwright `e2e/w03-legal.spec.ts` | Optional; skip via env |

---

## Explicitly deferred

- Submitting to Google Play or App Store Connect (human + credentials)
- Counsel sign-off on legal copy (P4-E-02, P8-E-01)
- Enabling `payments.digital_enabled` in production
- Automated Fastlane CI deploy (credentials not in repo)

---

## Acceptance criteria mapping

**Store review passes** — checklist complete for in-repo artifacts; live submission and human legal PASS remain deferred per task scope.
