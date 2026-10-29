import 'dart:io';

import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/account/presentation/account_settings_screen.dart';
import 'package:mobile_rider/features/safety/presentation/report_incident_screen.dart';
import 'package:mobile_rider/features/safety/presentation/guardian_share_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  group('R-24 report incident', () {
    testWidgets('submits selected category and description', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
          database: AlongDatabase.memory(),
          wayfindingTts: FakeWayfindingTts(),
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ReportIncidentScreen(tripId: 'trip-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('incident_category_safety')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Driver was speeding');
      await tester.tap(find.byKey(const Key('report_incident_submit')));
      await tester.pumpAndSettle();

      expect(fakeSupabase.reportIncidentInvokeCount, 1);
      expect(fakeSupabase.lastReportIncidentParams?['p_type'], 'safety');

      fakeSupabase.dispose();
      container.dispose();
    });
  });

  ProviderContainer containerFor(
    FakeAlongSupabase fake, {
    List<Override> extra = const [],
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
        database: AlongDatabase.memory(),
        wayfindingTts: FakeWayfindingTts(),
      ),
      ...extra,
    ],
  );

  Widget host(ProviderContainer c, Widget home) => UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  group('R-24 incident photos', () {
    Future<(FakeAlongSupabase, ProviderContainer)> pumpReport(
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = FakeAlongSupabase(configRows: defaultTestConfigRows());
      await fake.verifyOtp(phone: '+2348000000001', token: '123456');
      var n = 0;
      final c = containerFor(
        fake,
        extra: [
          incidentPhotoPickerProvider.overrideWithValue(
            (source, name) async => '/tmp/photo-${n++}.jpg',
          ),
          incidentPhotoBytesProvider.overrideWithValue(
            (path) async => _onePixelPng,
          ),
        ],
      );
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        host(c, const ReportIncidentScreen(tripId: 'trip-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('incident_category_safety')));
      await tester.enterText(find.byType(TextField), 'Driver was speeding');
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('report_incident_attach')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('incident_photo_gallery')));
        await tester.pumpAndSettle();
      }
      return (fake, c);
    }

    testWidgets('uploads photos, then files the report with their paths', (
      tester,
    ) async {
      final (fake, _) = await pumpReport(tester);
      expect(find.byKey(const Key('incident_photo_1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('report_incident_submit')));
      await tester.pumpAndSettle();

      expect(fake.uploadedObjects, hasLength(2));
      final paths =
          fake.lastReportIncidentParams?['p_attachment_paths'] as List;
      expect(paths, hasLength(2));
      expect(paths.first, startsWith('incidents/'));
      expect(fake.lastReportIncidentParams?['p_client_ref'], isNotNull);
    });

    testWidgets('stops at four photos and can remove one', (tester) async {
      await pumpReport(tester);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('report_incident_attach')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('incident_photo_camera')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('report_incident_attach')), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp('4')).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('incident_photo_3')), findsNothing);
      expect(find.byKey(const Key('report_incident_attach')), findsOneWidget);
    });

    testWidgets('queues the report when offline', (tester) async {
      final (fake, c) = await pumpReport(tester);
      fake.incidentError = const SocketException('offline');
      await tester.tap(find.byKey(const Key('report_incident_submit')));
      await tester.pumpAndSettle();

      expect(fake.reportIncidentInvokeCount, 0);
      expect(await c.read(incidentReporterProvider).hasPending(), isTrue);
      expect(find.byType(ReportIncidentScreen), findsNothing);
    });
  });

  group('R-25 guardian share', () {
    testWidgets('shares with trusted contacts, then stops', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final trip = tripSummaryFromFixture(sampleAcceptedTripResponse());
      final fake =
          FakeAlongSupabase(
              configRows: defaultTestConfigRows(),
              requestTripResponse: sampleAcceptedTripResponse(),
            )
            ..emergencyContactRows = [
              {'id': 'c1', 'name': 'Ada Obi', 'phone_e164': '+2348011111111'},
              {
                'id': 'c2',
                'name': 'Tunde Bello',
                'phone_e164': '+2348022222222',
              },
            ];
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        host(c, GuardianShareScreen(args: GuardianShareArgs(trip: trip))),
      );
      await tester.pumpAndSettle();

      // Deselect one contact, keep the plate private, pick 30 minutes.
      await tester.tap(find.byKey(const Key('guardian_contact_c2')));
      await tester.tap(find.byKey(const Key('guardian_expiry_min30')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('share_trip_create')));
      await tester.pumpAndSettle();

      expect(fake.createTripShareInvokeCount, 1);
      final call = fake.createTripShareCalls.single!;
      expect(call['p_contact_name'], 'Ada Obi');
      expect(call['p_share_plate'], isFalse);
      expect(call['p_ttl_minutes'], 30);
      expect(find.byKey(const Key('guardian_status_sharing')), findsOneWidget);
      expect(find.byKey(const Key('share_whatsapp_share-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('guardian_share_stop')));
      await tester.pumpAndSettle();
      expect(fake.revokeTripShareInvokeCount, 1);
      expect(find.byKey(const Key('share_trip_create')), findsOneWidget);
    });

    testWidgets('without contacts makes one link to copy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final trip = tripSummaryFromFixture(sampleAcceptedTripResponse());
      final fake = FakeAlongSupabase(configRows: defaultTestConfigRows());
      final c = containerFor(fake);
      addTearDown(() {
        fake.dispose();
        c.dispose();
      });
      await tester.pumpWidget(
        host(c, GuardianShareScreen(args: GuardianShareArgs(trip: trip))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('share_trip_create')));
      await tester.pumpAndSettle();
      expect(fake.createTripShareInvokeCount, 1);
      expect(find.byKey(const Key('share_copy_share-1')), findsOneWidget);
    });
  });

  group('R-26 account settings', () {
    testWidgets('shows women-only when regulatory flag enabled', (
      tester,
    ) async {
      final fakeSupabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        cityRegulatoryFlags: const {'women_only_matching': true},
      );
      await fakeSupabase.verifyOtp(phone: '+2348000000001', token: '123456');
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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AccountSettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('account_women_only')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('account_payment_cash')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('account_payment_cash')), findsOneWidget);
      expect(find.byKey(const Key('account_wallet')), findsOneWidget);

      fakeSupabase.dispose();
      container.dispose();
    });
  });
}

/// A valid 1×1 PNG so Image.memory decodes in tests.
const _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xE8, 0xEA, 0x9F, 0x06, 0x00, 0x03, 0x56, 0x01, 0xB0, 0x75, 0xFE, 0x4D, 0x56, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
