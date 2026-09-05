import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists rider onboarding completion locally (until R-05 profile sync).
class OnboardingPreferences {
  OnboardingPreferences({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'rider_onboarding_complete';

  final FlutterSecureStorage _storage;

  Future<bool> isComplete() async {
    final value = await _storage.read(key: _key);
    return value == 'true';
  }

  Future<void> markComplete() => _storage.write(key: _key, value: 'true');

  Future<void> clear() => _storage.delete(key: _key);
}
