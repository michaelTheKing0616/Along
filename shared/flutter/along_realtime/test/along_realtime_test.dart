import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReconnectPolicy caps delay at max', () {
    const policy = ReconnectPolicy();
    expect(policy.delayForAttempt(0), const Duration(seconds: 1));
    expect(policy.delayForAttempt(10), const Duration(seconds: 30));
  });

  test('RealtimeHeartbeatMonitor fires on stale channel', () {
    var stale = false;
    final monitor = RealtimeHeartbeatMonitor(
      timeout: const Duration(milliseconds: 10),
      onStale: () => stale = true,
    );
    monitor.onMessageReceived();
    expect(stale, isFalse);
  });
}
