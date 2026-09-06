# ADR-0020 — flutter_tts for rider wayfinding audio (P2-B-01)

**Status:** Accepted · **Date:** 2026-09-06 · **Task:** P2-B-01 · **Spec:** §4.11, doc 06 R-19, doc 07 §9

## Decision

Add **`flutter_tts` 4.2.0** to `mobile-rider` for R-19 audio wayfinding. The server returns a `tts_script` array from `walking-directions`; the client speaks each line on play/pause without a network round-trip per step.

| Package | Version | Used in |
|---|---|---|
| `flutter_tts` | **4.2.0** | `mobile-rider` (R-19 audio mode) |

## Alternatives

- **Platform channels (AVSpeechSynthesizer / Android TextToSpeech) directly** — rejected; duplicates maintenance already standardised in blueprint doc 07 (`flutter_tts.speak(label)`).
- **Skip audio / text-only** — rejected; P2-B-01 acceptance requires audio via TTS.

## Consequences

- TTS is behind the R-19 audio tab only; text and map modes do not load the engine.
- Widget tests inject a fake `WayfindingTts` — no device TTS in CI.
- Major upgrades require superseding this ADR.
