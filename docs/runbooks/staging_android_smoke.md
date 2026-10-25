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
| 2 | OTP screen | Enter the code by hand. With `sms.provider=log`, read it as service_role (SQL editor / psql): `select peek_log_otp('+234…');` — not callable by anon/authenticated (0094). |
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
npx supabase functions deploy --project-ref upqeypbdegteofwvekie
```

Do not commit secrets. After deploy, grep the diff for `private_key` / `BEGIN PRIVATE KEY` — must be 0.
