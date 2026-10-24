import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AlongMotionPolicy.debugPlayMotion = false;
    AlongGyroCard.debugTilt = Offset.zero;
    AlongHaptics.requested = 0;
    AlongHaptics.enabled = true;
  });

  testWidgets('seat selection springs through the peak and rests at 1', (
    tester,
  ) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(_seat(status: 'yours'));
    await tester.pump();
    final start = _seatScale(tester);
    expect(start, lessThan(0.95));
    var peak = start;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      peak = peak < _seatScale(tester) ? _seatScale(tester) : peak;
    }
    expect(peak, greaterThan(1.02));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_seatScale(tester), closeTo(1, 0.04));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a seat taken live pulses and then rests', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(_seat(status: 'free'));
    await tester.pumpWidget(_seat(status: 'occupied'));
    await tester.pump();
    var peak = _seatScale(tester);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      final scale = _seatScale(tester);
      if (scale > peak) peak = scale;
    }
    expect(peak, greaterThan(1.01));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_seatScale(tester), closeTo(1, 0.05));
  });

  testWidgets('reduced motion keeps the selected seat at rest', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _seat(status: 'yours'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_seatScale(tester), 1);
  });

  testWidgets('check stroke completes', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AlongStrokeCheck(color: Color(0xFF111111))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final state = tester.state<AlongStrokeCheckState>(
      find.byType(AlongStrokeCheck),
    );
    expect(state, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet fling settles on the upper snap', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlongMapMotion(
            builder: (context, extent) {
              return Stack(
                children: [
                  Text('extent:${extent.toStringAsFixed(2)}'),
                  AlongSpringSheet(
                    fraction: 0.4,
                    snaps: const [0.4, 0.8],
                    child: const SizedBox.expand(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('extent:0.00'), findsOneWidget);
    await tester.fling(
      find.byKey(const Key('sheet_handle')),
      const Offset(0, -280),
      2000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final panel = tester.getSize(find.byKey(const Key('sheet_panel')));
    expect(panel.height, greaterThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe confirm completes and asks for a success haptic', (
    tester,
  ) async {
    AlongMotionPolicy.debugPlayMotion = true;
    var held = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: AlongSwipeConfirm(
                label: 'Hold this seat',
                onConfirmed: () => held = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(
      find.byKey(const Key('swipe_thumb')),
      const Offset(240, 0),
    );
    await tester.pump();
    expect(held, isTrue);
    expect(AlongHaptics.requested, greaterThan(0));
    expect(find.text('Held'), findsOneWidget);
  });

  testWidgets('route pulse finishes a cycle', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    var cycles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AlongRoutePulse(onCycle: () => cycles++)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(cycles, 1);
  });

  testWidgets('pin drop rests at zero', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlongPinDrop(
            child: SizedBox(key: Key('pin'), width: 12, height: 12),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.getTopLeft(find.byKey(const Key('pin'))).dy, closeTo(0, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('odometer rests on the new fare', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    var amount = 100;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  AlongOdometer(
                    value: amount,
                    style: const TextStyle(fontSize: 20),
                  ),
                  TextButton(
                    onPressed: () => setState(() => amount = 1200),
                    child: const Text('roll'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('roll'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('₦'), findsWidgets);
    expect(find.text('1,200'), findsOneWidget);
  });

  testWidgets('splash mark finishes into the handoff', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    var done = false;
    await tester.pumpWidget(
      MaterialApp(home: AlongSplash(onDone: () => done = true)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(done, isTrue);
    expect(find.text('Along'), findsOneWidget);
  });

  testWidgets('container transform opens onto the next screen', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    var open = false;
    Future<void> pump() {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlongContainerTransform(
              open: open,
              closed: const Text('Go'),
              destination: const Text('Arrived'),
            ),
          ),
        ),
      );
    }

    await pump();
    expect(find.text('Go'), findsOneWidget);
    open = true;
    await pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Arrived'), findsOneWidget);
  });

  testWidgets('gyro card tilts only when a reading is supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlongGyroCard(child: Text('Wallet'))),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(AlongGyroCard),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    AlongGyroCard.debugTilt = const Offset(0.4, -0.2);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlongGyroCard(child: Text('Wallet'))),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(AlongGyroCard),
        matching: find.byType(Transform),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a seat tap depresses the cushion and asks for a light haptic', (
    tester,
  ) async {
    AlongMotionPolicy.debugPlayMotion = true;
    AlongHaptics.requested = 0;
    AlongSeatPress.depress.clear();
    await tester.pumpWidget(_seat(status: 'free', onSeatTap: (_) {}));
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('seat_fm'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(AlongSeatPress.depress['fm'] ?? 0, greaterThan(0.15));
    await gesture.up();
    await tester.pump();
    expect(AlongHaptics.requested, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(AlongSeatPress.depress['fm'] ?? 1, lessThan(0.2));
    expect(_seatScale(tester), closeTo(1, 0.06));
    expect(tester.takeException(), isNull);
  });

  testWidgets('eta digits roll onto the new range', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    var label = '1-2';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  AlongRollingDigits(
                    text: label,
                    suffix: ' min',
                    style: const TextStyle(fontSize: 28, height: 1),
                  ),
                  TextButton(
                    onPressed: () => setState(() => label = '4-6'),
                    child: const Text('roll'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('roll'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('4'), findsWidgets);
    expect(find.text('6'), findsWidgets);
    expect(find.text(' min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vehicle hero flies from the card into the quote', (
    tester,
  ) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  height: 72,
                  child: InkWell(
                    key: const Key('open_quote'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AlongFlowQuote(),
                        ),
                      );
                    },
                    child: const AlongVehicleHero(
                      kind: AlongVehicleKind.keke,
                      width: 96,
                      height: 60,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_quote')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AlongVehicleMark), findsWidgets);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Confirm fare'), findsOneWidget);
    expect(find.text('Quote'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the refresh car rests mid-road when motion is off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, child: AlongDriveTrack(progress: 0.58)),
        ),
      ),
    );
    await tester.pump();
    final car = tester.getTopLeft(find.byType(AlongVehicleMark));
    expect(car.dx, greaterThan(80));
    expect(car.dx, lessThan(220));
    expect(tester.takeException(), isNull);
  });

  testWidgets('who is riding uses initials', (tester) async {
    await tester.pumpWidget(_seat(status: 'free', riders: AlongRider.riding));
    expect(find.text("Who's riding"), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);
    expect(find.text('Chinedu'), findsNothing);
    expect(find.bySemanticsLabel('Rider CN'), findsOneWidget);
  });

  testWidgets('tab icon selection settles', (tester) async {
    AlongMotionPolicy.debugPlayMotion = true;
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AlongTabBar())),
    );
    await tester.tap(find.bySemanticsLabel('Rides'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keke refresh runs and hides', (tester) async {
    var ran = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlongKekeRefresh(
            onRefresh: () async {
              ran = true;
              await Future<void>.delayed(const Duration(milliseconds: 30));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 400, child: Text('rows'))],
            ),
          ),
        ),
      ),
    );
    await tester.fling(find.text('rows'), const Offset(0, 400), 2000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(ran, isTrue);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('keke_refresh')), findsNothing);
  });

  testWidgets('moments and the goal ring build at rest', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AlongMoment(kind: AlongMomentKind.confirmed),
              AlongMoment(kind: AlongMomentKind.arriving),
              AlongProgressRing(progress: 1, label: '100%', celebrate: true),
              AlongFareSplit(each: 600),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('You ₦600'), findsOneWidget);
    expect(find.byIcon(AlongIcons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ride pieces rest without ticking', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AlongLiveStrip(),
                AlongFareLock(clock: '1:48', progress: 0.9),
                AlongArrivalMark(),
                AlongGoalSpring(progress: 48200 / 60000, label: '80'),
                AlongQuickReplies(),
                AlongBreakNudge(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('live_strip')), findsOneWidget);
    expect(find.byKey(const Key('fare_lock')), findsOneWidget);
    expect(find.byKey(const Key('arrival_mark')), findsOneWidget);
    expect(find.byKey(const Key('goal_spring')), findsOneWidget);
    expect(find.byKey(const Key('quick_replies')), findsOneWidget);
    expect(find.byKey(const Key('break_nudge')), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('I dey come'), findsOneWidget);
    expect(find.text('Take a break'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}

double _seatScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byKey(const Key('seat_fm')),
          matching: find.byType(Transform),
        )
        .first,
  );
  // Transform.scale leaves z at 1, so the axis max stays 1. Read x.
  return transform.transform.storage[0];
}

Widget _seat({
  required String status,
  List<AlongRider> riders = const [],
  ValueChanged<String>? onSeatTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SeatMap(
        body: 'cabin',
        riders: riders,
        onSeatTap: onSeatTap,
        rows: [
          SeatMapRowView(
            id: 'front',
            seats: [
              SeatMapSeat(
                id: 'fm',
                label: 'FM',
                role: 'passenger',
                status: status,
                statusWord: status,
                price: '₦1,200',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
