import 'dart:async';

import 'package:along_realtime/src/channels/along_realtime_channels.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Broadcast implementation for `driver:{driver_id}` (doc 03 §5).
class SupabaseDriverChannel implements DriverChannel {
  SupabaseDriverChannel(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  String? _activeDriverId;

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  @override
  Future<void> subscribe(String driverId) async {
    if (_activeDriverId == driverId && _channel != null) return;

    await unsubscribe();

    final channel = _client.channel(
      'driver:$driverId',
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'trip_request',
      callback: (payload) {
        if (!_events.isClosed) {
          _events.add(_unwrapPayload(payload));
        }
      },
    );

    await channel.subscribe();
    _channel = channel;
    _activeDriverId = driverId;
  }

  @override
  Future<void> unsubscribe() async {
    final channel = _channel;
    _channel = null;
    _activeDriverId = null;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  void dispose() {
    unawaited(unsubscribe());
    _events.close();
  }

  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
    final nested = raw['payload'];
    if (nested is Map<String, dynamic>) return nested;
    return raw;
  }
}
