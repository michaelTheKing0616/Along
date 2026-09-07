import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const testConfig = AppConfig(
    flavor: 'dev',
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
    batteryGuardPercent: 15,
  );

  group('P9-B-01 city switching', () {
    const abujaId = 'b1000000-0000-4000-8000-000000000001';
    const zariaId = '0a000000-0000-4000-8000-000000000001';

    test('switchCity persists Abuja then recenters to Zaria-Test', () async {
      final fake = FakeAlongSupabase(
        signedInUser: User(
          id: 'test-driver-id',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: testConfig,
          supabase: fake,
          database: AlongDatabase.memory(),
          locationStreamSource: FakeLocationStreamSource(
            permissionGranted: true,
            fixedSamples: [
              LocationSample(
                point: const GeoPoint(lat: 9.05, lng: 7.49),
                accuracyM: 8,
                recordedAt: DateTime.utc(2026, 9, 5),
              ),
            ],
          ),
        ),
      );
      addTearDown(container.dispose);

      await _pumpUntilReady(container);

      await container.read(driverHomeControllerProvider.notifier).switchCity(abujaId);
      final abujaState = container.read(driverHomeControllerProvider);

      expect(abujaState.cityId, abujaId);
      expect(abujaState.citySlug, 'abuja');
      expect(abujaState.cityName, 'Abuja');
      expect(abujaState.mapCenter!.lat, closeTo(9.057, 0.001));
      expect(abujaState.mapCenter!.lng, closeTo(7.495, 0.001));

      await container.read(driverHomeControllerProvider.notifier).switchCity(zariaId);
      final zariaState = container.read(driverHomeControllerProvider);

      expect(zariaState.cityId, zariaId);
      expect(zariaState.citySlug, 'zaria-test');
      expect(zariaState.cityName, 'Zaria-Test');
      expect(zariaState.mapCenter!.lat, closeTo(11.066, 0.001));
      expect(zariaState.mapCenter!.lng, closeTo(7.702, 0.001));
      expect(
        fake.rpcCalls.where((call) => call.$1 == 'set_driver_city').length,
        2,
      );
    });
  });
}

Future<void> _pumpUntilReady(ProviderContainer container) async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = container.read(driverHomeControllerProvider);
    if (state.movingPingIntervalS == 4 &&
        state.isVerified &&
        state.userLocation != null) {
      return;
    }
  }
}
