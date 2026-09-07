-- P7-E-02: load-test DB tuning — hot-path indexes for full-city concurrency (doc 01 §7, doc 10 TS-OPS-02/03).
-- No production secrets; config defaults only. Staging/prod scale overrides via app_config city scope.

-- Realtime trip-party authz: active trips by status (city lives on journeys, not trips).
create index if not exists trips_active_status
  on trips (status, driver_id)
  where status in ('accepted', 'boarded', 'in_transit');

-- Rider lookup on trip topics at subscriber connect time.
create index if not exists trips_rider_active
  on trips (rider_id)
  where status in ('accepted', 'boarded', 'in_transit', 'requested');

-- Presence fan-out: online drivers ordered by recency (city resolved via drivers join at query time).
create index if not exists driver_presence_status_ping
  on driver_presence (status, last_ping_at desc)
  where status <> 'offline';

-- Planner query log — bounded retention hint for load-test ops (global default 7 days).
select config_default('planner.query_log_retention_days', '7');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'planner.query_log_retention_days',
    '{"type":"number","minimum":1,"maximum":90}',
    'planner_queries retention window (days); lower during load-test windows to curb bloat',
    array['global','city']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- Documented Realtime scale target for ops dashboards (not enforced in SQL).
select config_default('realtime.trip_subscriber_target', '5000');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'realtime.trip_subscriber_target',
    '{"type":"number","minimum":100,"maximum":50000}',
    'TS-OPS-03 full-city concurrent trip:* subscriber target (k6 threshold reference)',
    array['global','city']::config_scope[],
    false
  )
on conflict (key) do nothing;

-- Supabase Realtime scale (documented — apply in project dashboard for staging/prod, not secrets):
--   max concurrent connections ≥ 6000 (5000 trip subs + headroom)
--   max messages per second ≥ 2000 (trip loc pump + ambient fan-out)
--   pooler: Supavisor transaction mode for Edge (doc 01 §7)
