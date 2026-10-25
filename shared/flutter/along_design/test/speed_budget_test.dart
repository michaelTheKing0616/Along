// Tap-count budgets from docs/speed-budget.md. Each test counts the taps a
// rider or driver makes to finish the action and fails if a flow grows.
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
}

void main() {
  testWidgets('rate: 1 star tap + Done = 2 taps', (tester) async {
    var taps = 0;
    int? rating;
    var done = false;
    await _pump(
      tester,
      AlongTripReceiptScreen(
        receipt: AlongReceipt.sample,
        onRate: (v) => rating = v,
        onDone: () => done = true,
      ),
    );
    await tester.tap(find.byKey(const Key('receipt_star_5')));
    taps++;
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('receipt_done')));
    await tester.tap(find.byKey(const Key('receipt_done')));
    taps++;
    await tester.pump();
    expect(rating, 5);
    expect(done, isTrue);
    expect(taps, 2);
  });

  testWidgets('PIN: 4 digit taps, the 4th submits, no confirm', (tester) async {
    final submitted = <String>[];
    var taps = 0;
    await _pump(
      tester,
      AlongPinEntryScreen(
        riderName: 'Ada',
        onSubmit: (pin) async {
          submitted.add(pin);
          return const AlongPinResult(AlongPinVerdict.verified);
        },
      ),
    );
    for (final d in ['4', '8', '2', '7']) {
      await tester.tap(find.byKey(Key('pin_key_$d')));
      taps++;
      await tester.pump();
    }
    expect(submitted, ['4827']);
    expect(taps, 4);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('chat: a quick reply sends in 1 tap once the sheet is open', (
    tester,
  ) async {
    final sent = <String>[];
    await _pump(
      tester,
      Scaffold(
        body: AlongTripChatSheet(
          otherName: 'Musa',
          lines: const [],
          quickReplies: const ["I'm at the pickup", 'Where are you?'],
          onSend: sent.add,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trip_chat_quick_0')));
    await tester.pump();
    expect(sent, ["I'm at the pickup"]);
  });

  testWidgets('chat: typed text sends on the arrow and clears', (tester) async {
    final sent = <String>[];
    await _pump(
      tester,
      Scaffold(
        body: AlongTripChatSheet(
          otherName: 'Musa',
          lines: const [],
          quickReplies: const [],
          onSend: sent.add,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('trip_chat_input')),
      ' Blue bag ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('trip_chat_send')));
    await tester.pump();
    expect(sent, ['Blue bag']);
    expect(find.text(' Blue bag '), findsNothing);
  });

  testWidgets('chat: a failed line retries on tap; closed chat hides input', (
    tester,
  ) async {
    final retried = <String>[];
    final line = AlongChatLine(
      id: 'x1',
      body: 'Running 2 min late',
      mine: true,
      at: DateTime.utc(2026),
      status: AlongChatStatus.failed,
    );
    await _pump(
      tester,
      Scaffold(
        body: AlongTripChatSheet(
          otherName: 'Musa',
          lines: [line],
          quickReplies: const ['Okay'],
          onSend: (_) {},
          onRetry: retried.add,
        ),
      ),
    );
    expect(find.byKey(const Key('trip_chat_status_failed')), findsOneWidget);
    await tester.tap(find.byKey(const Key('trip_chat_retry_x1')));
    expect(retried, ['x1']);

    await _pump(
      tester,
      Scaffold(
        body: AlongTripChatSheet(
          otherName: 'Musa',
          lines: [line],
          quickReplies: const ['Okay'],
          onSend: (_) {},
          closed: true,
        ),
      ),
    );
    expect(find.byKey(const Key('trip_chat_input')), findsNothing);
    expect(find.text('This trip has ended. Chat is closed.'), findsOneWidget);
  });
}
