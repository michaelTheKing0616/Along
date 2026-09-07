# Incident Response (Safety Review)

**Owner:** Safety lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** see `sos_escalation.md` on-call table (safety primary)

## When to use
An `incidents` row exists (reported from rider/driver app or linked from a resolved SOS) and appears in the **Incident queue** on **A-12** (`/{city}/safety`). This runbook covers **non-SOS** and **post-SOS** incident triage — harassment, behavior, vehicle quality, lost item, and **`fare_dispute`** type incidents that did not require live SOS.

**Live SOS** (open `sos_alerts`) is handled by [`sos_escalation.md`](sos_escalation.md) — acknowledge and resolve SOS first; then return here to triage the linked `incidents` row if one was created.

## Preconditions & access
- Role: `safety`, `ops_lead`, or `superadmin` for full board; `ops_agent` may view but triage requires `safety`, `ops_lead`, or `superadmin` (`admin_triage_incident` guard).
- Console: **Safety board** (`/{city}/safety`, screen **A-12**).
- SOS SLA keys (for cross-reference only on live SOS tab): `sos.ack_sla_s`, `sos.escalate_sla_s`, `sos.emergency_number` — see `sos_escalation.md`.
- **Do not** edit `incidents` via SQL — use `admin_triage_incident` only.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| S1 | Violence, assault, kidnapping risk, or active SOS | Follow [`sos_escalation.md`](sos_escalation.md) immediately — do not use incident-only workflow |
| S2 | Incident type `safety`, severity ≥ 3, or reporter unreachable | Assign to safety lead; contact parties within 1 h |
| S3 | `fare_dispute`, `lost_item`, `vehicle_quality` — severity 1–2 | Triage and resolve in console; route fare graph issues to `fare_dispute.md` |
| S4 | Duplicate/spam report | Dismiss with note |

## Steps
1. Open **A-12** (`/{city}/safety`). Scroll to **Incident queue** (below SOS table). **Expected:** open/triaged incidents listed with type, severity, reporter, status.
2. If any **open SOS** rows appear above, handle per [`sos_escalation.md`](sos_escalation.md) (`admin_ack_sos` → `admin_resolve_sos`) before incident-only triage.
3. Select an incident row. Read description, reporter role, linked trip id, current severity.
4. Set **Status** (`open` → `triaged` → `resolved` or `dismissed`), **Severity (1–4)**, and **Assign to** (safety or ops lead from dropdown).
5. Click **Update incident** → RPC `admin_triage_incident(p_id, p_status, p_assigned_to, p_severity)`. **Expected:** success banner; row reflects new status/severity/assignee.
6. For type **`fare_dispute`**: if the issue is graph fare accuracy, hand off to ops agent via `fare_dispute.md` (**A-06**). Keep incident open until corrections queue item is resolved, then mark incident `resolved`.
7. For type **`safety`** linked from SOS: ensure SOS is `resolved` or `false_alarm` first; add resolution note referencing SOS id.
8. Verify audit: **A-16** (`/{city}/audit`) — filter `target_type = incidents` for your triage actions.

### Stop and escalate
- Active SOS or reporter says they are in immediate danger → [`sos_escalation.md`](sos_escalation.md) S1; call `sos.emergency_number` (NG default 112).
- Incident involves minor or sexual assault allegation → safety lead + legal contact; do not dismiss without lead sign-off.
- Trip id missing but allegation is serious → ops lead + engineering to locate journey trace; do not guess.

## Communication
Reporter: "This is Along's safety team. We've received your report about [type]. Are you safe to talk now?"

Internal: Slack `#along-safety` — "Incident [id] [type] S[n] triaged → [assignee]. Trip [trip_id slice]."

Authority script: only per `sos_escalation.md` when S1 — do not disclose more than trip-share page shows.

## After-action
- Record: `incidents` status, severity, assignee, description updates via `admin_triage_incident`.
- Within 24 h for S2+: brief review — was triage timely? standing action needed on **A-11** driver tab (`admin_transition_standing`)?
- Metrics: open incident count on **A-02** dashboard; SOS counts separate on same board.

## Related
- Screen **A-12** — `/{city}/safety` (incident queue + SOS board)
- Screen **A-16** — `/{city}/audit`
- Screen **A-02** — `/{city}/dashboard`
- Runbook: [`sos_escalation.md`](sos_escalation.md) (live SOS — complementary, not duplicated)
- Runbook: `fare_dispute.md` (fare accuracy disputes)
- Runbook: `pilot_day_dry_run.md` (step 3)
- RPCs: `admin_triage_incident`, `admin_ack_sos`, `admin_resolve_sos` (SOS only)
- Config: `sos.ack_sla_s`, `sos.escalate_sla_s`, `sos.emergency_number`
