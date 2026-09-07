import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/offline/stale_badge.dart';
import 'package:mobile_rider/features/search/presentation/destination_search_panel.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('P7-B-01 offline cache with stale badge', () {
    testWidgets('trip options shows stale badge from plan_cache when offline',
        (tester) async {
      final db = AlongDatabase.memory();
      final cacheStore = PlanCacheStore(db);
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        planTripError: Exception('offline'),
      );

      final planner = PlannerRepository(fakeSupabase, planCache: cacheStore);
      await cacheStore.write(
        cacheKey: planCacheKey(
          origin: const GeoPoint(lat: 9.0765, lng: 7.3986),
          destination: const GeoPoint(lat: 9.08, lng: 7.45),
          filters: {
            'women_only': false,
            'load': {'flagged': false},
            'modes': null,
          },
        ),
        planTripPayload:
            samplePlanTripResponse()['data'] as Map<String, dynamic>,
      );

      final probe = FakeNetworkConditionsProbe(
        const NetworkConditionsSnapshot(offline: true),
      );

      final container = ProviderContainer(
        overrides: [
          ...buildProviderOverrides(
            config: const AppConfig(
              flavor: 'dev',
              supabaseUrl: 'https://test.supabase.co',
              supabaseAnonKey: 'test-key',
            ),
            supabase: fakeSupabase,
            ambientChannel: FakeAmbientChannel(),
            recentPlacesStore: FakeRecentPlacesStore(),
            database: db,
            networkProbe: probe,
          ),
          plannerRepositoryProvider.overrideWithValue(planner),
        ],
      );

      container.read(tripPlanSessionProvider.notifier).setSession(
            const TripPlanSession(
              origin: GeoPoint(lat: 9.0765, lng: 7.3986),
              destination: GeoPoint(lat: 9.08, lng: 7.45),
              destinationLabel: 'Area 1 Park',
            ),
          );

      addTearDown(() {
        fakeSupabase.dispose();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TripOptionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stale_badge')), findsOneWidget);
      expect(find.byKey(const Key('option_card_cand-direct-1')), findsOneWidget);
      expect(find.textContaining('Cached'), findsOneWidget);
    });

    testWidgets('offline search shows cached graph places with stale badge',
        (tester) async {
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

      final probe = FakeNetworkConditionsProbe(
        const NetworkConditionsSnapshot(offline: true),
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
            networkProbe: probe,
          ),
          graphCacheStoreProvider.overrideWithValue(graphStore),
        ],
      );

      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DestinationSearchPanel(
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      container.read(searchControllerProvider);
      await tester.pumpAndSettle();

      container.read(searchControllerProvider.notifier).onQueryChanged('wuse');
      await tester.pumpAndSettle();

      expect(find.text('Wuse Market'), findsOneWidget);
      expect(find.byKey(const Key('stale_badge')), findsOneWidget);
    });
  });

  group('LowDataMode', () {
    testWidgets('AvatarGate skips network image when loadAvatars is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarGate(
              loadAvatars: false,
              initials: 'MO',
              imageUrl: 'https://example.com/a.jpg',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('avatar_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('avatar_image')), findsNothing);
    });
  });
}

class _OfflineSupabase implements AlongSupabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('offline');
}
