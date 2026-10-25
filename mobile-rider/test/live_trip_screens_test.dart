import 'dart:convert';

import 'package:along_core/along_core.dart'
    show Money, TripExtensionProposal, TripSummary;
import 'package:along_data/along_data.dart' hide Money;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:along_design/along_design.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/trips/presentation/trip_detail_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_screen.dart';
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

Widget _harness({required ProviderContainer container, required Widget child}) {
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
      .read(
        liveTripControllerFamilyProvider(
          LiveTripArgs(tripId: trip.tripId, initialTrip: trip),
        ).notifier,
      )
      .stopPolling();
}

Future<void> _seedNaMePairing(AlongDatabase db, String tripId) async {
  await db
      .into(db.kvStore)
      .insertOnConflictUpdate(
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

    testWidgets('shows plate and directional arrow from live heading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          container: container,
          child: MeetVehicleScreen(trip: trip),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('meet_vehicle_plate')), findsOneWidget);
      expect(find.text('ABC-123-XY'), findsOneWidget);
      expect(find.byKey(const Key('vehicle_direction_arrow')), findsOneWidget);
      expect(
        find.byKey(const Key('meet_vehicle_na_me_button')),
        findsOneWidget,
      );

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
          .read(
            liveTripControllerFamilyProvider(
              LiveTripArgs(tripId: trip.tripId, initialTrip: trip),
            ).notifier,
          )
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
            builder: (context, state) =>
                WayfindingScreen(args: state.extra as WayfindingRouteArgs),
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

    testWidgets('renders strobe from cached pairing without network RPC', (
      tester,
    ) async {
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
            requestTripResponse: sampleAcceptedTripResponse(
              status: 'in_transit',
            ),
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

    testWidgets('shows LegTimeline compact and SOS placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          container: container,
          child: ActiveTripScreen(trip: trip),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('active_trip_leg_timeline')), findsOneWidget);
      expect(find.byKey(const Key('active_trip_sos')), findsOneWidget);
      expect(find.byKey(const Key('active_trip_share')), findsOneWidget);
      expect(find.byKey(const Key('active_trip_eta')), findsOneWidget);
      expect(find.byKey(const Key('live_eta_calculating')), findsOneWidget);
      expect(find.text('Working out your arrival'), findsOneWidget);

      _stopLiveTripPoll(container, trip);
    });
  });

  group('live eta payload', () {
    testWidgets('shows the shared eta payload on the live sheet and stops', (
      tester,
    ) async {
      final json = sampleAcceptedTripResponse(
        tripId: 'trip-eta-1',
        status: 'in_transit',
      );
      json['eta'] = {
        'status': 'ready',
        'pickup': null,
        'trip': {
          'kind': 'single',
          'low_s': 500,
          'high_s': 500,
          'label': '8 min',
        },
        'stops': [
          {'id': 'wuse', 'name': 'Wuse', 'state': 'passed', 'label': '7:12'},
          {
            'id': 'garki',
            'name': 'Garki',
            'state': 'upcoming',
            'label': '7:45',
          },
        ],
        'updated_at': '2026-10-24T06:30:00.000Z',
      };
      final ready = tripSummaryFromFixture(json);
      final etaContainer = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: FakeAlongSupabase(
            configRows: defaultTestConfigRows(),
            requestTripResponse: json,
          ),
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
      await tester.pumpWidget(
        _harness(
          container: etaContainer,
          child: ActiveTripScreen(trip: ready),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('live_eta_window')), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Wuse · 7:12'), findsOneWidget);
      expect(find.text('Garki · 7:45'), findsOneWidget);
      expect(find.textContaining('14 min'), findsNothing);

      _stopLiveTripPoll(etaContainer, ready);
      await tester.pump();
      etaContainer.dispose();
    });
  });

  group('R-17 trip complete (TS-UI-04 taps)', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;
    late TripSummary trip;

    setUp(() {
      trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(
          tripId: 'trip-complete-1',
          status: 'completed',
        ),
      );
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleAcceptedTripResponse(
          tripId: 'trip-complete-1',
          status: 'completed',
        ),
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
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('default path is 1 tap: Yes closes, no rating here', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) {
              return AlongButton(
                label: 'Open complete',
                onPressed: () {
                  taps++;
                  TripCompleteSheet.show(context, trip: trip);
                },
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open complete'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trip_complete_yes')));
      await tester.pumpAndSettle();

      expect(fakeSupabase.confirmFareInvokeCount, 1);
      expect(fakeSupabase.lastConfirmFareParams?['p_outcome'], 'as_shown');
      expect(fakeSupabase.rateTripInvokeCount, 0);
      expect(find.byType(TripCompleteSheet), findsNothing);
      expect(taps, 1);
    });

    testWidgets('digital-enabled default is Pay then cash overflow', (
      tester,
    ) async {
      fakeSupabase = FakeAlongSupabase(
        configRows: [
          ...defaultTestConfigRows().where(
            (row) => row['key'] != 'payments.digital_enabled',
          ),
          {
            'key': 'payments.digital_enabled',
            'scope_type': 'global',
            'scope_id': '*',
            'value': 'true',
          },
        ],
        requestTripResponse: sampleAcceptedTripResponse(
          tripId: 'trip-complete-1',
          status: 'completed',
        ),
      );
      container.dispose();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: const AppConfig(
            flavor: 'dev',
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          supabase: fakeSupabase,
          ambientChannel: FakeAmbientChannel(),
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) {
              return AlongButton(
                label: 'Open complete',
                onPressed: () => TripCompleteSheet.show(context, trip: trip),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open complete'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_complete_pay')), findsOneWidget);
      expect(find.byKey(const Key('trip_complete_paid_cash')), findsOneWidget);
      expect(find.byKey(const Key('trip_complete_yes')), findsNothing);

      await tester.tap(find.byKey(const Key('trip_complete_paid_cash')));
      await tester.pumpAndSettle();

      expect(fakeSupabase.confirmFareInvokeCount, 1);
      expect(find.byKey(const Key('trip_complete_done')), findsNothing);
      expect(find.byType(TripCompleteSheet), findsNothing);
    });
  });

  group('TS-UI-04 payment visibility', () {
    late ProviderContainer container;
    late TripSummary trip;

    setUp(() {
      trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(status: 'in_transit'),
      );
    });

    tearDown(() => container.dispose());

    testWidgets('cash trip hides Pay when digital_enabled is false', (
      tester,
    ) async {
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleAcceptedTripResponse(status: 'in_transit'),
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
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: ActiveTripScreen(trip: trip),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active_trip_pay')), findsNothing);

      _stopLiveTripPoll(container, trip);
      fakeSupabase.dispose();
    });

    testWidgets('Pay sheet locks amount when trip attached', (tester) async {
      final configRows = [
        ...defaultTestConfigRows(),
        {
          'key': 'payments.digital_enabled',
          'scope_type': 'global',
          'scope_id': '*',
          'value': 'true',
        },
      ];
      final fakeSupabase = FakeAlongSupabase(
        configRows: configRows,
        requestTripResponse: sampleAcceptedTripResponse(status: 'in_transit'),
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
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Open pay',
              onPressed: () => PayDriverSheet.show(context, trip: trip),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pay'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pay_driver_amount')), findsOneWidget);
      expect(find.text('Amount locked to this trip'), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);

      fakeSupabase.dispose();
    });
  });

  group('R-15 extension accept', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: sampleAcceptedTripResponse(status: 'in_transit'),
        tripExtensionRows: [
          {
            'id': 'ext-driver-1',
            'trip_id': 'trip-accepted-1',
            'status': 'proposed',
            'proposed_by': 'driver',
            'fare_delta': '150.00',
            'currency': 'NGN',
            'new_alighting_stage_id': 's-wuse',
          },
        ],
        routeStageRows: [
          {'id': 's-wuse', 'name': 'Wuse Market'},
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
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('accept incoming driver proposal is 1 tap', (tester) async {
      final trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(status: 'in_transit'),
      );
      final proposal = TripExtensionProposal(
        extensionId: 'ext-driver-1',
        tripId: trip.tripId,
        proposedBy: 'driver',
        destinationName: 'Wuse Market',
        fareDelta: Money.parse('150.00', currency: 'NGN'),
        currency: 'NGN',
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Show extension',
              onPressed: () => IncomingExtensionSheet.show(
                context,
                trip: trip,
                proposal: proposal,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show extension'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('extension_accept')));
      await tester.pumpAndSettle();

      expect(fakeSupabase.respondExtensionInvokeCount, 1);
      expect(fakeSupabase.lastRespondExtensionParams?['p_response'], 'accept');
    });

    test(
      'resolvePendingExtension prefers TripView.extension over table poll',
      () async {
        final trip = tripSummaryFromFixture(sampleTripWithPendingExtension());
        final proposal = await container
            .read(tripsRepositoryProvider)
            .resolvePendingExtension(trip);

        expect(proposal?.extensionId, 'ext-view-1');
        expect(proposal?.destinationName, 'Wuse Market');
      },
    );

    testWidgets('extend sheet embeds R-06 destination search', (tester) async {
      final trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(status: 'in_transit'),
      );

      await tester.pumpWidget(
        _harness(
          container: container,
          child: Builder(
            builder: (context) => AlongButton(
              label: 'Extend',
              onPressed: () => ExtendTripSheet.show(context, trip: trip),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Extend'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('destination_search_field')), findsOneWidget);
      expect(find.byKey(const Key('extend_place_Wuse Market')), findsNothing);
    });
  });

  group('R-22 trips history', () {
    testWidgets('shows completed trips with itemised detail', (tester) async {
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        tripRows: [
          {
            'id': 'trip-hist-1',
            'status': 'completed',
            'ended_at': '2026-09-05T16:00:00Z',
            'boarding_name': 'Lugbe Park',
            'alighting_name': 'Area 1 Park',
            'mode_code': 'keke',
            'mode_label': 'Keke',
            'fare_shown': '450.00',
            'load_surcharge_amount': 0,
            'commission_amount': '34.00',
            'fare_currency': 'NGN',
            'driver_name': 'Musa',
            'plate_number': 'ABC-123-XY',
          },
        ],
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
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const TripsHistoryScreen(),
                ),
                GoRoute(
                  path: AppRoutes.tripDetail,
                  builder: (context, state) =>
                      TripDetailScreen(tripId: state.extra as String),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lugbe Park → Area 1 Park'), findsOneWidget);

      await tester.tap(find.byKey(const Key('trip_history_trip-hist-1')));
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('trip_detail_fare')), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    });
  });
}
