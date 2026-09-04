# ADR-0011 — Push notifications via Firebase Cloud Messaging

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §4.6 (driver must answer within seconds), Phase 1/3

## Decision
FCM for Android and (via FCM) APNs for iOS; driver request pushes are high-priority data messages with TTL = `dispatch.request_ttl_s` and per-trip collapse keys; the Flutter background handler raises a full-screen intent. Supabase Realtime remains the foreground channel; FCM exists for background wake only.

## Alternatives
OneSignal (extra vendor, same underlying FCM), SMS wake (too slow/costly).

## Consequences
Adds the Firebase SDK to both apps (size budget accounted in doc 01 §7); no Firebase Analytics/Crashlytics (Sentry is the observability tool; no device fingerprinting SDKs).
