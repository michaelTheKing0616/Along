import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AlongHaptics.enabled = true;
    AlongHaptics.requested = 0;
    AlongMotionPolicy.debugPlayMotion = false;
  });

  testWidgets('a landmark chip snaps the pickup label', (tester) async {
    await tester.pumpWidget(const _App(child: AlongFlowPickup()));
    await tester.pump();
    expect(find.byKey(const Key('demo_adapter')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('pickup_label'))).data,
      'Wuse Market Gate 2',
    );

    await tester.tap(find.byKey(const Key('landmark_banex')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('pickup_label'))).data,
      'Banex entrance',
    );

    final size = tester.getSize(find.byKey(const Key('landmark_gate2')));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));

    final pin = find.byKey(const Key('pickup_pin'));
    final gesture = await tester.startGesture(tester.getCenter(pin));
    await gesture.moveBy(const Offset(0, -36));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('pickup_label'))).data,
      'Dropped pin',
    );
    await gesture.up();
  });

  testWidgets('a matched PIN asks for a success haptic', (tester) async {
    AlongHaptics.requested = 0;
    await tester.pumpWidget(const _App(child: AlongFlowDriver()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('verify_pin')));
    await tester.pump();
    expect(AlongHaptics.requested, 2);
    expect(find.text('PIN matched'), findsOneWidget);
  });

  testWidgets('the haptics toggle blocks the preview', (tester) async {
    await tester.pumpWidget(const _App(child: AlongFlowSettings()));
    await tester.pump();
    AlongHaptics.requested = 0;
    await tester.tap(find.byKey(const Key('haptics_try')));
    await tester.pump();
    expect(AlongHaptics.requested, 2);

    await tester.tap(find.byKey(const Key('haptics_switch')));
    await tester.pump();
    AlongHaptics.requested = 0;
    await tester.tap(find.byKey(const Key('haptics_try')));
    await tester.pump();
    expect(AlongHaptics.requested, 0);
  });

  testWidgets('reduced motion fades a press instead of scaling it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AlongPressable(
          child: ColoredBox(
            key: Key('press_child'),
            color: Color(0xFF000000),
            child: SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('press_child'))),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(AlongPressable),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlongPressable),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    await gesture.up();
  });

  testWidgets('confirm works without a swipe', (tester) async {
    var confirmed = 0;
    await tester.pumpWidget(
      _App(
        child: AlongSwipeConfirm(
          label: 'Accept',
          onConfirmed: () => confirmed++,
        ),
      ),
    );
    await tester.pump();
    final box = tester.getSize(find.byKey(const Key('confirm_without_swipe')));
    expect(box.width, greaterThanOrEqualTo(48));
    expect(box.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byKey(const Key('confirm_without_swipe')));
    await tester.pump();
    expect(confirmed, 1);
  });

  testWidgets('SOS copy calls 112 and does not promise a desk', (tester) async {
    await tester.pumpWidget(const _App(child: AlongFlowSos()));
    await tester.pump();
    final text = find
        .byType(Text)
        .evaluate()
        .map((element) {
          final widget = element.widget as Text;
          return widget.data ?? widget.textSpan?.toPlainText() ?? '';
        })
        .join('\n');
    expect(text, contains('Call 112'));
    expect(text.toLowerCase(), isNot(contains('safety team')));
    expect(text.toLowerCase(), isNot(contains('staffed')));
    expect(text, isNot(contains('24/7')));
  });
}

class _App extends StatelessWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: alongTheme(),
      home: child,
    );
  }
}
