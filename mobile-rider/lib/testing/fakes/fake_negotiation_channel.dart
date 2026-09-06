import 'dart:async';

import 'package:along_realtime/along_realtime.dart';

/// Test double for negotiation Broadcast (doc 04 §8).
class FakeNegotiationChannel implements NegotiationChannel {
  FakeNegotiationChannel();

  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  String? subscribedNegotiationId;

  @override
  Stream<Map<String, dynamic>> get roundUpdates => _updates.stream;

  @override
  Future<void> subscribe(String negotiationId) async {
    subscribedNegotiationId = negotiationId;
  }

  @override
  Future<void> unsubscribe() async {
    subscribedNegotiationId = null;
  }

  void emitUpdate(Map<String, dynamic> payload) {
    _updates.add(payload);
  }

  void dispose() {
    _updates.close();
  }
}
