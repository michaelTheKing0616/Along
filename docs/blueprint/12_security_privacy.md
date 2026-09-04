# 12 — Security & Privacy

Spec references: §4.1.2 (disclosure), §4.4 (money), §4.14 (data products), Phase 11 audit. Regulatory: Nigeria Data Protection Act 2023 / NDPR, CBN guidelines (payments via licensed aggregator only — Along never holds funds).

## 1. Threat model (STRIDE-lite, top risks)

| # | Threat | Vector | Control |
|---|---|---|---|
| T1 | Disintermediation / stalking via pre-commit position leak | ambient endpoints, Realtime, planner payloads | Tier A shapes contain no ids/coordinates (schema tests TS-DISC-*); `driver_presence` has no rider policy; candidate tokens opaque + 60 s |
| T2 | Fare manipulation | client-supplied fare | Fares only from `resolve_fare`; `trips.fare_shown` copied server-side from `fare_quotes`; clients send quote ids, never amounts (except negotiation chips validated against steps) |
| T3 | Ledger tampering | direct table writes, replay | Append-only triggers; `ledger_post` security definer; idempotency keys; advisory lock; nightly invariant |
| T4 | Fake settlements | forged webhook, reused agent code | HMAC-SHA512 verify with constant-time compare; raw webhook stored; unique `provider_reference`; agent codes single-use, 15 min, city-bound |
| T5 | Identity fraud (duplicate drivers, stolen docs) | verification uploads | Human review mandatory; provider verification; HMAC identity hash dedupe; face-match assist; document access logged and watermarked |
| T6 | Sybil graph poisoning | many accounts confirming fake fares | One confirmation per account; trust weights by age/trips; device-fingerprint clustering down-weights; MAD outlier guard; promotion thresholds |
| T7 | Account takeover | OTP brute force, SIM swap | OTP rate limits (5/h/phone, 20/h/IP), 6 digits, 5 min expiry, lockout; re-auth for payout bank changes; session revocation on phone change |
| T8 | Privilege escalation in admin | role forging, IDOR | Roles from `admin_users` only; RLS on every table; `admin_can_access_city`; TOTP for privileged roles; dual control for money |
| T9 | Location data misuse | history retention, exports | Retention 24 h full / 30 d downsampled; exports k-anonymised (k ≥ 10) and aggregate only (FM39/40); no third-party analytics SDKs |
| T10 | Abuse of SOS / share links | spam, link leakage | SOS never rate-limited but false alarms tracked; share tokens hashed, 12 h TTL, revocable, page shows minimal data |
| T11 | Supply-chain | malicious packages | lockfiles, `pnpm audit`/`dart pub outdated` gates, Dependabot, ADR for every new dependency |
| T12 | Secrets leakage | repo, logs | No secrets in apps/repo; Vault; structured logs scrub phone/plate/token patterns; CI secret scanning (gitleaks) |

## 2. Authentication & sessions
- Phone OTP via Supabase Auth; SMS hook signs payloads (HMAC) to Termii/Twilio adapter; OTP never logged.
- JWT lifetime 1 h, refresh 30 d rotating; refresh tokens in `flutter_secure_storage`; sign-out revokes.
- Admin: email + password (≥ 12 chars) + TOTP; session 12 h; IP + UA in `audit_log`.
- Public web (share/guarantor pages): anonymous with token; tokens ≥ 128-bit random, stored hashed.

## 3. Authorization
- RLS is the only enforcement layer; Edge Functions re-check party membership before using the service role (they never blindly trust `user_id` from the body).
- Column protection triggers for client-updatable tables (drivers, profiles, vehicles).
- All state changes via `security definer` functions with `set search_path = public, pg_temp` and explicit `revoke execute … from public; grant execute … to authenticated` (or to service role only for internal functions).
- Realtime authorization policies on `realtime.messages` for `trip:*`, `driver:*`, `negotiation:*`, `admin:*` topics.

## 4. Input validation
- Server-side `zod`/SQL checks on every field (ranges in doc 03 §0); text length caps; enum membership against config tables; geo sanity (accuracy ≤ 500 m, speed ≤ 60 m/s, timestamps within ±5 min of server time else clamped and flagged).
- File uploads: content-type sniffing, ≤ 5 MB, images only, EXIF stripped server-side for incident attachments; verification images keep EXIF for forensics but are never public.

## 5. Data classification & handling

| Class | Examples | Storage | Retention |
|---|---|---|---|
| Restricted | ID numbers, documents, raw webhooks, identity hashes | `private.*`, private buckets; ID numbers never stored (hash only) | Documents: until verification + 24 months (regulatory); raw webhooks 90 d |
| Confidential | phone, precise location samples, ledger, flags | RLS tables; phone masked in admin UI | Samples 24 h full / 30 d downsampled; ledger indefinite (financial record); flags 24 months |
| Internal | graph, config, aggregates | RLS tables | indefinite |
| Public | tiles, styles, legal pages | CDN | — |

Rider/driver data rights (NDPA): export (`rpc.export_my_data` → JSON, async), deletion (`rpc.request_deletion` → anonymise profile, keep ledger/trip financial records with pseudonymous ids as legally required), consent records for location/notifications in `profiles.consents jsonb` with timestamps. Privacy notice (W-03) plain-language, Hausa/Yoruba/Igbo/Pidgin translations by Phase 10.

## 6. Abuse detection (non-blocking, review-only)
Device fingerprint (app-generated random install id + coarse device model; no IMEI) stored per session; clusters of accounts sharing an install id or confirming identical values within minutes are down-weighted in the promotion pipeline and surfaced in A-10. No automatic bans (FM13 spirit applies to riders too).

## 7. Payments posture
Along never stores card data; Paystack hosted flows only; webhook endpoint IP-allowlisted where provider supports; reconciliation job compares provider ledger with `settlements/payments` daily. Along is not a wallet and never holds funds: digital rider payments are split at source via Paystack subaccounts (ADR-0010 amendment) — driver share goes straight to the driver's bank, commission to Along. Driver *debts* (cash commission owed) are receivables, not customer funds. QR scan-to-pay (doc 14, ADR-0014) uses the same split path: QR payloads are Along universal links carrying a public, random `driver_code` (never a secret); amounts are server-derived from the trip or an HMAC-signed dynamic token; the plate is shown before payment and a rider whose active trip is with a different driver is hard-warned (sticker-swap defence); the resolver is rate-limited and returns no identity for inactive codes; saved rider payment methods are provider tokens only, never exposed to clients. The anonymous web page (`W-04`) initiates payments without an account — rate-limit per IP and treat it as a public surface (CSP, no PII beyond driver first name + plate). Legal review checkpoints: before enabling digital payments in prod (P4-E-02: confirm the no-funds-held reading under CBN rules, KYC obligations for subaccounts, VAT on commission) and before Phase 8 (P8-E-01: corporate invoicing, B2G data licensing under NDPA, advertising standards).

## 8. Operational security
- Least-privilege service accounts; Supabase project owners = 2 people; MFA on all consoles.
- Incident response runbook (`docs/runbooks/security_incident.md`): severity matrix, 72 h NDPC breach notification path, comms templates.
- Phase 11 external penetration test scope: mobile APIs, admin, webhooks, Realtime authz, RLS bypass attempts, token forgery, rate-limit evasion.

## 9. Secure-by-default checklists (Reviewer)
- New table → RLS enabled + policies file + pgTAP RLS test.
- New RPC → `security definer` + `search_path` + explicit grants + input validation + audit (if admin).
- New Edge Function → zod schema, auth check, idempotency (if mutating), structured logs, no PII in logs.
- New screen → no PII beyond tier; no secrets; strings via l10n.
- New dependency → ADR + audit clean.
