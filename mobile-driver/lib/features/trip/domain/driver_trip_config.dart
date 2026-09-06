import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

/// Thresholds for D-15/D-16 — all from app_config.
class DriverTripConfig {
  const DriverTripConfig({
    required this.manifestPollInterval,
    required this.tripLocationSampleInterval,
    required this.naMeStrobeMs,
    required this.naMeCycleDuration,
    required this.sosHoldDurationMs,
    required this.commissionRate,
    required this.noShowAfterS,
  });

  final Duration manifestPollInterval;
  final Duration tripLocationSampleInterval;
  final Duration naMeStrobeMs;
  final Duration naMeCycleDuration;
  final Duration sosHoldDurationMs;
  final num commissionRate;
  final int noShowAfterS;

  NaMeTimingConfig get naMeTiming => NaMeTimingConfig(
        strobeInterval: naMeStrobeMs,
        cycleDuration: naMeCycleDuration,
      );
}

final driverTripConfigProvider = FutureProvider<DriverTripConfig>((ref) async {
  final config = ref.read(configRepositoryProvider);
  final manifestPollS =
      (await config.configNum('driver.manifest_poll_s')).toInt();
  final sampleIntervalS =
      (await config.configNum('client.trip_location_sample_interval_s'))
          .toInt();
  final strobeMs = (await config.configNum('motion.naMe.strobe_ms')).toInt();
  final cycleS =
      (await config.configNum('motion.naMe.cycle_duration_s')).toInt();
  final sosHoldMs = (await config.configNum('sos.hold_duration_ms')).toInt();
  final commissionRate = await config.configNum('commission.rate');
  final noShowAfterS =
      (await config.configNum('dispatch.no_show_after_s')).toInt();

  return DriverTripConfig(
    manifestPollInterval: Duration(seconds: manifestPollS),
    tripLocationSampleInterval: Duration(seconds: sampleIntervalS),
    naMeStrobeMs: Duration(milliseconds: strobeMs),
    naMeCycleDuration: Duration(seconds: cycleS),
    sosHoldDurationMs: Duration(milliseconds: sosHoldMs),
    commissionRate: commissionRate,
    noShowAfterS: noShowAfterS,
  );
});
