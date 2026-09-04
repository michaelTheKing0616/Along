-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.price_negotiation_rounds
-- RLS enabled: true
-- RLS forced: false

create policy price_negotiation_rounds_no_client_write
  on price_negotiation_rounds for all to authenticated
  using (false)
  with check (false);

create policy price_negotiation_rounds_select_admin
  on price_negotiation_rounds for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text, 'ops_agent'::text, 'finance'::text]) AND admin_can_access_city(( SELECT d.city_id
   FROM (price_negotiations n
     JOIN drivers d ON ((d.id = n.driver_id)))
  WHERE (n.id = price_negotiation_rounds.negotiation_id))));

create policy price_negotiation_rounds_select_party
  on price_negotiation_rounds for select to authenticated
  using (EXISTS ( SELECT 1
   FROM price_negotiations n
  WHERE ((n.id = price_negotiation_rounds.negotiation_id) AND ((n.rider_id = auth.uid()) OR (n.driver_id = auth.uid())))));
