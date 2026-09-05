import 'dart:async';

import 'package:along_notifications/src/push_message.dart';

/// Contract for FCM registration and background handling (ADR-0011).
abstract class PushService {
  Future<String?> getToken();
  Stream<PushMessage> get onMessageOpened;

  /// Foreground / background data messages (driver trip_request wake).
  Stream<PushMessage> get onDataMessage;

  Future<void> registerTokenWithServer(
    Future<void> Function(String token) register,
  );
}

/// Test double and dev stub when Firebase is not configured on device.
class StubPushService implements PushService {
  StubPushService();

  final _opened = StreamController<PushMessage>.broadcast();
  final _data = StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get onMessageOpened => _opened.stream;

  @override
  Stream<PushMessage> get onDataMessage => _data.stream;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> registerTokenWithServer(
    Future<void> Function(String token) register,
  ) async {}

  void emitDataMessage(PushMessage message) {
    if (!_data.isClosed) {
      _data.add(message);
    }
  }

  void emitOpened(PushMessage message) {
    if (!_opened.isClosed) {
      _opened.add(message);
    }
  }

  void dispose() {
    _opened.close();
    _data.close();
  }
}

/// Routes push payloads to app deep links (`along://trip/{id}`).
class PushDeepLinkRouter {
  const PushDeepLinkRouter();

  String? routeFor(PushMessage message) {
    final tripId = message.tripId;
    if (tripId == null || tripId.isEmpty) return null;
    return 'along://trip/$tripId';
  }
}
