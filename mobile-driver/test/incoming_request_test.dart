import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_sheet.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_driver/testing/fakes/fake_driver_channel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const testConfig = AppConfig(
    flavor: 'dev',
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
    batteryGuardPercent: 15,
  );

  TripSummary sampleTrip({
    bool loadFlagged = true,
    TripApproachBand? approachBand,
  }) {
    final summary = DomainMappers.incomingTripFromEnvelope(
      FakeAlongSupabase().sampleTripRequestEnvelope(loadFlagged: loadFlagged),
    );
    if (approachBand == null) return summary;
    return TripSummary(
      tripId: summary.tripId,
      journeyId: summary.journeyId,
      journeySequence: summary.journeySequence,
      status: summary.status,
      fare: summary.fare,
      naMe: summary.naMe,
      liveChannel: summary.liveChannel,
      expiresAt: summary.expiresAt,
      rider: summary.rider,
      board: summary.board,
      alight: summary.alight,
      load: summary.load,
      womenOnly: summary.womenOnly,
      dispatchAttempt: summary.dispatchAttempt,
      isRoamingHail: summary.isRoamingHail,
      approachBand: approachBand,
    );
  }

  IncomingRequestState sampleState({
    bool loadFlagged = true,
    TripApproachBand? approachBand,
  }) {
    return IncomingRequestState(
      trip: sampleTrip(loadFlagged: loadFlagged, approachBand: approachBand),
      commissionRate: 0.075,
      requestTtlS: 25,
      remainingSeconds: 18,
    );
  }

  Widget buildSheet({
    required IncomingRequestState state,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: alongTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IncomingRequestSheet(
            state: state,
            l10n: lookupAppLocalizations(const Locale('en')),
            onAccept: onAccept ?? () {},
            onDecline: onDecline ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('load row is visible before accept when flagged', (tester) async {
    await tester.pumpWidget(buildSheet(state: sampleState(loadFlagged: true)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incoming_request_load_row')), findsOneWidget);
    expect(find.textContaining('Medium load'), findsOneWidget);
  });

  testWidgets('shows approach band labels without metres or walk ETA', (
    tester,
  ) async {
    for (final entry in [
      (TripApproachBand.under2, 'under 2 min'),
      (TripApproachBand.m2_5, '2–5 min'),
      (TripApproachBand.over5, '5+ min'),
    ]) {
      await tester.pumpWidget(
        buildSheet(state: sampleState(approachBand: entry.$1)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('incoming_request_approach_band')),
        findsOneWidget,
      );
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.textContaining('400 m'), findsNothing);
      expect(find.textContaining('walk_eta'), findsNothing);
      expect(find.textContaining('9.0'), findsNothing);
      expect(find.textContaining('7.0'), findsNothing);
    }
  });

  testWidgets('accept is one tap', (tester) async {
    var acceptTaps = 0;
    await tester.pumpWidget(
      buildSheet(state: sampleState(), onAccept: () => acceptTaps++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('incoming_request_accept')));
    await tester.pumpAndSettle();

    expect(acceptTaps, 1);
  });

  group('IncomingRequestNotifier', () {
    ProviderContainer buildContainer({
      required FakeAlongSupabase fake,
      FakeDriverChannel? channel,
    }) {
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: testConfig,
          supabase: fake,
          database: AlongDatabase.memory(),
          driverChannel: channel ?? FakeDriverChannel(),
          clock: Clock.fixed(DateTime.utc(2026, 9, 5, 13, 59, 40)),
          locationStreamSource: FakeLocationStreamSource(
            permissionGranted: true,
            fixedSamples: [
              LocationSample(
                point: const GeoPoint(lat: 9.05, lng: 7.49),
                accuracyM: 8,
                recordedAt: DateTime.utc(2026, 9, 5),
              ),
            ],
          ),
        ),
      );
      addTearDown(container.dispose);
      return container;
    }

    test('accept calls respond_to_trip once', () async {
      final fake = FakeAlongSupabase(
        signedInUser: User(
          id: 'test-driver-id',
          appMetadata: const {},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      Map<String, dynamic>? captured;
      fake.onRespondToTrip = (params) => captured = params;

      final channel = FakeDriverChannel();
      final container = ProviderContainer(
        overrides: buildProviderOverrides(
          config: testConfig,
          supabase: fake,
          database: AlongDatabase.memory(),
          driverChannel: channel,
          clock: Clock.fixed(DateTime.utc(2026, 9, 5, 13, 59, 40)),
          batteryMonitor: FakeBatteryMonitor(
            const BatterySnapshot(levelPercent: 80, isCharging: false),
          ),
          locationStreamSource: FakeLocationStreamSource(
            permissionGranted: true,
            fixedSamples: [
              LocationSample(
                point: const GeoPoint(lat: 9.05, lng: 7.49),
                accuracyM: 8,
                recordedAt: DateTime.utc(2026, 9, 5),
              ),
            ],
          ),
        ),
      );
      addTearDown(container.dispose);

      container.read(incomingRequestNotifierProvider);
      final home = container.read(driverHomeControllerProvider.notifier);

      await _pumpUntilReady(container);
      await home.setStatus(DriverStatus.roamingAvailable);
      await _pumpUntilReady(container);
      expect(channel.subscribedDriverId, 'test-driver-id');

      channel.emitTripRequest(fake.sampleTripRequestEnvelope());
      await _pumpUntilReady(container);

      expect(container.read(incomingRequestNotifierProvider), isNotNull);

      await container.read(incomingRequestNotifierProvider.notifier).accept();
      await _pumpUntilReady(container);

      expect(captured?['p_action'], 'accept');
      expect(captured?['p_trip_id'], 'trip-1');
      expect(container.read(incomingRequestNotifierProvider), isNull);
    });
  });

  testWidgets('offer card fits 320dp and a voice phrase accepts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var accepted = 0;
    await tester.pumpWidget(
      buildSheet(
        state: sampleState(loadFlagged: false),
        onAccept: () => accepted++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('incoming_request_accept')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const Key('incoming_voice_command')),
      'gree',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(accepted, 1);
  });
}

Future<void> _pumpUntilReady(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
    container.read(driverHomeControllerProvider);
  }
}
