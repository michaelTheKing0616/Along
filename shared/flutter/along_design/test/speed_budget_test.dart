// Tap-count budgets from docs/speed-budget.md. Each test counts the taps a
// rider or driver makes to finish the action and fails if a flow grows.
import 'dart:async';

import 'package:along_core/along_core.dart';
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

  group('Na Me board', () {
    const pairing = AlongNaMeChoice(
      colorToken: 'color.naMe.green',
      shape: 'circle',
      label: 'Green Circle',
    );
    const options = [
      AlongNaMeChoice(
        colorToken: 'color.naMe.blue',
        shape: 'star',
        label: 'Blue Star',
      ),
      pairing,
      AlongNaMeChoice(
        colorToken: 'color.naMe.red',
        shape: 'square',
        label: 'Red Square',
      ),
      AlongNaMeChoice(
        colorToken: 'color.naMe.purple',
        shape: 'diamond',
        label: 'Purple Diamond',
      ),
    ];

    Widget flow({
      Stream<NaMeOpticalProof>? proofs,
      required VoidCallback onBoarded,
      List<String>? pins,
    }) => AlongNaMeDriverFlow(
      riderName: 'Ada',
      pairing: pairing,
      options: options,
      opticalProofs: proofs,
      onOptical: proofs == null
          ? null
          : (_) async => const AlongNaMeResult(AlongNaMeVerdict.matched),
      onTap: (c) async => c == pairing
          ? const AlongNaMeResult(AlongNaMeVerdict.matched)
          : const AlongNaMeResult(
              AlongNaMeVerdict.wrong,
              attemptsLeft: 2,
              tapLocked: true,
            ),
      onPin: (pin) async {
        pins?.add(pin);
        onBoarded();
        return const AlongPinResult(AlongPinVerdict.verified);
      },
      onStart: () {},
    );

    testWidgets('optical: 0 taps to board', (tester) async {
      final proofs = StreamController<NaMeOpticalProof>();
      addTearDown(proofs.close);
      await _pump(tester, flow(proofs: proofs.stream, onBoarded: () {}));
      expect(find.byKey(const Key('na_me_camera')), findsOneWidget);
      proofs.add(const NaMeOpticalProof(code: 1, step: 1));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('na_me_match')), findsOneWidget);
      expect(find.byKey(const Key('na_me_start')), findsOneWidget);
    });

    testWidgets('tap-match: 1 tap to board', (tester) async {
      var taps = 0;
      await _pump(tester, flow(onBoarded: () {}));
      await tester.tap(find.byKey(const Key('na_me_choice_1')));
      taps++;
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('na_me_match')), findsOneWidget);
      expect(taps, 1);
    });

    testWidgets('PIN: 1 tap + 4 digits to board', (tester) async {
      var taps = 0;
      var boarded = false;
      final pins = <String>[];
      await _pump(tester, flow(onBoarded: () => boarded = true, pins: pins));
      await tester.tap(find.byKey(const Key('na_me_use_pin')));
      taps++;
      await tester.pump();
      for (final d in ['4', '8', '2', '7']) {
        await tester.tap(find.byKey(Key('pin_key_$d')));
        taps++;
        await tester.pump();
      }
      await tester.pump();
      expect(boarded, isTrue);
      expect(pins, ['4827']);
      expect(taps, 5);
    });

    testWidgets('no decode in 6 s falls back to tap-match', (tester) async {
      final proofs = StreamController<NaMeOpticalProof>();
      addTearDown(proofs.close);
      await _pump(tester, flow(proofs: proofs.stream, onBoarded: () {}));
      await tester.pump(const Duration(milliseconds: 5900));
      expect(find.byKey(const Key('na_me_camera')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('na_me_tap')), findsOneWidget);
    });

    testWidgets('a wrong tap is neutral and reveals nothing', (tester) async {
      await _pump(tester, flow(onBoarded: () {}));
      await tester.tap(find.byKey(const Key('na_me_choice_0')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('na_me_no_match')), findsOneWidget);
      expect(find.byKey(const Key('na_me_match')), findsNothing);
      for (final o in options) {
        expect(find.text(o.label), findsNothing);
      }
      // Tap-match is locked after one wrong tap: only the PIN is offered.
      expect(find.byKey(const Key('na_me_retry')), findsNothing);
      expect(find.byKey(const Key('na_me_no_match_pin')), findsOneWidget);
    });

    testWidgets('the match finishes under 1.2 s and the rider taps nothing', (
      tester,
    ) async {
      var done = false;
      await _pump(
        tester,
        AlongNaMeCelebration(
          pairing: pairing,
          title: 'You\'re matched',
          onDone: () => done = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1150));
      expect(done, isTrue);
      expect(AlongMoves.match.duration.inMilliseconds, lessThan(1200));
    });

    testWidgets('reduced motion: the match lands on its rest pose at once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(360, 800), disableAnimations: true),
            child: AlongNaMeCelebration(
              pairing: pairing,
              title: 'You\'re matched',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final title = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text('You\'re matched'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(title.opacity, 1);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
