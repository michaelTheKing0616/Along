import 'package:along_core/along_core.dart'
    show Money, TripReceipt, TripSummary;
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/active_trip_screen.dart';
import 'package:mobile_rider/features/live_trip/presentation/driver_contact.dart';
import 'package:mobile_rider/features/live_trip/presentation/live_trip_controller.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_receipt_page.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/testing/fakes/fake_along_supabase.dart';
import 'package:mobile_rider/testing/fakes/fake_ambient_channel.dart';

import 'support/trip_options_fixtures.dart';

Map<String, dynamic> _eta({
  Map<String, dynamic>? pickup,
  Map<String, dynamic>? trip,
}) => {
  'status': 'ready',
  'pickup': pickup,
  'trip': trip,
  'stops': const <Map<String, dynamic>>[],
  'updated_at': '2026-10-25T06:30:00.000Z',
};

ProviderContainer _container(
  FakeAlongSupabase supabase, {
  List<Uri>? launched,
}) => ProviderContainer(
  overrides: [
    ...buildProviderOverrides(
      config: const AppConfig(
        flavor: 'dev',
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'test-key',
      ),
      supabase: supabase,
      ambientChannel: FakeAmbientChannel(),
      database: AlongDatabase.memory(),
      wayfindingTts: FakeWayfindingTts(),
    ),
    contactLauncherProvider.overrideWithValue(
      (uri) async => launched?.add(uri),
    ),
  ],
);

Widget _harness(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void _stop(ProviderContainer container, TripSummary trip) {
  container
      .read(
        liveTripControllerFamilyProvider(
          LiveTripArgs(tripId: trip.tripId, initialTrip: trip),
        ).notifier,
      )
      .stopPolling();
}

void main() {
  testWidgets(
    'driver-arrival phase shows the handoff panel from the pickup ETA',
    (tester) async {
      final json = sampleAcceptedTripResponse(tripId: 'trip-handoff-1');
      json['eta'] = _eta(
        pickup: {
          'kind': 'single',
          'low_s': 150,
          'high_s': 150,
          'label': '3 min',
        },
      );
      json['handoff'] = {'pin': '4827', 'contact_available': true};
      final trip = tripSummaryFromFixture(json);
      final launched = <Uri>[];
      final supabase = FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: json,
      );
      final container = _container(supabase, launched: launched);
      await tester.pumpWidget(
        _harness(container, ActiveTripScreen(trip: trip)),
      );
      await tester.pump();

      expect(find.byKey(const Key('active_trip_handoff')), findsOneWidget);
      expect(find.text('2:30'), findsOneWidget);
      expect(find.text(trip.vehicle.plateNumber), findsWidgets);
      expect(find.byType(AlongLiveEtaPanel), findsNothing);
      expect(find.byKey(const Key('handoff_pin')), findsOneWidget);
      for (final d in ['4', '8', '2', '7']) {
        expect(find.text(d), findsWidgets);
      }
      await tester.ensureVisible(find.byKey(const Key('handoff_call')));
      await tester.tap(find.byKey(const Key('handoff_call')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('handoff_message')));
      await tester.pump();
      // Contact goes through the trip-contact relay, never a payload phone.
      expect(supabase.tripContactCalls.map((c) => c['channel']), [
        'call',
        'sms',
      ]);
      expect(launched, [
        Uri(scheme: 'tel', path: '+2348031234567'),
        Uri(scheme: 'sms', path: '+2348031234567'),
      ]);

      // Rider can mint a fresh PIN in one tap; the card shows it at once.
      await tester.ensureVisible(find.byKey(const Key('handoff_new_pin')));
      await tester.tap(find.byKey(const Key('handoff_new_pin')));
      await tester.pump();
      await tester.pump();
      expect(supabase.regeneratePinCalls, 1);
      expect(find.text('1'), findsWidgets);
      expect(find.text('5'), findsWidgets);

      _stop(container, trip);
      await tester.pump();
      container.dispose();
    },
  );

  testWidgets('in transit shows the live ETA window, median to p85', (
    tester,
  ) async {
    final json = sampleAcceptedTripResponse(
      tripId: 'trip-live-1',
      status: 'in_transit',
    );
    json['eta'] = _eta(
      trip: {
        'kind': 'range',
        'low_s': 720,
        'high_s': 960,
        'label': '12–16 min',
      },
    );
    final trip = tripSummaryFromFixture(json);
    final container = _container(
      FakeAlongSupabase(
        configRows: defaultTestConfigRows(),
        requestTripResponse: json,
      ),
    );
    await tester.pumpWidget(_harness(container, ActiveTripScreen(trip: trip)));
    await tester.pump();

    expect(find.byKey(const Key('active_trip_handoff')), findsNothing);
    expect(find.text('12–16'), findsOneWidget);

    _stop(container, trip);
    await tester.pump();
    container.dispose();
  });

  testWidgets('completion shows the receipt once the complete sheet is done', (
    tester,
  ) async {
    final json = sampleAcceptedTripResponse(
      tripId: 'trip-done-1',
      status: 'in_transit',
    );
    final trip = tripSummaryFromFixture(json);
    final supabase =
        FakeAlongSupabase(
            configRows: defaultTestConfigRows(),
            requestTripResponse: json,
          )
          ..tripSnapshotSequence = [
            {...json, 'status': 'completed'},
          ];
    final container = _container(supabase);
    await tester.pumpWidget(_harness(container, ActiveTripScreen(trip: trip)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    final yes = find.byKey(const Key('trip_complete_yes'));
    if (yes.evaluate().isNotEmpty) {
      await tester.tap(yes);
      await tester.pumpAndSettle();
    }
    final paidCash = find.byKey(const Key('trip_complete_paid_cash'));
    if (paidCash.evaluate().isNotEmpty) {
      await tester.tap(paidCash);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('trip_complete_done')), findsNothing);
    expect(find.byKey(const Key('trip_receipt_page')), findsOneWidget);
    expect(find.byKey(const Key('receipt_stars')), findsOneWidget);

    // One rating, sent once, when the rider leaves the receipt.
    await tester.tap(find.byKey(const Key('receipt_star_3')));
    await tester.tap(find.byKey(const Key('receipt_star_4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('receipt_tag_safe_driving')));
    await tester.tap(find.byKey(const Key('receipt_tag_on_time')));
    await tester.tap(find.byKey(const Key('receipt_tag_safe_driving')));
    await tester.tap(find.byKey(const Key('receipt_tag_polite')));
    await tester.pump();
    expect(supabase.rateTripInvokeCount, 0);
    await tester.tap(find.byKey(const Key('receipt_done')));
    await tester.pumpAndSettle();
    expect(supabase.rateTripInvokeCount, 1);
    expect(supabase.lastRateTripParams?['p_score'], 4);
    expect(supabase.lastRateTripParams?['p_tags'], ['on_time', 'polite']);
    expect(find.byKey(const Key('trip_receipt_page')), findsNothing);

    _stop(container, trip);
    await tester.pump();
    container.dispose();
  });

  test('rating tag labels', () {
    expect(ratingTagLabel('clean_vehicle'), 'Clean car');
    expect(ratingTagLabel('great_music'), 'Great music');
  });

  test('receipt view maps server lines and total', () {
    final trip = tripSummaryFromFixture(sampleAcceptedTripResponse());
    final view = receiptViewFor(
      trip,
      TripReceipt(
        fare: Money.parse('1200', currency: 'NGN'),
        surcharge: Money.parse('150', currency: 'NGN'),
        total: Money.parse('1350', currency: 'NGN'),
      ),
      DateTime(2026, 10, 25, 7, 52),
    );
    expect(view.lines.map((l) => l.label), ['Fare', 'Load surcharge']);
    expect(view.lines.map((l) => l.amount), [1200, 150]);
    expect(view.total, 1350);
    expect(view.when, 'Today, 07:52');
    expect(view.paidCash, isNull);
  });
}
