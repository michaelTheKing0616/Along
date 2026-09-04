import 'package:along_notifications/src/push_message.dart';

/// Contract for FCM registration and background handling (wired in later tasks).
abstract class PushService {
  Future<String?> getToken();
  Stream<PushMessage> get onMessageOpened;
  Future<void> registerTokenWithServer(Future<void> Function(String token) register);
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
