import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/transfer/active_journey_monitor.dart';
import 'package:mobile_rider/features/transfer/presentation/transfer_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('R-14 transfer auto-navigation', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleRequestTripResponse(
          tripId: 'trip-leg-1',
          expiresAt: '2026-09-05T16:05:00Z',
        ),
        journeyRows: [
          {
            'id': 'journey-1',
            'status': 'active',
            'current_trip_sequence': 1,
            'city_id': 'b1000000-0000-4000-8000-000000000001',
            'plan_snapshot': {
              'candidate_id': 'cand-multi-1',
              'legs': [
                {
                  'leg_index': 0,
                  'mode': {'code': 'car', 'label': 'Car'},
                  'board': {
                    'name': 'Lugbe Park',
                    'location': {'lat': 9.01, 'lng': 7.40},
                  },
                  'alight': {'name': 'Berger Park'},
                },
                {
                  'leg_index': 1,
                  'mode': {'code': 'keke', 'label': 'Keke'},
                  'board': {
                    'name': 'Berger Park',
                    'location': {'lat': 9.03, 'lng': 7.42},
                  },
                  'alight': {'name': 'Area 1 Park'},
                  'wait_s': 120,
                  'supply': {'vehicles_bucket': '2-3'},
                },
              ],
            },
          },
        ],
        journeyTransferWalkRows: [
          {
            'journey_id': 'journey-1',
            'after_trip_sequence': 1,
            'directions': sampleWalkingDirectionsPayload(),
          },
        ],
      );

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
          wayfindingTts: FakeWayfindingTts(),
        ),
      );

      router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                const Scaffold(body: Text('home_stub')),
          ),
          GoRoute(
            path: AppRoutes.transfer,
            builder: (context, state) {
              final args = state.extra as TransferRouteArgs;
              return TransferScreen(args: args);
            },
          ),
        ],
      );

      container.listen(activeJourneyMonitorProvider, (previous, next) {
        final args = next.transferNavigation;
        if (args == null) return;
        if (previous?.transferNavigation == args) return;
        if (router.state.matchedLocation == AppRoutes.transfer) return;
        router.push(AppRoutes.transfer, extra: args);
      });
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('presents R-14 when journey status becomes transfer', (tester) async {
      final trip = DomainMappers.tripFromDto(
        TripView.fromJson(fakeSupabase.requestTripResponse!),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pump();

      container.read(activeJourneyMonitorProvider.notifier).trackFromTrip(
            trip,
            candidateId: 'cand-multi-1',
          );

      fakeSupabase.journeyRows = [
        {
          ...fakeSupabase.journeyRows.first,
          'status': 'transfer',
          'current_trip_sequence': 2,
        },
      ];

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const Key('transfer_request_next_leg')).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(router.state.matchedLocation, AppRoutes.transfer);
      expect(find.byKey(const Key('transfer_request_next_leg')), findsOneWidget);

      container.read(activeJourneyMonitorProvider.notifier).stopTracking();
    });
  });
}
