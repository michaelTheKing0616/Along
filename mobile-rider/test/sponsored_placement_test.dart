import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/placements/presentation/sponsored_placement_slot.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('P8-B-01 sponsored placement slots (FM39)', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() async {
      fakeSupabase = FakeAlongSupabase(
        configRows: [
          ...defaultTestConfigRows(),
          {
            'key': 'placements.enabled',
            'scope_type': 'global',
            'scope_id': '*',
            'value': 'true',
          },
        ],
        planTripResponse: samplePlanTripResponse(),
        requestTripResponse: sampleRequestTripResponse(),
        sponsoredPlacementsResponse: [
          {
            'id': '0f510000-0000-4000-8000-000000000001',
            'context_type': 'destination',
            'target_reference': 's-area1',
            'advertiser': 'Fixture',
            'content': {'headline': 'Partner offer near Area 1'},
          },
        ],
        corridorRows: [
          {
            'id': '0c010000-0000-4000-8000-000000000001',
            'city_id': 'b1000000-0000-4000-8000-000000000001',
            'slug': 'lugbe-area1',
            'name': 'Lugbe — Area 1',
          },
        ],
        tripRows: [
          {
            'id': 'trip-hist-1',
            'status': 'completed',
            'mode_code': 'keke',
            'boarding_name': 'Lugbe Park',
            'alighting_name': 'Area 1 Park',
            'fare_shown': '450.00',
            'fare_currency': 'NGN',
            'ended_at': '2026-09-05T15:00:00Z',
          },
        ],
        riderRow: {
          'id': 'test-user-id',
          'home_city_id': 'b1000000-0000-4000-8000-000000000001',
          'wayfinding_mode': 'text',
          'saved_sort': 'recommended',
          'women_only_pref': false,
        },
      );
      await fakeSupabase.verifyOtp(phone: '+2348000000001', token: '123456');
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          recentPlacesStore: FakeRecentPlacesStore(),
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('R-07 shows Sponsored slot with contextual RPC only', (tester) async {
      container.read(tripPlanSessionProvider.notifier).setSession(
            TripPlanSession(
              origin: const GeoPoint(lat: 9.0765, lng: 7.3986),
              destination: const GeoPoint(lat: 9.08, lng: 7.45),
              destinationLabel: 'Area 1 Park',
              placementContext: const PlacementContext(
                type: PlacementContextType.park,
                targetReference: '0a020000-0000-4000-8000-000000000001',
              ),
            ),
          );

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

      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Partner offer near Area 1'), findsOneWidget);

      final resolveCalls = fakeSupabase.rpcCalls
          .where((call) => call.$1 == 'resolve_sponsored_placements');
      expect(resolveCalls, isNotEmpty);
      for (final (_, params) in resolveCalls) {
        PlacementsRepository.assertNoPersonalIdentifiers(params);
        expect(params.containsKey('p_rider_id'), isFalse);
        expect(params.containsKey('p_trip_id'), isFalse);
        expect(params.containsKey('p_query_id'), isFalse);
      }
    });

    testWidgets('R-07 hides slot when placements.enabled is false', (tester) async {
      fakeSupabase.configRows = defaultTestConfigRows();
      container.read(tripPlanSessionProvider.notifier).setSession(
            const TripPlanSession(
              origin: GeoPoint(lat: 9.0765, lng: 7.3986),
              destination: GeoPoint(lat: 9.08, lng: 7.45),
              destinationLabel: 'Area 1 Park',
              placementContext: PlacementContext(
                type: PlacementContextType.park,
                targetReference: '0a020000-0000-4000-8000-000000000001',
              ),
            ),
          );

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

      expect(find.text('Sponsored'), findsNothing);
      expect(
        fakeSupabase.rpcCalls.where((c) => c.$1 == 'resolve_sponsored_placements'),
        isEmpty,
      );
    });

    testWidgets('R-22 shows Sponsored slot with corridor context only', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TripsHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sponsored'), findsOneWidget);

      final resolveCalls = fakeSupabase.rpcCalls
          .where((call) => call.$1 == 'resolve_sponsored_placements');
      expect(resolveCalls, isNotEmpty);
      final params = resolveCalls.first.$2;
      PlacementsRepository.assertNoPersonalIdentifiers(params);
      expect(params['p_context_type'], 'corridor');
      expect(params.containsKey('p_trip_id'), isFalse);
    });
  });

  testWidgets('SponsoredPlacementSlot records impression on display', (tester) async {
    final fakeSupabase = FakeAlongSupabase(
      configRows: defaultTestConfigRows(),
    );
    final container = ProviderContainer(
      overrides: buildProviderOverrides(
        config: const AppConfig(
          flavor: 'dev',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        supabase: fakeSupabase,
        ambientChannel: FakeAmbientChannel(),
      ),
    );
    addTearDown(container.dispose);
    addTearDown(fakeSupabase.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SponsoredPlacementSlot(
              placements: const [
                SponsoredPlacement(
                  id: '0f510000-0000-4000-8000-000000000001',
                  contextType: PlacementContextType.park,
                  targetReference: '0a020000-0000-4000-8000-000000000001',
                  advertiser: 'Fixture',
                  content: {'headline': 'Headline'},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      fakeSupabase.rpcCalls.where((c) => c.$1 == 'record_placement_counter'),
      isNotEmpty,
    );
    final counterParams = fakeSupabase.rpcCalls
        .firstWhere((c) => c.$1 == 'record_placement_counter')
        .$2;
    PlacementsRepository.assertNoPersonalIdentifiers(counterParams);
    expect(counterParams['p_metric'], 'impression');
  });
}
