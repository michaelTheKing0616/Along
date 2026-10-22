import 'dart:async';
import 'dart:io';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/offline/low_data_providers.dart';
import 'package:mobile_rider/features/onboarding/data/onboarding_preferences.dart';
import 'package:mobile_rider/features/onboarding/domain/phone_number_formatter.dart';
import 'package:mobile_rider/features/rider_prefs/rider_prefs_store.dart';
import 'package:along_map/along_map.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/testing/fakes/fake_negotiation_channel.dart';
import 'package:path_provider/path_provider.dart';

/// Runtime configuration (flavour, Supabase URL, Sentry DSN).
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden at startup');
});

/// Supabase gateway — overridden in tests.
final alongSupabaseProvider = Provider<AlongSupabase>((ref) {
  throw UnimplementedError(
    'alongSupabaseProvider must be overridden at startup',
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(alongSupabaseProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(alongSupabaseProvider));
});

final phoneFormatterProvider = FutureProvider<PhoneNumberFormatter>((
  ref,
) async {
  try {
    final country = await ref
        .read(catalogRepositoryProvider)
        .defaultActiveCountry()
        .timeout(const Duration(seconds: 5));
    return PhoneNumberFormatter(phonePrefix: country.phonePrefix);
  } catch (_) {
    return const PhoneNumberFormatter(phonePrefix: '+234');
  }
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
  return PlannerRepository(
    ref.watch(alongSupabaseProvider),
    planCache: ref.watch(planCacheStoreProvider),
  );
});

final planCacheStoreProvider = Provider<PlanCacheStore>((ref) {
  return PlanCacheStore(ref.watch(alongDatabaseProvider));
});

final graphCacheStoreProvider = Provider<GraphCacheStore>((ref) {
  return GraphCacheStore(
    ref.watch(alongDatabaseProvider),
    ref.watch(alongSupabaseProvider),
    RoutesRepository(ref.watch(alongSupabaseProvider)),
  );
});

final corridorTilePrecacheProvider = Provider<CorridorTilePrecacheService>((
  ref,
) {
  throw UnimplementedError(
    'corridorTilePrecacheProvider must be overridden at startup',
  );
});

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository(
    ref.watch(alongSupabaseProvider),
    ref.watch(plannerRepositoryProvider),
  );
});

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository(
    ref.watch(alongSupabaseProvider),
    ref.watch(alongDatabaseProvider),
  );
});

final negotiationRepositoryProvider = Provider<NegotiationRepository>((ref) {
  return NegotiationRepository(ref.watch(alongSupabaseProvider));
});

final negotiationChannelProvider = Provider<NegotiationChannel>((ref) {
  throw UnimplementedError(
    'negotiationChannelProvider must be overridden at startup',
  );
});

final walkingDirectionsRepositoryProvider =
    Provider<WalkingDirectionsRepository>((ref) {
      return WalkingDirectionsRepository(
        ref.watch(alongSupabaseProvider),
        ref.watch(alongDatabaseProvider),
      );
    });

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(
    ref.watch(alongSupabaseProvider),
    ref.watch(walkingDirectionsRepositoryProvider),
  );
});

final seatRepositoryProvider = Provider<SeatRepository>((ref) {
  return SeatRepository(ref.watch(alongSupabaseProvider));
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(ref.watch(alongSupabaseProvider));
});

final emergencyContactStoreProvider = Provider<EmergencyContactStore>((ref) {
  return EmergencyContactStore(ref.watch(alongDatabaseProvider));
});

final sosOutboxProvider = Provider<SosOutbox>((ref) {
  return SosOutbox(PendingActionQueue(ref.watch(alongDatabaseProvider)));
});

final sosRaiseCoordinatorProvider = Provider<SosRaiseCoordinator>((ref) {
  return SosRaiseCoordinator(
    repository: ref.watch(safetyRepositoryProvider),
    outbox: ref.watch(sosOutboxProvider),
  );
});

final riderProfileRepositoryProvider = Provider<RiderProfileRepository>((ref) {
  return RiderProfileRepository(ref.watch(alongSupabaseProvider));
});

final riderPrefsStoreProvider = Provider<RiderPrefsStore>((ref) {
  return RiderPrefsStore(ref.watch(alongDatabaseProvider));
});

final wayfindingTtsProvider = Provider<WayfindingTts>((ref) {
  return FlutterWayfindingTts();
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
  NegotiationChannel? negotiationChannel,
  AlongDatabase? database,
  NetworkConditionsProbe? networkProbe,
  CorridorTilePrecacheService? corridorTilePrecache,
  OnboardingPreferences? onboardingPreferences,
  LocationStreamSource? locationStreamSource,
  RecentPlacesReader? recentPlacesStore,
  Clock? clock,
  WayfindingTts? wayfindingTts,
}) {
  return [
    appConfigProvider.overrideWithValue(config),
    alongSupabaseProvider.overrideWithValue(supabase),
    ambientChannelProvider.overrideWithValue(ambientChannel),
    negotiationChannelProvider.overrideWithValue(
      negotiationChannel ?? FakeNegotiationChannel(),
    ),
    alongDatabaseProvider.overrideWithValue(database ?? AlongDatabase.memory()),
    networkConditionsProbeProvider.overrideWithValue(
      networkProbe ??
          FakeNetworkConditionsProbe(const NetworkConditionsSnapshot()),
    ),
    if (corridorTilePrecache != null)
      corridorTilePrecacheProvider.overrideWithValue(corridorTilePrecache)
    else
      corridorTilePrecacheProvider.overrideWithValue(
        CorridorTilePrecacheService(
          cacheDirectory: Directory.systemTemp.createTempSync(
            'along_map_cache',
          ),
        ),
      ),
    if (onboardingPreferences != null)
      onboardingPreferencesProvider.overrideWithValue(onboardingPreferences),
    if (locationStreamSource != null)
      locationStreamSourceProvider.overrideWithValue(locationStreamSource),
    if (recentPlacesStore != null)
      recentPlacesStoreProvider.overrideWithValue(recentPlacesStore),
    if (clock != null) clockProvider.overrideWithValue(clock),
    if (wayfindingTts != null)
      wayfindingTtsProvider.overrideWithValue(wayfindingTts),
  ];
}
