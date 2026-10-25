import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TripEta _eta(int lowS, int highS, {String status = 'ready'}) => TripEta(
  status: status,
  trip: TripEtaValue(kind: 'range', lowS: lowS, highS: highS, label: ''),
  stops: const [],
  updatedAt: DateTime(2026, 10, 25, 7, 36),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 800),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ETA window', () {
    test('median to p85 in minutes, never inverted', () {
      final w = AlongEtaWindow.fromEta(_eta(720, 960))!;
      expect(w.figure, '12–16');
      expect(AlongEtaWindow.fromEta(_eta(600, 600))!.figure, '10');
      expect(AlongEtaWindow.fromEta(_eta(0, 0, status: 'calculating')), isNull);
      expect(AlongEtaWindow.fromEta(null), isNull);
    });

    test('slowdown only past the 90 second threshold', () {
      expect(alongEtaSlowdownMinutes(_eta(600, 840), _eta(600, 900)), isNull);
      expect(alongEtaSlowdownMinutes(_eta(600, 840), _eta(700, 1020)), 3);
      expect(alongEtaSlowdownMinutes(null, _eta(600, 900)), isNull);
    });
  });

  testWidgets('receipt stars update and report the rating', (tester) async {
    int? rated;
    await _pump(
      tester,
      AlongTripReceiptScreen(
        receipt: AlongReceipt.sample,
        onRate: (r) => rated = r,
      ),
    );
    expect(find.byKey(const Key('receipt_change')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('receipt_star_3')));
    await tester.tap(find.byKey(const Key('receipt_star_3')));
    await tester.pump();
    expect(rated, isNotNull);
  });

  testWidgets('missing receipt offers a retry', (tester) async {
    var retried = false;
    await _pump(
      tester,
      AlongTripReceiptScreen(receipt: null, onRetry: () => retried = true),
    );
    await tester.tap(find.byKey(const Key('receipt_retry')));
    expect(retried, isTrue);
  });

  testWidgets('earnings switch periods and show the empty state', (
    tester,
  ) async {
    await _pump(
      tester,
      const AlongDriverEarningsScreen(
        today: AlongEarningsPeriod.emptyToday,
        week: AlongEarningsPeriod.week,
        payout: AlongPayout.sample,
      ),
    );
    expect(find.text('No trips today'), findsOneWidget);
    await tester.tap(find.byKey(const Key('earnings_week')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('No trips today'), findsNothing);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('handoff and earnings fit 320 wide at ${scale}x', (
      tester,
    ) async {
      await _pump(
        tester,
        const AlongPickupHandoffScreen(
          secondsAway: 95,
          driverName: 'Musa',
          plate: 'ABJ 482 KE',
          car: 'Silver Toyota Corolla',
          pin: '4827',
          pickupPoint: 'Wuse Market, Gate 2',
        ),
        size: const Size(320, 640),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('handoff_pin')), findsOneWidget);
      await _pump(
        tester,
        const AlongDriverEarningsScreen(
          today: AlongEarningsPeriod.today,
          week: AlongEarningsPeriod.week,
          payout: AlongPayout.sample,
        ),
        size: const Size(320, 640),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
