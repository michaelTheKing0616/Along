-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.payments
-- RLS enabled: true
-- RLS forced: false

create policy payments_no_client_write
  on payments for all to authenticated
  using (false)
  with check (false);

create policy payments_select_admin
  on payments for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = payments.driver_id))));

create policy payments_select_driver
  on payments for select to authenticated
  using (driver_id = auth.uid());

create policy payments_select_rider
  on payments for select to authenticated
  using (rider_id = auth.uid());
