import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden at startup');
});

final alongSupabaseProvider = Provider<AlongSupabase>((ref) {
  throw UnimplementedError('alongSupabaseProvider must be overridden at startup');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(alongSupabaseProvider));
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(ref.watch(alongSupabaseProvider));
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.watch(alongSupabaseProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(alongSupabaseProvider));
});

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository(ref.watch(alongSupabaseProvider));
});

final alongDatabaseProvider = Provider<AlongDatabase>((ref) {
  throw UnimplementedError(
    'alongDatabaseProvider must be overridden at startup',
  );
});

final driverOnboardingPreferencesProvider =
    Provider<DriverOnboardingPreferences>((ref) {
  return DriverOnboardingPreferences();
});

final driverOnboardingStepProvider = FutureProvider<DriverOnboardingStep>(
  (ref) async {
    return ref.watch(driverOnboardingPreferencesProvider).currentStep();
  },
);

List<Override> buildProviderOverrides({
  required AppConfig config,
  required AlongSupabase supabase,
  AlongDatabase? database,
  DriverOnboardingPreferences? onboardingPreferences,
}) {
  return [
    appConfigProvider.overrideWithValue(config),
    alongSupabaseProvider.overrideWithValue(supabase),
    alongDatabaseProvider.overrideWithValue(
      database ?? AlongDatabase.memory(),
    ),
    if (onboardingPreferences != null)
      driverOnboardingPreferencesProvider.overrideWithValue(
        onboardingPreferences,
      ),
  ];
}
