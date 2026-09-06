-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.driver_payouts
-- RLS enabled: true
-- RLS forced: false

create policy driver_payouts_no_client_write
  on driver_payouts for all to authenticated
  using (false)
  with check (false);

create policy driver_payouts_select_admin
  on driver_payouts for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = driver_payouts.driver_id))));

create policy driver_payouts_select_own
  on driver_payouts for select to authenticated
  using (driver_id = auth.uid());
