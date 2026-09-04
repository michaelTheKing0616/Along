# ADR-0013 — Pinned toolchain versions and hosting region

**Status:** Accepted · **Date:** 2026-09-04 · **Task:** P0-E-01 · **Spec:** §5.1, §6 (no unpinned dependencies)

## Decision

Pin all toolchain versions at repo bootstrap. Upgrading a **major** version requires a new ADR that supersedes the relevant line item below.

### Flutter / Dart

| Component | Version | Pin location |
|---|---|---|
| Flutter SDK | **3.47.2** (stable) | `.fvmrc`, CI `mobile.yml` |
| Dart SDK | **3.13.2** (bundled with Flutter 3.47.2) | `pubspec.yaml` `environment.sdk: ^3.13.0` |
| Melos | **6.3.2** | root `pubspec.yaml`, CI |
| flutter_lints | **5.0.0** | Flutter package `pubspec.yaml` files |
| lints (pure Dart) | **5.1.1** | `along_core/pubspec.yaml` |

### Supabase / Postgres

| Component | Version | Pin location |
|---|---|---|
| Supabase CLI | **2.115.0** | root `package.json`, CI workflows |
| Postgres (local + target) | **15** (major) | `supabase/config.toml` `[db] major_version` |
| PostGIS | **3.4.x** (Supabase-managed image) | provisioned by CLI; verify after `supabase start` |

### TypeScript / Node (admin, jobs, contracts, tokens)

| Component | Version | Pin location |
|---|---|---|
| Node.js | **22.x LTS** (`22.15.0` tested) | `package.json` `engines`, CI |
| pnpm | **9.15.0** | root `package.json` `packageManager`, CI |
| TypeScript | **5.8.3** | `backend/jobs`, `admin-console` |
| ESLint | **9.28.0** | `backend/jobs`, `admin-console` |
| typescript-eslint | **8.33.0** | `backend/jobs`, `admin-console` |
| Vitest | **3.2.1** | `backend/jobs`, `admin-console` |

### Deno (Edge Functions)

| Component | Version | Pin location |
|---|---|---|
| Deno | **2.9.6** | CI `functions.yml`; local via official installer or `denoland/setup-deno` |

### Next.js / MapLibre (admin + mobile — pinned now, implemented in later tasks)

| Component | Version | Notes |
|---|---|---|
| Next.js | **15.1.12** | admin-console scaffold in P0-D-01 |
| MapLibre GL JS | **5.6.1** | admin map views |
| maplibre_gl (Flutter plugin) | **0.22.0** | `along_map` in P1-E-02 |

### Routing stack (backend/routing — pinned now, implemented in P1-A-07)

| Component | Version | Notes |
|---|---|---|
| OSRM | **v5.27.1** | Docker image tag |
| OSRM car profile | git SHA `car.lua` from OSRM v5.27.1 | recorded at first `backend/routing` commit |
| OSRM foot profile | git SHA `foot.lua` from OSRM v5.27.1 | same |
| Planetiler | **0.8.2** | tile build |
| Photon | **0.6.2** | geocoding |

### External providers (API / SDK versions)

| Provider | Version | Notes |
|---|---|---|
| Paystack API | **v1** (`/transaction/initialize`, webhooks) | live + test keys via Vault |
| Termii API | **v3** | SMS/OTP hook |
| FCM (Firebase Admin SDK) | **13.4.0** (Node) | push in P1-A-08 |

### Supabase hosting region

**Selected region:** `eu-west-2` (London)

**Basis (provisional):** Blueprint doc 09 §1 states eu-west is typically ~100–120 ms RTT from Lagos/Abuja. Formal ICMP/HTTPS RTT measurement from Lagos and Abuja endpoints was **not completed in the P0-E-01 worker environment** (no Nigeria egress from CI sandbox). Product owner should confirm with a one-time measurement from both cities before provisioning `along-staging` / `along-prod`.

| Measurement target | Expected RTT | Measured (pending) |
|---|---|---|
| Lagos → `eu-west-2.supabase.co` | ~100–120 ms | _TBD_ |
| Abuja → `eu-west-2.supabase.co` | ~100–120 ms | _TBD_ |
| Lagos → `eu-west-1.supabase.co` | ~100–120 ms | _TBD_ |

If measurement shows `eu-west-1` (Ireland) materially lower, update this ADR before first cloud project creation.

## Rule

Any upgrade of a pinned **major** version is a new ADR (supersedes this one's line item).

## Consequences

- CI and local dev must use pinned versions (FVM for Flutter, pinned CLI in npm devDependency, Deno version in workflow).
- Dependabot may propose minor/patch bumps; major bumps need ADR.
- Region choice is reversible before first Supabase cloud project is created.
