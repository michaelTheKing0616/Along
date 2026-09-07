-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.sos_alerts
-- RLS enabled: true
-- RLS forced: false

create policy sos_alerts_no_client_write
  on sos_alerts for all to authenticated
  using (false)
  with check (false);

create policy sos_alerts_select_admin
  on sos_alerts for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'safety'::text, 'ops_lead'::text]) AND ((trip_id IS NULL) OR admin_can_access_city(( SELECT j.city_id
   FROM (trips t
     JOIN journeys j ON ((j.id = t.journey_id)))
  WHERE (t.id = sos_alerts.trip_id))) OR ((journey_id IS NOT NULL) AND admin_can_access_city(( SELECT j.city_id
   FROM journeys j
  WHERE (j.id = sos_alerts.journey_id))))));

create policy sos_alerts_select_raiser
  on sos_alerts for select to authenticated
  using (raised_by = auth.uid());
