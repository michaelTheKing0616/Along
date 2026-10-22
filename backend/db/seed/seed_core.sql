-- P0-A-01: doc 02 §17 — core seed (deployments, countries, mode_config; scoped app_config overrides only).

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
-- Layout presets and review caps are owned by migration 0084.
-- ON CONFLICT DO NOTHING so a re-seed cannot wipe driver-facing starting layouts.
insert into mode_config (code, label, icon_key, color_token, comfort_weight, load_capacity, default_seat_capacity, sort_order) values
  ('car',     'Along taxi', 'mode.car',     'mode.car',     4.0, 'large',  4, 10),
  ('keke',    'Keke',       'mode.keke',    'mode.keke',    6.0, 'small',  3, 20),
  ('okada',   'Okada',      'mode.okada',   'mode.okada',   8.0, 'none',   1, 30),
  ('minibus', 'Minibus',    'mode.minibus', 'mode.minibus', 5.0, 'medium', 14, 40)
on conflict (code) do nothing;

-- Scoped override for seeded NG country (doc 02 §17, ADR-0016)
select config_default('sos.emergency_number', '"112"', 'country', 'NG');
