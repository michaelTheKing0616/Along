import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_along_supabase.dart';

void main() {
  test(
    'replays idempotent actions once, leaves unknown types untouched',
    () async {
      final db = AlongDatabase.memory();
      final queue = PendingActionQueue(db);
      await queue.enqueue(
        id: 'post_trip_message:c1',
        type: 'post_trip_message',
        payload: {'p_trip_id': 't', 'p_body': 'hi', 'p_client_ref': 'c1'},
      );
      await queue.enqueue(
        id: 'sos:t',
        type: SosOutbox.actionType,
        payload: const SosRaiseRequest(tripId: 't', lat: 9, lng: 7).toJson(),
      );
      await queue.enqueue(id: 'x1', type: 'submit_rating', payload: {'r': 5});
      final calls = <String>[];
      final gateway = FakeAlongSupabase(
        rpcHandler: (fn, params) {
          calls.add('$fn:${params['p_client_ref'] ?? ''}');
          return {'sos_id': 's1', 'status': 'open'};
        },
      );
      final replayer = QueuedActionReplayer(
        queue: queue,
        gateway: gateway,
        safety: SafetyRepository(gateway),
      );

      final before = await replayer.summary();
      expect(before.sendsWhenOnline, 2);
      expect(before.needsConnection, 1);

      expect(await replayer.replay(), 2);
      expect(calls, ['post_trip_message:c1', 'raise_sos:']);
      final left = await queue.pendingFifo();
      expect(left.single.type, 'submit_rating');
      expect(left.single.attempts, 0);

      // A second replay is a no-op: nothing is sent twice.
      expect(await replayer.replay(), 0);
      expect(calls, hasLength(2));
    },
  );

  test('a transient failure keeps the action for the next replay', () async {
    final queue = PendingActionQueue(AlongDatabase.memory());
    await queue.enqueue(
      id: 'record_driver_rest:k',
      type: 'record_driver_rest',
      payload: {'p_idempotency_key': 'k'},
    );
    var fail = true;
    final gateway = FakeAlongSupabase(
      rpcHandler: (fn, params) {
        if (fail) throw Exception('offline');
        return null;
      },
    );
    final replayer = QueuedActionReplayer(
      queue: queue,
      gateway: gateway,
      safety: SafetyRepository(gateway),
    );
    expect(await replayer.replay(), 0);
    expect((await queue.pendingFifo()).single.attempts, 1);
    fail = false;
    expect(await replayer.replay(), 1);
    expect(await queue.pendingFifo(), isEmpty);
  });

  test('delivery class per type', () {
    expect(
      queuedDeliveryFor('post_trip_message'),
      QueuedDelivery.sendsWhenOnline,
    );
    expect(queuedDeliveryFor('raise_sos'), QueuedDelivery.sendsWhenOnline);
    expect(queuedDeliveryFor('submit_rating'), QueuedDelivery.needsConnection);
  });
}
