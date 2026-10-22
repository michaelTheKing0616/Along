import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stages = <String, Widget Function({bool legacy})>{
    'onboarding': ({bool legacy = false}) =>
        AlongFlowOnboarding(legacyCopy: legacy),
    'home': ({bool legacy = false}) => const AlongFlowHome(),
    'seats': ({bool legacy = false}) => const AlongFlowSeats(),
    'live': ({bool legacy = false}) => const AlongFlowLive(),
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
    testWidgets('${stage.key} before light 360x800', (tester) async {
      await _pump(
        tester,
        child: stage.value(legacy: true),
        legacy: true,
        size: const Size(360, 800),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/flows/before/${stage.key}_light_360x800.png',
        ),
      );
    });

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
  await tester.pump(const Duration(milliseconds: 100));
}
