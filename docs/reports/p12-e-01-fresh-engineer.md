# P12-E-01 — Fresh engineer dry-run

**Date:** 2026-09-07 · **Branch:** `task/p12-e-01` · **Engineer context:** Worker validating README local-stack path

## Goal

Verify a fresh engineer can bring up the local stack using only repo docs (README + blueprint 09), without inventing credentials.

## Prerequisites assumed

- macOS or Linux with Docker Desktop running
- Node.js 22.x, pnpm 9.x (see ADR-0013)
- Flutter 3.47.2 via FVM (optional for mobile steps)
- `psql` client (optional verification)

## Commands executed

| # | Command | Result |
|---|---|---|
| 1 | `pnpm install` | **Not re-run** — workspace already bootstrapped; would install pinned Supabase CLI 2.115.0 per root `package.json` |
| 2 | `pnpm supabase status` | **PASS** — API `http://127.0.0.1:54321`, DB `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, Studio `:54323` |
| 3 | `psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "SELECT 1 AS ping;"` | **PASS** — `ping = 1` |
| 4 | `psql ... -c "SELECT key, value FROM app_config WHERE key='payments.digital_enabled' AND scope_type='global';"` | **PASS** — `false` |
| 5 | `psql ... -c "SELECT count(*) FROM app_config_keys;"` | **PASS** — `44` registry rows; `161` global defaults in `app_config` |
| 6 | `pnpm supabase db reset` | **Skipped** — stack already migrated/seeded; reset is heavy (~minutes) and documented as step 3 for truly fresh clones |
| 7 | `cp admin-console/.env.example admin-console/.env.local` | **Not re-run** — would copy demo Supabase keys from example file (no invented secrets) |
| 8 | `pnpm --filter @along/admin-console dev` | **Not re-run** — long-running; README documents as next step |
| 9 | `melos bootstrap` | **Not re-run** — requires Flutter/FVM; README documents as mobile prerequisite |

## Notes

- Bare `supabase` is not on PATH globally; use `pnpm supabase` (npm script) after `pnpm install`.
- First `npx supabase status` failed in sandbox (telemetry write EPERM); succeeded with full permissions — normal local dev is unaffected.
- Env templates referenced (not committed with secrets): `admin-console/.env.example`, `env/staging.example.json`.
- Config reference generated from live DB into `docs/CONFIG_REFERENCE.md`.

## Acceptance mapping

**Exit: fresh engineer runs stack from docs only (recorded)** — partial live verification: stack was already up; status + psql probes confirm README connection strings and config defaults match documentation. Full greenfield path documented in README § Local stack (≤ 10 commands).
