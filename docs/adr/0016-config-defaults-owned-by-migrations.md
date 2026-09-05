# ADR-0016 — `app_config` defaults are owned by migrations, not seeds

**Status:** Accepted · **Date:** 2026-09-05 · **Amends:** doc 02 §2.3, §17; task P0-A-01 wording

## Context
The blueprint told P0-A-01 to insert every `app_config` key in `seed_core.sql`. Two consequences surfaced in Phase 1:
1. Later feature migrations (0014, 0017, 0018) also inserted their keys; the seed had no `on conflict` clause, so a fresh `supabase db reset` fails on `app_config_pkey`. It was carried as "known, non-blocking", which is wrong: a red fresh-reset is the Phase 0 defect class the Reviewer already failed P0-A-05 for.
2. More seriously, Supabase's `seed.sql` runs only on local `db reset`. It never runs on `db push` to staging or prod. Every threshold the system depends on would be absent in staging — the first thing P1-E-04's smoke test would hit.

## Decision
- **Migrations own config defaults.** The migration that introduces a feature registers its keys with `select config_default('<key>', '<json>');` (helper in doc 02 §2.3): `insert … on conflict do nothing`. Defaults fill gaps; they never overwrite an operator's live value. `do update` on `app_config` in a migration is a defect (migration 0014 has one and must be corrected).
- **Seeds own data, not configuration.** `seed_core.sql` inserts deployments, countries, cities, modes, palettes and may add *scoped* overrides for entities it created (NG `sos.emergency_number`), also via `config_default`. It inserts no global keys.
- **Consolidation migration** moves all keys currently in the seed into one migration (`config_defaults_baseline`) so staging/prod get the complete doc 02 §2.3 table on first push.
- **Test `TS-CFG-02`:** after migrations alone (no seed), every key in doc 02 §2.3 resolves via `cfg()`. Runs in the `db` CI workflow.

## Alternatives considered
- Keep config in the seed and run the seed against staging/prod by hand: non-reproducible, and a prod seed run would risk overwriting live values.
- `on conflict do update` everywhere: fixes the reset error but silently resets operator edits on every deploy that touches a default — the worst failure mode for a config-not-code system.

## Consequences
Task P1-A-09 implements the helper, the baseline migration, the seed cleanup, the 0014 correction and `TS-CFG-02`. Future Workers: new config key ⇒ new `config_default()` line in your migration; never in a seed.
