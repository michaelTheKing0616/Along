-- pgTAP: TS-CFG-02 — migrations alone (no seed): every doc 02 §2.3 key resolves via cfg() (ADR-0016)
-- Run after `supabase db reset --no-seed` (see backend/db/scripts/run_ts_cfg_02.sh).
create extension if not exists pgtap;

begin;
select plan(2);

with required_global as (
  select unnest(array[
    'commission.rate',
    'commission.applies_to_load_surcharge',
    'ledger.block_threshold',
    'ledger.warn_threshold',
    'ledger.grace_period_hours',
    'ledger.deactivate_threshold',
    'ledger.onboarding_deposit',
    'dispatch.request_ttl_s',
    'dispatch.max_cascade',
    'dispatch.candidate_token_ttl_s',
    'planner.max_legs',
    'planner.max_candidates',
    'planner.walk_radius_m',
    'planner.dest_radius_m',
    'planner.direct_viability_factor',
    'planner.direct_viability_slack_s',
    'planner.recommended_weights',
    'planner.strenuous_weights',
    'planner.heading_tolerance_deg',
    'planner.walk_speed_mps',
    'graph.snap_radius_m',
    'graph.stage_merge_radius_m',
    'promotion.threshold_weight',
    'promotion.min_distinct_accounts',
    'promotion.fare_tolerance_pct',
    'promotion.location_tolerance_m',
    'promotion.outlier_mad_k',
    'promotion.collusion_downweight',
    'promotion.decay_window_days',
    'promotion.decay_step',
    'trust.rider_base',
    'trust.rider_per_trip',
    'trust.rider_cap',
    'trust.rider_min_age_days',
    'trust.driver_verified',
    'trust.driver_unverified',
    'presence.ping_interval_moving_s',
    'presence.ping_interval_still_s',
    'presence.stale_after_s',
    'presence.offline_after_s',
    'presence.history_full_res_hours',
    'presence.history_downsampled_days',
    'presence.downsample_interval_s',
    'presence.stale_job_interval_s',
    'presence.ambient_cell_precision',
    'realtime.ambient_stale_grace_s',
    'realtime.max_payload_bytes',
    'realtime.heartbeat_stale_s',
    'realtime.live_paused_after_s',
    'boarding.colocation_radius_m',
    'boarding.colocation_duration_s',
    'boarding.min_speed_mps',
    'boarding.in_transit_min_speed_mps',
    'boarding.in_transit_duration_s',
    'boarding.sample_max_age_s',
    'boarding.sample_max_accuracy_m',
    'negotiation.park.round_cap',
    'negotiation.park.round_timeout_s',
    'negotiation.roaming.eta_none_s',
    'negotiation.roaming.eta_single_s',
    'negotiation.roaming.round_timeout_s',
    'negotiation.roaming.round_cap',
    'negotiation.roaming.pickup_radius_m',
    'negotiation.chip_steps',
    'reconciliation.dest_radius_m',
    'reconciliation.min_route_fraction',
    'reconciliation.extension_gap_m',
    'clustering.eps_m',
    'clustering.min_points',
    'clustering.min_distinct_drivers',
    'clustering.min_distinct_days',
    'clustering.window_days',
    'client.trip_poll_interval_s',
    'driver.negotiation_poll_s',
    'name.colors',
    'name.shapes',
    'share.link_ttl_hours',
    'otp.rate_limit_per_hour',
    'sms.providers',
    'sms.provider',
    'public.origin',
    'load.warn_capacities',
    'fare.default_rate_per_km',
    'fare.min_fare',
    'planner.default_wait_s',
    'planner.shared_vehicle_factor',
    'dispatch.no_show_after_s',
    'decline.reasons',
    'ledger.dual_control_threshold',
    'ledger.deactivate_after_days',
    'export.k',
    'geometry.min_supporting_traces',
    'inference.min_trips',
    'field.location_tol_m',
    'field.fare_tol_pct',
    'payments.digital_enabled',
    'payments.min_digital_amount',
    'payments.fee_bearer',
    'payments.qr_resolve_rate_per_min',
    'payments.unattributed_lookback_hours',
    'payments.dynamic_qr_ttl_s',
    'rating.tags'
  ]) as key
),
missing_global as (
  select rg.key
  from required_global rg
  where cfg(rg.key) is null
)
select is(
  (select count(*) from missing_global),
  0::bigint,
  'TS-CFG-02: all doc 02 §2.3 global keys resolve via cfg() after migrations only (no seed)'
);

-- Country-scoped key: minimal geo fixture (not seed_core) to exercise cfg() resolution
insert into deployments (id, tenant_name) values
  ('c0000000-0000-4000-8000-000000000099', 'TS-CFG-02 Tenant');

insert into countries (code, name, currency_code, currency_symbol, phone_prefix, timezone, deployment_id, active)
values ('NG', 'Nigeria', 'NGN', E'₦', '+234', 'Africa/Lagos', 'c0000000-0000-4000-8000-000000000099', true)
on conflict (code) do nothing;

insert into cities (id, country_code, name, slug, centroid, status)
values (
  'c0000000-0000-4000-8000-000000000001',
  'NG',
  'TS-CFG-02 City',
  'ts-cfg-02-city',
  st_setsrid(st_makepoint(7.4, 9.0), 4326)::geography,
  'live'
);

select ok(
  cfg('sos.emergency_number', 'c0000000-0000-4000-8000-000000000001'::uuid) is not null,
  'TS-CFG-02: sos.emergency_number resolves at country scope via cfg() after migrations only'
);

select * from finish();
rollback;
