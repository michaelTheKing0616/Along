-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.notifications
-- RLS enabled: true
-- RLS forced: false

create policy notifications_no_client_write
  on notifications for all to authenticated
  using (false)
  with check (false);

create policy notifications_select_own
  on notifications for select to authenticated
  using (profile_id = auth.uid());
