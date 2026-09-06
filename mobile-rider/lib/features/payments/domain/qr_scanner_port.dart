import 'dart:async';

/// Injectable QR scan port — fake in widget tests, stub on device until P1-G-01.
abstract class QrScannerPort {
  Stream<String> get scans;

  Future<void> start();

  Future<void> stop();

  Future<void> setTorch(bool enabled);
}

/// Test double that emits payloads programmatically.
class FakeQrScanner implements QrScannerPort {
  FakeQrScanner();

  final _controller = StreamController<String>.broadcast();
  bool _torch = false;

  @override
  Stream<String> get scans => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setTorch(bool enabled) async {
    _torch = enabled;
  }

  bool get torchEnabled => _torch;

  void emit(String payload) {
    if (!_controller.isClosed) {
      _controller.add(payload);
    }
  }

  void dispose() => _controller.close();
}

/// Placeholder camera layer (live camera deferred to P1-G-01).
class StubQrScanner implements QrScannerPort {
  StubQrScanner();

  final _controller = StreamController<String>.broadcast();
  bool _torch = false;

  @override
  Stream<String> get scans => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setTorch(bool enabled) async {
    _torch = enabled;
  }

  bool get torchEnabled => _torch;

  void dispose() => _controller.close();
}
