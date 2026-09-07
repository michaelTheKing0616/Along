# QR Sticker Lifecycle

**Owner:** Ops lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a (non-incident ops)

## When to use

Managing Along **static driver QR stickers** (doc 14 §2): issuing a new batch, verifying association files and scan behaviour, rotating a compromised or swapped code, or reprinting after rotation. Finance and field ops share this runbook.

**Do not issue production vehicle stickers** until `cfg('public.origin')` is a real `https://` origin **and** P4-E-02 + P1-G-01 are PASS. See `qr_sticker_print_spec.md` for physical spec.

## Preconditions & access

| Role | Access |
| --- | --- |
| `finance`, `superadmin` | A-13 sticker batch PDF export, QR payments list |
| `ops_lead`, `ops_agent` | A-11 driver detail (code, rotate, sticker request status) |
| Vercel / DNS | `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json` on the same host as W-04 `/p/[code]` |

Config keys: `public.origin` (Supabase `config`), Vercel env `PUBLIC_ORIGIN`, `APPLE_TEAM_ID`, `RIDER_IOS_BUNDLE_ID`, `RIDER_ANDROID_PACKAGE`, `ANDROID_APP_LINK_SHA256`.

## Severity / triage

| Level | Signal | Response |
| --- | --- | --- |
| S1 | Confirmed sticker swap / fraud report | Rotate code immediately; suspend digital acceptance if needed; open `incidents` |
| S2 | Sticker damaged / unreadable | Reprint single driver; no rotation if code unchanged |
| S3 | Planned batch for newly verified drivers | Normal issue flow after production gate |

## Steps

### 1. Issue (new batch)

1. Confirm production gate (origin + P4-E-02 + P1-G-01) — **stop and escalate** if any fail.
2. A-13 → select city + verified drivers with active `driver_code` and subaccount.
3. Export sticker batch PDF; cross-check plate per row against A-11 driver detail.
4. Send to print vendor per `qr_sticker_print_spec.md` (≥ 70 mm, EC-H, `#0A0A0A` / `#F7D117`).
5. Record batch id / date in ops notes; deliver to field or mail to drivers.
6. Driver affixes per placement guidance; completes D-25 **Verify my sticker**.

**Expected:** Scan resolves to correct first name + plate; in-app verify shows match.

### 2. Verify (association files + resolver)

1. Set Vercel env on the public-web project (same deployment as W-04):

   | Variable | Source |
   | --- | --- |
   | `PUBLIC_ORIGIN` | Match `cfg('public.origin')` — e.g. `https://along.ng` |
   | `APPLE_TEAM_ID` | Apple Developer → Membership → Team ID |
   | `RIDER_IOS_BUNDLE_ID` | `ng.along.rider` (prod) or `ng.along.rider.staging` |
   | `RIDER_ANDROID_PACKAGE` | `ng.along.rider` (prod) or `ng.along.rider.staging` |
   | `ANDROID_APP_LINK_SHA256` | Play Console → App signing → SHA-256 cert fingerprint(s), comma-separated |

2. Deploy admin-console; confirm **no redirect**:

   ```bash
   curl -sS -o /dev/null -w '%{http_code} %{content_type}\n' \
     "https://<origin>/.well-known/apple-app-site-association"
   curl -sS -o /dev/null -w '%{http_code} %{content_type}\n' \
     "https://<origin>/.well-known/assetlinks.json"
   ```

   **Expected:** `200 application/json` for both.

3. Confirm W-04 public bypass: unauthenticated `GET /p/<test_code>` returns 200 (or honest 404 for unknown code), not redirect to sign-in.

4. Confirm resolver: `GET /functions/v1/qr/resolve/<code>` returns driver first name + plate for active code.

5. **Manual OS-camera gate (P1-G-01):** on 3 low-end Android + iOS devices with rider app installed, OS camera scan of a test QR opens the app to R-27; with app uninstalled, opens W-04 in browser. *Deferred to P1-G-01 — not blocking this runbook's file/association deploy.*

### 3. Rotate (compromise, swap, or driver request)

1. A-11 driver detail → **Rotate code** (or `rpc.rotate_driver_code` via approved admin action).
2. **Expected:** Old code → resolver 404 / inactive; new code resolves; audit row created.
3. Create sticker reprint request for the driver; invalidate old stickers in field (collect or mark void).
4. Notify driver via push: old stickers stop working.

### 4. Reprint (after rotation or damage)

1. If code **unchanged** (damage only): export single-driver label from A-13; same `driver_code`.
2. If code **rotated**: must use **new** code in QR URL — old stickers permanently invalid.
3. Follow print spec; driver re-runs D-25 verify.

**Stop and escalate** if rotation succeeds but Paystack subaccount / digital acceptance out of sync with A-11.

## Mobile app configuration (human / mobile release task)

The rider app already handles `along://p/` and `along.ng/p/` in-app (P4-B-02). For **OS camera** to open the installed app, apply these platform keys before store release:

### iOS (`mobile-rider/ios/`)

1. Create `Runner/Runner.entitlements`:

   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
     <string>applinks:along.ng</string>
   </array>
   ```

   Replace host with the hostname from `public.origin` (no `https://`).

2. Enable **Associated Domains** capability in Xcode for the rider target.

3. Optional custom scheme (in-app only): add URL type `along` in `Info.plist` if not present.

### Android (`mobile-rider/android/app/src/main/AndroidManifest.xml`)

Inside `MainActivity`, add:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="along.ng" android:pathPrefix="/p/" />
</intent-filter>
```

Replace `android:host` with hostname from `public.origin`. Use flavour-specific manifest overlays for staging host if testing on a non-prod domain.

Verify Android App Links: `adb shell pm get-app-links ng.along.rider`

## Communication

**Driver (rotation):** "Your payment QR code has been updated. Old stickers no longer work. A new sticker is on the way — use the QR in the app until it arrives."

**Driver (verify):** "Open Along → My QR → Verify my sticker. Scan your sticker; the app should confirm it matches your account."

## After-action

- Log batch/issue/rotation in ops notes; link `incidents` row for S1.
- Update `driver_code_rotated_at` visible in A-11.
- Re-run well-known curl checks after any Vercel env change.

## Related

- `docs/runbooks/qr_sticker_print_spec.md` — physical label spec
- `docs/blueprint/14_qr_payments.md` §2, §7
- `docs/blueprint/09_infra_devops.md` §7 (public web / well-known)
- `docs/blueprint/06_ui_audit_and_screens.md` — D-25, W-04, A-11, A-13
