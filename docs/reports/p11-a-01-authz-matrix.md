# P11-A-01 Authorization Matrix

**Generated:** 2026-10-25T19:27:39Z (UTC) from live `pg_policies` on `postgresql://postgres:postgres@…`
**Source of truth for expectations:** doc 02 §16 + per-table `-- RLS:` comments

## Legend

| Status | Meaning |
|---|---|
| MATCH | Live policies align with doc 02 §16 summary |
| DRIFT | Live policy weaker or missing vs doc — security fix required |
| DOC-STALE | Live policy is intentional later-phase behaviour; doc §16 row not yet updated |

## Summary

| DOC-STALE | 14 |
| MATCH | 97 |

## Per-table matrix

| Schema | Table | RLS | Policies | Doc §16 row | Status | Notes |
|---|---|---:|---:|---|---|---|
| public | api_keys | yes | 2 | (later-phase B2B) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | api_usage | yes | 2 | (later-phase B2B) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | corporate_accounts | yes | 3 | (later-phase corporate) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | corporate_invoices | yes | 3 | (later-phase corporate) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | corporate_members | yes | 3 | (later-phase corporate) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | corporate_trip_allocations | yes | 3 | (later-phase corporate) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | corporate_trip_policies | yes | 3 | (later-phase corporate) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | countries | yes | 3 | geo/config | DOC-STALE | anon active-country read added P9-A-01 onboarding |
| public | device_installs | yes | 4 | (not in §16 matrix) | DOC-STALE |  |
| public | invoice_lines | yes | 3 | (later-phase corporate) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | operator_accounts | yes | 3 | (later-phase operator) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | operator_members | yes | 3 | (later-phase operator) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | placement_counters | yes | 2 | (later-phase ads) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| public | sponsored_placements | yes | 2 | (later-phase ads) | DOC-STALE | Phase 8/10 B2B/corporate/operator policies — §16 row pending |
| private | api_rate_windows | yes | 0 | private.* | MATCH | service role only; RLS on, no client policies |
| private | guarantor_ack_tokens | yes | 0 | private.* | MATCH | service role only; RLS on, no client policies |
| private | identity_hashes | yes | 0 | private.* | MATCH | service role only; RLS on, no client policies |
| private | payment_webhook_raw | yes | 0 | private.* | MATCH | service role only; RLS on, no client policies |
| private | qr_resolve_rate_buckets | yes | 0 | private.* | MATCH | service role only; RLS on, no client policies |
| private | sms_otp_inbox | yes | 0 | (not in §16 matrix) | MATCH | service role only; RLS on, no client policies |
| public | admin_users | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | anonymized_od_cells | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | anonymized_od_exports | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | app_config | yes | 2 | geo/config | MATCH |  |
| public | app_config_keys | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | audit_log | yes | 3 | audit_log | MATCH |  |
| public | candidate_park_clusters | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | cities | yes | 2 | geo/config | MATCH |  |
| public | conductor_sessions | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | corridors | yes | 2 | geo/config | MATCH |  |
| public | coverage_gap_reports | yes | 2 | coverage_gap_reports | MATCH |  |
| public | data_sources | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | deployments | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | device_tokens | yes | 1 | device_tokens | MATCH |  |
| public | driver_day_plans | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | driver_earnings_goals | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | driver_ledger_entries | yes | 3 | driver_ledger_entries | MATCH |  |
| public | driver_payouts | yes | 3 | (not in §16 matrix) | MATCH |  |
| public | driver_presence | yes | 3 | driver_presence | MATCH | no rider SELECT; Tier-A via ambient_vehicles() |
| public | driver_rest_prefs | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | driver_rests | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | driver_ride_rules | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | driver_risk_scores | yes | 2 | trip_reconciliation_flags | MATCH |  |
| public | driver_route_profiles | yes | 5 | driver_route_profiles | MATCH |  |
| public | driver_route_stops | yes | 5 | driver_route_profiles | MATCH |  |
| public | driver_standing_transitions | yes | 3 | driver_standing_transitions | MATCH |  |
| public | driver_vehicles | yes | 3 | (not in §16 matrix) | MATCH |  |
| public | driver_verifications | yes | 3 | driver_verifications | MATCH | city-scoped admin via admin_can_access_* (00079) |
| public | drivers | yes | 4 | drivers | MATCH |  |
| public | emergency_contacts | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | fare_corrections | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | fare_observations | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | fare_quotes | yes | 6 | fare_quotes | MATCH | city-scoped admin via admin_can_access_* (00079) |
| public | field_agents | yes | 3 | (not in §16 matrix) | MATCH |  |
| public | field_reconciliations | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | field_submissions | yes | 4 | (not in §16 matrix) | MATCH |  |
| public | fuel_notes | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | graph_confirmations | yes | 1 | graph_confirmations | MATCH |  |
| public | graph_revisions | yes | 1 | intelligence | MATCH |  |
| public | guarantors | yes | 4 | guarantors | MATCH |  |
| public | guardian_events | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | incidents | yes | 3 | incidents | MATCH |  |
| public | itineraries | yes | 2 | itineraries | MATCH |  |
| public | itinerary_stops | yes | 2 | itineraries | MATCH |  |
| public | job_runs | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | journey_transfer_walks | yes | 3 | (not in §16 matrix) | MATCH |  |
| public | journeys | yes | 3 | journeys | MATCH |  |
| public | live_segment_observations | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | matched_traces | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | mode_config | yes | 2 | geo/config | MATCH |  |
| public | notifications | yes | 2 | notifications | MATCH |  |
| public | parks | yes | 2 | graph | MATCH |  |
| public | payments | yes | 4 | payments | MATCH |  |
| public | pending_ledger_adjustments | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | pickup_events | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | planner_queries | yes | 2 | planner_queries | MATCH |  |
| public | price_negotiation_rounds | yes | 3 | negotiations | MATCH |  |
| public | price_negotiations | yes | 3 | negotiations | MATCH |  |
| public | profiles | yes | 3 | profiles | MATCH | city-scoped admin via admin_can_access_* (00079) |
| public | qr_sticker_requests | yes | 3 | (not in §16 matrix) | MATCH |  |
| public | ratings | yes | 3 | ratings | MATCH |  |
| public | ride_rule_presets | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | rider_favourites | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | rider_guardian_prefs | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | rider_payment_methods | yes | 2 | rider_payment_methods | MATCH |  |
| public | riders | yes | 4 | riders | MATCH | city-scoped admin via admin_can_access_* (00079) |
| public | road_geometry_corrections | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | route_inference_candidates | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | route_legs | yes | 2 | graph | MATCH |  |
| public | route_requests | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | route_stages | yes | 2 | graph | MATCH |  |
| public | route_through_fares | yes | 2 | graph | MATCH |  |
| public | routes | yes | 2 | graph | MATCH |  |
| public | segment_speed_profiles | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | settlement_agents | yes | 3 | (not in §16 matrix) | MATCH |  |
| public | settlements | yes | 4 | settlements | MATCH |  |
| public | sos_alerts | yes | 3 | sos_alerts | MATCH |  |
| public | split_settlement_alerts | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | stage_dwell_samples | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | transfer_points | yes | 2 | graph | MATCH |  |
| public | trip_dispatch_context | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | trip_events | yes | 3 | trip_events | MATCH |  |
| public | trip_extensions | yes | 3 | trip_extensions | MATCH |  |
| public | trip_messages | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | trip_pins | yes | 2 | (not in §16 matrix) | MATCH |  |
| public | trip_reconciliation_flags | yes | 2 | trip_reconciliation_flags | MATCH |  |
| public | trip_shares | yes | 2 | trip_shares | MATCH |  |
| public | trips | yes | 4 | trips | MATCH | city-scoped admin via admin_can_access_* (00079) |
| public | vehicle_layouts | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | vehicle_seat_states | yes | 1 | (not in §16 matrix) | MATCH |  |
| public | vehicles | yes | 3 | vehicles | MATCH |  |

## Non-negotiables (doc 02 §16 footer, enforced by `check_authz_matrix.sql`)

- Every `public`/`private` application table has RLS enabled
- `private.*` has no `anon`/`authenticated` policies (service role + SECURITY DEFINER RPCs only)
- `driver_presence` has zero rider-readable SELECT policies
- `profiles`/`riders`/`driver_verifications`/`fare_quotes` admin SELECT is city-scoped
- `trips_select_admin` includes `city_admin` (parity with `journeys`)

## Fixes applied (migration 00079)

- Enabled RLS on `private.guarantor_ack_tokens`, `private.payment_webhook_raw`, `private.qr_resolve_rate_buckets`
- Added `admin_can_access_profile(uuid)` SECURITY DEFINER helper
- Scoped `profiles_select_admin`, `riders_select_admin`, `driver_verifications_*_admin`, `fare_quotes_select_admin`
- Added `city_admin` to `trips_select_admin`

_Regenerate: `bash backend/db/scripts/check_authz_matrix.sh`_
