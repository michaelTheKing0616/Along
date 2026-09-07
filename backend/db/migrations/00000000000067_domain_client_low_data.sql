-- P7-B-01: rider low-data mode client thresholds (doc 07 §4, doc 02 §2.3)

select config_default('client.low_data_tile_max_zoom', '15');
select config_default('client.ambient_poll_interval_s', '30');

insert into app_config_keys (key, value_schema, description, allowed_scopes, read_only) values
  (
    'client.low_data_tile_max_zoom',
    '{"type":"number","minimum":10,"maximum":18}',
    'LowDataMode: cap MapLibre tile refresh at this zoom when 2G or OS data saver is on',
    array['global','city']::config_scope[],
    false
  ),
  (
    'client.ambient_poll_interval_s',
    '{"type":"number","minimum":10,"maximum":120}',
    'LowDataMode: ambient RPC poll interval (seconds) when Broadcast is disabled',
    array['global','city']::config_scope[],
    false
  )
on conflict (key) do nothing;
