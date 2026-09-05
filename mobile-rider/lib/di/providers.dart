import 'dart:io';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';
import 'package:path_provider/path_provider.dart';

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

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository(ref.watch(alongSupabaseProvider));
});

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(ref.watch(alongSupabaseProvider));
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository(ref.watch(alongSupabaseProvider));
});

final alongDatabaseProvider = Provider<AlongDatabase>((ref) {
  throw UnimplementedError(
    'alongDatabaseProvider must be overridden at startup',
  );
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(alongSupabaseProvider));
});

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository(
    ref.watch(alongSupabaseProvider),
    ref.watch(alongDatabaseProvider),
  );
});

final ambientChannelProvider = Provider<AmbientChannel>((ref) {
  throw UnimplementedError(
    'ambientChannelProvider must be overridden at startup',
  );
});

final recentPlacesStoreProvider = Provider<RecentPlacesReader>((ref) {
  return RecentPlacesStore();
});

final locationStreamSourceProvider = Provider<LocationStreamSource>((ref) {
  return GeolocatorLocationSource();
});

final clockProvider = Provider<Clock>((ref) => Clock.system);

final mapCacheDirectoryProvider = FutureProvider<Directory>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Directory('${dir.path}/map_cache');
});

final onboardingPreferencesProvider = Provider<OnboardingPreferences>((ref) {
  return OnboardingPreferences();
});

/// Test overrides bundle.
List<Override> buildProviderOverrides({
  required AppConfig config,
  required AlongSupabase supabase,
  required AmbientChannel ambientChannel,
  AlongDatabase? database,
  OnboardingPreferences? onboardingPreferences,
  LocationStreamSource? locationStreamSource,
  RecentPlacesReader? recentPlacesStore,
  Clock? clock,
}) {
  return [
    appConfigProvider.overrideWithValue(config),
    alongSupabaseProvider.overrideWithValue(supabase),
    ambientChannelProvider.overrideWithValue(ambientChannel),
    alongDatabaseProvider.overrideWithValue(
      database ?? AlongDatabase.memory(),
    ),
    if (onboardingPreferences != null)
      onboardingPreferencesProvider.overrideWithValue(onboardingPreferences),
    if (locationStreamSource != null)
      locationStreamSourceProvider.overrideWithValue(locationStreamSource),
    if (recentPlacesStore != null)
      recentPlacesStoreProvider.overrideWithValue(recentPlacesStore),
    if (clock != null) clockProvider.overrideWithValue(clock),
  ];
}
