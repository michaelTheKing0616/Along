-- P8-B-01: allow authenticated clients to record aggregate placement counters (no rider identity in RPC)

revoke all on function record_placement_counter(uuid, text) from public;
grant execute on function record_placement_counter(uuid, text) to authenticated, service_role;
