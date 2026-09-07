# App Store Connect — Along Rider & Driver listings

**Status:** Product draft for store review prep · **Legal URLs:** `https://along.ng/legal/terms` · `https://along.ng/legal/privacy`  
**Not counsel-approved** — final copy pending P4-E-02 / P8-E-01.

Bundle IDs: configure in Xcode (`mobile-rider`, `mobile-driver` prod flavors).

---

## App name & subtitle

| App | Name (30) | Subtitle (30) |
|---|---|---|
| Rider | Along | Shared taxis & keke near you |
| Driver | Along Driver | Routes, matches & earnings |

---

## Promotional text (170 chars, updatable without review)

**Rider:** Plan multi-leg trips across keke, okada & shared taxis. Cash by default — digital pay only when Along enables it in your city.  
**Driver:** Publish your route, accept requests, track Along balance. Cash trips today; digital QR when enabled.

---

## Description (4000 chars max)

Use the full descriptions from `docs/store/play_listing.md` (Rider and Driver sections). App Store requires separate listings per app — paste the matching section.

**Required footer (both apps):**

```
Privacy Policy: https://along.ng/legal/privacy
Terms of Use: https://along.ng/legal/terms

Along does not own vehicles. Cash is the default payment method. Digital payments are off by default and may not be available in your area.
```

---

## Keywords (100 chars, Rider example)

`keke,okada,taxi,abuja,lagos,transport,ride,navigate,shared,mobility`

Driver example: `driver,taxi,keke,route,earnings,nigeria,transport,fleet,commission`

---

## Support & marketing URLs

| Field | URL |
|---|---|
| Support URL | `https://along.ng` (help centre in-app; web landing TBD) |
| Marketing URL | `https://along.ng` |
| Privacy Policy URL | `https://along.ng/legal/privacy` |

---

## App Privacy (Privacy Nutrition Labels)

Mapped to doc 12 §5. Declare in App Store Connect → App Privacy.

### Data linked to you

| Category | Types | Purpose |
|---|---|---|
| Contact Info | Phone number, Name | App functionality, account |
| Location | Precise Location | App functionality, trip matching, SOS |
| Financial Info | Payment info (via Paystack), purchase history | App functionality, commission |
| Identifiers | User ID, device install ID | App functionality, fraud prevention |
| Usage Data | Product interaction (minimal) | Analytics (first-party only; no ad SDKs) |
| Diagnostics | Crash data | App functionality (Sentry) |

### Data not linked to you

- Aggregate corridor analytics (k-anonymised, not collected on device for App Privacy)

### Data not collected

- Browsing history, emails, contacts, health, sensitive categories
- Third-party advertising data

### Tracking

**No** — Along does not track users across other companies' apps or websites for advertising (no IDFA ad use).

---

## Age rating

4+ / 12+ depending on questionnaire — location and infrequent cash/payment references; no mature content.

---

## Export compliance & encryption

Uses standard HTTPS (TLS) only — qualifies for exemption; confirm annually in Connect.

---

## Review notes

1. **OTP sign-in:** provide demo staging number or review bypass per internal runbook.  
2. **Location:** required for core trip planning; explain in Review Notes.  
3. **Digital payments:** feature flag off in production build under review; Paystack test mode in staging. Do **not** imply universal in-app pay in screenshots.  
4. **Legal pages:** public at `/legal/terms` and `/legal/privacy` on along.ng (admin-console on Vercel).

---

## In-app purchase / payments

No Apple IAP for trip fares — physical/cash and licensed payment aggregator (Paystack) for digital pay when enabled. Declare external payment where required by Apple regional rules.
