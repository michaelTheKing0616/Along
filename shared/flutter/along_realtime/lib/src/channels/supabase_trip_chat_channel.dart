import 'dart:async';

import 'package:along_realtime/src/channels/along_realtime_channels.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase private Broadcast for `trip_chat:{id}` (migration 98). Postgres
/// sends from post_trip_message / mark_trip_messages_read; RLS on
/// realtime.messages admits only the trip's rider and driver.
class SupabaseTripChatChannel implements TripChatChannel {
  SupabaseTripChatChannel(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _topic;
  final _events = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  @override
  Future<void> subscribe(String tripId) async {
    final topic = 'trip_chat:$tripId';
    if (_topic == topic && _channel != null) return;
    await unsubscribe();
    final channel = _client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );
    channel.onBroadcast(
      event: 'chat',
      callback: (payload) {
        if (_events.isClosed) return;
        final nested = payload['payload'];
        _events.add(nested is Map<String, dynamic> ? nested : payload);
      },
    );
    channel.subscribe();
    _channel = channel;
    _topic = topic;
  }

  @override
  Future<void> unsubscribe() async {
    final channel = _channel;
    _channel = null;
    _topic = null;
    if (channel != null) await _client.removeChannel(channel);
  }

  void dispose() {
    unawaited(unsubscribe());
    _events.close();
  }
}
