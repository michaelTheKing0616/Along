import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fair fare card fits 320 and a dispute leaves the usual fare', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var disputes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FairFareCard(
            title: 'Fair fare',
            offeredLabel: 'Offer ₦1,500',
            usualLabel: 'Usual fare ₦900',
            quietLabel: 'Not enough trips on this corridor yet',
            disputeLabel: 'This fare is high',
            weatherReason: 'Heavy rain on Nyanya road',
            onDispute: () => disputes += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Usual fare ₦900'), findsOneWidget);
    expect(find.text('Heavy rain on Nyanya road'), findsOneWidget);
    expect(find.textContaining('+234'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('fair_fare_dispute')));
    await tester.pump();
    expect(disputes, 1);
    expect(find.text('Usual fare ₦900'), findsOneWidget);
  });
}
