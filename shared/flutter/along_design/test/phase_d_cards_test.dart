import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guardian check fits 320dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianCheckCard(
            title: 'Are you OK?',
            body: 'The car has been still longer than you asked.',
            confirmLabel: "I'm OK",
            onConfirm: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('guardian_check_ok')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest nudge names priority and hides money', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestNudgeCard(
            title: 'Time for a break',
            body: 'You have been driving longer than your limit.',
            restLabel: 'Start rest',
            priorityLabel: 'Priority dispatch is on after this rest',
            onRest: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('rest_priority_label')), findsOneWidget);
    expect(find.textContaining('₦'), findsNothing);
    expect(find.textContaining('NGN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('masked message shows the role only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MaskedMessageLine(
            roleLabel: 'Driver',
            body: 'Black bag is in the boot',
          ),
        ),
      ),
    );
    expect(find.text('Driver'), findsOneWidget);
    expect(find.textContaining('+234'), findsNothing);
  });
}
