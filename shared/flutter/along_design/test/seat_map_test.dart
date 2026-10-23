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

  testWidgets('cabin rows share a column grid and fill a tall phone', (
    tester,
  ) async {
    const rows = [
      SeatMapRowView(
        id: 'front',
        seats: [
          SeatMapSeat(
            id: 'fm',
            label: 'FM',
            role: 'passenger',
            status: 'yours',
            statusWord: 'Yours',
            price: '₦1,200',
          ),
          SeatMapSeat(
            id: 'fr',
            label: 'FR',
            role: 'passenger',
            status: 'free',
            statusWord: 'Free',
            price: '₦900',
          ),
          SeatMapSeat(
            id: 'drv',
            label: 'Driver',
            role: 'driver',
            status: 'occupied',
            statusWord: 'Driver',
          ),
        ],
      ),
      SeatMapRowView(
        id: 'back',
        seats: [
          SeatMapSeat(
            id: 'bl',
            label: 'BL',
            role: 'passenger',
            status: 'free',
            statusWord: 'Free',
            price: '₦700',
          ),
          SeatMapSeat(
            id: 'ml',
            label: 'ML',
            role: 'passenger',
            status: 'occupied',
            statusWord: 'Taken',
          ),
          SeatMapSeat(
            id: 'mr',
            label: 'MR',
            role: 'passenger',
            status: 'free',
            statusWord: 'Free',
            price: '₦700',
          ),
          SeatMapSeat(
            id: 'br',
            label: 'BR',
            role: 'passenger',
            status: 'free',
            statusWord: 'Free',
            price: '₦700',
          ),
        ],
      ),
    ];

    for (final size in const [Size(320, 640), Size(360, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            home: Scaffold(
              body: SeatMap(body: 'cabin', rows: rows),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final drv = tester.getRect(find.byKey(const Key('seat_drv')));
      final fm = tester.getRect(find.byKey(const Key('seat_fm')));
      final fr = tester.getRect(find.byKey(const Key('seat_fr')));
      final bl = tester.getRect(find.byKey(const Key('seat_bl')));
      final ml = tester.getRect(find.byKey(const Key('seat_ml')));
      final br = tester.getRect(find.byKey(const Key('seat_br')));
      final legend = tester.getRect(find.text('Available'));

      expect(drv.left, closeTo(bl.left, 0.6), reason: '$size flush left');
      expect(fr.right, closeTo(br.right, 0.6), reason: '$size flush right');
      expect(bl.width, greaterThanOrEqualTo(56), reason: '$size cushion');
      expect(bl.width, lessThanOrEqualTo(76.5), reason: '$size cap');
      expect(bl.height, closeTo(bl.width, 0.6), reason: '$size square');
      expect(drv.height, closeTo(bl.height, 0.6));
      expect(fm.width, greaterThan(bl.width));
      final frontPitch = fm.left - drv.left;
      final backPitch = ml.left - bl.left;
      expect(frontPitch / backPitch, closeTo(4 / 3, 0.02));
      expect(legend.bottom, greaterThan(size.height - 40));
      expect(br.bottom, greaterThan(legend.top - 48));
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('cabin layouts 2+3 and 3+3 fit 320 and 360', (tester) async {
    const layouts = [
      [
        ['A', 'B'],
        ['C', 'D', 'E'],
      ],
      [
        ['A', 'B', 'C'],
        ['D', 'E', 'F'],
      ],
    ];
    for (final size in const [Size(320, 640), Size(360, 800)]) {
      await tester.binding.setSurfaceSize(size);
      for (final layout in layouts) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size),
            child: MaterialApp(
              home: Scaffold(
                body: SeatMap(
                  body: 'cabin',
                  rows: [
                    for (var r = 0; r < layout.length; r++)
                      SeatMapRowView(
                        id: 'r$r',
                        seats: [
                          for (final label in layout[r])
                            SeatMapSeat(
                              id: 's$r$label',
                              label: label,
                              role: 'passenger',
                              status: 'free',
                              statusWord: 'Free',
                              price: '₦500',
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
    await tester.binding.setSurfaceSize(null);
  });
}
