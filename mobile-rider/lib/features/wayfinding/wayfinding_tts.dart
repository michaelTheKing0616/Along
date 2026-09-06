import 'package:flutter_tts/flutter_tts.dart';

/// Abstraction over platform TTS for widget tests (ADR-0020).
abstract class WayfindingTts {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Production TTS using flutter_tts (doc 07 §9).
class FlutterWayfindingTts implements WayfindingTts {
  FlutterWayfindingTts() : _tts = FlutterTts();

  final FlutterTts _tts;
  var _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('en-NG');
    await _tts.awaitSpeakCompletion(true);
    _initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    await _ensureInit();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _ensureInit();
    await _tts.stop();
  }
}

/// No-op TTS for tests.
class FakeWayfindingTts implements WayfindingTts {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}
