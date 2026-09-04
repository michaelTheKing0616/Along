-- pgTAP: every required app_config key from doc 02 §2.3 is present in seed
create extension if not exists pgtap;

begin;
select plan(4);

-- Assumes seed_core.sql was applied by supabase db reset before pg_prove runs.
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
    'presence.ambient_cell_precision',
    'boarding.colocation_radius_m',
    'boarding.colocation_duration_s',
    'boarding.min_speed_mps',
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
    'name.colors',
    'name.shapes',
    'share.link_ttl_hours',
    'otp.rate_limit_per_hour',
    'sms.providers',
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
  left join app_config ac
    on ac.key = rg.key and ac.scope_type = 'global' and ac.scope_id = '*'
  where ac.key is null
)
select is(
  (select count(*) from missing_global),
  0::bigint,
  'all doc 02 §2.3 global app_config keys are present at global scope'
);

select ok(
  exists (
    select 1 from app_config
    where key = 'sos.emergency_number'
      and scope_type = 'country'
      and scope_id = 'NG'
  ),
  'sos.emergency_number is present at country scope for NG'
);

select ok(
  (select count(*) from mode_config where code in ('car', 'keke', 'okada', 'minibus')) = 4,
  'mode_config seeded with four modes'
);

select ok(
  to_regclass('public.admin_users') is not null,
  'admin_users table exists for §1 helper functions'
);

select * from finish();
rollback;
