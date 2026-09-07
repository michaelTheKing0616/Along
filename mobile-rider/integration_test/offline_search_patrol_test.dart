import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';
import 'package:patrol/patrol.dart';

/// Patrol offline search flow — skipped unless PATROL_HAS_EMULATOR (doc 07 §4).
void main() {
  const skipPatrol = bool.fromEnvironment(
    'PATROL_HAS_EMULATOR',
    defaultValue: false,
  );

  patrolTest(
    'offline search shows cached graph results with stale badge',
    ($) async {
      final db = AlongDatabase.memory();
      final graphStore = GraphCacheStore(
        db,
        _OfflineSupabase(),
        RoutesRepository(_OfflineSupabase()),
      );
      await graphStore.upsert(
        cityId: 'b1000000-0000-4000-8000-000000000001',
        graphVersion: 'v1',
        payload: {
          'parks': [
            {
              'id': 'p1',
              'name': 'Wuse Market',
              'lat': 9.0765,
              'lng': 7.3986,
            },
          ],
          'stages': [],
          'legs': [],
        },
      );

      final container = ProviderContainer(
        overrides: [
          ...buildProviderOverrides(
            config: const AppConfig(
              flavor: 'dev',
              supabaseUrl: 'https://test.supabase.co',
              supabaseAnonKey: 'test-key',
            ),
            supabase: _OfflineSupabase(),
            ambientChannel: FakeAmbientChannel(),
            recentPlacesStore: FakeRecentPlacesStore(),
            database: db,
            networkProbe: FakeNetworkConditionsProbe(
              const NetworkConditionsSnapshot(offline: true),
            ),
          ),
          graphCacheStoreProvider.overrideWithValue(graphStore),
        ],
      );

      container.read(searchControllerProvider.notifier).onQueryChanged('wuse');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final search = container.read(searchControllerProvider);
      expect(search.isStaleResults, isTrue);
      expect(search.results.single.name, 'Wuse Market');
      container.dispose();
    },
    skip: skipPatrol ? null : true,
  );
}

class _OfflineSupabase implements AlongSupabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('offline');
}
