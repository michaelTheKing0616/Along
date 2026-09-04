-- Presence scenario seed (doc 10 §2).
-- BLOCKED: driver_presence table not migrated until Phase 1 (P1-A-*).
-- Scenario intent: parked at A (2), roaming toward dest (1), roaming away (1), stale (1).
-- Apply this file once driver_presence migration exists; until then presence TS-* use inline fixtures.

select 1 where false; -- no-op placeholder keeps apply script idempotent
