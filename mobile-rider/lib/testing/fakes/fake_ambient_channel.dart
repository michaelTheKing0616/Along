import 'dart:async';

import 'package:along_realtime/along_realtime.dart';

/// Test double for ambient Broadcast subscription (doc 03 §2).
class FakeAmbientChannel implements AmbientChannel {
  FakeAmbientChannel();

  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  String? subscribedCitySlug;
  String? subscribedGeohash5;

  @override
  Stream<Map<String, dynamic>> get cellUpdates => _updates.stream;

  @override
  Future<void> subscribe({
    required String citySlug,
    required String geohash5,
  }) async {
    subscribedCitySlug = citySlug;
    subscribedGeohash5 = geohash5;
  }

  @override
  Future<void> unsubscribe() async {
    subscribedCitySlug = null;
    subscribedGeohash5 = null;
  }

  void emitCells({
    required String asOf,
    required List<Map<String, dynamic>> cells,
  }) {
    _updates.add({
      'type': 'cells',
      'as_of': asOf,
      'cells': cells,
    });
  }

  void dispose() {
    _updates.close();
  }
}
