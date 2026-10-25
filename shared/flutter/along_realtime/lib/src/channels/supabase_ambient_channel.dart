import 'dart:async';

import 'package:along_realtime/src/channels/along_realtime_channels.dart';
import 'package:along_realtime/src/geo/geohash.dart';
import 'package:along_core/along_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Broadcast implementation for `ambient:{city_slug}:{geohash5}` (doc 03 §2).
class SupabaseAmbientChannel implements AmbientChannel {
  SupabaseAmbientChannel(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  String? _activeTopic;

  @override
  Stream<Map<String, dynamic>> get cellUpdates => _updates.stream;

  @override
  Future<void> subscribe({
    required String citySlug,
    required String geohash5,
  }) async {
    final topic = 'ambient:$citySlug:$geohash5';
    if (_activeTopic == topic && _channel != null) return;

    await unsubscribe();

    final channel = _client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );

    channel.onBroadcast(
      event: 'cells',
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

  /// Joins the channel for [location] using a 5-char geohash prefix.
  Future<void> subscribeAt({
    required String citySlug,
    required GeoPoint location,
  }) {
    return subscribe(
      citySlug: citySlug,
      geohash5: geohashEncode(location, precision: 5),
    );
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
