# 14 — QR Payments (scan-to-pay a driver)

Spec references: §4.4 (commission and fare kept separate; cash remains default), Phase 4 (payments optional, itemised), §4.6 (fewest taps), FM3. Decisions: ADR-0010 (split at source), **ADR-0014** (this mechanism). Product-owner request 2026-09-04.

## 1. Goal and non-goals

**Goal:** a rider can pay a driver digitally by scanning a QR code, in the fewest possible taps, with the driver's share settling directly to the driver's bank (Paystack subaccount) and Along's commission collected at source. Works for riders *with* the Along app (best path) and riders *without* it (web fallback).

**Non-goals:** Along holding money (never — ADR-0010); replacing cash (cash stays the default; QR is an option); wallets/stored value; loyalty balances.

## 2. What the QR encodes

Two QR types, one URL scheme, one resolver:

| Type | Payload | Where it lives | Lifetime |
|---|---|---|---|
| **Static driver QR** | `https://along.ng/p/<driver_code>` | Printed sticker (dashboard / seat back), also shown in the driver app (D-25) | Permanent; revocable by rotating `driver_code` |
| **Dynamic trip QR** | `https://along.ng/p/<driver_code>?t=<signed_token>` where token = HMAC(`trip_id, amount, exp`) | Driver app D-16/D-18 "Request payment" | 10 min |

`driver_code`: 8 characters, Crockford base32 (no `I L O U`), random, unique, non-sequential. It is public information (it's on a sticker), so the resolver returns only what the sticker context already reveals — driver first name, vehicle plate, mode, digital-acceptance status — and is rate-limited (30/min per IP). Rotation (`rpc.rotate_driver_code`) invalidates old stickers; ops reprints.

Universal link / App Link: iOS `apple-app-site-association` and Android `assetlinks.json` served from `cfg('public.origin')` so the OS camera opens the rider app when installed; otherwise the browser opens **W-04**. The intended production origin is `https://along.ng` once that domain is purchased (not in scope until investment). While `public.origin` is empty, QR payloads still encode `along://p/<code>` (custom scheme — works in-app) and W-04 is reachable only via the admin/Vercel host; **do not print stickers** until a real https origin exists.

## 3. Rider flows and tap counts

### 3.1 Rider has the app and an active/just-completed trip with this driver (best case)
1. Rider points the phone camera (OS camera, or the **Scan to pay** button on R-13/R-17) at the sticker.
2. App opens **R-27 Pay driver** (upgrades the former post-MVP "Digital payment" sheet; also reached from the `Pay` button on R-17 without any QR): "Pay ₦450 to Musa · Keke ABC-123 · Standard fare" — amount prefilled from `trips.fare_shown + load_surcharge (+ accepted extensions)`; plate shown large for verification.
3. Tap **Pay ₦450** → default payment method (saved card authorisation, or Pay-with-Transfer, or USSD per rider preference) → Paystack completes → success sheet "Paid · Musa received ₦416 · Along fee ₦34" (itemised, FM3).

**Taps in app: 1** (plus any bank-side authentication such as 3-D Secure or the transfer in the bank app, which Along cannot remove). If the rider has no saved method, the first payment adds a method-picker step (+1 tap); the choice is remembered.

> Note: when the rider already has an in-app trip with this driver, the QR is strictly optional — **R-17 already has a one-tap `Pay ₦450`** button that does the same thing. The QR's value is verification ("am I paying the right car?") and the cases below.

### 3.2 Rider has the app but no matched trip with this driver (boarded informally, app offline earlier)
Same scan → R-27 shows the driver and plate, and an **amount step**: chips with the driver's published fares to the end of their route from the nearest stage (from `driver_route_stops.price_to_end` differences, via `rpc.qr_suggested_amounts`), plus "Other". Tap a chip → tap Pay. **2 taps.** The payment is recorded with `trip_id = null`, `rider_id` set, and offered to the rider as "Add this trip to your history?" afterwards (creates a lightweight completed `trips` row with `fare_tier=3, unconfirmed` only if the rider opts in — never silently).

### 3.3 Rider without the app (web fallback, W-04)
Scan → browser → `along.ng/p/<code>` → **W-04**: driver first name, plate, mode; amount chips + keypad; "Pay" → Paystack hosted checkout (card / transfer / USSD) with split → success page with itemised receipt and an SMS receipt option (phone entry optional). **2 taps + checkout.** Payment recorded with `rider_id = null`, `source='web_anonymous'`, `driver_id` set. Commission still collected at source. "Get Along for fares and routes" link at the bottom — the sticker doubles as acquisition.

### 3.4 Dynamic trip QR (driver shows phone)
Driver taps **Request payment** on D-16/D-18 → full-screen QR with amount. Rider scans → R-27/W-04 with amount locked to the token (no amount step). **1 tap** in app, **1 tap** on web. Token verified server-side (`exp`, HMAC, trip belongs to driver, trip not already paid).

## 4. Server logic

### 4.1 Resolve
`GET /functions/v1/qr/resolve/<driver_code>?t=<token>` → **A** (public, rate-limited)
```json
{ "driver": {"first_name":"Musa","plate":"ABC-123-KJ","mode":ModeRef,"accepts_digital":true,"active":true},
  "context": null | {"trip_id","amount":Money,"label":"Trip to Area 1","locked":true},
  "suggested_amounts": [Money...], "currency":"NGN", "min_amount": Money }
```
- `accepts_digital=false` (no subaccount) → client shows "This driver accepts cash only" + nothing else.
- `active=false` (deactivated/suspended) → "This code is no longer active" (no name/plate).
- If the caller is an authenticated rider, the resolver also looks up **their** trips with this driver in `accepted|boarded|in_transit|completed(≤ 24 h) and not paid` → `context` filled with the prefilled amount. If the rider's *active* trip is with a **different** driver → response includes `warning:'different_driver'` and the client blocks payment behind an explicit "This isn't my trip's driver — pay anyway" confirmation (sticker-swap defence).

### 4.2 Initiate
`POST /functions/v1/payments/initiate` (extended) `{ driver_code, trip_id?, amount?, token?, method_pref?, channel:'app'|'web', payer_phone? }`
- Validates: amount ≥ `cfg payments.min_digital_amount`; if `trip_id` → amount must equal the trip's payable total (fare + surcharge + accepted extensions) unless `context.locked=false` and the rider chose "Different amount" (then a `fare_corrections` row is created, as in R-17); if `token` → amount from token.
- Computes `commission = round_to_minor(amount × rate)` where rate = `trips.commission_rate` if a trip is attached else `cfg commission.rate(city of driver)`.
- Creates `payments(status='initiated', source, driver_id, trip_id?, rider_id?, amount, commission_amount, split_config)` and a Paystack transaction with `subaccount = drivers.payout_subaccount_code`, `transaction_charge = commission (minor units)`, `bearer = cfg payments.fee_bearer` (default `'account'`: Along absorbs the Paystack fee out of its commission so the driver receives exactly `amount − commission`; revisit at P4-E-02 against the current fee schedule — small fares may need `'subaccount'` or a minimum), `metadata = {payment_id}`; for saved card authorisations uses charge-authorization directly.
- Returns `{payment_id, authorization_url | transfer_account | ussd_code, expires_at}`.

### 4.3 Confirm (webhook)
`webhooks/paystack` `charge.success` with `metadata.payment_id` → `payments.status='succeeded'`, `confirmed_at`, provider fees recorded; then:
- If `trip_id` present: `trips.payment_method='digital'`. If the trip is already `completed` and a `cash_commission_debit` exists for it → `ledger_post(digital_settlement_credit, +commission, 'trip:{id}:digital_offset')` so the driver's balance nets to zero for that trip (commission was collected at source). If not yet completed → completion will see `payment_method='digital'` and post no cash debit (existing rule).
- If no `trip_id`: `ledger_post(digital_settlement_credit, 0?)` — **no**: nothing is owed and nothing was pre-debited, so no ledger row; the payment row itself is the record. Finance sees it in A-13 "QR payments (unattributed)".
- Notify driver (push + in-app sound/haptic on D-16/D-18/D-08): "₦450 received · ₦416 to your bank". Notify rider (if known) with receipt.

Idempotent on `provider_reference`; webhook signature rules unchanged (doc 12 §7).

### 4.4 Failure/expiry
`payments.expired` job (every minute): `initiated/pending` older than 30 min → `expired`. Pay-with-Transfer virtual accounts expire per provider; UI shows countdown. Duplicate payment for the same trip → second `initiate` returns `CONFLICT` with the existing receipt.

## 5. Data model deltas (doc 02)

```sql
alter table drivers add column driver_code text unique;            -- 8-char Crockford base32, generated at verification approval
alter table drivers add column driver_code_rotated_at timestamptz;

-- payments: generalised (was trip-bound)
alter table payments alter column trip_id drop not null;
alter table payments alter column rider_id drop not null;
alter table payments add column driver_id uuid not null references drivers(id);
alter table payments add column source text not null check (source in ('app_trip','qr_static','qr_dynamic','web_anonymous'));
alter table payments add column commission_amount numeric(12,2) not null;
alter table payments add column driver_amount numeric(12,2) not null;      -- amount − commission
alter table payments add column provider_fee numeric(12,2);                -- from webhook
alter table payments add column fee_bearer text not null check (fee_bearer in ('account','subaccount'));
alter table payments add column payer_phone_e164 text;                     -- web anonymous receipt (optional, consented)
alter table payments add column channel text not null check (channel in ('app','web'));
create index payments_driver_created on payments(driver_id, created_at desc);
create unique index payments_one_success_per_trip on payments(trip_id) where trip_id is not null and status = 'succeeded';

create table rider_payment_methods (                                   -- saved Paystack authorisations (tokens only)
  id uuid primary key default gen_random_uuid(),
  rider_id uuid not null references riders(id) on delete cascade,
  provider text not null default 'paystack',
  authorization_code text not null,                                    -- provider token; never card PAN
  brand text, last4 text, exp_month smallint, exp_year smallint, bank text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (rider_id, authorization_code)
);
create unique index rider_payment_methods_default on rider_payment_methods(rider_id) where is_default;
```
Config keys: `payments.min_digital_amount` (`100`), `payments.fee_bearer` (`'account'`), `payments.qr_resolve_rate_per_min` (`30`), `payments.unattributed_lookback_hours` (`24`), `payments.dynamic_qr_ttl_s` (`600`).

RLS: `payments` — rider own; driver own (`driver_id`); finance/ops_lead in scope; writes by functions only. `rider_payment_methods` — rider own; `authorization_code` never returned to clients (view exposes brand/last4 only).

## 6. Screens (doc 06 additions)

- **R-27 Pay driver** (upgrades the former post-MVP "Digital payment" sheet; also reached from the `Pay` button on R-17 without any QR) — full sheet: driver first name + rating, **plate in `numeric.l`**, mode chip; amount `FareHero` (prefilled/locked, or chips + keypad); `TierPill` when tied to a trip; method row (default method with "change"); `Pay ₦450` primary 56; `different_driver` warning state; success state itemised (to driver / Along fee) with "Done" and "Save receipt". Cash-only driver state.
- **R-31 Scan** — in-app scanner (camera view, torch toggle, "Enter code instead" for `driver_code` typing when the camera is poor) reachable from R-13/R-17/R-05 sheet. Recognises only `along.ng/p/*` payloads.
- **R-32 Payment methods** (linked from R-26 Account → Payment) — add/remove saved methods (Paystack tokenisation flow), default method, "Pay with transfer" preference.
- **D-25 My QR code** — large static QR + `driver_code` in `display.l`; "Share as image"; "Order printed sticker" (creates an ops request); "Verify my sticker" (scans and confirms it resolves to this driver); "Rotate code" (with warning). Requires subaccount; otherwise the screen is the bank-setup prompt.
- **D-16 / D-18** — `Request payment` → **D-26 Payment request** full-screen dynamic QR with amount + countdown; live "Paid ✓" state when the webhook lands (Broadcast `driver:{id}` `{type:'payment_received'}`).
- **D-19** — new section "Digital payments received" (informational, separate from Along balance).
- **W-04 Pay a driver (web)** — mobile-first page: driver/plate/mode, amount chips + keypad, Pay → Paystack checkout, success receipt, optional phone for SMS receipt, "Get the app". No login. Loads ≤ 60 KB.
- **A-11 Driver detail** — driver code, rotate, sticker print request status; **A-13** — QR payments list (attributed / unattributed), sticker print batch export (codes → PDF with plate + QR), fee-bearer economics report.

## 7. Security

| Risk | Control |
|---|---|
| Sticker swap (fraudster's QR on a real vehicle) | Plate + name displayed before pay; hard warning when the rider's active trip is with another driver; "Report wrong QR" → `incidents`; driver "Verify my sticker" self-check; ops sticker batches are plate-labelled |
| Driver-code enumeration | Random base32, rate-limited resolver, minimal response, `active=false` hides identity |
| Token forgery (dynamic QR) | HMAC with Vault key, `exp`, bound to `trip_id` + `amount` + `driver_id`; single successful payment per trip (unique index) |
| Amount tampering | Server computes amount from trip/token; client-entered amounts only in the explicit "no trip" or "different amount" paths, and those create `fare_corrections` or unattributed records |
| Card data exposure | Paystack hosted/tokenised flows only; `authorization_code` never leaves the server |
| Webhook spoofing / replay | Existing HMAC + idempotency (doc 12) |
| Along holding funds | Split at source; `bearer` and `transaction_charge` set per transaction; reconciliation job compares provider split settlements with `payments` daily |
| Web page abuse (spam payments to harass a driver) | Payments are the payer's loss only; but rate-limit initiations per IP; allow driver to pause QR (`accepts_digital` toggle) |

## 8. Tests (doc 10 additions)

- **TS-QR-01** Resolve static code → first name/plate/mode only; unknown code → 404 without timing leak; inactive → no identity.
- **TS-QR-02** Rider with active trip with driver → `context.amount = fare + surcharge + accepted extensions`, locked.
- **TS-QR-03** Rider with active trip with *another* driver → `different_driver` warning; initiate without `confirm_other_driver=true` → `VALIDATION`.
- **TS-QR-04** Dynamic token: tampered/expired → `CANDIDATE_EXPIRED`; valid → amount locked.
- **TS-QR-05** Initiate: split fields = `(amount − commission, commission)` to the minor unit; `bearer` from config; rate from trip snapshot when attached.
- **TS-QR-06** Webhook success on completed cash trip → `payment_method=digital` + offsetting `digital_settlement_credit`; balance for that trip nets to 0; replay → single row.
- **TS-QR-07** Webhook success before completion → completion posts no cash debit.
- **TS-QR-08** Second payment for same trip → `CONFLICT`.
- **TS-QR-09** Web anonymous payment → `payments(rider_id null, source web_anonymous)`; no ledger row; driver notified.
- **TS-QR-10** Code rotation: old code 404, new resolves, audited, sticker request created.
- **TS-QR-11** Saved-method tokens never exposed; charge only by owning rider.
- **TS-QR-12** Daily split-settlement reconciliation matches `sum(driver_amount)`.
- **TS-UI-06** Tap count: app + active trip + saved method = 1 tap after scan; web = 2 taps + checkout (patrol/Playwright).

Authoritative wording of each scenario lives in doc 10 ("QR & digital payments").

## 9. Tasks (doc 11 additions, Phase 4)

| ID | Task | Size | Attach | Depends | Acceptance |
|---|---|---|---|---|---|
| P4-A-09 | QR backend: `driver_code` generation/rotation, `payments` generalisation, `rider_payment_methods`, `qr/resolve`, `payments/initiate` extension (split, bearer, tokens), webhook offset logic, expiry job, notifications | L | 14 §4–5, 03 §7 | P4-A-08 | TS-QR-01..10 |
| P4-B-02 | R-27 Pay driver, R-31 Scan, R-32 Payment methods, universal-link handling, receipts | L | 14 §3, §6 | P4-A-09 | TS-UI-06; sticker-swap warning state |
| P4-C-02 | D-25 My QR, D-26 Payment request (dynamic QR), payment-received feedback, D-19 section | M | 14 §6 | P4-A-09 | Dynamic QR verifies; live paid state |
| P4-D-02 | W-04 web pay page (Next.js route, ≤ 60 KB), A-11/A-13 QR additions, sticker batch PDF export | M | 14 §3.3, §6 | P4-A-09 | Playwright anonymous payment; PDF has plate + QR per driver |
| P4-E-03 | Universal links (`apple-app-site-association`, `assetlinks.json`), `along.ng/p/*` routing, sticker print spec (size, material, QR error-correction H, plate text) | S | 14 §2 | P4-B-02 | Camera scan opens app on both platforms; web fallback when uninstalled |

Digital payments (including QR) remain behind `cfg payments.digital_enabled` until P4-E-02 sign-off.
