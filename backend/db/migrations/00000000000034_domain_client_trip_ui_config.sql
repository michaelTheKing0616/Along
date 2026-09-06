-- P3-B-01: Na Me strobe timing + SOS hold duration (doc 05 motion.naMe, doc 06 R-13)
select config_default('motion.naMe.strobe_ms', '250');
select config_default('motion.naMe.cycle_duration_s', '8');
select config_default('sos.hold_duration_ms', '600');
