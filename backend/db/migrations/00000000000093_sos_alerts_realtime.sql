-- The admin safety board (A-12) subscribes to postgres_changes on sos_alerts and
-- reloads on any change, but the table was never added to the realtime
-- publication, so new SOS alerts only appeared after a manual refresh.
-- RLS still applies to realtime: only admins who can select a row receive it.
do $$
begin
  execute 'alter publication supabase_realtime add table public.sos_alerts';
exception
  when undefined_object or duplicate_object then
    null;
end $$;
