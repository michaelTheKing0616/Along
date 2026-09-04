# ADR-0013 — Pinned toolchain versions and hosting region

**Status:** Proposed — to be completed by task P0-E-01 · **Spec:** §5.1, §6 (no unpinned dependencies)

## To record at bootstrap (do not guess; measure and pin)
- Flutter stable version and Dart SDK (`.fvmrc`)
- Supabase CLI version; Postgres major (15 expected); PostGIS version
- Deno version for Edge Functions; Node LTS for `backend/jobs` and admin
- Next.js major; MapLibre GL Native / `maplibre_gl` plugin version; MapLibre GL JS version
- OSRM version and profile git SHAs; Planetiler version; Photon version
- Supabase region chosen by measured RTT from Lagos/Abuja (record the numbers)
- Paystack API version; Termii API version; FCM SDK versions

## Rule
Any upgrade of a pinned major version is a new ADR (supersedes this one's line item).
