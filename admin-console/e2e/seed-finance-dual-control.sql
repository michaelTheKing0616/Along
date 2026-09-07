-- E2E finance dual-control seed (P4-D-01 / A-13)

insert into cities (id, country_code, name, slug, state_region, centroid, status)
values (
  'b1000000-0000-4000-8000-000000000001',
  'NG',
  'Abuja',
  'abuja',
  'FCT',
  st_setsrid(st_makepoint(7.495, 9.057), 4326)::geography,
  'live'
) on conflict (id) do nothing;

insert into auth.users (id, aud, role, phone) values
  ('b0000000-0000-4000-8000-000000000106', 'authenticated', 'authenticated', '+2348000000106'),
  ('d1000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', '+2348000000299')
on conflict (id) do nothing;

insert into profiles (id, phone_e164, display_name) values
  ('b0000000-0000-4000-8000-000000000106', '+2348000000106', 'Finance Two'),
  ('d1000000-0000-4000-8000-000000000001', '+2348000000299', 'E2E Finance Driver')
on conflict (id) do update set display_name = excluded.display_name;

insert into admin_users (id, role, deployment_id) values
  ('b0000000-0000-4000-8000-000000000106', 'finance', 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do update set role = excluded.role, disabled_at = null;

insert into drivers (id, city_id, verified_status, standing, driver_code, payout_subaccount_code) values
  (
    'd1000000-0000-4000-8000-000000000001',
    'b1000000-0000-4000-8000-000000000001',
    'verified',
    'good_standing',
    'E2EFIN1',
    'ACCT_e2e_finance_driver'
  )
on conflict (id) do update set
  city_id = excluded.city_id,
  driver_code = excluded.driver_code,
  payout_subaccount_code = excluded.payout_subaccount_code;

delete from pending_ledger_adjustments
where driver_id = 'd1000000-0000-4000-8000-000000000001';

delete from driver_ledger_entries
where driver_id = 'd1000000-0000-4000-8000-000000000001';
