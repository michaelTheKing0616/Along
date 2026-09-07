/// FCM driver-request delivery latency (doc 01 §7: ≤ 3 s p95).
///
/// Measurement method:
/// 1. `notify` Edge Function includes `sent_at_ms` (epoch ms) in FCM data payload.
/// 2. Client calls [recordDelivery] when `onDataMessage` / background handler fires.
/// 3. Aggregate p95 locally during field tests; production via Sentry custom metric
///    `push.driver_request_delivery_ms` or server-side diff against `trip_events`.
///
/// CI validates percentile math on injected samples; hardware run is DEFERRED.
class PushDeliveryMetrics {
  PushDeliveryMetrics({this.targetP95Ms = 3000});

  final double targetP95Ms;
  final List<double> _samplesMs = [];

  /// Records one delivery sample from server send to client receipt.
  void recordDelivery({
    required int serverSentAtMs,
    required int clientReceivedAtMs,
  }) {
    final delta = (clientReceivedAtMs - serverSentAtMs).toDouble();
    if (delta >= 0) {
      _samplesMs.add(delta);
    }
  }

  /// Convenience when payload carries `sent_at_ms` string from FCM data map.
  void recordFromPayload(Map<String, dynamic> data, {DateTime? receivedAt}) {
    final raw = data['sent_at_ms'];
    if (raw == null) return;
    final sentMs = int.tryParse(raw.toString());
    if (sentMs == null) return;
    recordDelivery(
      serverSentAtMs: sentMs,
      clientReceivedAtMs: (receivedAt ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  int get sampleCount => _samplesMs.length;

  double get p95Ms {
    if (_samplesMs.isEmpty) return double.infinity;
    final sorted = List<double>.from(_samplesMs)..sort();
    final index = (sorted.length * 0.95).ceil().clamp(1, sorted.length) - 1;
    return sorted[index];
  }

  bool get passesTarget => _samplesMs.isNotEmpty && p95Ms <= targetP95Ms;

  void clear() => _samplesMs.clear();
}
