-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.conductor_sessions
-- RLS enabled: true
-- RLS forced: false

create policy conductor_sessions_read
  on conductor_sessions for select to authenticated
  using ((created_by = auth.uid()) OR is_admin() OR (EXISTS ( SELECT 1
   FROM driver_day_plans p
  WHERE ((p.id = conductor_sessions.day_plan_id) AND (p.driver_id = auth.uid())))));
