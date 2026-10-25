import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Large-text and narrow-width probe. Separate from the 1.0 golden wrap
/// rule: wrapping is allowed, overflow and a clipped essential action are not.
void main() {
  final stages = <String, Widget>{
    'onboarding': AlongFlowOnboarding(),
    'home': const AlongFlowHome(),
    'rides': const AlongFlowRides(),
    'seats': const AlongFlowSeats(),
    'search': const AlongFlowSearch(),
    'live': const AlongFlowLive(),
    'rating': const AlongFlowRating(),
    'sos': const AlongFlowSos(),
    'guardian': const AlongFlowGuardian(),
    'plate': const AlongFlowPlate(),
    'wallet': const AlongFlowWallet(),
    'day': const AlongFlowDay(),
    'online': const AlongFlowOnline(),
    'offer': const AlongFlowOffer(),
    'earnings': const AlongFlowEarnings(),
    'pickup': const AlongFlowPickup(),
    'quote': const AlongFlowQuote(),
    'matching': const AlongFlowMatching(),
    'recovery': const AlongFlowRecovery(),
    'pin': const AlongFlowTripPin(),
    'driver': const AlongFlowDriver(),
    'nav': const AlongFlowNav(),
    'receipt': const AlongFlowReceipt(),
    'notices': const AlongFlowNotices(),
    'settings': const AlongFlowSettings(),
    'pass': const AlongFlowPass(),
    'split': const AlongFlowSplit(),
    'loading': const AlongFlowLoading(),
    'refresh': const AlongFlowRefresh(),
    'phases': const AlongFlowPhases(),
    'dev-motions': const AlongFlowMotions(),
    'schedule': const AlongFlowSchedule(),
    'stops': const AlongFlowStops(),
    'options': const AlongFlowRideOptions(
      options: AlongRideOptions(
        squeezeFree: true,
        seatHolds: 1,
        womenOnlyRows: [2],
      ),
    ),
    'topup': const AlongFlowTopUp(),
    'payout': const AlongFlowPayout(),
    'offline-home': const AlongFlowOfflineHome(),
    'offline-matching': const AlongFlowOfflineMatching(),
    'offline-live': const AlongFlowOfflineLive(),
    'offline-reconnecting': const AlongFlowOfflineReconnecting(),
    'empty-routes': const Scaffold(
      body: EmptyState(variant: EmptyStateVariant.coverageGap),
    ),
    'empty-history': const Scaffold(
      body: EmptyState(variant: EmptyStateVariant.noHistory),
    ),
    'empty-offline': const Scaffold(
      body: EmptyState(variant: EmptyStateVariant.offline),
    ),
  };

  for (final stage in stages.entries) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final size in const [Size(360, 800), Size(320, 640)]) {
        for (final scale in const [1.3, 2.0]) {
          final tone = brightness == Brightness.dark ? 'dark' : 'light';
          final label =
              '${stage.key} $tone ${size.width.toInt()}x${size.height.toInt()} x$scale';
          testWidgets(label, (tester) async {
            await _pump(
              tester,
              child: stage.value,
              brightness: brightness,
              size: size,
              scale: scale,
            );
            expect(tester.takeException(), isNull, reason: label);
            _expectEssentialActions(tester, label);
          });
        }
      }
    }
  }

  testWidgets('reduced motion keeps the next action at text scale 2', (
    tester,
  ) async {
    const actions = [
      'Confirm fare',
      'Cancel search',
      'Widen radius',
      'Try again',
      'Call 112',
      'Report an issue',
      'Test haptic',
    ];
    final pages = [
      const AlongFlowQuote(),
      const AlongFlowMatching(),
      const AlongFlowRecovery(),
      const AlongFlowNotices(),
      const AlongFlowSos(),
      const AlongFlowReceipt(),
      const AlongFlowSettings(),
    ];
    for (var i = 0; i < pages.length; i++) {
      await _pump(
        tester,
        child: pages[i],
        size: const Size(320, 640),
        scale: 2,
        reduced: true,
      );
      expect(tester.takeException(), isNull, reason: actions[i]);
      expect(find.text(actions[i]), findsOneWidget, reason: actions[i]);
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required double scale,
  Brightness brightness = Brightness.light,
  bool reduced = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: alongTheme(brightness: brightness),
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced || data.disableAnimations,
          ),
          child: child!,
        );
      },
      home: child,
    ),
  );
  await tester.pump();
}

void _expectEssentialActions(WidgetTester tester, String label) {
  final problems = <String>[];
  for (final button in find.byType(AlongButton).evaluate()) {
    final texts = find.descendant(
      of: find.byWidget(button.widget),
      matching: find.byType(Text),
    );
    for (final element in texts.evaluate()) {
      final render = element.renderObject;
      if (render is RenderParagraph && render.didExceedMaxLines) {
        problems.add(render.text.toPlainText());
      }
    }
  }
  expect(problems, isEmpty, reason: '$label clipped actions: $problems');
}
