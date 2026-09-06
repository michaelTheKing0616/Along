import 'dart:io';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_notifications/along_notifications.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/features/negotiation/presentation/driver_pricing_controller.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_driver/features/payments/domain/share_image_port.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_controller.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';
import 'package:mobile_driver/testing/fakes/fake_negotiation_channel.dart';
import 'package:path_provider/path_provider.dart';

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

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(ref.watch(alongSupabaseProvider));
});

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository(
    ref.watch(alongSupabaseProvider),
    ref.watch(alongDatabaseProvider),
  );
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(ref.watch(alongSupabaseProvider));
});

final negotiationRepositoryProvider = Provider<NegotiationRepository>((ref) {
  return NegotiationRepository(ref.watch(alongSupabaseProvider));
});

final negotiationChannelProvider = Provider<NegotiationChannel>((ref) {
  throw UnimplementedError(
    'negotiationChannelProvider must be overridden at startup',
  );
});

final driverChannelProvider = Provider<DriverChannel>((ref) {
  throw UnimplementedError(
    'driverChannelProvider must be overridden at startup',
  );
});

final pushServiceProvider = Provider<PushService>((ref) {
  throw UnimplementedError(
    'pushServiceProvider must be overridden at startup',
  );
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository(ref.watch(alongSupabaseProvider));
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

final locationStreamSourceProvider = Provider<LocationStreamSource>((ref) {
  return GeolocatorLocationSource();
});

final batteryMonitorProvider = Provider<BatteryMonitor>((ref) {
  return DeviceBatteryMonitor();
});

final driverForegroundNotifierProvider = Provider<DriverForegroundNotifier>(
  (ref) {
    return InMemoryDriverForegroundNotifier();
  },
);

final presencePingSchedulerProvider = Provider<PresencePingScheduler>((ref) {
  final config = ref.watch(appConfigProvider);
  return PresencePingScheduler(
    locationSource: ref.watch(locationStreamSourceProvider),
    batteryMonitor: ref.watch(batteryMonitorProvider),
    batteryGuardPercent: config.batteryGuardPercent,
    onPing: (sample) async {
      final home = ref.read(driverHomeControllerProvider);
      await ref.read(presenceRepositoryProvider).presencePing(
            PresencePingRequest(
              p_location: Point(
                lat: sample.point.lat,
                lng: sample.point.lng,
              ),
              p_heading: sample.headingDegrees ?? 0,
              p_speed_mps: sample.speedMps ?? 0,
              p_accuracy_m: sample.accuracyM,
              p_seats_available: home.seatsAvailable,
            ),
          );
      await ref
          .read(driverHomeControllerProvider.notifier)
          .refreshDemandAt(sample.point);
    },
  );
});

final driverPresenceSessionProvider = Provider<DriverPresenceSession>((ref) {
  return DriverPresenceSession(
    scheduler: ref.watch(presencePingSchedulerProvider),
    foregroundNotifier: ref.watch(driverForegroundNotifierProvider),
  );
});

final clockProvider = Provider<Clock>((ref) => Clock.system);

final mapCacheDirectoryProvider = FutureProvider<Directory>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Directory('${dir.path}/map_cache');
});

List<Override> buildProviderOverrides({
  required AppConfig config,
  required AlongSupabase supabase,
  AlongDatabase? database,
  DriverOnboardingPreferences? onboardingPreferences,
  LocationStreamSource? locationStreamSource,
  BatteryMonitor? batteryMonitor,
  DriverForegroundNotifier? foregroundNotifier,
  Clock? clock,
  DriverChannel? driverChannel,
  PushService? pushService,
  NegotiationChannel? negotiationChannel,
  QrScannerPort? qrScanner,
  ShareImagePort? shareImagePort,
}) {
  return [
    appConfigProvider.overrideWithValue(config),
    alongSupabaseProvider.overrideWithValue(supabase),
    alongDatabaseProvider.overrideWithValue(
      database ?? AlongDatabase.memory(),
    ),
    driverChannelProvider.overrideWithValue(
      driverChannel ?? FakeDriverChannel(),
    ),
    negotiationChannelProvider.overrideWithValue(
      negotiationChannel ?? FakeNegotiationChannel(),
    ),
    pushServiceProvider.overrideWithValue(
      pushService ?? StubPushService(),
    ),
    if (onboardingPreferences != null)
      driverOnboardingPreferencesProvider.overrideWithValue(
        onboardingPreferences,
      ),
    if (locationStreamSource != null)
      locationStreamSourceProvider.overrideWithValue(locationStreamSource),
    if (batteryMonitor != null)
      batteryMonitorProvider.overrideWithValue(batteryMonitor),
    if (foregroundNotifier != null)
      driverForegroundNotifierProvider.overrideWithValue(foregroundNotifier),
    if (clock != null) clockProvider.overrideWithValue(clock),
    if (qrScanner != null)
      qrScannerProvider.overrideWithValue(qrScanner),
    if (shareImagePort != null)
      shareImageProvider.overrideWithValue(shareImagePort),
  ];
}
