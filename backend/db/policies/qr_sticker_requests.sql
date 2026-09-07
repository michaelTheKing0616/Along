-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.qr_sticker_requests
-- RLS enabled: true
-- RLS forced: false

create policy qr_sticker_requests_no_client_write
  on qr_sticker_requests for all to authenticated
  using (false)
  with check (false);

create policy qr_sticker_requests_select_admin
  on qr_sticker_requests for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = qr_sticker_requests.driver_id))));

create policy qr_sticker_requests_select_own
  on qr_sticker_requests for select to authenticated
  using (driver_id = auth.uid());
