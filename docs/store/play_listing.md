# Google Play — Along Rider & Driver listings

**Status:** Product draft for store review prep · **Legal URLs:** `https://along.ng/legal/terms` · `https://along.ng/legal/privacy`  
**Not counsel-approved** — final copy pending P4-E-02 / P8-E-01.

Apps: `mobile-rider` (Along — Move your way) · `mobile-driver` (Along Driver)

---

## Short description (80 chars max)

**Rider:** Find keke, okada & shared taxis near you. Plan trips, pay cash by default.  
**Driver:** Publish your route, get matched riders, track Along balance & earnings.

---

## Full description (4000 chars max)

### Along (Rider)

Along helps you move around Nigerian cities using the shared taxis, kekes, okadas, and minibuses already on the road — without pretending we own a fleet.

**Plan your trip**  
Enter where you're going. Along shows real options: walk to a park, board, maybe transfer once — with honest wait times and fares from mapped routes or crowd-confirmed prices.

**One tap to request**  
Pick an option and request. See your driver's plate and a colour-and-shape "Na Me" signal so you meet the right vehicle.

**Cash first**  
Most trips are paid in cash to your driver. Digital card and bank pay through Paystack is **off by default** and only appears when Along enables it in your city after compliance review.

**Safety**  
Share a live trip link with someone you trust. Hold SOS to alert Along's safety team with your live location — we connect to our safety line, not emergency dispatch.

**Privacy**  
We don't sell your data or run ad trackers. Location is used to plan and run trips; see our privacy notice for retention and NDPA rights.

Download Along and move your way.

---

### Along Driver

Drive with Along — stay visible to riders on your existing route without a new fleet or employer.

**Set your route in minutes**  
Confirm the stops and prices you already charge. Toggle online at your park or while roaming.

**Incoming requests**  
See pickup stage, drop-off area, fare, and Along fee before you accept. Women-only matching when configured.

**Cash trips, clear ledger**  
Riders pay you cash. Along commission posts to your Along balance; settle via bank transfer, USSD, card, or agent when needed.

**Digital pay (when enabled)**  
QR and in-app pay may be unavailable until Along turns on digital payments for your city. Cash always works.

**Verification**  
Upload documents for human review before matching goes live.

Terms: along.ng/legal/terms · Privacy: along.ng/legal/privacy

---

## Category & tags

| Field | Rider | Driver |
|---|---|---|
| Category | Maps & Navigation | Business (or Maps & Navigation) |
| Tags | transport, taxi, keke, okada, Nigeria, mobility | driver, taxi, keke, earnings, Nigeria |

---

## Privacy policy URL

`https://along.ng/legal/privacy`

---

## Data safety form (Google Play)

Aligned with blueprint doc 12 §5 data classification. Answer **Yes/No/Optional** per Play Console sections.

### Data collected

| Data type | Collected | Shared | Purpose | Encrypted in transit | User can request deletion |
|---|---|---|---|---|---|
| Phone number | Yes | No (except SMS provider) | Account, OTP, trip comms | Yes | Yes |
| Approx./precise location | Yes | No (matched party only during trip) | Trip planning, matching, SOS | Yes | Yes (retention limits apply) |
| Name | Yes | Yes (matched driver/rider) | Profile, meet-up | Yes | Yes |
| Photos (incident reports) | Optional | No | Safety reports | Yes | Yes |
| Photos (driver docs) | Drivers only | No | Verification | Yes | Yes (after retention) |
| Financial info (transactions) | Yes | Paystack only | Fares, commission, settlement | Yes | Limited (legal hold) |
| Device or other IDs | Yes (install id) | No | Abuse detection | Yes | Yes |
| Crash logs | Yes | Sentry | Stability | Yes | Yes |

### Data **not** collected

- Contacts, SMS content, calendar
- Health, political, or sexual orientation
- Full payment card numbers (Paystack hosted checkout only)
- IMEI / hardware serial

### Security practices

- Data encrypted in transit (TLS)
- Data deletion request supported in-app / privacy@along.ng
- Independent security review: external pen test **deferred** (P11-E-01 runbook)

### Digital payments disclosure

Digital in-app payments are **disabled by default** (`payments.digital_enabled = false`). Store listing and in-app copy must not imply card pay is universally available.

---

## Content rating questionnaire (notes)

- No user-generated public content feed
- Location sharing with matched party and optional trip share link
- SOS feature — no graphic violence
- Cash and optional digital payments — no simulated gambling

---

## App access (review credentials)

Provide test phone OTP bypass or staging credentials per `docs/runbooks/staging_android_smoke.md` — **do not commit secrets**.
