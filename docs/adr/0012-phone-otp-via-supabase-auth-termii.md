# ADR-0012 — Phone OTP via Supabase Auth with a custom SMS hook (Termii primary, Twilio fallback)

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §5.1, Phase 1 onboarding, doc 12 §2

## Decision
Supabase Auth phone sign-in; the "Send SMS" hook posts to an Edge Function that routes to providers listed in `cfg sms.providers` (Termii for Nigerian numbers — cost and deliverability — with Twilio fallback). OTP rate limits per phone and IP; 6 digits, 5-minute expiry. Admin users authenticate with email + password + TOTP.

## Consequences
Provider swap is configuration; OTP codes never appear in logs; a second country adds a provider mapping, not code.
