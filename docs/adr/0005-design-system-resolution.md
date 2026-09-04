# ADR-0005 — Design system resolution (tokens, type, colour) over the two Stitch variants

**Status:** Accepted · **Date:** 2026-09-04 · **Spec:** §5.2, FM19, FM20, FM34 · **Detail:** blueprint doc 05 §1

## Decision
- Neutral white/grey surfaces; **ink black primary action**; **taxi yellow `#F7D117` as brand surface** (never text on white); semantic and mode palettes as tokens; no cream, no olive.
- **Inter only**, with tabular numerals; no monospaced numeric face.
- Mixed radius scale by role (4/8/12/16/20/pill).
- Mode colours: car teal, keke yellow, okada blue, minibus purple, always paired with custom icons.
- Single token source (`shared/design-tokens/tokens.json`) generating Dart and CSS; literal values in app code are a review failure.
- Real brand mark (`main_logo_along_*`) vectorised; Stitch logos rejected.
- Dark mode out of scope through Phase 9; token structure permits it later.

## Rationale
Legibility in sunlight on low-brightness panels, smaller font payload for low-data users, and the removal of the olive tonal artefact that made the Stitch set look dated. Uber/Bolt-grade contrast without importing their private-hire semantics.

## Consequences
Stitch screens are layout references only; colours/type/copy come from doc 05/06. Workers must not copy Stitch Tailwind classes or Material tonal palettes.
