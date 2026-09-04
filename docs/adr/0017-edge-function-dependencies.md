# ADR-0017 — Edge Function npm dependencies (Supabase JS, Zod)

**Status:** Accepted · **Date:** 2026-09-04 · **Task:** P1-A-06 · **Spec:** §5.1, doc 09 §5

## Decision

Pin npm imports for Deno Edge Functions in `backend/functions/deno.json`:

| Package | Version | Use |
|---|---|---|
| `@supabase/supabase-js` | **2.49.1** | Service-role client for `plan-trip` and future Edge Functions |
| `zod` | **3.24.2** | Request validation per doc 03 / doc 09 §5 |

Use `jsr:@supabase/functions-js` for the Edge runtime types only (no runtime dependency beyond Deno).

## Rationale

- Supabase Edge Functions run on Deno; the official JS client is the standard integration path (ADR-0001).
- Zod keeps validation aligned with OpenAPI shapes without code generation in Phase 1.

## Consequences

- CI `functions.yml` runs `deno test` with `--allow-env --allow-read --allow-net` when tests mock or call HTTP.
- Major version bumps require updating this ADR and `deno.lock`.
