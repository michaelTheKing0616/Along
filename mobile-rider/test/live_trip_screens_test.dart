import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/meet_vehicle_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/wayfinding/presentation/wayfinding_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';

import 'support/trip_options_fixtures.dart';

Widget _harness({
  required ProviderContainer container,
  required Widget child,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void _stopLiveTripPoll(ProviderContainer container, TripSummary trip) {
  container
      .read(liveTripControllerFamilyProvider(LiveTripArgs(
        tripId: trip.tripId,
        initialTrip: trip,
      )).notifier)
      .stopPolling();
}

Future<void> _seedNaMePairing(AlongDatabase db, String tripId) async {
  await db.into(db.kvStore).insertOnConflictUpdate(
        KvStoreCompanion.insert(
          key: 'na_me:$tripId',
          value: jsonEncode({
            'color_token': 'color.naMe.green',
            'shape': 'diamond',
            'label': 'Green Diamond',
            'trip_id': tripId,
          }),
        ),
      );
}

void main() {
  group('R-11 meet vehicle', () {
    late FakeAlongSupabase fakeSupabase;
    late AlongDatabase database;
    late ProviderContainer container;
    late TripSummary trip;

    setUp(() {
      trip = tripSummaryFromFixture(sampleAcceptedTripResponse(heading: 90));
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleAcceptedTripResponse(heading: 90),
      );
      database = AlongDatabase.memory();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          database: database,
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
    });

    tearDown(() {
      _stopLiveTripPoll(container, trip);
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('shows plate and directional arrow from live heading', (tester) async {
      await tester.pumpWidget(
        _harness(container: container, child: MeetVehicleScreen(trip: trip)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('meet_vehicle_plate')), findsOneWidget);
      expect(find.text('ABC-123-XY'), findsOneWidget);
      expect(find.byKey(const Key('vehicle_direction_arrow')), findsOneWidget);
      expect(find.byKey(const Key('meet_vehicle_na_me_button')), findsOneWidget);

      _stopLiveTripPoll(container, trip);
    });

    testWidgets('mark boarded calls mark_boarded RPC', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MeetVehicleScreen(trip: trip),
          ),
          GoRoute(
            path: AppRoutes.activeTrip,
            builder: (context, state) =>
                ActiveTripScreen(trip: state.extra as TripSummary),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      await container
          .read(liveTripControllerFamilyProvider(LiveTripArgs(
            tripId: trip.tripId,
            initialTrip: trip,
          )).notifier)
          .markBoarded();

      expect(fakeSupabase.markBoardedInvokeCount, 1);
      _stopLiveTripPoll(container, trip);
    });

    testWidgets('wayfinding CTA pushes AppRoutes.wayfinding', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MeetVehicleScreen(trip: trip),
          ),
          GoRoute(
            path: AppRoutes.wayfinding,
            builder: (context, state) => WayfindingScreen(
              args: state.extra as WayfindingRouteArgs,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('meet_vehicle_wayfinding')), findsOneWidget);
      expect(trip.board.location, isNotNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('meet_vehicle_wayfinding')),
        120,
      );
      await tester.tap(find.byKey(const Key('meet_vehicle_wayfinding')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WayfindingScreen), findsOneWidget);

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Walk north on Airport Road').evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.text('Walk north on Airport Road'), findsOneWidget);

      _stopLiveTripPoll(container, trip);
    });
  });

  group('R-12 Na Me offline (TS-UI-02)', () {
    late AlongDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = AlongDatabase.memory();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: FakeAlongSupabase(configRows: defaultTestConfigRows()),
          ambientChannel: FakeAmbientChannel(),
          database: database,
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
    });

    tearDown(() => container.dispose());

    testWidgets('renders strobe from cached pairing without network RPC', (tester) async {
      await _seedNaMePairing(database, 'trip-offline-1');

      await tester.pumpWidget(
        _harness(
          container: container,
          child: const NaMeScreen(
            args: NaMeRouteArgs(tripId: 'trip-offline-1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('na_me_fullscreen')), findsOneWidget);
      expect(find.text('GREEN DIAMOND'), findsOneWidget);

      await tester.tap(find.byKey(const Key('na_me_fullscreen')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('na_me_strobing')), findsOneWidget);
    });
  });

  group('R-13 active trip', () {
    late ProviderContainer container;
    late TripSummary trip;

    setUp(() {
      trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(status: 'in_transit'),
      );
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: FakeAlongSupabase(
            configRows: defaultTestConfigRows(),
            requestTripResponse: sampleAcceptedTripResponse(status: 'in_transit'),
          ),
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
    });

    tearDown(() {
      _stopLiveTripPoll(container, trip);
      container.dispose();
    });

    testWidgets('shows LegTimeline compact and SOS placeholder', (tester) async {
      await tester.pumpWidget(
        _harness(container: container, child: ActiveTripScreen(trip: trip)),
      );
      await tester.pump();

      expect(find.byKey(const Key('active_trip_leg_timeline')), findsOneWidget);
      expect(find.byKey(const Key('active_trip_sos')), findsOneWidget);
      expect(find.byKey(const Key('active_trip_share')), findsOneWidget);

      _stopLiveTripPoll(container, trip);
    });
  });
}
