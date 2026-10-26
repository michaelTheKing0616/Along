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
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/meet_vehicle_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/na_me_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_complete_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_receipt_page.dart';
import 'package:mobile_rider/features/search/presentation/search_screens.dart';
import 'package:mobile_rider/features/trip_options/presentation/requesting_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

class _QuietNaMeHost implements NaMeScreenHost {
  @override
  Future<void> enter() async {}

  @override
  Future<void> exit() async {}
}

/// Real rider slice 2 screens (request to receipt) on fakes,
/// light/dark/1.3x.
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
      naMeScreenHostProvider.overrideWithValue(_QuietNaMeHost()),
    ],
  );

  void stopPoll(ProviderContainer c, TripSummary trip) {
    c
        .read(
          liveTripControllerFamilyProvider(
            LiveTripArgs(tripId: trip.tripId, initialTrip: trip),
          ).notifier,
        )
        .stopPolling();
  }

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

  for (final (name, brightness, scale) in variants) {
    testWidgets('rider requesting $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final json = sampleRequestTripResponse();
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: json,
      );
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        app(
          c,
          RequestingScreen(
            trip: tripSummaryFromFixture(json),
            roamingSource: false,
          ),
          brightness,
          scale,
        ),
      );
      await settle(tester);
      await shoot(tester, 'rider_requesting_$name');
      await tester.pumpWidget(const SizedBox());
      // The countdown ticks inside the provider; drop it before the end.
      c.dispose();
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('rider adjust pickup $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic> place(String kind, String name, double m) => {
        'kind': kind,
        'name': name,
        'area': 'Lugbe',
        'location': {'lat': 9.072, 'lng': 7.481},
        'distance_m': m,
      };
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        snappedStage: {
          'stage_id': 's-lugbe',
          'name': 'Lugbe Park',
          'distance_m': 40,
          'route_ids': ['route-1'],
        },
        placeResults: [
          place('park', 'Lugbe Park', 40),
          place('stage', 'Federal Housing junction', 260),
          place('stage', 'Police Signboard', 410),
        ],
      );
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      c.read(homeControllerProvider);
      await tester.pumpWidget(
        app(c, const AdjustPickupScreen(), brightness, scale),
      );
      await settle(tester);
      await shoot(tester, 'rider_adjust_pickup_$name');
    });

    testWidgets('rider meet vehicle $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final json = sampleAcceptedTripResponse(
        heading: 90,
        liveAsOf: DateTime.utc(2026, 9, 5, 16, 4, 2),
      );
      _placeDriver(json, 9.021, 7.388);
      final trip = tripSummaryFromFixture(json);
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: json,
      );
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        app(c, MeetVehicleScreen(trip: trip), brightness, scale),
      );
      await settle(tester);
      await shoot(tester, 'rider_meet_vehicle_$name');
      stopPoll(c, trip);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider live trip $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final json = sampleAcceptedTripResponse(
        status: 'in_transit',
        liveAsOf: DateTime.utc(2026, 9, 5, 16, 4, 2),
      );
      _placeDriver(json, 9.031, 7.428);
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
      final trip = tripSummaryFromFixture(json);
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: json,
      );
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        app(c, ActiveTripScreen(trip: trip), brightness, scale),
      );
      await settle(tester);
      await shoot(tester, 'rider_live_trip_$name');
      stopPoll(c, trip);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider na me $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = AlongDatabase.memory();
      await db
          .into(db.kvStore)
          .insertOnConflictUpdate(
            KvStoreCompanion.insert(
              key: 'na_me:trip-1',
              value: jsonEncode({
                'color_token': 'color.naMe.green',
                'shape': 'diamond',
                'label': 'Green Diamond',
                'trip_id': 'trip-1',
              }),
            ),
          );
      final fake = FakeAlongSupabase(configRows: defaultTestConfigRows());
      final c = containerFor(fake, database: db);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        app(
          c,
          const NaMeScreen(args: NaMeRouteArgs(tripId: 'trip-1')),
          brightness,
          scale,
        ),
      );
      await settle(tester);
      await shoot(tester, 'rider_na_me_$name');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider trip complete $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final liveJson = sampleAcceptedTripResponse(
        status: 'in_transit',
        liveAsOf: DateTime.utc(2026, 9, 5, 16, 4, 2),
      );
      _placeDriver(liveJson, 9.031, 7.428);
      final live = tripSummaryFromFixture(liveJson);
      final trip = tripSummaryFromFixture(
        sampleAcceptedTripResponse(status: 'completed'),
      );
      final fake = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: liveJson,
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
      stopPoll(c, live);
      TripCompleteSheet.show(
        tester.element(find.byType(ActiveTripScreen)),
        trip: trip,
      );
      await settle(tester);
      await shoot(tester, 'rider_trip_complete_$name');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rider receipt $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final json = sampleAcceptedTripResponse(status: 'completed');
      final trip = tripSummaryFromFixture(json);
      final fake = FakeAlongSupabase(configRows: defaultTestConfigRows());
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        app(
          c,
          TripReceiptPage(
            trip: trip,
            receipt: TripReceipt(
              fare: Money.parse('450', currency: 'NGN'),
              surcharge: Money.parse('50', currency: 'NGN'),
              total: Money.parse('500', currency: 'NGN'),
            ),
          ),
          brightness,
          scale,
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('receipt_star_5')));
      await settle(tester);
      await shoot(tester, 'rider_receipt_$name');
    });
  }
}

/// Moves the live driver fix so the drawn map shows real progress.
void _placeDriver(Map<String, dynamic> json, double lat, double lng) {
  final live = json['live'] as Map<String, dynamic>;
  final driver = live['driver'] as Map<String, dynamic>;
  driver['lat'] = lat;
  driver['lng'] = lng;
}
