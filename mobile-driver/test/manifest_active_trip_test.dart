import 'dart:convert';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_screen.dart';
import 'package:mobile_driver/features/trip/presentation/manifest_controller.dart';
import 'package:mobile_driver/features/trip/presentation/manifest_screen.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_screen.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';

Widget _harness({
  required ProviderContainer container,
  required Widget child,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: alongTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Future<void> _seedNaMePairing(AlongDatabase db, String tripId) async {
  await db.into(db.kvStore).insertOnConflictUpdate(
        KvStoreCompanion.insert(
          key: 'na_me:$tripId',
          value: jsonEncode({
            'color_token': 'green',
            'shape': 'diamond',
            'label': 'Green Diamond',
            'trip_id': tripId,
          }),
        ),
      );
}

void main() {
  const testConfig = AppConfig(
    flavor: 'dev',
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
    batteryGuardPercent: 15,
  );

  group('D-15 manifest', () {
    late FakeAlongSupabase fakeSupabase;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: testConfig,
          supabase: fakeSupabase,
          driverChannel: FakeDriverChannel(),
          locationStreamSource: _FakeLocationStream(),
        ),
      );
    });

    tearDown(() {
      container.read(manifestControllerProvider.notifier).stopPolling();
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('lists manifest rows with Na Me chip', (tester) async {
      await tester.pumpWidget(
        _harness(container: container, child: const ManifestScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('manifest_screen')), findsOneWidget);
      expect(find.byKey(const Key('manifest_row_trip-accepted-1')), findsOneWidget);
      expect(find.text('Ada'), findsWidgets);

      container.read(manifestControllerProvider.notifier).stopPolling();
    });

    test('driver_manifest RPC maps entries', () async {
      final repo = TripsRepository(
        fakeSupabase,
        container.read(alongDatabaseProvider),
      );
      final entries = await repo.driverManifest();
      expect(entries.length, 2);
      expect(entries.first.tripId, 'trip-accepted-1');
      expect(entries.first.naMe.label, 'Green Diamond');
    });
  });

  group('D-16 active trip', () {
    late FakeAlongSupabase fakeSupabase;
    late AlongDatabase database;
    late ProviderContainer container;

    setUp(() {
      fakeSupabase = FakeAlongSupabase();
      database = AlongDatabase.memory();
      container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: testConfig,
          supabase: fakeSupabase,
          database: database,
          driverChannel: FakeDriverChannel(),
          locationStreamSource: _FakeLocationStream(),
        ),
      );
    });

    tearDown(() {
      fakeSupabase.dispose();
      container.dispose();
    });

    testWidgets('start trip calls start_trip RPC', (tester) async {
      String? startedTripId;
      fakeSupabase.onStartTrip = (tripId) => startedTripId = tripId;
      fakeSupabase.tripStatuses['trip-boarded-1'] = 'boarded';

      const args = ActiveTripArgs(tripId: 'trip-boarded-1');
      await tester.pumpWidget(
        _harness(
          container: container,
          child: ActiveTripScreen(args: args),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('active_trip_start')), findsOneWidget);
      await tester.tap(find.byKey(const Key('active_trip_start')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(startedTripId, 'trip-boarded-1');
    });

    testWidgets('complete trip calls complete_trip RPC', (tester) async {
      String? completedTripId;
      fakeSupabase.onCompleteTrip = (tripId) => completedTripId = tripId;
      fakeSupabase.tripStatuses['trip-in-transit-1'] = 'in_transit';

      const args = ActiveTripArgs(tripId: 'trip-in-transit-1');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ActiveTripScreen(args: args),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: alongTheme(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byKey(const Key('active_trip_complete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(completedTripId, 'trip-in-transit-1');
    });

    testWidgets('Na Me fullscreen reads cached pairing offline', (tester) async {
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
}

class _FakeLocationStream implements LocationStreamSource {
  @override
  Stream<LocationSample> samples({
    required double distanceFilterM,
    required double maxAccuracyM,
  }) =>
      const Stream.empty();

  @override
  Future<bool> ensurePermission() async => true;
}
