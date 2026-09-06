-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.guarantors
-- RLS enabled: true
-- RLS forced: false

create policy guarantors_insert_own
  on guarantors for insert to authenticated
  with check (driver_id = auth.uid());

create policy guarantors_no_client_update_delete
  on guarantors for update to authenticated
  using (false)
  with check (false);

create policy guarantors_select_admin
  on guarantors for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = guarantors.driver_id))));

create policy guarantors_select_own
  on guarantors for select to authenticated
  using (driver_id = auth.uid());
