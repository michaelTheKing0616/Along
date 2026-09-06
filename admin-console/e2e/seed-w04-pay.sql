-- E2E W-04 anonymous pay + A-13 sticker PDF (P4-D-02 / TS-UI-06)
-- Requires: seed_core, seed_abuja, seed-e2e-admins

insert into auth.users (id, aud, role, phone) values
  ('d2000000-0000-4000-8000-000000000201', 'authenticated', 'authenticated', '+2348000000499')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('d2000000-0000-4000-8000-000000000201', '+2348000000499', 'Musa')
on conflict (id) do update set display_name = excluded.display_name;

insert into drivers (
  id, city_id, verified_status, standing, driver_code,
  payout_subaccount_code, accepts_digital
) values (
  'd2000000-0000-4000-8000-000000000201',
  'b1000000-0000-4000-8000-000000000001',
  'verified',
  'good_standing',
  'W04TEST1',
  'ACCT_w04_e2e_subaccount',
  true
) on conflict (id) do update set
  driver_code = excluded.driver_code,
  payout_subaccount_code = excluded.payout_subaccount_code,
  accepts_digital = excluded.accepts_digital,
  verified_status = excluded.verified_status;

insert into vehicles (
  id, country_code, mode_code, plate_number, color, make_model, seat_capacity
) values (
  'd2100000-0000-4000-8000-000000000201',
  'NG',
  'car',
  'W04-PLATE',
  'yellow',
  'Toyota Avanza',
  4
) on conflict (id) do update set plate_number = excluded.plate_number;

insert into driver_vehicles (driver_id, vehicle_id, active) values
  ('d2000000-0000-4000-8000-000000000201', 'd2100000-0000-4000-8000-000000000201', true)
on conflict do nothing;

-- Enable digital payments for Abuja in E2E only (global default stays false)
insert into app_config (key, scope_type, scope_id, value)
values ('payments.digital_enabled', 'city', 'b1000000-0000-4000-8000-000000000001', 'true')
on conflict (key, scope_type, scope_id) do update set value = excluded.value;

-- Sample succeeded unattributed web payment for A-13 lists
delete from payments
where driver_id = 'd2000000-0000-4000-8000-000000000201'
  and provider_reference like 'e2e_w04_%';

insert into payments (
  id, driver_id, trip_id, rider_id, source, channel,
  amount, currency, commission_amount, driver_amount, fee_bearer,
  provider_reference, method, status, confirmed_at
) values (
  'f2000000-0000-4000-8000-000000000201',
  'd2000000-0000-4000-8000-000000000201',
  null,
  null,
  'web_anonymous',
  'web',
  500.00,
  'NGN',
  37.50,
  462.50,
  'account',
  'e2e_w04_sample_payment',
  'card',
  'succeeded',
  now()
);
