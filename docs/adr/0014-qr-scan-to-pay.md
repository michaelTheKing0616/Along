# ADR-0014 — QR scan-to-pay via Along universal links resolving to Paystack split transactions

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4.4, §4.6, Phase 4 · **Detail:** blueprint doc 14

## Context
Product owner asked for per-driver QR codes linked to each driver's Paystack subaccount so riders can pay by scanning, in the fewest taps.

## Decision
- The QR encodes an **Along universal link** (`https://along.ng/p/<driver_code>`), not a provider payment page. The link opens the rider app when installed (prefilled amount from the rider's trip, one tap to pay) and a lightweight web page otherwise (chips + pay, no login) — so riders without the app can still pay and Along still collects commission at source.
- **Static printed sticker** per driver is primary; a **dynamic per-trip QR** (signed token with trip and amount) on the driver's phone is secondary.
- Every payment is a Paystack transaction with the driver's **subaccount** and Along's commission as `transaction_charge`; Along never holds funds (ADR-0010). Fee bearer is configuration (`payments.fee_bearer`, default Along absorbs from commission) pending P4-E-02 economics.
- A digital payment on a trip that was already debited as cash posts an offsetting `digital_settlement_credit`, so the ledger stays a single source of truth.
- Sticker-swap fraud is mitigated by showing the plate before payment and hard-warning when the rider's active trip is with a different driver.

## Alternatives considered
- Raw Paystack payment-page QR per subaccount: no trip attribution, rider types amounts, no reconciliation with the ledger, split has to be configured per page.
- NQR (NIBSS national QR): interoperable with bank apps, but generation/settlement path through our aggregator is unverified at planning time; evaluate as an *additional* payload in Phase 8 without changing the resolver design.
- Dynamic-only QR: fewer tampering risks but requires the driver to present a phone every time; static stickers match real vehicle practice.

## Consequences
New public web surface (`along.ng/p/*`) with universal-link configuration; `payments` becomes driver-centric with optional trip/rider; saved payment methods stored as provider tokens only; ops process for sticker printing and code rotation.
