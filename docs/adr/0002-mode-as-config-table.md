# ADR-0002 — Vehicle mode is a configuration table, not a Postgres enum

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** Constitution 3 ("adding a mode requires no code change"), §4.2.2 `mode_comfort_weights`, §4.13 load capacity, FM5

## Context
The spec lists `mode` as an enum-like field on `routes`, `route_legs`, `vehicles` and a separate `mode_comfort_weights` table. A Postgres enum requires `ALTER TYPE` (a migration = a code change) to add a mode, contradicting Constitution 3.

## Decision
`mode_config(code text primary key, label, label_i18n, icon_key, color_token, comfort_weight, load_capacity, default_seat_capacity, default_dwell_s, active, sort_order)`. Every `mode_code` column is a foreign key to it. The spec's `mode_comfort_weights` is realised as the `comfort_weight` column; §4.13's "mode load-capacity metadata" as `load_capacity`. Adding a mode = one `INSERT` + an icon/colour token pair that already exist in the design system's reserved slots (doc 05 §2 defines four; a fifth reuses a neutral slot until design adds one).

## Consequences
- Client apps render modes from server data (labels, icon keys, colour token names); unknown icon keys fall back to a generic vehicle glyph.
- Planner mode filters and UI chips are data-driven.
- `mode_config` writes are admin-only and audited.
