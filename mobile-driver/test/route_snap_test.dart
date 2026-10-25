import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/routes/presentation/draw_route_controller.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('DrawRouteController snap', () {
    late FakeAlongSupabase fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeAlongSupabase(
        signedInUser: User(
          id: 'test-driver-id',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      fake.placesSearchResults = [
        {
          'kind': 'stage',
          'id': 'berger-stage',
          'name': 'Berger Junction',
          'area': 'Abuja',
          'location': {'lat': 9.0765, 'lng': 7.3986},
          'distance_m': 12,
        },
      ];

      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fake,
          database: AlongDatabase.memory(),
        ),
      );
    });

    tearDown(() {
      fake.dispose();
      container.dispose();
    });

    test('local snap matches stage within radius', () {
      final controller = container.read(
        drawRouteControllerProvider(const DrawRouteArgs()).notifier,
      );

      final stop = controller.snapStopLocally(
        tap: const GeoPoint(lat: 9.0765, lng: 7.3986),
        stageLocation: const GeoPoint(lat: 9.0765, lng: 7.3986),
        stageId: 'berger-stage',
        stageName: 'Berger Junction',
      );

      expect(stop.matchedStageName, 'Berger Junction');
      expect(stop.isNewStop, isFalse);
    });

    test('addStopAt snaps to existing stage from places search', () async {
      const args = DrawRouteArgs();
      final keepAlive = container.listen(drawRouteControllerProvider(args), (_, __) {});

      await pumpUntilReady(container);

      final controller = container.read(drawRouteControllerProvider(args).notifier);
      await controller.addStopAt(const GeoPoint(lat: 9.0765, lng: 7.3986));

      final state = container.read(drawRouteControllerProvider(args));
      expect(state.stops.single.matchedStageName, 'Berger Junction');
      expect(state.stops.single.isNewStop, isFalse);

      keepAlive.close();
    });
  });
}

Future<void> pumpUntilReady(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
    final state = container.read(drawRouteControllerProvider(const DrawRouteArgs()));
    if (state.cityId != null) return;
  }
}
