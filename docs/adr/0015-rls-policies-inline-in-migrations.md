# ADR-0015 — RLS policies live inline in migrations; `policies/` is a generated snapshot

**Status:** Accepted · **Date:** 2026-09-04 · **Supersedes:** doc 09 §3 wording "applied by migrations (`\ir`)"

## Context
The blueprint originally placed RLS policies in `backend/db/policies/<table>.sql` and had migrations include them with psql's `\ir`. The Supabase CLI migration runner does not execute psql meta-commands, so P0-A-02 could not follow the instruction. The Worker's interim pattern — policies inlined in the migration *plus* a hand-maintained "canonical" copy in `policies/` — created two sources of truth that would drift silently.

## Decision
- **Migrations are the single source of truth for RLS.** A policy is created, altered or dropped only in a migration, in the same file as the schema change that motivates it.
- `backend/db/policies/<table>.sql` becomes a **generated snapshot**: `backend/db/scripts/dump_policies.sh` (run after `supabase db reset` locally and in the `db` CI workflow) writes one file per table from `pg_policies` + `pg_class.relrowsecurity/relforcerowsecurity`. CI fails if the committed snapshot differs from the regenerated one. Files carry a `-- GENERATED — do not edit` header.
- Reviewers use the snapshot (and the RLS-coverage script) to check doc 02 §16; Workers never edit it by hand.

## Alternatives considered
- Delete `policies/` and rely on `select * from pg_policies`: simplest, but loses a reviewable, diffable per-table view in PRs — which is where RLS mistakes get caught.
- Generate migrations *from* `policies/` (policies canonical): more machinery, and policy changes still need a migration for remote environments, so the generator would only add a step.
- Keep both hand-maintained: rejected — drift is certain and dangerous for an authorisation layer.

## Consequences
Follow-up task P0-A-09 converts the existing files, removes "canonical source" comments from migrations 0003–0009, and adds the CI check. Any future ADR touching authorisation must reference the snapshot diff in its PR.
