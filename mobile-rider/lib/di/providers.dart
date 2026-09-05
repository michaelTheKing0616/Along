import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';

/// Runtime configuration (flavour, Supabase URL, Sentry DSN).
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden at startup');
});

/// Supabase gateway — overridden in tests.
final alongSupabaseProvider = Provider<AlongSupabase>((ref) {
  throw UnimplementedError('alongSupabaseProvider must be overridden at startup');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(alongSupabaseProvider));
});

final onboardingPreferencesProvider = Provider<OnboardingPreferences>((ref) {
  return OnboardingPreferences();
});

/// Test overrides bundle.
List<Override> buildProviderOverrides({
  required AppConfig config,
  required AlongSupabase supabase,
  OnboardingPreferences? onboardingPreferences,
}) {
  return [
    appConfigProvider.overrideWithValue(config),
    alongSupabaseProvider.overrideWithValue(supabase),
    if (onboardingPreferences != null)
      onboardingPreferencesProvider.overrideWithValue(onboardingPreferences),
  ];
}
