# Verification Review

**Owner:** Ops lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a (queue-driven; escalate duplicate-identity cases to ops lead)

## When to use
A driver has submitted identity or vehicle documents and `driver_verifications.status = pending`. A verifier (`verifier` or `ops_agent` role) must review the queue on **A-04** (`/{city}/verification`) before the driver can appear as available. Target: same-day review during pilot hours; backlog > 24 h → escalate to ops lead.

## Preconditions & access
- Role: `verifier`, `ops_agent`, `ops_lead`, or `superadmin` (see route allowlist).
- Console: sign in at admin console → select city → **Verification** (`/{city}/verification`, screen **A-04**).
- MFA: required for `superadmin`; optional for verifier/ops_agent in pilot.
- **Do not** open raw SQL or Supabase dashboard to change verification status — all actions go through RPCs below.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| P1 | Duplicate identity hash flagged on row | Stop — requires `ops_lead` to approve via RPC (UI shows `DUPLICATE_IDENTITY` error for verifier-only accounts) |
| P2 | Face-match score missing or below internal threshold | Extra document review; reject with clear reason if mismatch |
| P3 | Routine pending queue item | Standard approve/reject flow |

## Steps
1. Open **A-04** (`/{city}/verification`). Confirm the queue lists pending rows first (oldest age on top).
2. Select a pending row. Review redacted OCR extract and vehicle metadata (plate, make/model, seat capacity). **Expected:** detail panel visible; no raw NIN/license numbers in OCR display.
3. Click **View document** for each document type. **Expected:** watermarked image loads; `admin_log_view_document` writes an audit row (`action = view_document`). Document URL expires after 10 minutes.
4. If duplicate badge shows, **stop and escalate** to ops lead — do not force-approve as verifier.
5. For women-only corridor eligibility, check **Women-only eligible** when driver and vehicle meet policy; otherwise leave unchecked.
6. **Approve:** click **Approve** → RPC `admin_approve_verification(p_verification_id, p_women_only_eligible)`. **Expected:** success banner; row status `approved`; driver can proceed to availability once all required document types are approved.
7. **Reject:** enter rejection reason (required) → **Reject** → RPC `admin_reject_verification(p_verification_id, p_reason)`. **Expected:** success banner; row status `rejected`; driver notified to resubmit.
8. Optional cross-check: open **A-16** (`/{city}/audit`), filter `target_type = driver_verifications`, confirm approve/reject/view_document rows with your actor id.

### Stop and escalate
- Duplicate identity (`DUPLICATE_IDENTITY` from `admin_approve_verification`).
- Document appears forged or belongs to another person — reject with reason, notify ops lead; do not approve.
- Storage path missing / document fails to load after retry — escalate to engineering; do not approve blind.

## Communication
Driver (SMS/in-app, English + local language as needed):
- Approved: "Your Along verification is complete. You can now go online in the driver app."
- Rejected: "We could not verify your [document type]. Reason: [reason]. Please resubmit a clear photo in the app."

Internal: Slack `#along-ops` — "Verification backlog [city]: [N] pending, oldest [age]."

## After-action
- Record: audit rows on `driver_verifications` (automatic via RPC triggers).
- Metrics: **A-02** dashboard (`/{city}/dashboard`) shows verification queue count — confirm it decrements after your session.
- Review: weekly ops standup — backlog age, duplicate-identity rate, reject reasons.

## Related
- Screen **A-04** — `/{city}/verification`
- Screen **A-02** — `/{city}/dashboard` (queue counts)
- Screen **A-16** — `/{city}/audit` (audit trail)
- RPCs: `admin_approve_verification`, `admin_reject_verification`, `admin_check_identity_duplicate`, `admin_log_view_document`
- Runbook: `pilot_day_dry_run.md` (step 1)
- Spec §1 principle 8 (verification is launch-blocking)
