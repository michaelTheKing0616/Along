/// Share-sheet port for D-25 "Share as image" (stub in prod until platform wiring).
abstract class ShareImagePort {
  Future<void> shareQrImage({
    required String driverCode,
    required String plate,
    required String payloadUrl,
  });
}

class StubShareImagePort implements ShareImagePort {
  @override
  Future<void> shareQrImage({
    required String driverCode,
    required String plate,
    required String payloadUrl,
  }) async {}
}

class FakeShareImagePort implements ShareImagePort {
  int invokeCount = 0;
  String? lastDriverCode;
  String? lastPlate;
  String? lastPayloadUrl;

  @override
  Future<void> shareQrImage({
    required String driverCode,
    required String plate,
    required String payloadUrl,
  }) async {
    invokeCount++;
    lastDriverCode = driverCode;
    lastPlate = plate;
    lastPayloadUrl = payloadUrl;
  }
}
