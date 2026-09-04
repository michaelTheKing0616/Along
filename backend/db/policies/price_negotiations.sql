-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.price_negotiations
-- RLS enabled: true
-- RLS forced: false

create policy price_negotiations_no_client_write
  on price_negotiations for all to authenticated
  using (false)
  with check (false);

create policy price_negotiations_select_admin
  on price_negotiations for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM drivers d
  WHERE (d.id = price_negotiations.driver_id))));

create policy price_negotiations_select_party
  on price_negotiations for select to authenticated
  using ((rider_id = auth.uid()) OR (driver_id = auth.uid()));
