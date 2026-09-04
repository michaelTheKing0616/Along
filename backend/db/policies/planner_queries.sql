-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.planner_queries
-- RLS enabled: true
-- RLS forced: false

create policy planner_queries_no_client_write
  on planner_queries for all to authenticated
  using (false)
  with check (false);

create policy planner_queries_select_admin
  on planner_queries for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'analyst'::text]));
