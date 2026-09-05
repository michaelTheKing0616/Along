import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_location/along_location.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    parkPickerRadiusM: 500,
  );

  ProviderContainer buildContainer({
    required FakeAlongSupabase fake,
    FakeLocationStreamSource? location,
    FakeBatteryMonitor? battery,
    InMemoryDriverForegroundNotifier? foreground,
  }) {
    final container = ProviderContainer(
      overrides: buildProviderOverrides(
        config: testConfig,
        supabase: fake,
        database: AlongDatabase.memory(),
        locationStreamSource: location ??
            FakeLocationStreamSource(
              permissionGranted: true,
              fixedSamples: [
                LocationSample(
                  point: const GeoPoint(lat: 9.05, lng: 7.49),
                  accuracyM: 8,
                  recordedAt: DateTime.utc(2026, 9, 5),
                  headingDegrees: 45,
                  speedMps: 2,
                ),
              ],
            ),
        batteryMonitor: battery ??
            FakeBatteryMonitor(
              const BatterySnapshot(levelPercent: 80, isCharging: false),
            ),
        foregroundNotifier: foreground ?? InMemoryDriverForegroundNotifier(),
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  test('going offline calls set_presence offline immediately', () async {
    final fake = FakeAlongSupabase(
      signedInUser: User(
        id: 'test-driver-id',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    Map<String, dynamic>? captured;
    fake.onSetPresence = (params) {
      if (params['p_status'] == 'offline') {
        captured = params;
      }
    };

    final container = buildContainer(fake: fake);
    final controller = container.read(driverHomeControllerProvider.notifier);

    await pumpUntilReady(container);

    await controller.setStatus(DriverStatus.roamingAvailable);
    await controller.setStatus(DriverStatus.offline);

    expect(captured?['p_status'], 'offline');
  });

  test('battery guard doubles ping interval', () async {
    final fake = FakeAlongSupabase(
      signedInUser: User(
        id: 'test-driver-id',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    final battery = FakeBatteryMonitor(
      const BatterySnapshot(levelPercent: 10, isCharging: false),
    );

    final container = buildContainer(fake: fake, battery: battery);
    final scheduler = container.read(presencePingSchedulerProvider);

    await scheduler.start(
      movingInterval: const Duration(milliseconds: 100),
      stillInterval: const Duration(milliseconds: 100),
      seatsAvailable: 4,
    );

    expect(scheduler.batteryGuardActive, isTrue);
    expect(scheduler.effectiveInterval, const Duration(milliseconds: 200));

    await scheduler.stop();
  });

  test('foreground notification starts when online', () async {
    final fake = FakeAlongSupabase(
      signedInUser: User(
        id: 'test-driver-id',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    final foreground = InMemoryDriverForegroundNotifier();

    final container = buildContainer(fake: fake, foreground: foreground);
    final controller = container.read(driverHomeControllerProvider.notifier);

    await pumpUntilReady(container);

    await controller.setStatus(DriverStatus.roamingAvailable);

    expect(foreground.visible, isTrue);
    expect(
      container.read(driverHomeControllerProvider).foregroundVisible,
      isTrue,
    );

    await controller.setStatus(DriverStatus.offline);
    expect(foreground.visible, isFalse);
  });
}

Future<void> pumpUntilReady(ProviderContainer container) async {
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
