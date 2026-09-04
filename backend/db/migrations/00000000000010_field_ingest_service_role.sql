-- P0-E-03: service-role grants for field ingestion pipeline (doc 13 §3, orchestrator decision).

grant select, insert on field_submissions to service_role;
grant select, update on field_reconciliations to service_role;
grant select on field_agents to service_role;
grant select on cities to service_role;
grant select on corridors to service_role;
grant select on mode_config to service_role;
grant select on parks to service_role;

grant execute on function reconcile_field_submission(uuid) to service_role;
