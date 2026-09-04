-- device_tokens: owner full access.
create policy device_tokens_all_own
  on device_tokens for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
