import 'package:along_core/along_core.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

void main() {
  group('R-05 ambient realtime subscription', () {
    late FakeAlongSupabase fakeSupabase;
    late FakeAmbientChannel fakeAmbient;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        ambientCells: [sampleAmbientCell()],
      );
      fakeAmbient = FakeAmbientChannel();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          recentPlacesStore: FakeRecentPlacesStore(),
          locationStreamSource: FakeLocationStreamSource(
            permissionGranted: true,
            fixedSamples: [
              LocationSample(
                point: const GeoPoint(lat: 9.0765, lng: 7.3986),
                accuracyM: 10,
                recordedAt: DateTime.utc(2026, 1, 1),
              ),
            ],
          ),
          clock: Clock.fixed(DateTime.utc(2026, 1, 1, 0, 1, 0)),
          ambientChannel: fakeAmbient,
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      fakeAmbient.dispose();
      container.dispose();
    });

    test('subscribes to ambient Broadcast channel on location grant', () async {
      container.read(homeControllerProvider);
      await _waitFor(() => fakeAmbient.subscribedCitySlug != null);

      expect(fakeAmbient.subscribedCitySlug, 'abuja');
      expect(fakeAmbient.subscribedGeohash5, isNotEmpty);
    });

    test('updates ambient cells from Broadcast without periodic RPC poll', () async {
      fakeSupabase.ambientCells = const [];
      container.read(homeControllerProvider);
      await _waitFor(() => fakeAmbient.subscribedCitySlug != null);

      fakeAmbient.emitCells(
        asOf: DateTime.utc(2026, 1, 1, 0, 1, 0).toIso8601String(),
        cells: [sampleAmbientCell(countBucket: '6+')],
      );
      await _waitFor(
        () => container.read(homeControllerProvider).ambientCells.isNotEmpty,
      );

      final state = container.read(homeControllerProvider);
      expect(state.ambientCells, isNotEmpty);
      expect(state.ambientCells.single.bucket, 10);
    });
  });
}

Future<void> _waitFor(bool Function() predicate, {int maxMs = 2000}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('Timed out waiting for condition');
}
