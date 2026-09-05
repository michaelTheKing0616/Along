import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';

class VehicleFormState {
  const VehicleFormState({
    this.modes = const [],
    this.country,
    this.selectedModeCode,
    this.plateNumber = '',
    this.seatCapacity = 4,
    this.color = '',
    this.makeModel = '',
    this.ownerIsMe = true,
    this.ownerName = '',
    this.ownerPhone = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isLoading = true,
  });

  final List<ModeConfigRow> modes;
  final CountryConfig? country;
  final String? selectedModeCode;
  final String plateNumber;
  final int seatCapacity;
  final String color;
  final String makeModel;
  final bool ownerIsMe;
  final String ownerName;
  final String ownerPhone;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isLoading;

  VehicleFormState copyWith({
    List<ModeConfigRow>? modes,
    CountryConfig? country,
    String? selectedModeCode,
    String? plateNumber,
    int? seatCapacity,
    String? color,
    String? makeModel,
    bool? ownerIsMe,
    String? ownerName,
    String? ownerPhone,
    bool? isSubmitting,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
  }) {
    return VehicleFormState(
      modes: modes ?? this.modes,
      country: country ?? this.country,
      selectedModeCode: selectedModeCode ?? this.selectedModeCode,
      plateNumber: plateNumber ?? this.plateNumber,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      color: color ?? this.color,
      makeModel: makeModel ?? this.makeModel,
      ownerIsMe: ownerIsMe ?? this.ownerIsMe,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final vehicleControllerProvider =
    AsyncNotifierProvider<VehicleController, VehicleFormState>(
  VehicleController.new,
);

class VehicleController extends AsyncNotifier<VehicleFormState> {
  CatalogRepository get _catalog => ref.read(catalogRepositoryProvider);
  DriverRepository get _driver => ref.read(driverRepositoryProvider);
  DriverOnboardingPreferences get _prefs =>
      ref.read(driverOnboardingPreferencesProvider);

  @override
  Future<VehicleFormState> build() async {
    final modes = await _catalog.modeConfigs();
    final countryCode = await _prefs.countryCode() ?? 'NG';
    final country = await _catalog.countryConfig(countryCode);
    final defaultMode = modes.isNotEmpty ? modes.first : null;

    return VehicleFormState(
      modes: modes,
      country: country,
      selectedModeCode: defaultMode?.code,
      seatCapacity: defaultMode?.defaultSeatCapacity ?? 4,
      isLoading: false,
    );
  }

  void setMode(String code) {
    final current = state.requireValue;
    final mode = current.modes.firstWhere((m) => m.code == code);
    state = AsyncData(
      current.copyWith(
        selectedModeCode: code,
        seatCapacity: mode.defaultSeatCapacity,
        clearError: true,
      ),
    );
  }

  void setPlate(String value) {
    state = AsyncData(
      state.requireValue.copyWith(plateNumber: value, clearError: true),
    );
  }

  void setSeatCapacity(int value) {
    state = AsyncData(
      state.requireValue.copyWith(seatCapacity: value, clearError: true),
    );
  }

  void setColor(String value) {
    state = AsyncData(
      state.requireValue.copyWith(color: value, clearError: true),
    );
  }

  void setMakeModel(String value) {
    state = AsyncData(
      state.requireValue.copyWith(makeModel: value, clearError: true),
    );
  }

  void setOwnerIsMe(bool value) {
    state = AsyncData(
      state.requireValue.copyWith(ownerIsMe: value, clearError: true),
    );
  }

  void setOwnerName(String value) {
    state = AsyncData(
      state.requireValue.copyWith(ownerName: value, clearError: true),
    );
  }

  void setOwnerPhone(String value) {
    state = AsyncData(
      state.requireValue.copyWith(ownerPhone: value, clearError: true),
    );
  }

  bool _isValidPlate(String plate, String pattern) {
    return RegExp(pattern, caseSensitive: false).hasMatch(plate.trim());
  }

  Future<bool> submit() async {
    final current = state.requireValue;
    final mode = current.selectedModeCode;
    final country = current.country;

    if (mode == null ||
        country == null ||
        current.plateNumber.trim().isEmpty ||
        !_isValidPlate(current.plateNumber, country.platePattern)) {
      state = AsyncData(current.copyWith(errorMessage: 'validation'));
      return false;
    }

    if (!current.ownerIsMe &&
        (current.ownerName.trim().isEmpty ||
            current.ownerPhone.trim().isEmpty)) {
      state = AsyncData(current.copyWith(errorMessage: 'validation'));
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final vehicleId = await _driver.registerVehicle(
        RegisterVehicleRequest(
          mode_code: mode,
          plate_number: current.plateNumber.trim(),
          seat_capacity: current.seatCapacity,
          color: current.color.trim().isEmpty ? null : current.color.trim(),
          make_model:
              current.makeModel.trim().isEmpty ? null : current.makeModel.trim(),
          owner_is_me: current.ownerIsMe,
          owner_name: current.ownerIsMe ? null : current.ownerName.trim(),
          owner_phone: current.ownerIsMe ? null : current.ownerPhone.trim(),
        ),
      );
      await _prefs.setVehicleId(vehicleId);
      await _prefs.setStep(DriverOnboardingStep.documents);
      state = AsyncData(current.copyWith(isSubmitting: false, clearError: true));
      ref.invalidate(driverOnboardingStepProvider);
      return true;
    } on AlongException catch (e) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          errorMessage: e.code == AlongErrorCode.conflict ? 'conflict' : 'generic',
        ),
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
