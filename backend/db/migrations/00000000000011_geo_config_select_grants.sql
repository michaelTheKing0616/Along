-- P0-D-02 / doc 02 §16: SELECT grants for geo & config tables (policies already exist in 0002).
-- Grants only — no new policies.

grant select on deployments to authenticated;
grant select on countries to authenticated;
grant select on cities to authenticated;
grant select on corridors to authenticated;
grant select on mode_config to authenticated;
grant select on app_config to authenticated;
