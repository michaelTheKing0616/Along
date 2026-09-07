-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.countries
-- RLS enabled: true
-- RLS forced: false

create policy countries_select_anon_active
  on countries for select to anon
  using (active);

create policy countries_select_authenticated
  on countries for select to authenticated
  using (true);

create policy countries_write_admin
  on countries for all to authenticated
  using (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]))
  with check (has_admin_role(ARRAY['superadmin'::text, 'ops_lead'::text]));
