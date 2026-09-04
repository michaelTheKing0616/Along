# SOS Escalation

**Owner:** Safety lead · **Last reviewed:** (template — complete in P5-D-01) · **Pager/rota:** on-call schedule required before Phase 5 exit

## When to use
An `sos_alerts` row is created (rider or driver held SOS). The safety board (A-12) and the on-call phone receive push + SMS. Target: acknowledge within **60 s**, first contact within **3 min**.

## Preconditions & access
`safety` or `ops_lead` role; A-12 open; access to the masked-call tool; local emergency numbers per city (`cfg sos.emergency_number`, NG = 112).

## Severity / triage
| Level | Signal | Action |
|---|---|---|
| S1 | Raiser unreachable, or trip trace deviating/stopped in unusual area, or report of violence | Call emergency services with plate, last location, direction; keep raiser's line open; notify trusted contact if share exists |
| S2 | Raiser reachable, situation tense but controlled (dispute, harassment) | Stay on line; instruct to exit at a safe public point; log; follow up incident |
| S3 | Accidental / false alarm confirmed by raiser via hold-to-cancel + call | Mark `false_alarm`; no penalty |

## Steps
1. Acknowledge in A-12 (`admin_ack_sos`) — pushes "Along safety team is with you" to the raiser.
2. Open the trip: parties, plate, live position (Tier I), leg, last 5 min of trace.
3. Call the raiser (masked). If no answer within 60 s → call the other party; if still nothing → S1.
4. S1: call 112 (or city number) with: plate, vehicle description, live coordinates + heading, raiser first name, phone. Keep updating A-12 note every 2 min.
5. If a `trip_shares` exists, the contact's page already shows live status; do not disclose more than the page does.
6. Resolve (`admin_resolve_sos`) with status and note. Create/link an `incidents` row of type `safety` with severity.

## Communication
Rider/driver: "This is Along's safety team. We can see your trip and location. Are you safe to talk?" Authority script in English + local language.

## After-action
Within 24 h: incident review, driver/rider follow-up, update `incidents`, consider standing action via A-11 (human decision), update this runbook if a step failed.
