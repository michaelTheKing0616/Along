# Pilot Day Dry-Run

**Owner:** Ops lead · **Recorded:** 2026-09-07 · **Environment:** staging / local E2E stack

This document records the **Phase 6 exit-criterion dry-run**: ops can run a full pilot-corridor day — verify a driver, resolve a fare dispute, review an incident, pull a demand report — **without touching the database directly** (no raw SQL, no Supabase table editor, no psql for mutations).

## Rules (non-negotiable)
- All mutations through admin console RPCs only.
- Use placeholder identities below — **never** commit production phone numbers, NIN, or document images.
- **`payments.digital_enabled` remains false** — no real rider charges, no sticker PDF print for production.
- SOS live escalation: follow `sos_escalation.md` only if a real SOS fires; this dry-run uses seeded incidents.

## Participants & accounts
| Role | Placeholder account | Console role |
|---|---|---|
| Verifier | `[PLACEHOLDER: verifier@along.local]` | `verifier` |
| Ops agent | `[PLACEHOLDER: ops-agent@along.local]` | `ops_agent` |
| Safety | `[PLACEHOLDER: safety@along.local]` | `safety` |
| Analyst / ops lead | `[PLACEHOLDER: ops-lead@along.local]` | `ops_lead` |

**City slug:** `abuja` (E2E seed) — adjust if your staging city differs.

---

## Dry-run script

### Step 0 — Morning dashboard (A-02)
**Screen:** `/{city}/dashboard` (**A-02**)

| Action | Expected result |
|---|---|
| Sign in as ops lead | Dashboard loads; corridor KPIs visible |
| Note verification queue count | Integer ≥ 0; links to A-04 |
| Note open SOS / flags counts | Diagnostic only |

**RPC (read-only):** `admin_corridor_analytics` for default corridor, last 24 h.

---

### Step 1 — Verify a driver
**Runbook:** `verification_review.md`  
**Screen:** `/{city}/verification` (**A-04**)

| # | Action | Expected UI / RPC result |
|---|---|---|
| 1.1 | Sign in as verifier | A-04 queue visible |
| 1.2 | Select pending row `[PLACEHOLDER: driver "Test Driver A"]` | Detail panel; redacted OCR |
| 1.3 | View document | Watermarked image; audit `view_document` |
| 1.4 | Approve (women-only unchecked) | RPC `admin_approve_verification` → success banner; status `approved` |
| 1.5 | Select second pending row | Reject with reason `[PLACEHOLDER: unreadable scan]` → `admin_reject_verification` → `rejected` |
| 1.6 | A-02 dashboard refresh | Verification queue count decreased |

**Stop-and-escalate check:** duplicate badge → halt; ops lead required.

---

### Step 2 — Resolve a fare dispute
**Runbook:** `fare_dispute.md`  
**Screen:** `/{city}/corrections` (**A-06**)

| # | Action | Expected UI / RPC result |
|---|---|---|
| 2.1 | Sign in as ops agent | Corrections table visible |
| 2.2 | Select pending correction (non-MAD row) | Shows `fare_shown`, `proposed_fare`, submitter trust |
| 2.3 | Approve with note `[PLACEHOLDER: matches receipt]` | RPC `admin_review_fare_correction(approve)` → success; status `approved`; graph confirmation recorded |
| 2.4 | Select second pending row | Reject with note → `admin_review_fare_correction(reject)` → `rejected` |
| 2.5 | Observe MAD outlier row (if seeded) | Badge visible; **do not approve** without ops lead — documents stop-and-escalate |

**Config referenced:** `promotion.fare_tolerance_pct` for outlier badge (not changed during dry-run).

---

### Step 3 — Review a safety incident
**Runbook:** `incident_response.md` (not `sos_escalation.md`)  
**Screen:** `/{city}/safety` (**A-12**)

| # | Action | Expected UI / RPC result |
|---|---|---|
| 3.1 | Sign in as safety | Safety board + incident queue visible |
| 3.2 | Confirm SOS runbook link present | Points to `sos_escalation.md` |
| 3.3 | Select incident row (type `safety` or `fare_dispute`) | Triage panel opens |
| 3.4 | Set status `triaged`, severity `2`, assign safety lead | RPC `admin_triage_incident` → success banner |
| 3.5 | Set status `resolved` | Row leaves open queue or shows `resolved` |
| 3.6 | A-16 audit filter `incidents` | Triage rows with actor timestamp |

**Cross-link check:** live open SOS would use `admin_ack_sos` / `admin_resolve_sos` per `sos_escalation.md` — not mixed into incident-only steps.

**Config referenced (SOS tab only):** `sos.ack_sla_s`, `sos.escalate_sla_s`.

---

### Step 4 — Pull a demand report
**Runbook:** corridor analytics (ops reporting)  
**Screen:** `/{city}/analytics` (**A-15**)

| # | Action | Expected UI / RPC result |
|---|---|---|
| 4.1 | Sign in as ops lead or analyst | Corridor selector populated |
| 4.2 | Select pilot corridor `[PLACEHOLDER: Wuse ↔ Nyanya]` | Summary cards load |
| 4.3 | Review 24 h summary | `searches`, `requests`, `completed_trips`, `fulfilment_rate`, `median_wait_s`, `fare_discrepancy_rate` present |
| 4.4 | Paginate time series | RPC `admin_corridor_analytics` with cursor; bounded page (`analytics.page_size`) |
| 4.5 | Review coverage gaps table | Diagnostic rows; no raw SQL export needed |

**RPC:** `admin_corridor_analytics(p_corridor_id, p_from, p_to, p_cursor, p_limit)`  
**Config referenced:** `analytics.page_size`, `analytics.max_window_days`, `analytics.bucket_interval_s`.

---

## Exit criterion self-check
| Criterion | Pass? | Evidence |
|---|---|---|
| Verify a driver without SQL | ☐ | Step 1 via A-04 RPCs |
| Resolve a fare dispute without SQL | ☐ | Step 2 via A-06 RPCs |
| Review an incident without SQL | ☐ | Step 3 via A-12 `admin_triage_incident` |
| Pull demand report without SQL | ☐ | Step 4 via A-15 `admin_corridor_analytics` |
| No raw SQL rule observed | ☐ | Entire script console-only |

**Sign-off**

| Field | Value |
|---|---|
| Date | `[PLACEHOLDER: YYYY-MM-DD]` |
| Ops lead | `[PLACEHOLDER: name]` |
| Environment | `[PLACEHOLDER: staging URL]` |
| Result | `[ ] PASS  [ ] FAIL — notes:` |

---

## Related runbooks
- `verification_review.md`
- `fare_dispute.md`
- `incident_response.md`
- `corridor_onboarding.md` (pre-requisite for new corridors)
- `sos_escalation.md` (live SOS only)

## Related screens
| ID | Path | Used in step |
|---|---|---|
| A-02 | `/{city}/dashboard` | 0 |
| A-04 | `/{city}/verification` | 1 |
| A-06 | `/{city}/corrections` | 2 |
| A-12 | `/{city}/safety` | 3 |
| A-15 | `/{city}/analytics` | 4 |
| A-16 | `/{city}/audit` | 1, 3 (verification) |
