-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.route_requests
-- RLS enabled: true
-- RLS forced: false

create policy route_requests_owner
  on route_requests for select to authenticated
  using ((rider_id = auth.uid()) OR is_admin());
