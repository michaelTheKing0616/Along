-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.device_tokens
-- RLS enabled: true
-- RLS forced: false

create policy device_tokens_all_own
  on device_tokens for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
