# Staging Android smoke — Redmi A2+ (P1-E-04)

Reference device: Xiaomi Redmi A2+ (Android Go class). Run on a physical device with USB debugging enabled.

## Prerequisites

1. `env/staging.json` and `env/google-services.staging.json` present locally (gitignored).
2. `./scripts/wire_staging.sh` executed.
3. Staging Supabase project `upqeypbdegteofwvekie` migrated and Edge Functions deployed.
4. Auth **Send SMS** hook enabled in Supabase Dashboard → Authentication → Hooks, pointing at `send-sms` with `SEND_SMS_HOOK_SECRETS` set on the function.
5. Optional: OSRM tunnel running (`backend/routing/scripts/osrm_tunnel.sh`) and `OSRM_URL` secret set for non-degraded routing.

## Build & install (rider, staging flavour)

```bash
cd mobile-rider
flutter pub get
flutter build apk --flavor staging --dart-define-from-file=env/staging.json
adb install -r build/app/outputs/flutter-apk/app-staging-release.apk
```

## Smoke checklist

| Step | Action | Pass criterion |
| --- | --- | --- |
| 1 | Open app → enter Nigerian phone (10 digits, or `0803…`) → Continue | No crash; OTP request succeeds. Keyboard Done also submits. |
| 2 | OTP screen | Staging smoke builds that carry `--dart-define=STAGING_OTP_KEY=…` auto-fill via the guarded `staging-otp` function (see **Staging OTP auto-fill** below). Otherwise enter it by hand, or read it as service_role: `select peek_log_otp('+234…');` (not callable by anon/authenticated, 0094). |
| 3 | Enter OTP → complete sign-in | Lands on home / search screen |
| 4 | Search destination inside seeded pilot corridor → plan trip | HTTP 200; `candidates` array non-empty **or** `degraded: true` with honest empty-state when graph/tunnel unavailable |
| 5 | When OSRM tunnel up | `meta.degraded` is `false` and time estimates lack forced straight-line fallback |
| 6 | When OSRM tunnel down / `OSRM_URL` empty | `meta.degraded` is `true`; UI still renders options or coverage-gap fallback |

## plan-trip curl (same project, sanity before device)

Replace `<ANON_JWT>`, origin/destination with seeded Abuja/Zaria-test coordinates.

```bash
curl -sS -X POST "https://upqeypbdegteofwvekie.supabase.co/functions/v1/plan-trip" \
  -H "Authorization: Bearer <ANON_JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "origin": {"lat": 11.06, "lng": 7.7},
    "destination": {"lat": 11.08, "lng": 7.72},
    "filters": {"women_only": false, "load": {"flagged": false}},
    "session_id": "00000000-0000-4000-8000-000000000099"
  }' | jq '.meta.degraded, (.data.candidates | length)'
```

## Environment status (this workspace)

**Device smoke:** SKIP — no Redmi A2+ attached in this CI/agent environment. Run the checklist above on the reference device.

**Deploy commands (human, if not run here):**

```bash
npx supabase link --project-ref upqeypbdegteofwvekie
npx supabase db push --project-ref upqeypbdegteofwvekie
bash backend/functions/scripts/deploy_functions.sh staging upqeypbdegteofwvekie
```

Do not commit secrets. After deploy, grep the diff for `private_key` / `BEGIN PRIVATE KEY` — must be 0.

## Staging OTP auto-fill (`staging-otp`)

Staging-only Edge Function that reads the log-mode OTP with service_role, server side. Every guard fails closed:

| Guard | Denial |
|---|---|
| `ALONG_ENV` must be `staging` | 404 |
| Production-looking runtime: `SUPABASE_URL` matches `ALONG_PROD_PROJECT_REFS` or a `prod` host | 404 |
| `STAGING_OTP_KEY` (≥32 chars) must be set; header `x-staging-otp-key` must be sent (constant-time compare) | unset/absent → 404, mismatch → 403 |
| Phone must be in `STAGING_OTP_ALLOWLIST` (comma-separated E.164 test numbers; empty → deny all) | 403 |
| `sms.provider` must be `log` | 403 |
| Rate limit: 10 req/min per IP+phone (per isolate) | 429 |

Denials are logged as `staging_otp_denied` with a reason and the last 4 digits of the phone. OTP values are never logged.

**Staging secrets** (never set on production):

```bash
npx supabase secrets set --project-ref upqeypbdegteofwvekie \
  ALONG_ENV=staging STAGING_OTP_KEY="$(openssl rand -hex 32)" \
  STAGING_OTP_ALLOWLIST="+2348000000001,+2348000000002" \
  ALONG_PROD_PROJECT_REFS="<prod-project-ref>"
```

Only put dedicated test numbers on the allowlist, never real users.

**Deploy:** always use `backend/functions/scripts/deploy_functions.sh <staging|prod> <ref>`. For `prod` it skips `staging-otp`. A bare `supabase functions deploy` deploys every function, so don't use it against production. CI (`functions` job) checks that the prod plan excludes `staging-otp` and that no committed env file contains `STAGING_OTP_KEY`.

**App builds:** add `--dart-define=STAGING_OTP_KEY=<key>` to **staging** smoke builds only, e.g.
`flutter build apk --flavor staging --dart-define-from-file=env/staging.json --dart-define=STAGING_OTP_KEY=$STAGING_OTP_KEY`.
Auto-fill runs only when `FLAVOR=staging` and the key is present. A prod or dev build that carries the key throws at startup (`AppConfig.assertStagingOtpKeyAllowed`). Never commit the key to `env/*.json`.
