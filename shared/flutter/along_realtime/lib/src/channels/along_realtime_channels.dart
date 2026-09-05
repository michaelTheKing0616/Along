import 'dart:async';

/// Typed Realtime event from a trip channel.
class TripRealtimeEvent {
  const TripRealtimeEvent({required this.type, required this.payload});

  final String type;
  final Map<String, dynamic> payload;
}

/// Contract for `trip:{id}` channel (full wiring in Phase 3).
abstract class TripChannel {
  Stream<TripRealtimeEvent> get events;
  Future<void> subscribe(String tripId);
  Future<void> unsubscribe();
  Future<void> publishLocation(Map<String, dynamic> sample);
}

/// Contract for ambient discovery channel `ambient:{city_slug}:{geohash5}`.
abstract class AmbientChannel {
  Stream<Map<String, dynamic>> get cellUpdates;
  Future<void> subscribe({
    required String citySlug,
    required String geohash5,
  });
  Future<void> unsubscribe();
}

/// Contract for driver status channel `driver:{id}`.
abstract class DriverChannel {
  Stream<Map<String, dynamic>> get events;
  Future<void> subscribe(String driverId);
  Future<void> unsubscribe();
}

/// Contract for negotiation channel `negotiation:{id}`.
abstract class NegotiationChannel {
  Stream<Map<String, dynamic>> get roundUpdates;
  Future<void> subscribe(String negotiationId);
  Future<void> unsubscribe();
}

/// Heartbeat monitor: fires when no message received within [timeout].
class RealtimeHeartbeatMonitor {
  RealtimeHeartbeatMonitor({required this.timeout, required this.onStale});

  final Duration timeout;
  final void Function() onStale;

  Timer? _timer;

  void onMessageReceived() {
    _timer?.cancel();
    _timer = Timer(timeout, onStale);
  }

  void dispose() => _timer?.cancel();
}
