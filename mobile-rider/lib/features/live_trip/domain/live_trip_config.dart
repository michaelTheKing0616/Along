import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';

/// Thresholds for Tier B trip screens — all from app_config.
class LiveTripConfig {
  const LiveTripConfig({
    required this.pollInterval,
    required this.heartbeatStaleAfter,
    required this.livePausedAfter,
    required this.driverOfflineAfter,
    required this.naMeStrobeMs,
    required this.naMeCycleDuration,
    required this.sosHoldDurationMs,
  });

  final Duration pollInterval;
  final Duration heartbeatStaleAfter;
  final Duration livePausedAfter;
  final Duration driverOfflineAfter;
  final Duration naMeStrobeMs;
  final Duration naMeCycleDuration;
  final Duration sosHoldDurationMs;
}

final liveTripConfigProvider = FutureProvider<LiveTripConfig>((ref) async {
  final config = ref.read(configRepositoryProvider);
  final pollS = (await config.configNum('client.trip_poll_interval_s')).toInt();
  final heartbeatS =
      (await config.configNum('realtime.heartbeat_stale_s')).toInt();
  final pausedS =
      (await config.configNum('realtime.live_paused_after_s')).toInt();
  final offlineS = (await config.configNum('presence.offline_after_s')).toInt();
  final strobeMs = (await config.configNum('motion.naMe.strobe_ms')).toInt();
  final cycleS =
      (await config.configNum('motion.naMe.cycle_duration_s')).toInt();
  final sosHoldMs = (await config.configNum('sos.hold_duration_ms')).toInt();

  return LiveTripConfig(
    pollInterval: Duration(seconds: pollS),
    heartbeatStaleAfter: Duration(seconds: heartbeatS),
    livePausedAfter: Duration(seconds: pausedS),
    driverOfflineAfter: Duration(seconds: offlineS),
    naMeStrobeMs: Duration(milliseconds: strobeMs),
    naMeCycleDuration: Duration(seconds: cycleS),
    sosHoldDurationMs: Duration(milliseconds: sosHoldMs),
  );
});
