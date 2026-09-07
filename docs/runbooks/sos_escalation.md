# SOS Escalation

**Owner:** Safety lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** see [On-call rota](#on-call-rota) below

## When to use
An `sos_alerts` row is created (rider or driver held SOS). The safety board (A-12) and the on-call phone receive push + SMS. Target: acknowledge within **60 s** (`cfg sos.ack_sla_s`), first contact within **3 min**. Rows escalate visually on A-12 at **60 s** and **180 s** (`cfg sos.escalate_sla_s`) if still unacknowledged.

## Preconditions & access
`safety` or `ops_lead` role; A-12 open; access to the masked-call tool; local emergency numbers per city (`cfg sos.emergency_number`, NG = 112).

## On-call rota

Maintain this table in the ops wiki and mirror critical fields in PagerDuty/Opsgenie. **Do not store production secrets or personal phone numbers in git** — use placeholders below until live rota is configured in the pager tool.

| Role | Primary on-call | Backup on-call | Contact channel | Rotation |
|---|---|---|---|---|
| Safety lead | `[PLACEHOLDER: safety primary name]` | `[PLACEHOLDER: safety backup name]` | Pager app + SMS to roster number `[PLACEHOLDER: +234XXXXXXXXXX]` | Weekly, handoff Mon 09:00 WAT |
| Ops lead (escalation) | `[PLACEHOLDER: ops primary name]` | `[PLACEHOLDER: ops backup name]` | Pager app + phone bridge `[PLACEHOLDER: bridge PIN]` | Weekly, offset from safety by 3 days |
| Engineering liaison | `[PLACEHOLDER: eng primary name]` | `[PLACEHOLDER: eng backup name]` | Slack `#along-safety` + pager | Follow-the-sun for prod incidents only |

**Rota fields required before Phase 5 exit:** role, primary, backup, contact channel, rotation schedule. Update within 24 h of any roster change.

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| S1 | Raiser unreachable, or trip trace deviating/stopped in unusual area, or report of violence | Call emergency services with plate, last location, direction; keep raiser's line open; notify trusted contact if share exists |
| S2 | Raiser reachable, situation tense but controlled (dispute, harassment) | Stay on line; instruct to exit at a safe public point; log; follow up incident |
| S3 | Accidental / false alarm confirmed by raiser via hold-to-cancel + call | Mark `false_alarm`; no penalty |

## Steps
1. Acknowledge in A-12 (`admin_ack_sos`) — pushes `sos_ack` FCM to the raiser ("Along safety team is with you").
2. Open the trip: parties, plate, live position (Tier I), leg, last 5 min of trace.
3. Call the raiser (masked). If no answer within 60 s → call the other party; if still nothing → S1.
4. S1: call 112 (or city number) with: plate, vehicle description, live coordinates + heading, raiser first name, phone. Keep updating A-12 note every 2 min.
5. If a `trip_shares` exists, the contact's page already shows live status; do not disclose more than the page does.
6. Resolve (`admin_resolve_sos`) with status and note. Create/link an `incidents` row of type `safety` with severity (`admin_triage_incident`).

## Communication
Rider/driver: "This is Along's safety team. We can see your trip and location. Are you safe to talk?" Authority script in English + local language.

## After-action
Within 24 h: incident review, driver/rider follow-up, update `incidents`, consider standing action via A-11 (human decision), update this runbook if a step failed.
