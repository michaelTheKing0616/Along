import 'dart:async';

import 'package:along_realtime/along_realtime.dart';

/// In-memory driver channel for widget/controller tests.
class FakeDriverChannel implements DriverChannel {
  FakeDriverChannel();

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  String? subscribedDriverId;

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  @override
  Future<void> subscribe(String driverId) async {
    subscribedDriverId = driverId;
  }

  @override
  Future<void> unsubscribe() async {
    subscribedDriverId = null;
  }

  void emitTripRequest(Map<String, dynamic> payload) {
    if (!_events.isClosed) {
      _events.add(payload);
    }
  }

  void dispose() {
    _events.close();
  }
}
