-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.emergency_contacts
-- RLS enabled: true
-- RLS forced: false

create policy emergency_contacts_owner
  on emergency_contacts for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
