-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.graph_revisions
-- RLS enabled: true
-- RLS forced: false

create policy graph_revisions_select_admin
  on graph_revisions for select to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text, 'ops_agent'::text, 'analyst'::text]));
