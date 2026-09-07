# External penetration test coordination

**Owner:** Security / Engineering lead · **Last reviewed:** 2026-09-07 · **Pager/rota:** n/a (scheduled engagement)

## When to use

Schedule and track the **Phase 11 external penetration test** before production go-live (doc 12 §8). This runbook defines scope, contacts, and out-of-scope items for the vendor engagement. **Human field evidence is DEFERRED** until a vendor is contracted and the test completes — do not record PASS from an agent.

## Preconditions & access

| Role | Access needed |
|---|---|
| Eng lead | Staging project owner (Supabase), GitHub admin (read-only CI artifacts), vendor SOW sign-off |
| Vendor | Staging URLs, test rider/driver accounts, admin test user (non-prod), webhook tunnel endpoint |
| Ops | On-call rota during test window; ability to freeze staging deploys |

**Contacts (placeholders — fill before engagement):**

| Role | Name | Email | Phone |
|---|---|---|---|
| Eng lead / SPOC | _TBD_ | _TBD_ | _TBD_ |
| Security reviewer | _TBD_ | _TBD_ | _TBD_ |
| Vendor primary | _TBD_ | _TBD_ | _TBD_ |
| Legal / NDPA | _TBD_ | _TBD_ | _TBD_ |

## Scope (in)

Per doc 12 §8 and blueprint Phase 11 gate:

1. **Mobile APIs** — Edge Functions (`plan-trip`, `request_trip`, presence, payments, webhooks) against staging with authenticated rider/driver JWTs.
2. **Admin console** — SSR auth, role routing, dual-control flows, document viewer signed URLs, config editor (read-only mutations in staging).
3. **Webhooks** — Paystack HMAC verification, replay/idempotency, unsigned payload rejection.
4. **Realtime authz** — `trip:*`, `driver:*`, `negotiation:*`, `admin:*` topic subscription attempts (TS-DISC-04 scenarios).
5. **RLS bypass** — direct PostgREST/table access as `authenticated` for cross-party reads/writes.
6. **Token forgery** — JWT tampering, share/SOS token guessing, QR `driver_code` enumeration (rate-limit behaviour).
7. **Rate-limit evasion** — OTP, QR resolve, anonymous W-04 pay page, planner abuse.

**Environment:** staging only (`env/staging.example.json` shape; secrets via Vault/Supabase secrets, never committed).

## Out of scope

- Production data or production Supabase projects.
- Denial-of-service at scale (k6 load tests are separate — see P7-E-02 / P3-E-01).
- Physical device theft, SIM-swap, or social engineering of riders/drivers in the field.
- Paystack/Termii/FCM provider infrastructure (test their integrations only via Along endpoints).
- Source-code review beyond what CI semgrep/gitleaks already cover (optional retainer item).
- **`payments.digital_enabled` production flip** — remains false until P4-E-02 counsel sign-off; pen test must not enable digital charges in prod.

## Severity / triage

| Severity | Response target | Action |
|---|---|---|
| Critical | 4 h | Eng lead + vendor call; staging freeze; track in remediation table below |
| High | 24 h | Assigned owner; fix or documented compensating control before go-live |
| Medium | 5 business days | Backlog; may ship with accepted risk if counsel agrees |
| Low / Info | Next sprint | Triage in security audit report |

## Steps

1. **Contract vendor** — SOW references this scope; NDPA DPA with vendor if they handle PII in staging.
2. **Provision staging accounts** — 2 riders, 3 drivers (verified/unverified/warned), admin per role (`admin`, `city_admin`, `safety`, `finance`, `agent`); document creds in Vault, not git.
3. **Share artifacts** — OpenAPI (`shared/contracts`), authz matrix (`docs/reports/p11-a-01-authz-matrix.md`), threat model (doc 12 §1).
4. **Kickoff call** — Confirm URLs, test window, emergency stop (`#security` channel / phone tree).
5. **Execute test** — Vendor works in staging; no prod traffic.
6. **Daily sync** — Review preliminary findings; critical/high escalated immediately.
7. **Final report** — Vendor delivers executive summary + technical findings + retest evidence.
8. **Remediation** — Log each finding in `docs/reports/p11-e-01-security-audit.md` (or successor); retest before go-live.
9. **Sign-off** — Eng lead + security reviewer confirm no open critical/high (Phase 11 gate).

**Stop and escalate** if: vendor accesses prod, exfiltrates real rider PII, or discovers active secret in git history.

## Communication

- **Internal:** `#security` Slack; incident template in `security_incident.md` if breach suspected.
- **Vendor:** Single SPOC; all findings via encrypted channel (vendor portal or PGP email).
- **Regulatory:** NDPC 72 h path only if real personal data breach confirmed — legal leads.

## After-action

- Attach vendor report (redacted) to `BUILD_LEDGER.md` Phase 11 entry.
- Update semgrep/gitleaks rules if new Along-specific patterns discovered.
- Schedule annual retest or after major auth/payments changes.

## Related

- doc 12 §8 (pen test scope), §1 threat model
- `docs/runbooks/security_incident.md`
- `docs/reports/p11-e-01-security-audit.md`
- P11-E-01 task (local scans + coordination; external test DEFERRED)
