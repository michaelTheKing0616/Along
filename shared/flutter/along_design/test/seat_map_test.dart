import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seat targets are 48dp and a row rule title is the driver text', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeatMap(
            body: 'cabin',
            onSeatTap: (id) => tapped = id,
            rows: const [
              SeatMapRowView(
                id: 'back',
                ruleTitle: 'Women only in the back',
                seats: [
                  SeatMapSeat(
                    id: 'b1',
                    label: 'Back left',
                    role: 'passenger',
                    status: 'free',
                    statusWord: 'free',
                  ),
                  SeatMapSeat(
                    id: 'drv',
                    label: 'Driver',
                    role: 'driver',
                    status: 'blocked',
                    statusWord: 'driver',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Women only in the back'), findsOneWidget);
    expect(find.bySemanticsLabel('Back left, free'), findsOneWidget);
    final box = tester.getSize(find.byKey(const Key('seat_b1')));
    expect(box.width, greaterThanOrEqualTo(AlongSpace.sizeTouchMin));
    expect(box.height, greaterThanOrEqualTo(AlongSpace.sizeTouchMin));

    await tester.tap(find.byKey(const Key('seat_b1')));
    expect(tapped, 'b1');

    await tester.tap(find.byKey(const Key('seat_drv')));
    expect(tapped, 'b1');
  });

  testWidgets('coach and bike chrome both render from the body token', (
    tester,
  ) async {
    for (final body in ['coach', 'bike', 'bench']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeatMap(
              body: body,
              rows: const [
                SeatMapRowView(
                  id: 'r',
                  seats: [
                    SeatMapSeat(
                      id: 'p',
                      label: 'Seat',
                      role: 'passenger',
                      status: 'held',
                      statusWord: 'held',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('seat_p')), findsOneWidget);
    }
  });
}
