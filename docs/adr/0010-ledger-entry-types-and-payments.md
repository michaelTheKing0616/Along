# ADR-0010 — Ledger entry types (`payout_debit` added), Paystack behind a provider interface, agent codes

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4.4.1, Phase 4

## Decision
- Entry types: spec's five plus **`payout_debit`** (Along paying a positive balance out to a driver's bank after digital trips). Sign convention: positive credits the driver (reduces debt), negative debits. `balance_after` is an immutable running snapshot under a per-driver advisory lock; `driver_balances` view (`sum(amount)`) is authoritative; a nightly invariant compares them.
- Payments via **Paystack** (bank transfer, USSD, card, transfers-out) behind a `PaymentProvider` interface in `backend/functions/_shared/payments/`, so Flutterwave/others are adapters.
- Agent-assisted settlement uses single-use, 15-minute, city-bound 6-character codes redeemed by a `settlement_agents` account; both settlement paths converge on `ledger_post(digital_settlement_credit)`.
- **Digital rider payments use Paystack Split / Subaccounts (amendment 2026-09-04):** each verified driver gets a Paystack subaccount (their own bank account, created during verification via `payout bank` in D-24). A rider's digital payment is split *at source* — driver share settles directly to the driver's bank; Along's commission settles to Along. Along therefore never holds rider or driver money, and no positive driver balance accrues from digital trips. `digital_settlement_credit` for a digital trip is informational (records that the commission was collected at source, so no cash debit is owed); `payout_debit` remains only for exceptional cases (manual adjustments producing a positive balance, refunds), handled by finance under dual control.
- Along never operates stored value. Because money never rests with Along, the CBN licensing question is confined to Paystack (already licensed). Legal review confirms this reading before digital payments are enabled in production (task P4-E-02) and reviews B2B invoicing, data products and advertising before Phase 8 (P8-E-01).

## Consequences
Webhook is the only writer for provider-confirmed money; clients never assert payment outcomes. Driver onboarding gains one optional step (bank details) that unlocks digital-payment acceptance; drivers without it remain cash-only, which is the default anyway.
