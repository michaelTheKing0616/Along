# Store staged rollout

**Owner:** Mobile release · **Last reviewed:** 2026-09-07  
**Spec:** blueprint doc 09 §2 · **Related:** `docs/runbooks/deploy_rollback.md` §Production deploy step 7

## When to use

After a **tagged production release** passes staging smokes and platform-lead approval, promote **Along Rider** and **Along Driver** to public store tracks using staged percentage rollout — not for staging/TestFlight/Firebase builds.

## Preconditions

| Check | Expected |
|---|---|
| CI green on release tag | `mobile.yml`, `admin.yml`, `db.yml`, `functions.yml` |
| Crash-free sessions (staging/beta) | ≥ 99.5% over prior 7 days (Sentry) |
| Legal URLs live | `https://along.ng/legal/terms`, `/legal/privacy` |
| `payments.digital_enabled` | **false** unless P4-E-02 human PASS on file |
| Store listings | `docs/store/play_listing.md`, `docs/store/app_store_listing.md` uploaded |
| Fastlane secrets | Play service account JSON + App Store Connect API key in GitHub Environment `production` — **never in repo** |

## Rollout stages

| Stage | Audience % | Min dwell | Gate to advance |
|---|---|---|---|
| 1 — Canary | 10% | 24 h | Crash-free ≥ **99.5%**; no S1/S2 incidents; ANR rate ≤ 0.5% (Play) |
| 2 — Widen | 50% | 48 h | Same gates; support ticket volume normal |
| 3 — Full | 100% | — | Platform-lead sign-off in release ticket |

**Pause or halt** rollout on any S1/S2 (see `deploy_rollback.md` severity table). Roll back percentage in Play Console / App Store Connect before backend rollback when the regression is client-only.

## Google Play (Android)

1. Upload AAB via Fastlane `deploy_play_prod` (see `mobile-rider/fastlane/Fastfile`) or Play Console manually.
2. **Production → Releases → Staged rollout:** start at **10%**.
3. Monitor Play Vitals + Sentry release health for 24 h.
4. Increase to **50%**, then **100%** only if gates pass.
5. **Halt rollout** immediately if crash-free drops below 99.5% or critical ANR spike.

```bash
# Example (requires PLAY_STORE_JSON and lane wiring — stub only):
cd mobile-rider
bundle exec fastlane deploy_play_prod rollout:0.1
# After gate: rollout:0.5 then rollout:1.0
```

## App Store (iOS)

1. Submit build via Fastlane `deploy_testflight` then promote to **App Store** release.
2. Use **Phased Release** (7-day automatic ramp) **or** manual percentage if using enterprise tooling — default: phased release ON for prod.
3. Monitor Xcode Organizer crash rate + Sentry; **pause phased release** in App Store Connect if crash-free < 99.5%.
4. Driver and Rider apps roll independently; do not advance Driver if Rider shows regressions on shared packages.

```bash
cd mobile-rider
bundle exec fastlane deploy_appstore
# Pause/resume phased release in App Store Connect → Release → Phased Release
```

## Crash-free gate (99.5%)

Source: **Sentry** project `along-rider` / `along-driver`, environment `production`, window = rolling 24 h during each stage.

```
crash_free_rate = 1 - (crashed_sessions / total_sessions)
PASS if crash_free_rate >= 0.995
```

Record each stage decision in the GitHub Release ticket (timestamp, rate, approver).

## Rollback

| Store | Action |
|---|---|
| Google Play | Halt staged rollout → full rollback to previous production release in Console |
| App Store | Pause phased release; submit expedited review only if hotfix build ready |
| Backend | Independent — see `deploy_rollback.md`; do not flip `digital_enabled` as rollback |

## CI stub

Workflow job `store-rollout` is **not** automated until credentials exist. Manual steps above are authoritative. When Fastlane lanes are wired, add a `workflow_dispatch` job referencing:

- `mobile-rider/fastlane/Fastfile`
- `mobile-driver/fastlane/Fastfile`
- GitHub Environment `production` secrets: `PLAY_STORE_JSON`, `APP_STORE_CONNECT_API_KEY`

## Communication

- `#releases` Slack: post at 10% / 50% / 100% with crash-free metric screenshot
- On-call: mobile + platform for 30 min after each stage increase

## Evidence checklist

- [ ] Release tag and commit SHA recorded
- [ ] 10% stage: crash-free ≥ 99.5% after 24 h
- [ ] 50% stage: crash-free ≥ 99.5% after 48 h
- [ ] 100% complete or phased release active
- [ ] No open S1/S2 linked to release
