import 'dart:convert';
import 'dart:io';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/safety/presentation/guardian_share_screen.dart';
import 'package:mobile_rider/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_rider/features/safety/presentation/safety_kit.dart';
import 'package:mobile_rider/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/testing/fakes/fake_recent_places_store.dart';

import 'support/trip_options_fixtures.dart';

/// SOS, Guardian and incident photos on fakes, light/dark/1.3x.
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

  ProviderContainer containerFor(
    FakeAlongSupabase fake, {
    AlongDatabase? database,
    List<Override> extra = const [],
  }) => ProviderContainer(
    overrides: [
      ...extra,
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

  final pinned = DateTime.utc(2026, 9, 5, 16, 4, 12);
  final contacts = [
    {'id': 'c1', 'name': 'Ada Obi', 'phone_e164': '+2348011111111'},
    {'id': 'c2', 'name': 'Tunde Bello', 'phone_e164': '+2348022222222'},
    {'id': 'c3', 'name': 'Mama Chinwe', 'phone_e164': '+2348033333333'},
  ];
  final photo = File('test/support/incident_photo.png').readAsBytesSync();

  for (final (name, brightness, scale) in variants) {
    Future<(FakeAlongSupabase, ProviderContainer)> pump(
      WidgetTester tester,
      Widget Function(TripSummary trip) screen, {
      List<Map<String, dynamic>> contactRows = const [],
      Object? raiseError,
      List<Override> extra = const [],
    }) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final json = sampleAcceptedTripResponse(heading: 90);
      final trip = tripSummaryFromFixture(json);
      final fake =
          FakeAlongSupabase(
              configRows: defaultTestConfigRows(),
              requestTripResponse: json,
            )
            ..emergencyContactRows = contactRows
            ..raiseSosError = raiseError
            ..now = (() => pinned);
      await fake.verifyOtp(phone: '+2348000000001', token: '123456');
      final c = containerFor(
        fake,
        extra: [safetyNowProvider.overrideWithValue(() => pinned), ...extra],
      );
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/s', builder: (_, _) => screen(trip)),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
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
            routerConfig: router,
          ),
        ),
      );
      router.push('/s');
      await settle(tester);
      return (fake, c);
    }

    Future<void> shootApp(WidgetTester tester, String file) async {
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$file.png'),
      );
    }

    testWidgets('rider sos sent $name', (tester) async {
      await pump(
        tester,
        (trip) => SosActiveScreen(args: SosActiveRouteArgs(trip: trip)),
        contactRows: contacts,
      );
      expect(find.byKey(const Key('sos_team_alerted')), findsOneWidget);
      await shootApp(tester, 'rider_sos_sent_$name');
    });

    testWidgets('rider sos queued $name', (tester) async {
      await pump(
        tester,
        (trip) => SosActiveScreen(args: SosActiveRouteArgs(trip: trip)),
        contactRows: contacts.take(2).toList(),
        raiseError: const SocketException('offline'),
      );
      expect(find.byKey(const Key('sos_status_queued')), findsOneWidget);
      await shootApp(tester, 'rider_sos_queued_$name');
    });

    testWidgets('rider sos no contacts $name', (tester) async {
      await pump(
        tester,
        (trip) => SosActiveScreen(args: SosActiveRouteArgs(trip: trip)),
      );
      expect(find.byKey(const Key('sos_add_contact')), findsOneWidget);
      await shootApp(tester, 'rider_sos_no_contacts_$name');
    });

    testWidgets('rider guardian share $name', (tester) async {
      await pump(
        tester,
        (trip) => GuardianShareScreen(args: GuardianShareArgs(trip: trip)),
        contactRows: contacts,
      );
      await shootApp(tester, 'rider_guardian_share_$name');
    });

    testWidgets('rider guardian live $name', (tester) async {
      await pump(
        tester,
        (trip) => GuardianShareScreen(args: GuardianShareArgs(trip: trip)),
        contactRows: contacts.take(2).toList(),
      );
      await tester.tap(find.byKey(const Key('share_trip_create')));
      await settle(tester);
      expect(find.byKey(const Key('guardian_status_sharing')), findsOneWidget);
      await shootApp(tester, 'rider_guardian_live_$name');
    });

    testWidgets('rider report incident photos $name', (tester) async {
      var n = 0;
      await pump(
        tester,
        (trip) => const ReportIncidentScreen(tripId: 'trip-1'),
        extra: [
          incidentPhotoPickerProvider.overrideWithValue(
            (source, name) async => '/tmp/incident-${n++}.png',
          ),
          incidentPhotoBytesProvider.overrideWithValue((path) async => photo),
        ],
      );
      await tester.tap(find.byKey(const Key('incident_category_safety')));
      await tester.enterText(
        find.byKey(const Key('report_incident_description')),
        'Driver kept speeding on the expressway and ignored me.',
      );
      for (var i = 0; i < 2; i++) {
        await tester.scrollUntilVisible(
          find.byKey(const Key('report_incident_attach')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('report_incident_attach')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('incident_photo_gallery')));
        await settle(tester);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.scrollUntilVisible(
        find.byKey(const Key('report_incident_attach')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await settle(tester);
      await shootApp(tester, 'rider_report_incident_photos_$name');
    });
  }
}
