-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.journey_transfer_walks
-- RLS enabled: true
-- RLS forced: false

create policy journey_transfer_walks_no_client_write
  on journey_transfer_walks for all to authenticated
  using (false)
  with check (false);

create policy journey_transfer_walks_select_admin
  on journey_transfer_walks for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM journeys j
  WHERE ((j.id = journey_transfer_walks.journey_id) AND admin_can_access_city(j.city_id)))) AND has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text, 'analyst'::text]));

create policy journey_transfer_walks_select_own
  on journey_transfer_walks for select to authenticated
  using (EXISTS ( SELECT 1
   FROM journeys j
  WHERE ((j.id = journey_transfer_walks.journey_id) AND (j.rider_id = auth.uid()))));
