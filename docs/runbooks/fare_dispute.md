# Fare Dispute Resolution

**Owner:** Ops agent · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a (queue-driven; MAD outliers escalate to ops lead)

## When to use
A rider or driver disputes the fare shown vs paid after a trip. The post-trip flow creates a row in `fare_corrections` with `status = pending`. Ops resolves disputes on **A-06** (`/{city}/corrections`) — never by editing `route_legs`, `route_through_fares`, or ledger tables directly.

Cash remains the default payment path; **`payments.digital_enabled` stays false** in pilot — do not enable via **A-09**.

## Preconditions & access
- Role: `ops_agent`, `ops_lead`, or `superadmin`.
- Console: **Fare corrections** (`/{city}/corrections`, screen **A-06**).
- Understand the along-graph fare shown (`fare_shown`) vs `proposed_fare` and submitter trust weight on the detail panel.
- Outlier guard uses `promotion.fare_tolerance_pct` (`cfg promotion.fare_tolerance_pct`) — corrections beyond neighbour median ± tolerance show a **MAD outlier** badge.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| P1 | MAD outlier badge + large delta vs graph fare | Ops lead review required before approve; may indicate fraud or bad seed data |
| P2 | Along Pricing / negotiation-sourced correction (`negotiation` badge) | Verify agreed amount matches trip context; approve only if reasonable |
| P3 | Small delta, high-trust submitter, matches trip receipt | Approve with brief note |

## Steps
1. Open **A-06** (`/{city}/corrections`). Queue is sorted pending-first. Select the dispute row linked to the trip (trip id shown in detail).
2. Read **submitter trust**, route/stage labels, `fare_shown`, `proposed_fare`, and delta %. **Expected:** context sufficient to decide without SQL.
3. If **MAD outlier** badge present, compare proposed fare to current graph fare and neighbour median. **Stop and escalate** to ops lead if delta exceeds `promotion.fare_tolerance_pct` and you cannot explain it from trip evidence.
4. Optional: open trip context via **A-03** live/historical tools or driver detail if plate/driver code is needed — do not query `trips` table directly.
5. **Approve:** add optional note → **Approve** → RPC `admin_review_fare_correction(id, action: 'approve', note)`. **Expected:** success banner; correction status `approved`; `graph_confirmations` row created; if promotion threshold met, entity may promote (UI message: "graph confirmation recorded" / "entity promoted").
6. **Reject:** add note explaining decision → **Reject** → RPC `admin_review_fare_correction(id, action: 'reject', note)`. **Expected:** status `rejected`; graph unchanged.
7. Confirm on **A-15** (`/{city}/analytics`) that `fare_discrepancy_rate` for the corridor is sensible after batch resolution (diagnostic only — not an auto-penalty).
8. If dispute involves driver standing (repeat disputes, reconciliation flags), cross-link to **Integrity** (`/{city}/integrity`) — use `admin_review_flag` / `admin_transition_standing` there; do not suspend drivers from the corrections screen alone.

### Stop and escalate
- MAD outlier you cannot reconcile with trip evidence.
- Suspected collusion (several low-trust accounts confirming same outlier fare).
- Correction references a route/stage with no graph entity — escalate to ops lead + graph editor (**A-05**) rather than raw SQL insert.

## Communication
Rider/driver (plain language):
- Approved: "We reviewed your fare report for [route]. The along fare for this leg has been updated to ₦[amount]. Thank you for helping keep fares accurate."
- Rejected: "We reviewed your fare report and the shown fare matches our verified along rate. If you paid a different amount, that was between you and the driver — Along does not set fares."

Hausa/Yoruba/Igbo/Pidgin variants: use ops wiki templates; keep amount and route name literal.

## After-action
- Record: `fare_corrections` status + note; `graph_confirmations` on approve; audit via RPC triggers.
- Metrics: corridor `fare_discrepancy_rate` on **A-15** / **A-02** (24 h window via `admin_corridor_analytics`).
- Review: weekly — top dispute routes, MAD outlier rate, negotiation-sourced corrections.

## Related
- Screen **A-06** — `/{city}/corrections`
- Screen **A-15** — `/{city}/analytics` (demand + `fare_discrepancy_rate`)
- Screen **A-02** — `/{city}/dashboard`
- Screen **A-05** — `/{city}/graph` (graph fixes if seed wrong)
- Config: `promotion.fare_tolerance_pct`, `commission.rate` (display only — commission separate from fare)
- RPCs: `admin_review_fare_correction`, `fare_outlier_guard`
- Runbook: `pilot_day_dry_run.md` (step 2)
- Spec §1 principles 4 (fare transparency) and 6 (cash-first)
