# P7-A-03 — ETA accuracy A/B report (speed profiles vs generic defaults)

**Task:** P7-A-03 · **Generated from:** `backend/jobs/src/speed-profiles.test.ts` fixture  
**Data source:** matched_traces `match_meta.segment_observations` only (FM27 — no raw GPS)

## Method

- **Baseline:** `in_vehicle_time_estimate_s` scaled only by `planner.baseline_speed_mps` (10 m/s in fixture).
- **With profiles:** same base estimate calibrated via `calibrateInVehicleS` using segment median speed 5 m/s (≥ `jobs.speed_profile_min_samples` = 8).
- **Metric:** mean absolute error (MAE) vs actual in-vehicle duration from matched-trace fixture legs.

## Fixture legs

| Segment | Baseline estimate (s) | Actual (s) | Profile estimate (s) |
|---------|----------------------:|-----------:|-----------------------:|
| 501:forward | 600 | 1200 | 1200 |
| 502:forward | 900 | 1800 | 1800 |
| 503:forward | 450 | 900 | 900 |

## Results

| Metric | Value |
|--------|------:|
| MAE baseline (generic defaults) | **650.0 s** |
| MAE with segment_speed_profiles | **0.0 s** |
| Improvement | **100%** |

## Conclusion

Segment speed profiles derived from matched traces measurably reduce ETA error versus generic baseline speeds on the fixture. The vitest gate `profiles reduce MAE vs generic baseline on matched-trace fixture` asserts `maeProfileS < maeBaselineS`.

## Planner fallback (live speed)

Per doc 04 §15, live presence speed on the same segment within the last 10 minutes should take precedence over historical profiles. **No live segment-speed pipeline is implemented in this repo yet** — the planner uses `segment_speed_profiles_lookup` when `route_leg.segment_keys` are present; otherwise it keeps the seeded/OSRM `in_vehicle_time_estimate_s` unchanged.
