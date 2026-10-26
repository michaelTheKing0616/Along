import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/extend_trip_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_rider/features/safety/presentation/share_trip_sheet.dart';
import 'package:mobile_rider/features/trips/presentation/trip_detail_screen.dart';
import 'package:mobile_rider/features/trips/presentation/trips_history_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

/// Real rider slice 3 screens on fakes, light/dark/1.3x.
void main() {
  setUpAll(() async {
    final manifest = await rootBundle.loadStructuredData<List<dynamic>>(
      'FontManifest.json',
      (s) async => json.decode(s) as List<dynamic>,
    );
    for (final entry in manifest) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    await AlongFonts.ensureLoaded();
  });

  const variants = [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('light_1_3x', Brightness.light, 1.3),
  ];

  Widget app(
    ProviderContainer container,
    Widget home,
    Brightness brightness,
    double scale,
  ) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: alongTheme(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: child!,
        ),
        home: home,
      ),
    );
  }

  ProviderContainer containerFor(
    FakeAlongSupabase fake, {
    AlongDatabase? database,
  }) => ProviderContainer(
    overrides: [
      ...buildProviderOverrides(
        config: const AppConfig(
          flavor: 'dev',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        supabase: fake,
        ambientChannel: FakeAmbientChannel(),
        database: database ?? AlongDatabase.memory(),
        wayfindingTts: FakeWayfindingTts(),
        recentPlacesStore: FakeRecentPlacesStore(),
        clock: Clock.fixed(DateTime.utc(2026, 9, 5, 16, 4, 12)),
        locationStreamSource: FakeLocationStreamSource(
          fixedSamples: [
            LocationSample(
              point: const GeoPoint(lat: 9.072, lng: 7.481),
              accuracyM: 10,
              recordedAt: DateTime.utc(2026, 9, 5, 16),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shoot(WidgetTester tester, String file) async {
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$file.png'),
    );
  }

  final tripRows = [
    {
      'id': 'trip-hist-1',
      'status': 'completed',
      'ended_at': '2026-09-05T16:00:00Z',
      'boarding_name': 'Lugbe Park',
      'alighting_name': 'Area 1 Park',
      'mode_code': 'keke',
      'mode_label': 'Keke',
      'fare_shown': '450.00',
      'load_surcharge_amount': '50.00',
      'commission_amount': '34.00',
      'fare_currency': 'NGN',
      'driver_name': 'Musa Abubakar',
      'plate_number': 'ABC-123-XY',
    },
    {
      'id': 'trip-hist-2',
      'status': 'completed',
      'ended_at': '2026-09-04T08:30:00Z',
      'boarding_name': 'Wuse Market',
      'alighting_name': 'Berger Junction',
      'mode_code': 'taxi',
      'mode_label': 'Taxi',
      'fare_shown': '1200.00',
      'load_surcharge_amount': 0,
      'commission_amount': '90.00',
      'fare_currency': 'NGN',
      'driver_name': 'Chinedu Okafor',
      'plate_number': 'KUJ-552-AB',
    },
  ];

  for (final (name, brightness, scale) in variants) {
    Future<ProviderContainer> pumpScreen(
      WidgetTester tester,
      Widget home,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        tripRows: tripRows,
      );
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(app(c, home, brightness, scale));
      await settle(tester);
      return c;
    }

    final trip = tripSummaryFromFixture(
      sampleAcceptedTripResponse(status: 'in_transit'),
    );

    testWidgets('rider trips history $name', (tester) async {
      await pumpScreen(tester, const TripsHistoryScreen());
      await shoot(tester, 'rider_trips_history_$name');
    });

    testWidgets('rider trip detail $name', (tester) async {
      await pumpScreen(tester, const TripDetailScreen(tripId: 'trip-hist-1'));
      await shoot(tester, 'rider_trip_detail_$name');
    });

    testWidgets('rider report incident $name', (tester) async {
      await pumpScreen(tester, const ReportIncidentScreen(tripId: 'trip-1'));
      await tester.tap(find.byKey(const Key('incident_category_safety')));
      await settle(tester);
      await shoot(tester, 'rider_report_incident_$name');
    });

    /// Opens [sheet] over the real live-trip screen so frames read true.
    Future<void> overLiveTrip(
      WidgetTester tester,
      Widget sheet, {
      List<Map<String, dynamic>> places = const [],
    }) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final json = liveTripJson();
      final live = tripSummaryFromFixture(json);
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: json,
        tripRows: tripRows,
        placeResults: places,
      );
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        app(c, ActiveTripScreen(trip: live), brightness, scale),
      );
      await settle(tester);
      c
          .read(
            liveTripControllerFamilyProvider(
              LiveTripArgs(tripId: live.tripId, initialTrip: live),
            ).notifier,
          )
          .stopPolling();
      showModalBottomSheet<void>(
        context: tester.element(find.byType(ActiveTripScreen)),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => sheet,
      );
      await settle(tester);
    }

    testWidgets('rider share trip $name', (tester) async {
      await overLiveTrip(tester, ShareTripSheet(journeyId: 'j-1'));
      await shoot(tester, 'rider_share_trip_$name');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider pay driver $name', (tester) async {
      await overLiveTrip(
        tester,
        PayDriverSheet(
          trip: trip,
          receipt: TripReceipt(
            fare: Money.parse('450', currency: 'NGN'),
            surcharge: Money.parse('50', currency: 'NGN'),
            total: Money.parse('500', currency: 'NGN'),
          ),
        ),
      );
      // Hero total, breakdown and Pay button all show what is charged.
      expect(find.text('₦500'), findsWidgets);
      expect(find.text('Pay ₦500'), findsOneWidget);
      await shoot(tester, 'rider_pay_driver_$name');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider extend trip $name', (tester) async {
      await overLiveTrip(tester, ExtendTripSheet(trip: trip));
      await shoot(tester, 'rider_extend_trip_$name');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider extend preview $name', (tester) async {
      await overLiveTrip(
        tester,
        ExtendTripSheet(trip: trip),
        places: [
          {
            'kind': 'market',
            'name': 'Wuse Market',
            'area': 'Wuse',
            'location': {'lat': 9.06, 'lng': 7.47},
            'distance_m': 5200,
          },
        ],
      );
      await tester.enterText(
        find.byKey(const Key('destination_search_field')),
        'Wuse',
      );
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 600));
      await settle(tester);
      await tester.tap(find.byKey(const Key('result_Wuse Market')));
      await settle(tester);
      expect(find.byKey(const Key('extend_send_to_driver')), findsOneWidget);
      await shoot(tester, 'rider_extend_preview_$name');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider incoming extension $name', (tester) async {
      await overLiveTrip(
        tester,
        IncomingExtensionSheet(
          trip: trip,
          proposal: TripExtensionProposal(
            extensionId: 'ext-1',
            tripId: trip.tripId,
            proposedBy: 'driver',
            destinationName: 'Wuse Market',
            fareDelta: Money.parse('200', currency: 'NGN'),
            currency: 'NGN',
          ),
        ),
      );
      await shoot(tester, 'rider_incoming_extension_$name');
      await tester.pumpWidget(const SizedBox());
    });
  }
}

/// The in-transit trip the live-trip golden uses, driver part-way along.
Map<String, dynamic> liveTripJson() {
  final json = sampleAcceptedTripResponse(
    status: 'in_transit',
    liveAsOf: DateTime.utc(2026, 9, 5, 16, 4, 2),
  );
  final driver =
      (json['live'] as Map<String, dynamic>)['driver'] as Map<String, dynamic>;
  driver['lat'] = 9.031;
  driver['lng'] = 7.428;
  json['eta'] = {
    'status': 'ready',
    'updated_at': '2026-09-05T16:04:00Z',
    'stops': [
      {
        'id': 'stop-1',
        'name': 'Area 1 Park',
        'state': 'upcoming',
        'label': '16:16',
      },
    ],
    'trip': {
      'kind': 'range',
      'label': '16:16–16:19',
      'low_s': 720,
      'high_s': 900,
    },
  };
  return json;
}
