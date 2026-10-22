import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stages = <String, Widget Function({bool legacy})>{
    'onboarding': ({bool legacy = false}) =>
        AlongFlowOnboarding(legacyCopy: legacy),
    'home': ({bool legacy = false}) => const AlongFlowHome(),
    'rides': ({bool legacy = false}) => const AlongFlowRides(),
    'seats': ({bool legacy = false}) => const AlongFlowSeats(),
    'search': ({bool legacy = false}) => const AlongFlowSearch(),
    'live': ({bool legacy = false}) => const AlongFlowLive(),
    'rating': ({bool legacy = false}) => const AlongFlowRating(),
    'sos': ({bool legacy = false}) => const AlongFlowSos(),
    'guardian': ({bool legacy = false}) => const AlongFlowGuardian(),
    'plate': ({bool legacy = false}) => const AlongFlowPlate(),
    'wallet': ({bool legacy = false}) => const AlongFlowWallet(),
    'day': ({bool legacy = false}) => const AlongFlowDay(),
    'online': ({bool legacy = false}) => const AlongFlowOnline(),
    'offer': ({bool legacy = false}) => const AlongFlowOffer(),
    'earnings': ({bool legacy = false}) => const AlongFlowEarnings(),
  };

  for (final stage in stages.entries) {
    // `goldens/flows/before/` is the frozen pass-1 baseline. Do not regenerate it
    // from these widgets.
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final size in const [Size(360, 800), Size(320, 640)]) {
        final tone = brightness == Brightness.dark ? 'dark' : 'light';
        final label = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('${stage.key} $tone $label', (tester) async {
          await _pump(
            tester,
            child: stage.value(),
            brightness: brightness,
            size: size,
          );
          _expectNoLabelWrap(tester, '${stage.key} $tone $label');
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              'goldens/flows/after/${stage.key}_${tone}_$label.png',
            ),
          );
        });
      }
    }
  }

  testWidgets('live route mid draw light 360', (tester) async {
    await _pump(
      tester,
      child: const AlongFlowLive(progress: 0.35),
      size: const Size(360, 800),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/flows/after/live_route_35_light_360x800.png'),
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  Size size = const Size(360, 800),
  Brightness brightness = Brightness.light,
  bool legacy = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final theme = legacy
      ? alongTheme().copyWith(
          scaffoldBackgroundColor: AlongPalette.legacy.bg,
          textTheme: AlongType.textTheme(AlongPalette.legacy),
          extensions: [AlongPalette.legacy],
        )
      : alongTheme(brightness: brightness);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: child,
      ),
    ),
  );
  await tester.pump();
  final context = tester.element(find.byType(MaterialApp));
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, context));
  }
  await tester.pump();
  final overflow = tester.takeException();
  expect(overflow, isNull, reason: 'layout overflow');
}

/// Short labels stay on one line. Ellipsis is allowed. A wrapped chip,
/// fare, or row label fails the golden run before the pixels are compared.
void _expectNoLabelWrap(WidgetTester tester, String stage) {
  final problems = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final render = element.renderObject;
    if (render is! RenderParagraph) continue;
    final plain = render.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    if (render.didExceedMaxLines) {
      problems.add('clipped: $plain');
    }
    if (plain.length > 40) continue;
    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: plain.length),
    );
    final tops = boxes.map((box) => box.top).toList()..sort();
    var lines = tops.isEmpty ? 1 : 1;
    for (var i = 1; i < tops.length; i++) {
      // Fallback glyphs (the naira) sit a pixel off the Latin baseline.
      if (tops[i] - tops[i - 1] > 6) lines++;
    }
    if (lines > 1) problems.add('wrapped: $plain');
  }
  expect(problems, isEmpty, reason: '$stage\n${problems.join('\n')}');
}
