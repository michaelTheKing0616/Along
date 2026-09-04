# ADR-0004 — Tenant isolation derived from city → country → deployment

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** Constitution 7, §4.14 `deployments`, Phase 9, Phase 10

## Context
Phase 10 formalises multi-tenancy, but retrofitting a `tenant_id` onto every transactional table then would be a rewrite (Constitution 7 forbids). At the same time, a `tenant_id` on every row is noisy and error-prone in RLS.

## Decision
Every geographic/transactional row carries `city_id` from Phase 0. `cities.country_code → countries.deployment_id → deployments`. Tenant scoping is derived through that chain in `admin_can_access_city()` and in tenant-facing RLS. No per-row `tenant_id`.

## Consequences
- A deployment owns whole countries (or, if ever needed, a country can be split by adding `cities.deployment_override` — not built now).
- Cross-tenant leakage tests (Phase 10) operate on city membership.
- All planner/config/analytics queries are already city-scoped, which also satisfies Phase 9's multi-city requirement.
