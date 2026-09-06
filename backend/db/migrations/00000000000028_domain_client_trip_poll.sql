-- P2-B-01: client trip status poll interval (doc 02 §2.3)

select config_default('client.trip_poll_interval_s', '3');
