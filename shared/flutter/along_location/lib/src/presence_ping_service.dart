import 'dart:async';

import 'package:along_location/src/battery_monitor.dart';
import 'package:along_location/src/location_sample.dart';
import 'package:along_location/src/location_stream.dart';

typedef PresencePingCallback = Future<void> Function(LocationSample sample);

/// Schedules `presence_ping` while the driver is online (testable without isolates).
class PresencePingScheduler {
  PresencePingScheduler({
    required this._locationSource,
    required this._batteryMonitor,
    required this.batteryGuardPercent,
    required this.onPing,
  });

  final LocationStreamSource _locationSource;
  final BatteryMonitor _batteryMonitor;
  final int batteryGuardPercent;
  final PresencePingCallback onPing;

  StreamSubscription<LocationSample>? _locationSub;
  Timer? _pingTimer;
  LocationSample? _lastSample;
  Duration _baseInterval = const Duration(seconds: 4);
  Duration _effectiveInterval = const Duration(seconds: 4);
  int? _seatsAvailable;

  /// Seats last reported via [start] or [updateSeats].
  int? get seatsAvailable => _seatsAvailable;
  bool _batteryGuardActive = false;
  bool _running = false;

  bool get isRunning => _running;
  bool get batteryGuardActive => _batteryGuardActive;
  Duration get effectiveInterval => _effectiveInterval;

  Future<void> start({
    required Duration movingInterval,
    required Duration stillInterval,
    required int seatsAvailable,
  }) async {
    await stop();
    _baseInterval = movingInterval;
    _effectiveInterval = movingInterval;
    _seatsAvailable = seatsAvailable;
    _running = true;

    final granted = await _locationSource.ensurePermission();
    if (!granted) {
      _running = false;
      return;
    }

    _locationSub = FilteredLocationStream(_locationSource)
        .track(minInterval: const Duration(seconds: 2))
        .listen((sample) {
      _lastSample = sample;
      final speed = sample.speedMps ?? 0;
      _baseInterval = speed >= 1.5 ? movingInterval : stillInterval;
      unawaited(_refreshBatteryGuard());
    });

    await _refreshBatteryGuard();
    _scheduleNextPing();
  }

  Future<void> stop() async {
    _running = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    await _locationSub?.cancel();
    _locationSub = null;
    _lastSample = null;
    _batteryGuardActive = false;
  }

  void updateSeats(int seatsAvailable) {
    _seatsAvailable = seatsAvailable;
  }

  Future<void> _refreshBatteryGuard() async {
    final battery = await _batteryMonitor.read();
    final guardActive = battery.levelPercent < batteryGuardPercent &&
        !battery.isCharging;
    if (guardActive == _batteryGuardActive &&
        _effectiveInterval == _scaledInterval(_baseInterval, guardActive)) {
      return;
    }
    _batteryGuardActive = guardActive;
    _effectiveInterval = _scaledInterval(_baseInterval, guardActive);
    if (_running) {
      _scheduleNextPing();
    }
  }

  Duration _scaledInterval(Duration base, bool guardActive) =>
      guardActive ? base * 2 : base;

  void _scheduleNextPing() {
    _pingTimer?.cancel();
    if (!_running) return;

    _pingTimer = Timer(_effectiveInterval, () {
      unawaited(_emitPing());
      _scheduleNextPing();
    });
  }

  Future<void> _emitPing() async {
    if (!_running) return;
    await _refreshBatteryGuard();

    final sample = _lastSample;
    if (sample == null) return;
    await onPing(sample);
  }
}

/// Tracks foreground notification lifecycle for driver presence (doc 07 §6).
abstract class DriverForegroundNotifier {
  Future<void> startVisibleNotification();
  Future<void> stopVisibleNotification();
}

class InMemoryDriverForegroundNotifier implements DriverForegroundNotifier {
  bool visible = false;

  @override
  Future<void> startVisibleNotification() async {
    visible = true;
  }

  @override
  Future<void> stopVisibleNotification() async {
    visible = false;
  }
}

/// Combines foreground notification + ping scheduler for driver online state.
class DriverPresenceSession {
  DriverPresenceSession({
    required this._scheduler,
    required this._foregroundNotifier,
  });

  final PresencePingScheduler _scheduler;
  final DriverForegroundNotifier _foregroundNotifier;

  bool get isOnline => _scheduler.isRunning;
  bool get notificationVisible => _foregroundNotifier is InMemoryDriverForegroundNotifier
      ? (_foregroundNotifier).visible
      : _scheduler.isRunning;

  Future<void> goOnline({
    required Duration movingInterval,
    required Duration stillInterval,
    required int seatsAvailable,
  }) async {
    await _foregroundNotifier.startVisibleNotification();
    await _scheduler.start(
      movingInterval: movingInterval,
      stillInterval: stillInterval,
      seatsAvailable: seatsAvailable,
    );
  }

  Future<void> goOffline() async {
    await _scheduler.stop();
    await _foregroundNotifier.stopVisibleNotification();
  }

  void updateSeats(int seatsAvailable) {
    _scheduler.updateSeats(seatsAvailable);
  }
}
