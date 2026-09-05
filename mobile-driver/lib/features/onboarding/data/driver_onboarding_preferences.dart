import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Driver onboarding progress persisted locally between launches.
enum DriverOnboardingStep {
  auth,
  profile,
  vehicle,
  documents,
  pending,
  complete,
}

/// Persists driver onboarding step and vehicle id for the shell router.
class DriverOnboardingPreferences {
  DriverOnboardingPreferences({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _stepKey = 'driver_onboarding_step';
  static const _vehicleIdKey = 'driver_vehicle_id';
  static const _countryCodeKey = 'driver_country_code';

  final FlutterSecureStorage _storage;

  Future<DriverOnboardingStep> currentStep() async {
    final value = await _storage.read(key: _stepKey);
    return DriverOnboardingStep.values.firstWhere(
      (step) => step.name == value,
      orElse: () => DriverOnboardingStep.auth,
    );
  }

  Future<void> setStep(DriverOnboardingStep step) =>
      _storage.write(key: _stepKey, value: step.name);

  Future<String?> vehicleId() => _storage.read(key: _vehicleIdKey);

  Future<void> setVehicleId(String id) =>
      _storage.write(key: _vehicleIdKey, value: id);

  Future<String?> countryCode() => _storage.read(key: _countryCodeKey);

  Future<void> setCountryCode(String code) =>
      _storage.write(key: _countryCodeKey, value: code);

  Future<void> clear() async {
    await _storage.delete(key: _stepKey);
    await _storage.delete(key: _vehicleIdKey);
    await _storage.delete(key: _countryCodeKey);
  }
}
