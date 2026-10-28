import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline, reconnect replays the queue, then settles online', () async {
    final source = FakeConnectionSource(online: false);
    var queued = 2;
    final c = ConnectionController(
      source: source,
      queuedCount: () async => queued,
      replay: () async {
        final n = queued;
        queued = 0;
        return n;
      },
      restoredHold: const Duration(milliseconds: 10),
    );
    final seen = <ConnectionPhase>[];
    c.changes.listen((s) => seen.add(s.phase));
    await c.start();
    expect(c.current.phase, ConnectionPhase.offline);
    expect(c.current.queued, 2);
    source.online = true;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(c.current.phase, ConnectionPhase.restored);
    expect(c.current.sent, 2);
    expect(c.current.queued, 0);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.current.phase, ConnectionPhase.online);
    expect(seen, contains(ConnectionPhase.reconnecting));
    await c.dispose();
  });

  test('retry while still offline returns to offline', () async {
    final source = FakeConnectionSource(online: false);
    final c = ConnectionController(source: source);
    await c.start();
    await c.retry();
    expect(c.current.phase, ConnectionPhase.offline);
    await c.dispose();
  });

  test('failed replay keeps the actions queued', () async {
    final source = FakeConnectionSource(online: false);
    final c = ConnectionController(
      source: source,
      queuedCount: () async => 1,
      replay: () async => throw StateError('network'),
      restoredHold: const Duration(milliseconds: 5),
    );
    await c.start();
    source.online = true;
    await Future<void>.delayed(const Duration(milliseconds: 2));
    expect(c.current.phase, ConnectionPhase.restored);
    expect(c.current.sent, 0);
    expect(c.current.queued, 1);
    await c.dispose();
  });
}
