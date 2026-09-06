-- P3-C-01: driver manifest poll + trip location sample batch interval (doc 07 §6, doc 01 §7)
select config_default('driver.manifest_poll_s', '3');
select config_default('client.trip_location_sample_interval_s', '5');
