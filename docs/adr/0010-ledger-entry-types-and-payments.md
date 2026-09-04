# ADR-0010 — Ledger entry types (`payout_debit` added), Paystack behind a provider interface, agent codes

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4.4.1, Phase 4

## Decision
- Entry types: spec's five plus **`payout_debit`** (Along paying a positive balance out to a driver's bank after digital trips). Sign convention: positive credits the driver (reduces debt), negative debits. `balance_after` is an immutable running snapshot under a per-driver advisory lock; `driver_balances` view (`sum(amount)`) is authoritative; a nightly invariant compares them.
- Payments via **Paystack** (bank transfer, USSD, card, transfers-out) behind a `PaymentProvider` interface in `backend/functions/_shared/payments/`, so Flutterwave/others are adapters.
- Agent-assisted settlement uses single-use, 15-minute, city-bound 6-character codes redeemed by a `settlement_agents` account; both settlement paths converge on `ledger_post(digital_settlement_credit)`.
- Along never holds stored value; positive balances are paid out on a T+2 cycle (legal review before any wallet-like feature).

## Consequences
Webhook is the only writer for provider-confirmed money; clients never assert payment outcomes.
