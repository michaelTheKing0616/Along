import 'dart:async';

import 'package:along_realtime/src/channels/along_realtime_channels.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Broadcast for `negotiation:{id}` (doc 03 §2, doc 04 §8).
class SupabaseNegotiationChannel implements NegotiationChannel {
  SupabaseNegotiationChannel(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  String? _activeTopic;

  @override
  Stream<Map<String, dynamic>> get roundUpdates => _updates.stream;

  @override
  Future<void> subscribe(String negotiationId) async {
    final topic = 'negotiation:$negotiationId';
    if (_activeTopic == topic && _channel != null) return;

    await unsubscribe();

    final channel = _client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'negotiation_update',
      callback: (payload) {
        if (!_updates.isClosed) {
          _updates.add(_unwrapPayload(payload));
        }
      },
    );

    channel.subscribe();
    _channel = channel;
    _activeTopic = topic;
  }

  @override
  Future<void> unsubscribe() async {
    final channel = _channel;
    _channel = null;
    _activeTopic = null;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  void dispose() {
    unawaited(unsubscribe());
    _updates.close();
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
    final nested = raw['payload'];
    if (nested is Map<String, dynamic>) return nested;
    return raw;
  }
}
