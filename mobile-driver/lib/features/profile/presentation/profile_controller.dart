import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';

class ProfileFormState {
  const ProfileFormState({
    this.cities = const [],
    this.selectedCityId,
    this.displayName = '',
    this.gender,
    this.isSubmitting = false,
    this.errorMessage,
    this.isLoading = true,
  });

  final List<CityOption> cities;
  final String? selectedCityId;
  final String displayName;
  final String? gender;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isLoading;

  ProfileFormState copyWith({
    List<CityOption>? cities,
    String? selectedCityId,
    String? displayName,
    String? gender,
    bool? isSubmitting,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return ProfileFormState(
      cities: cities ?? this.cities,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileFormState>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<ProfileFormState> {
  CatalogRepository get _catalog => ref.read(catalogRepositoryProvider);
  DriverRepository get _driver => ref.read(driverRepositoryProvider);
  DriverOnboardingPreferences get _prefs =>
      ref.read(driverOnboardingPreferencesProvider);

  @override
  Future<ProfileFormState> build() async {
    final cities = await _catalog.activeCities();
    return ProfileFormState(
      cities: cities,
      selectedCityId: cities.isNotEmpty ? cities.first.id : null,
      isLoading: false,
    );
  }

  void setDisplayName(String value) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(displayName: value, clearError: true));
  }

  void setCity(String? cityId) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selectedCityId: cityId, clearError: true));
  }

  void setGender(String? gender) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(gender: gender, clearError: true));
  }

  Future<bool> submit() async {
    final current = state.requireValue;
    final name = current.displayName.trim();
    final cityId = current.selectedCityId;

    if (name.isEmpty || cityId == null) {
      state = AsyncData(current.copyWith(errorMessage: 'validation'));
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      await _driver.startDriverOnboarding(
        cityId: cityId,
        displayName: name,
        gender: current.gender,
      );
      final city = current.cities.firstWhere((c) => c.id == cityId);
      await _prefs.setCountryCode(city.countryCode);
      await _prefs.setStep(DriverOnboardingStep.vehicle);
      state = AsyncData(
        current.copyWith(isSubmitting: false, clearError: true),
      );
      ref.invalidate(driverOnboardingStepProvider);
      return true;
    } on AlongException catch (_) {
      state = AsyncData(
        current.copyWith(isSubmitting: false, errorMessage: 'generic'),
      );
      return false;
    } catch (_) {
      state = AsyncData(
        current.copyWith(isSubmitting: false, errorMessage: 'generic'),
      );
      return false;
    }
  }
}
