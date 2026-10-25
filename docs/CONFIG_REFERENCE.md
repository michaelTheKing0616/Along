# Along — Configuration Reference (`app_config`)
**Generated:** 2026-09-07 · **Task:** P12-E-01 · **Source:** live local DB `postgresql://postgres:postgres@127.0.0.1:54322/postgres` after migrations + `seed_core`
Runtime thresholds, weights, and feature switches live in Postgres `app_config`, resolved by `cfg(key, city_id, corridor_id)` (blueprint doc 02 §2.3). Defaults are registered by migrations via `config_default()` (ADR-0016). Admin edits go through `admin_set_config` (A-09) with JSON-schema validation from `app_config_keys`.
**Regenerate:**
```bash
psql "$DATABASE_URL" -c "SELECT ac.key, COALESCE(k.description,''), ac.value::text FROM app_config ac LEFT JOIN app_config_keys k ON k.key=ac.key WHERE ac.scope_type='global' AND ac.scope_id='*' ORDER BY ac.key;"
```
## Environment files (not `app_config`)
| File | Purpose |
|---|---|
| `env/staging.example.json` | Mobile `--dart-define-from-file` template for staging (Supabase URL, bundle IDs, Sentry placeholders) |
| `admin-console/.env.example` | Next.js local/staging env (Supabase URL + anon/service keys, tiles, public origin) |

### Edge Function secrets: rider/driver contact relay (`trip-contact`)
| Secret | Purpose |
|---|---|
| `CONTACT_PROVIDER` | `tel` (default; dev/staging, NOT masked: hands out the real number on tap, logged by suffix), `termii` or `africastalking` (masked relay) |
| `CONTACT_PROVIDER_API_KEY` | Masked-relay provider key. **Needed from ops before masking can go live.** |
| `CONTACT_PROXY_NUMBER` | Provider proxy/virtual number callers dial. **Needed from ops.** |

**Decision (Tope, 2026-10-25): no paid plans for now.** `CONTACT_PROVIDER` stays `tel`; nothing in any environment needs `CONTACT_PROVIDER_API_KEY` or `CONTACT_PROXY_NUMBER`, and leaving them unset is the supported state. The masked adapters are stubs until a provider account and its session API are confirmed; they fail closed (503 `CONTACT_UNAVAILABLE`) instead of falling back to the real number.

Copy example files and fill placeholders from your Supabase project dashboard — do not commit real secrets.
## Critical switches
| Key | Default (global) | Read-only | Notes |
|---|---|---|---|
| `payments.digital_enabled` | `false` | yes | **Master switch for digital payments.** Requires legal sign-off (P4-E-02) before enabling in prod. **Never flip as a deploy rollback shortcut** — use forward fix or targeted config change with audit reason. |
| `placements.enabled` | `false` | no | Sponsored placements master switch |
| `public.origin` | `""` | no | Public URLs (QR, universal links). Set when `along.ng` is purchased. |
| `sms.provider` | `"log"` | no | Local dev logs SMS; staging/prod use Termii via Edge hook |

## Global defaults
| Key | Description | Default | Allowed scopes | Read-only |
|---|---|---|---|---|
| `analytics.bucket_interval_s` | Migration default (see blueprint doc 02 §2.3). | `3600` | `{global,city,country,corridor}` | no |
| `analytics.max_window_days` | Migration default (see blueprint doc 02 §2.3). | `31` | `{global,city,country,corridor}` | no |
| `analytics.page_size` | Migration default (see blueprint doc 02 §2.3). | `24` | `{global,city,country,corridor}` | no |
| `api.default_rate_limit_per_min` | Default per-minute call cap for data API keys when not overridden on the key row | `60` | `{global}` | no |
| `api.max_page_size` | Maximum page size for aggregate API product responses | `50` | `{global}` | no |
| `audit.page_size` | Audit log page size (rows) | `50` | `{global}` | no |
| `auth.payout_reauth_window_s` | Migration default (see blueprint doc 02 §2.3). | `300` | `{global,city,country,corridor}` | no |
| `boarding.colocation_duration_s` | Migration default (see blueprint doc 02 §2.3). | `20` | `{global,city,country,corridor}` | no |
| `boarding.colocation_radius_m` | Migration default (see blueprint doc 02 §2.3). | `25` | `{global,city,country,corridor}` | no |
| `boarding.in_transit_duration_s` | Migration default (see blueprint doc 02 §2.3). | `30` | `{global,city,country,corridor}` | no |
| `boarding.in_transit_min_speed_mps` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `boarding.min_speed_mps` | Migration default (see blueprint doc 02 §2.3). | `1.5` | `{global,city,country,corridor}` | no |
| `boarding.sample_max_accuracy_m` | Migration default (see blueprint doc 02 §2.3). | `50` | `{global,city,country,corridor}` | no |
| `boarding.sample_max_age_s` | Migration default (see blueprint doc 02 §2.3). | `15` | `{global,city,country,corridor}` | no |
| `cache.graph_bundle_max_legs` | graph-bundle max legs per city | `5000` | `{global,city}` | no |
| `cache.graph_bundle_max_parks` | graph-bundle max parks per city | `500` | `{global,city}` | no |
| `cache.graph_bundle_max_stages` | graph-bundle max stages per city | `2000` | `{global,city}` | no |
| `cache.graph_bundle_ttl_s` | graph-bundle Edge cache TTL (seconds) | `3600` | `{global,city}` | no |
| `cache.places_ttl_s` | places-search Edge KV TTL (seconds) | `86400` | `{global,city}` | no |
| `cache.plan_trip_ttl_s` | plan-trip hot OD pair cache TTL (seconds) | `60` | `{global,city}` | no |
| `client.ambient_poll_interval_s` | LowDataMode: ambient RPC poll interval (seconds) when Broadcast is disabled | `30` | `{global,city}` | no |
| `client.low_data_tile_max_zoom` | LowDataMode: cap MapLibre tile refresh at this zoom when 2G or OS data saver is on | `15` | `{global,city}` | no |
| `client.trip_location_sample_interval_s` | Migration default (see blueprint doc 02 §2.3). | `5` | `{global,city,country,corridor}` | no |
| `client.trip_poll_interval_s` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `clustering.eps_m` | DBSCAN epsilon (m) for candidate park clustering | `35` | `{global,city}` | no |
| `clustering.min_distinct_days` | Distinct days required for candidate park cluster | `3` | `{global,city}` | no |
| `clustering.min_distinct_drivers` | Distinct drivers required for candidate park cluster | `4` | `{global,city}` | no |
| `clustering.min_points` | DBSCAN min points for candidate park clustering | `12` | `{global,city}` | no |
| `clustering.window_days` | Presence history window (days) for candidate park clustering | `14` | `{global,city}` | no |
| `commission.applies_to_load_surcharge` | Migration default (see blueprint doc 02 §2.3). | `true` | `{global,city,country,corridor}` | no |
| `commission.rate` | Platform commission rate | `0.075` | `{global,city}` | no |
| `decline.reasons` | Migration default (see blueprint doc 02 §2.3). | `["too_far", "wrong_direction", "vehicle_full", "no_room_for_load", "other"]` | `{global,city,country,corridor}` | no |
| `disclosure.approach_band_s` | Migration default (see blueprint doc 02 §2.3). | `[120, 300]` | `{global,city,country,corridor}` | no |
| `dispatch.candidate_token_ttl_s` | Migration default (see blueprint doc 02 §2.3). | `60` | `{global,city,country,corridor}` | no |
| `dispatch.max_cascade` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `dispatch.no_show_after_s` | Migration default (see blueprint doc 02 §2.3). | `300` | `{global,city,country,corridor}` | no |
| `dispatch.request_ttl_s` | Driver request TTL (seconds) | `25` | `{global,city}` | no |
| `driver.manifest_poll_s` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `driver.negotiation_poll_s` | Migration default (see blueprint doc 02 §2.3). | `2` | `{global,city,country,corridor}` | no |
| `export.geohash_precision` | Geohash precision for anonymised origin/destination export cells | `5` | `{global,city}` | no |
| `export.k` | Minimum trip count per OD export cell (k-anonymity threshold) | `10` | `{global,city}` | no |
| `extension.proposal_ttl_s` | Migration default (see blueprint doc 02 §2.3). | `120` | `{global,city,country,corridor}` | no |
| `fare.default_rate_per_km` | Migration default (see blueprint doc 02 §2.3). | `{"car": 120, "keke": 90, "okada": 110, "minibus": 60}` | `{global,city,country,corridor}` | no |
| `fare.min_fare` | Migration default (see blueprint doc 02 §2.3). | `{"car": 200, "keke": 100, "okada": 100, "minibus": 100}` | `{global,city,country,corridor}` | no |
| `field.fare_tol_pct` | Migration default (see blueprint doc 02 §2.3). | `0.15` | `{global,city,country,corridor}` | no |
| `field.location_tol_m` | Migration default (see blueprint doc 02 §2.3). | `50` | `{global,city,country,corridor}` | no |
| `geometry.cluster_m` | Spatial cluster radius (m) for geometry correction candidates | `20` | `{global,city}` | no |
| `geometry.min_supporting_traces` | Minimum distinct trips supporting a geometry correction candidate | `15` | `{global,city}` | no |
| `graph.snap_radius_m` | Driver route stop snap radius (m) | `60` | `{global,city}` | no |
| `graph.stage_merge_radius_m` | Stage dedupe radius (m) | `40` | `{global,city}` | no |
| `inference.frechet_m` | Max discrete Fréchet distance (m) for route inference trace clustering | `150` | `{global,city}` | no |
| `inference.min_trips` | Minimum matched trips for a route inference candidate | `20` | `{global,city}` | no |
| `itinerary.prepare_eta_s` | Migration default (see blueprint doc 02 §2.3). | `600` | `{global,city,country,corridor}` | no |
| `jobs.corporate_invoice_day` | Day of month (UTC) to generate corporate invoices for the prior billing period | `1` | `{global}` | no |
| `jobs.corporate_invoice_hour_utc` | Hour (UTC) on jobs.corporate_invoice_day when the corporate invoice job runs | `4` | `{global}` | no |
| `jobs.map_match_default_radius_m` | OSRM Match search radius (m) when trip_location_samples.accuracy_m is null | `25` | `{global,city}` | no |
| `jobs.map_match_min_confidence` | Minimum OSRM Match confidence to persist matched_traces | `0.6` | `{global,city}` | no |
| `jobs.map_match_min_samples` | Minimum trip_location_samples before OSRM Match runs | `10` | `{global,city}` | no |
| `jobs.speed_profile_min_samples` | Minimum matched-trace observations per segment × dow × hour before upserting segment_speed_profiles | `8` | `{global,city}` | no |
| `journey.abandon_after_min` | Migration default (see blueprint doc 02 §2.3). | `60` | `{global,city,country,corridor}` | no |
| `journey.transfer_prefetch_eta_s` | Migration default (see blueprint doc 02 §2.3). | `300` | `{global,city,country,corridor}` | no |
| `ledger.block_threshold` | Migration default (see blueprint doc 02 §2.3). | `-5000` | `{global,city,country,corridor}` | no |
| `ledger.deactivate_after_days` | Migration default (see blueprint doc 02 §2.3). | `14` | `{global,city,country,corridor}` | no |
| `ledger.deactivate_threshold` | Migration default (see blueprint doc 02 §2.3). | `-15000` | `{global,city,country,corridor}` | no |
| `ledger.dual_control_threshold` | Finance dual-control threshold | `20000` | `{global,city}` | no |
| `ledger.grace_period_hours` | Migration default (see blueprint doc 02 §2.3). | `48` | `{global,city,country,corridor}` | no |
| `ledger.onboarding_deposit` | Migration default (see blueprint doc 02 §2.3). | `0` | `{global,city,country,corridor}` | no |
| `ledger.warn_threshold` | Migration default (see blueprint doc 02 §2.3). | `-3000` | `{global,city,country,corridor}` | no |
| `load.warn_capacities` | Migration default (see blueprint doc 02 §2.3). | `{"large": ["none", "small", "medium"], "small": ["none"], "medium": ["none", "small"]}` | `{global,city,country,corridor}` | no |
| `motion.naMe.cycle_duration_s` | Migration default (see blueprint doc 02 §2.3). | `8` | `{global,city,country,corridor}` | no |
| `motion.naMe.strobe_ms` | Migration default (see blueprint doc 02 §2.3). | `250` | `{global,city,country,corridor}` | no |
| `name.colors` | Migration default (see blueprint doc 02 §2.3). | `["color.naMe.green", "color.naMe.blue", "color.naMe.red", "color.naMe.orange", "color.naMe.purple", "color.naMe.yellow", "color.naMe.pink", "color.naMe.cyan"]` | `{global,city,country,corridor}` | no |
| `name.shapes` | Migration default (see blueprint doc 02 §2.3). | `["circle", "square", "triangle", "diamond", "star", "hexagon"]` | `{global,city,country,corridor}` | no |
| `negotiation.chip_steps` | Migration default (see blueprint doc 02 §2.3). | `[-100, -50, 50, 100]` | `{global,city,country,corridor}` | no |
| `negotiation.park.round_cap` | Migration default (see blueprint doc 02 §2.3). | `4` | `{global,city,country,corridor}` | no |
| `negotiation.park.round_timeout_s` | Migration default (see blueprint doc 02 §2.3). | `20` | `{global,city,country,corridor}` | no |
| `negotiation.roaming.eta_none_s` | Migration default (see blueprint doc 02 §2.3). | `20` | `{global,city,country,corridor}` | no |
| `negotiation.roaming.eta_single_s` | Migration default (see blueprint doc 02 §2.3). | `60` | `{global,city,country,corridor}` | no |
| `negotiation.roaming.pickup_radius_m` | Migration default (see blueprint doc 02 §2.3). | `150` | `{global,city,country,corridor}` | no |
| `negotiation.roaming.round_cap` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `negotiation.roaming.round_timeout_s` | Migration default (see blueprint doc 02 §2.3). | `12` | `{global,city,country,corridor}` | no |
| `ops.live_map_poll_s` | Admin live map poll interval (seconds) | `5` | `{global,city}` | no |
| `otp.rate_limit_per_hour` | Migration default (see blueprint doc 02 §2.3). | `5` | `{global,city,country,corridor}` | no |
| `payments.digital_enabled` | Digital payments master switch (country/city) | `false` | `{global,country,city}` | yes |
| `payments.dynamic_qr_ttl_s` | Migration default (see blueprint doc 02 §2.3). | `600` | `{global,city,country,corridor}` | no |
| `payments.fee_bearer` | Migration default (see blueprint doc 02 §2.3). | `"account"` | `{global,city,country,corridor}` | no |
| `payments.initiate_ttl_s` | Migration default (see blueprint doc 02 §2.3). | `1800` | `{global,city,country,corridor}` | no |
| `payments.min_digital_amount` | Migration default (see blueprint doc 02 §2.3). | `100` | `{global,city,country,corridor}` | no |
| `payments.qr_resolve_rate_per_min` | Migration default (see blueprint doc 02 §2.3). | `30` | `{global,city,country,corridor}` | no |
| `payments.unattributed_lookback_hours` | Migration default (see blueprint doc 02 §2.3). | `24` | `{global,city,country,corridor}` | no |
| `placements.enabled` | Master switch for contextual sponsored placements (P8-B-01 UI reads this; FM39 boundary unchanged) | `false` | `{global,city}` | no |
| `places.photon_timeout_ms` | Migration default (see blueprint doc 02 §2.3). | `800` | `{global,city,country,corridor}` | no |
| `places.search_radius_m` | Migration default (see blueprint doc 02 §2.3). | `5000` | `{global,city,country,corridor}` | no |
| `places.trigram_min_similarity` | Migration default (see blueprint doc 02 §2.3). | `0.2` | `{global,city,country,corridor}` | no |
| `planner.baseline_speed_mps` | Migration default (see blueprint doc 02 §2.3). | `8.33` | `{global,city,country,corridor}` | no |
| `planner.default_wait_s` | Migration default (see blueprint doc 02 §2.3). | `300` | `{global,city,country,corridor}` | no |
| `planner.dest_radius_m` | Migration default (see blueprint doc 02 §2.3). | `600` | `{global,city,country,corridor}` | no |
| `planner.direct_viability_factor` | Migration default (see blueprint doc 02 §2.3). | `1.5` | `{global,city,country,corridor}` | no |
| `planner.direct_viability_slack_s` | Migration default (see blueprint doc 02 §2.3). | `300` | `{global,city,country,corridor}` | no |
| `planner.heading_tolerance_deg` | Migration default (see blueprint doc 02 §2.3). | `45` | `{global,city,country,corridor}` | no |
| `planner.max_candidates` | Migration default (see blueprint doc 02 §2.3). | `12` | `{global,city,country,corridor}` | no |
| `planner.max_legs` | Max planner legs | `3` | `{global}` | no |
| `planner.query_log_retention_days` | planner_queries retention window (days); lower during load-test windows to curb bloat | `7` | `{global,city}` | no |
| `planner.recommended_weights` | Migration default (see blueprint doc 02 §2.3). | `{"fare": 0.4, "time": 0.4, "strenuous": 0.2}` | `{global,city,country,corridor}` | no |
| `planner.shared_vehicle_factor` | Migration default (see blueprint doc 02 §2.3). | `1.25` | `{global,city,country,corridor}` | no |
| `planner.speed_profile_min_samples` | Migration default (see blueprint doc 02 §2.3). | `8` | `{global,city,country,corridor}` | no |
| `planner.strenuous_weights` | Migration default (see blueprint doc 02 §2.3). | `{"mode": 0.5, "transfer": 1.0, "walk_per_100m": 0.25}` | `{global,city,country,corridor}` | no |
| `planner.walk_radius_m` | Migration default (see blueprint doc 02 §2.3). | `800` | `{global,city,country,corridor}` | no |
| `planner.walk_speed_mps` | Migration default (see blueprint doc 02 §2.3). | `1.25` | `{global,city,country,corridor}` | no |
| `presence.ambient_cell_precision` | Migration default (see blueprint doc 02 §2.3). | `6` | `{global,city,country,corridor}` | no |
| `presence.at_park_radius_m` | Migration default (see blueprint doc 02 §2.3). | `150` | `{global,city,country,corridor}` | no |
| `presence.downsample_interval_s` | Migration default (see blueprint doc 02 §2.3). | `60` | `{global,city,country,corridor}` | no |
| `presence.fanout_interval_s` | Migration default (see blueprint doc 02 §2.3). | `10` | `{global,city,country,corridor}` | no |
| `presence.fanout_radius_m` | Migration default (see blueprint doc 02 §2.3). | `3000` | `{global,city,country,corridor}` | no |
| `presence.history_downsampled_days` | Migration default (see blueprint doc 02 §2.3). | `30` | `{global,city,country,corridor}` | no |
| `presence.history_full_res_hours` | Migration default (see blueprint doc 02 §2.3). | `24` | `{global,city,country,corridor}` | no |
| `presence.offline_after_s` | Migration default (see blueprint doc 02 §2.3). | `180` | `{global,city,country,corridor}` | no |
| `presence.ping_interval_moving_s` | Migration default (see blueprint doc 02 §2.3). | `4` | `{global,city,country,corridor}` | no |
| `presence.ping_interval_still_s` | Migration default (see blueprint doc 02 §2.3). | `15` | `{global,city,country,corridor}` | no |
| `presence.ping_min_interval_s` | Migration default (see blueprint doc 02 §2.3). | `2` | `{global,city,country,corridor}` | no |
| `presence.stale_after_s` | Migration default (see blueprint doc 02 §2.3). | `45` | `{global,city,country,corridor}` | no |
| `presence.stale_job_interval_s` | Migration default (see blueprint doc 02 §2.3). | `15` | `{global,city,country,corridor}` | no |
| `promotion.collusion_downweight` | Migration default (see blueprint doc 02 §2.3). | `0.25` | `{global,city,country,corridor}` | no |
| `promotion.decay_step` | Migration default (see blueprint doc 02 §2.3). | `0.15` | `{global,city,country,corridor}` | no |
| `promotion.decay_window_days` | Migration default (see blueprint doc 02 §2.3). | `90` | `{global,city,country,corridor}` | no |
| `promotion.fare_tolerance_pct` | Migration default (see blueprint doc 02 §2.3). | `0.15` | `{global,city,country,corridor}` | no |
| `promotion.location_tolerance_m` | Migration default (see blueprint doc 02 §2.3). | `50` | `{global,city,country,corridor}` | no |
| `promotion.min_distinct_accounts` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `promotion.outlier_mad_k` | Migration default (see blueprint doc 02 §2.3). | `3.0` | `{global,city,country,corridor}` | no |
| `promotion.threshold_weight` | Migration default (see blueprint doc 02 §2.3). | `3.0` | `{global,city,country,corridor}` | no |
| `public.origin` | Migration default (see blueprint doc 02 §2.3). | `""` | `{global,city,country,corridor}` | no |
| `rating.tags` | Migration default (see blueprint doc 02 §2.3). | `["safe_driving", "fair_fare", "clean_vehicle", "polite", "on_time", "overcharged", "unsafe", "rude"]` | `{global,city,country,corridor}` | no |
| `realtime.ambient_stale_grace_s` | Migration default (see blueprint doc 02 §2.3). | `60` | `{global,city,country,corridor}` | no |
| `realtime.heartbeat_stale_s` | Migration default (see blueprint doc 02 §2.3). | `15` | `{global,city,country,corridor}` | no |
| `realtime.live_paused_after_s` | Migration default (see blueprint doc 02 §2.3). | `30` | `{global,city,country,corridor}` | no |
| `realtime.max_payload_bytes` | Migration default (see blueprint doc 02 §2.3). | `512` | `{global,city,country,corridor}` | no |
| `realtime.trip_subscriber_target` | TS-OPS-03 full-city concurrent trip:* subscriber target (k6 threshold reference) | `5000` | `{global,city}` | no |
| `reconciliation.dest_radius_m` | Migration default (see blueprint doc 02 §2.3). | `200` | `{global,city,country,corridor}` | no |
| `reconciliation.extension_gap_m` | Migration default (see blueprint doc 02 §2.3). | `400` | `{global,city,country,corridor}` | no |
| `reconciliation.min_route_fraction` | Migration default (see blueprint doc 02 §2.3). | `0.7` | `{global,city,country,corridor}` | no |
| `rider.no_show_review_count` | Migration default (see blueprint doc 02 §2.3). | `3` | `{global,city,country,corridor}` | no |
| `rider.no_show_window_days` | Migration default (see blueprint doc 02 §2.3). | `14` | `{global,city,country,corridor}` | no |
| `settlement.agent_code_ttl_min` | Migration default (see blueprint doc 02 §2.3). | `15` | `{global,city,country,corridor}` | no |
| `settlement.initiate_ttl_min` | Migration default (see blueprint doc 02 §2.3). | `30` | `{global,city,country,corridor}` | no |
| `share.link_ttl_hours` | Migration default (see blueprint doc 02 §2.3). | `12` | `{global,city,country,corridor}` | no |
| `sms.provider` | Migration default (see blueprint doc 02 §2.3). | `"log"` | `{global,city,country,corridor}` | no |
| `sms.providers` | Migration default (see blueprint doc 02 §2.3). | `["termii", "twilio"]` | `{global,city,country,corridor}` | no |
| `sos.ack_sla_s` | SOS acknowledge SLA (seconds) | `60` | `{global,city}` | no |
| `sos.escalate_sla_s` | SOS escalate SLA (seconds) | `180` | `{global,city}` | no |
| `sos.hold_duration_ms` | Migration default (see blueprint doc 02 §2.3). | `600` | `{global,city,country,corridor}` | no |
| `trust.driver_unverified` | Migration default (see blueprint doc 02 §2.3). | `0.0` | `{global,city,country,corridor}` | no |
| `trust.driver_verified` | Migration default (see blueprint doc 02 §2.3). | `1.0` | `{global,city,country,corridor}` | no |
| `trust.rider_base` | Migration default (see blueprint doc 02 §2.3). | `0.2` | `{global,city,country,corridor}` | no |
| `trust.rider_cap` | Migration default (see blueprint doc 02 §2.3). | `1.0` | `{global,city,country,corridor}` | no |
| `trust.rider_min_age_days` | Migration default (see blueprint doc 02 §2.3). | `7` | `{global,city,country,corridor}` | no |
| `trust.rider_per_trip` | Migration default (see blueprint doc 02 §2.3). | `0.05` | `{global,city,country,corridor}` | no |
| `verification.provider.verifyme.base_url` | Optional VerifyMe API base URL; null keeps stub mode regardless of environment | `null` | `{global}` | no |
| `verification.provider.verifyme.stub_mode` | When true, verification-ocr uses the in-process VerifyMe stub adapter (never calls live API) | `true` | `{global}` | no |
| `wait.release_pickup_radius_m` | Migration default (see blueprint doc 02 §2.3). | `80` | `{global,city,country,corridor}` | no |
| `wait.stalled_progress_m` | Migration default (see blueprint doc 02 §2.3). | `25` | `{global,city,country,corridor}` | no |
| `wait.stalled_window_s` | Migration default (see blueprint doc 02 §2.3). | `90` | `{global,city,country,corridor}` | no |

## Scoped seed overrides (non-global)
These come from `backend/db/seed_core.sql` for pilot/Test City fixtures — not global defaults:

| Key | Scope | Value | Notes |
|---|---|---|---|
| `sos.emergency_number` | country `NG` | `"112"` | Emergency services number for Nigeria |
| `payments.provider` | country `GH` | `"paystack"` | Payment provider for Ghana (Phase 4+) |
| `commission.rate` | city (Test City seed) | `0.05` | Pilot corridor override |
| `graph.snap_radius_m` | city (Test City seed) | `40` | Tighter snap for dense pilot |

## Related
- Blueprint doc 02 §2.3 — authoritative key list and semantics
- `backend/db/tests/app_config_keys.sql` — pgTAP presence check (TS-CFG-*)
- ADR-0016 (`app_config` defaults owned by migrations)
- Admin console A-09 — runtime config editor

## Mobile: support route (driver app)

| Dart define | Purpose |
|---|---|
| `SUPPORT_URL` | Free support link opened by **Get help** on the driver's locked-PIN screen: `https://wa.me/<number>`, `tel:<number>`, `mailto:<address>` or `sms:<number>`. Empty (the default in `env/*.json`) hides the action; other schemes are ignored. |
