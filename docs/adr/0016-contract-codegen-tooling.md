# ADR-0016 — Contract codegen tooling (OpenAPI + JSON Schema → TS/Dart)

**Status:** Accepted · **Date:** 2026-09-04 · **Task:** P1-A-02 · **Spec:** §6 (no unpinned dependencies)

## Context

`docs/blueprint/03_api_contracts.md` is the human-readable source of truth for Edge Function (OpenAPI 3.1) and RPC (JSON Schema) contracts. Machine-readable artifacts live in `shared/contracts/` and must stay in sync via CI (doc 09 §2).

## Decision

Pin the following devDependencies in `shared/contracts/package.json` and generate committed outputs from the schema sources:

| Tool | Version | Purpose |
|---|---|---|
| `openapi-typescript` | **7.6.1** | TS types from `openapi.yaml` |
| `json-schema-to-typescript` | **15.0.4** | TS types from `schemas/rpc/*.json` |
| `@redocly/openapi-core` | **1.28.3** | OpenAPI 3.1 validation in CI |

Dart types are emitted by a small in-repo script (`scripts/generate_dart.mjs`) that reads the same JSON Schema `$defs` — no third-party Dart codegen dependency.

Generated outputs (committed, CI-checked for staleness):

- `shared/contracts/generated/edge.ts`
- `shared/contracts/generated/rpc.ts`
- `shared/flutter/along_data/lib/src/contracts/api_contracts.g.dart`

## Consequences

- Workers change contracts by editing `openapi.yaml` / `schemas/**` then running `pnpm --filter @along/contracts build`.
- CI `contracts.yml` and `functions.yml` fail on stale generated files or OpenAPI/handler drift.
- Major version bumps of the pinned tools require a new ADR superseding this one.
