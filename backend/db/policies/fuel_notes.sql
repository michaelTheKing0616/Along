-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.fuel_notes
-- RLS enabled: true
-- RLS forced: false

create policy fuel_notes_read
  on fuel_notes for select to authenticated
  using (true);
