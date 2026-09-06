-- GENERATED — do not edit. Regenerate: bash backend/db/scripts/dump_policies.sh
-- Table: public.trip_dispatch_context
-- RLS enabled: true
-- RLS forced: false

create policy trip_dispatch_context_no_client_access
  on trip_dispatch_context for all to authenticated
  using (false)
  with check (false);

create policy trip_dispatch_context_service_all
  on trip_dispatch_context for all to service_role
  using (true)
  with check (true);
