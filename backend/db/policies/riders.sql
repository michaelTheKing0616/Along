-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.riders
-- RLS enabled: true
-- RLS forced: false

create policy riders_insert_own
  on riders for insert to authenticated
  with check (id = auth.uid());

create policy riders_select_admin
  on riders for select to authenticated
  using (is_admin());

create policy riders_select_own
  on riders for select to authenticated
  using (id = auth.uid());

create policy riders_update_own
  on riders for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());
