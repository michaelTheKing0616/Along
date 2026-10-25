import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_along_supabase.dart';

void main() {
  late FakeAlongSupabase gateway;
  late InMemoryTripChatChannel channel;
  late List<Map<String, dynamic>> server;
  var failPosts = 0;
  var refs = 0;

  TripChatController make() => TripChatController(
    gateway: gateway,
    channel: channel,
    tripId: 't1',
    myRole: 'rider',
    retryDelay: const Duration(milliseconds: 10),
    newRef: () => 'ref-0000000${refs++}',
  );

  setUp(() {
    server = [];
    failPosts = 0;
    refs = 0;
    channel = InMemoryTripChatChannel();
    gateway = FakeAlongSupabase(
      rpcHandler: (fn, p) {
        switch (fn) {
          case 'list_trip_messages':
            return server;
          case 'post_trip_message':
            if (failPosts > 0) {
              failPosts--;
              throw const AlongException(
                code: AlongErrorCode.degradedUpstream,
                message: 'offline',
              );
            }
            final row = {
              'id': 'srv-${server.length}',
              'author_role': 'rider',
              'body': p['p_body'],
              'client_ref': p['p_client_ref'],
              'created_at': '2026-10-25T18:00:00Z',
              'read_at': null,
            };
            server.add(row);
            return row;
          case 'mark_trip_messages_read':
            return 1;
        }
        return null;
      },
    );
  });

  test('send is optimistic, then sent; read receipt ticks it read', () async {
    final c = make();
    await c.start();
    expect(channel.subscribedTripId, 't1');
    c.send(' On my way ');
    expect(c.lines.single.state, TripChatState.sending);
    expect(c.lines.single.body, 'On my way');
    await Future<void>.delayed(Duration.zero);
    expect(c.lines.single.state, TripChatState.sent);
    channel.emit({'type': 'read', 'reader_role': 'rider'});
    await Future<void>.delayed(Duration.zero);
    expect(c.lines.single.state, TripChatState.sent, reason: 'own receipt');
    channel.emit({'type': 'read', 'reader_role': 'driver'});
    await Future<void>.delayed(Duration.zero);
    expect(c.lines.single.state, TripChatState.read);
    c.dispose();
  });

  test(
    'offline send retries with the same client_ref, then fails to tap',
    () async {
      final c = make();
      await c.start();
      failPosts = 1;
      c.send('Running late');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.lines.single.state, TripChatState.sent);
      final posts = gateway.rpcCalls
          .where((r) => r.$1 == 'post_trip_message')
          .toList();
      expect(posts.length, 2);
      expect(posts[0].$2['p_client_ref'], posts[1].$2['p_client_ref']);

      failPosts = 10;
      c.send('Again');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c.lines.last.state, TripChatState.failed);
      failPosts = 0;
      c.retry(c.lines.last.key);
      expect(c.lines.last.state, TripChatState.sending);
      await Future<void>.delayed(Duration.zero);
      expect(c.lines.last.state, TripChatState.sent);
      c.dispose();
    },
  );

  test(
    'incoming message badges, fires the haptic hook, clears on open',
    () async {
      final c = make();
      var pings = 0;
      c.onIncoming = () => pings++;
      await c.start();
      channel.emit({
        'type': 'message',
        'message': {
          'id': 'd1',
          'author_role': 'driver',
          'body': "I'm here",
          'created_at': '2026-10-25T18:01:00Z',
        },
      });
      await Future<void>.delayed(Duration.zero);
      expect(c.unread, 1);
      expect(pings, 1);
      expect(c.lines.single.mine, isFalse);
      c.visible = true;
      expect(c.unread, 0);
      await Future<void>.delayed(Duration.zero);
      expect(
        gateway.rpcCalls.any((r) => r.$1 == 'mark_trip_messages_read'),
        isTrue,
      );
      c.dispose();
    },
  );

  test('closed trip stops sending', () async {
    gateway.rpcHandler = (fn, p) {
      if (fn == 'post_trip_message') {
        throw const AlongException(
          code: AlongErrorCode.stateInvalid,
          message: 'closed',
        );
      }
      return const <dynamic>[];
    };
    final c = make();
    await c.start();
    c.send('Hello');
    await Future<void>.delayed(Duration.zero);
    expect(c.closed, isTrue);
    expect(c.lines.single.state, TripChatState.failed);
    c.send('Ignored');
    expect(c.lines.length, 1);
    c.dispose();
  });

  test('quick replies come from config with a fallback', () {
    expect(
      tripChatQuickReplies({
        'driver': ['A', ' '],
      }, 'driver'),
      ['A'],
    );
    expect(tripChatQuickReplies(null, 'rider').first, "I'm at the pickup");
  });
}
