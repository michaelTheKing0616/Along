-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.ratings
-- RLS enabled: true
-- RLS forced: false

create policy ratings_no_client_write
  on ratings for all to authenticated
  using (false)
  with check (false);

create policy ratings_select_admin
  on ratings for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text, 'safety'::text]));

create policy ratings_select_party
  on ratings for select to authenticated
  using (EXISTS ( SELECT 1
   FROM trips t
  WHERE ((t.id = ratings.trip_id) AND ((t.rider_id = auth.uid()) OR (t.driver_id = auth.uid())))));
