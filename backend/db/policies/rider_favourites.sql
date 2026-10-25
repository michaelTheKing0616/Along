-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.rider_favourites
-- RLS enabled: true
-- RLS forced: false

create policy rider_favourites_owner
  on rider_favourites for select to authenticated
  using ((rider_id = auth.uid()) OR is_admin());
