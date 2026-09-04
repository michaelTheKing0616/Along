-- P0-A-01: doc 02 §17 — core seed (deployments, countries, mode_config, app_config).

-- Along NG deployment
insert into deployments (id, tenant_name, branding_config, region_config, active)
values (
  'a0000000-0000-4000-8000-000000000001',
  'Along NG',
  '{}'::jsonb,
  '{}'::jsonb,
  true
);

insert into countries (
  code, name, currency_code, currency_minor_units, currency_symbol, phone_prefix,
  default_locale, timezone, deployment_id, verification_schema, regulatory_flags, active
) values (
  'NG',
  'Nigeria',
  'NGN',
  2,
  E'₦',
  '+234',
  'en-NG',
  'Africa/Lagos',
  'a0000000-0000-4000-8000-000000000001',
  '[
    {"type":"nin","label":"NIN","pattern":"^\\d{11}$","provider":"verifyme"},
    {"type":"drivers_license","label":"Driver''s License","pattern":"^.{5,}$","provider":"verifyme"},
    {"type":"vehicle_particulars","label":"Vehicle Particulars","pattern":"^.{5,}$","provider":"verifyme"}
  ]'::jsonb,
  '{"women_only_matching": true}'::jsonb,
  true
);

-- mode_config (doc 02 §2.2)
insert into mode_config (code, label, icon_key, color_token, comfort_weight, load_capacity, default_seat_capacity, sort_order) values
  ('car',     'Along taxi', 'mode.car',     'mode.car',     4.0, 'large',  4, 10),
  ('keke',    'Keke',       'mode.keke',    'mode.keke',    6.0, 'small',  3, 20),
  ('okada',   'Okada',      'mode.okada',   'mode.okada',   8.0, 'none',   1, 30),
  ('minibus', 'Minibus',    'mode.minibus', 'mode.minibus', 5.0, 'medium', 14, 40);

-- app_config — all keys from doc 02 §2.3 at global scope (sos.emergency_number at country scope)
insert into app_config (key, scope_type, scope_id, value) values
  ('commission.rate', 'global', '*', '0.075'),
  ('commission.applies_to_load_surcharge', 'global', '*', 'true'),
  ('ledger.block_threshold', 'global', '*', '-5000'),
  ('ledger.warn_threshold', 'global', '*', '-3000'),
  ('ledger.grace_period_hours', 'global', '*', '48'),
  ('ledger.deactivate_threshold', 'global', '*', '-15000'),
  ('ledger.onboarding_deposit', 'global', '*', '0'),
  ('dispatch.request_ttl_s', 'global', '*', '25'),
  ('dispatch.max_cascade', 'global', '*', '3'),
  ('planner.max_legs', 'global', '*', '3'),
  ('planner.max_candidates', 'global', '*', '12'),
  ('planner.walk_radius_m', 'global', '*', '800'),
  ('planner.dest_radius_m', 'global', '*', '600'),
  ('planner.direct_viability_factor', 'global', '*', '1.5'),
  ('planner.direct_viability_slack_s', 'global', '*', '300'),
  ('planner.recommended_weights', 'global', '*', '{"fare":0.4,"time":0.4,"strenuous":0.2}'),
  ('planner.strenuous_weights', 'global', '*', '{"transfer":1.0,"walk_per_100m":0.25,"mode":0.5}'),
  ('planner.heading_tolerance_deg', 'global', '*', '45'),
  ('planner.walk_speed_mps', 'global', '*', '1.25'),
  ('graph.snap_radius_m', 'global', '*', '60'),
  ('graph.stage_merge_radius_m', 'global', '*', '40'),
  ('promotion.threshold_weight', 'global', '*', '3.0'),
  ('promotion.min_distinct_accounts', 'global', '*', '3'),
  ('promotion.fare_tolerance_pct', 'global', '*', '0.15'),
  ('promotion.location_tolerance_m', 'global', '*', '50'),
  ('promotion.outlier_mad_k', 'global', '*', '3.0'),
  ('promotion.decay_window_days', 'global', '*', '90'),
  ('promotion.decay_step', 'global', '*', '0.15'),
  ('promotion.collusion_downweight', 'global', '*', '0.25'),
  ('trust.rider_base', 'global', '*', '0.2'),
  ('trust.rider_per_trip', 'global', '*', '0.05'),
  ('trust.rider_cap', 'global', '*', '1.0'),
  ('trust.rider_min_age_days', 'global', '*', '7'),
  ('trust.driver_verified', 'global', '*', '1.0'),
  ('trust.driver_unverified', 'global', '*', '0.0'),
  ('presence.ping_interval_moving_s', 'global', '*', '4'),
  ('presence.ping_interval_still_s', 'global', '*', '15'),
  ('presence.ping_min_interval_s', 'global', '*', '2'),
  ('presence.stale_after_s', 'global', '*', '45'),
  ('presence.offline_after_s', 'global', '*', '180'),
  ('presence.at_park_radius_m', 'global', '*', '150'),
  ('presence.history_full_res_hours', 'global', '*', '24'),
  ('presence.history_downsampled_days', 'global', '*', '30'),
  ('presence.downsample_interval_s', 'global', '*', '60'),
  ('presence.ambient_cell_precision', 'global', '*', '6'),
  ('boarding.colocation_radius_m', 'global', '*', '25'),
  ('boarding.colocation_duration_s', 'global', '*', '20'),
  ('boarding.min_speed_mps', 'global', '*', '1.5'),
  ('negotiation.park.round_cap', 'global', '*', '4'),
  ('negotiation.park.round_timeout_s', 'global', '*', '20'),
  ('negotiation.roaming.eta_none_s', 'global', '*', '20'),
  ('negotiation.roaming.eta_single_s', 'global', '*', '60'),
  ('negotiation.roaming.round_timeout_s', 'global', '*', '12'),
  ('negotiation.roaming.round_cap', 'global', '*', '3'),
  ('negotiation.roaming.pickup_radius_m', 'global', '*', '150'),
  ('negotiation.chip_steps', 'global', '*', '[-100,-50,50,100]'),
  ('reconciliation.dest_radius_m', 'global', '*', '200'),
  ('reconciliation.min_route_fraction', 'global', '*', '0.7'),
  ('reconciliation.extension_gap_m', 'global', '*', '400'),
  ('clustering.eps_m', 'global', '*', '35'),
  ('clustering.min_points', 'global', '*', '12'),
  ('clustering.min_distinct_drivers', 'global', '*', '4'),
  ('clustering.min_distinct_days', 'global', '*', '3'),
  ('clustering.window_days', 'global', '*', '14'),
  ('name.colors', 'global', '*', '["color.naMe.green","color.naMe.blue","color.naMe.red","color.naMe.orange","color.naMe.purple","color.naMe.yellow","color.naMe.pink","color.naMe.cyan"]'),
  ('name.shapes', 'global', '*', '["circle","square","triangle","diamond","star","hexagon"]'),
  ('share.link_ttl_hours', 'global', '*', '12'),
  ('otp.rate_limit_per_hour', 'global', '*', '5'),
  ('sms.providers', 'global', '*', '["termii","twilio"]'),
  ('load.warn_capacities', 'global', '*', '{"small":["none"],"medium":["none","small"],"large":["none","small","medium"]}'),
  ('fare.default_rate_per_km', 'global', '*', '{"car":120,"keke":90,"okada":110,"minibus":60}'),
  ('fare.min_fare', 'global', '*', '{"car":200,"keke":100,"okada":100,"minibus":100}'),
  ('planner.default_wait_s', 'global', '*', '300'),
  ('planner.shared_vehicle_factor', 'global', '*', '1.25'),
  ('dispatch.no_show_after_s', 'global', '*', '300'),
  ('decline.reasons', 'global', '*', '["too_far","wrong_direction","vehicle_full","no_room_for_load","other"]'),
  ('ledger.dual_control_threshold', 'global', '*', '20000'),
  ('ledger.deactivate_after_days', 'global', '*', '14'),
  ('export.k', 'global', '*', '10'),
  ('geometry.min_supporting_traces', 'global', '*', '15'),
  ('inference.min_trips', 'global', '*', '20'),
  ('field.location_tol_m', 'global', '*', '50'),
  ('field.fare_tol_pct', 'global', '*', '0.15'),
  ('payments.digital_enabled', 'global', '*', 'false'),
  ('payments.min_digital_amount', 'global', '*', '100'),
  ('payments.fee_bearer', 'global', '*', '"account"'),
  ('payments.qr_resolve_rate_per_min', 'global', '*', '30'),
  ('payments.unattributed_lookback_hours', 'global', '*', '24'),
  ('payments.dynamic_qr_ttl_s', 'global', '*', '600'),
  ('rating.tags', 'global', '*', '["safe_driving","fair_fare","clean_vehicle","polite","on_time","overcharged","unsafe","rude"]');

-- country-scoped key (doc 02 §2.3)
insert into app_config (key, scope_type, scope_id, value) values
  ('sos.emergency_number', 'country', 'NG', '"112"');
