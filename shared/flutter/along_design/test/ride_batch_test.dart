import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('motion gallery names each rest pose', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlongFlowMotions()));
    await tester.pump();
    expect(find.text('Springs into place.'), findsOneWidget);
    expect(find.text('Scales, then a tick.'), findsOneWidget);
    expect(find.text('Fare counts up.'), findsOneWidget);
    expect(find.text('Draws itself on.'), findsOneWidget);
    expect(find.text('Draws along the trip.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule books the weekday commute', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlongFlowSchedule()));
    await tester.pump();
    expect(find.text('Book the commute'), findsOneWidget);
    expect(find.text('Repeats Mon to Fri'), findsOneWidget);
    await tester.tap(find.byKey(const Key('commute_switch')));
    await tester.pump();
    expect(find.text('Book Thursday'), findsOneWidget);
    expect(find.text('One seat, this week'), findsOneWidget);
  });

  testWidgets('stops show the rider and an ETA', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlongFlowStops()));
    await tester.pump();
    expect(find.text('Along'), findsOneWidget);
    expect(find.text('Danfo'), findsOneWidget);
    expect(find.text('After Berger'), findsOneWidget);
    expect(find.text('On this danfo'), findsOneWidget);
    expect(find.text('7:41'), findsOneWidget);
    expect(find.text('Now'), findsNWidgets(2));
  });

  testWidgets('ride options start from the driver model', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlongFlowRideOptions(
          options: AlongRideOptions(
            squeezeFree: true,
            seatHolds: 1,
            womenOnlyRows: [2],
          ),
        ),
      ),
    );
    await tester.pump();
    final squeeze = tester.widget<Switch>(
      find.byKey(const Key('squeeze_free')),
    );
    expect(squeeze.value, isTrue);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(AlongIcons.check), findsOneWidget);

    await tester.tap(find.byKey(const Key('women_row_1')));
    await tester.pump();
    expect(find.byIcon(AlongIcons.check), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('seat_hold_more')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('squeeze_free')));
    await tester.pump();
    expect(
      tester.widget<Switch>(find.byKey(const Key('squeeze_free'))).value,
      isFalse,
    );
  });

  testWidgets('an empty ride option model stays off', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlongFlowRideOptions(options: AlongRideOptions()),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<Switch>(find.byKey(const Key('squeeze_free'))).value,
      isFalse,
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.byIcon(AlongIcons.check), findsNothing);
  });

  testWidgets('top up selects a closed-loop amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlongFlowTopUp()));
    await tester.pump();
    expect(find.text('Along credit'), findsOneWidget);
    expect(find.text('It stays in Along'), findsOneWidget);
    expect(find.text('Add ₦2,000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('topup_5000')));
    await tester.pump();
    expect(find.text('Add ₦5,000'), findsOneWidget);
  });

  testWidgets('payout settles the pending amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlongFlowPayout()));
    await tester.pump();
    expect(find.text('Your Along account'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text('Settle ₦18,400'), findsOneWidget);
    expect(find.text('Paid'), findsNWidgets(4));
  });
}
