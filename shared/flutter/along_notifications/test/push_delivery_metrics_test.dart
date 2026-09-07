import 'package:along_notifications/src/push_delivery_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('p95 delivery latency computed from samples', () {
    final metrics = PushDeliveryMetrics(targetP95Ms: 3000);
    for (var i = 1; i <= 100; i++) {
      metrics.recordDelivery(
        serverSentAtMs: 1_000_000,
        clientReceivedAtMs: 1_000_000 + i * 10,
      );
    }
    expect(metrics.sampleCount, 100);
    expect(metrics.p95Ms, lessThanOrEqualTo(1000));
    expect(metrics.passesTarget, isTrue);
  });

  test('recordFromPayload parses sent_at_ms', () {
    final metrics = PushDeliveryMetrics();
    metrics.recordFromPayload(
      {'sent_at_ms': '1000', 'trip_id': 'abc'},
      receivedAt: DateTime.fromMillisecondsSinceEpoch(2500),
    );
    expect(metrics.sampleCount, 1);
    expect(metrics.p95Ms, 1500);
  });
}
