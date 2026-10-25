import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('NaMeScreen goldens', () {
    const timing = NaMeTimingConfig(
      strobeInterval: AlongMotion.naMeOn,
      cycleDuration: AlongMotion.naMeCycle,
    );
    final effects = DefaultNaMeEffects();

    for (final state in NaMeFullscreenVisualState.values) {
      testWidgets('green_diamond_${state.name}_scale_1_0', (tester) async {
        await pumpNaMeGolden(
          tester,
          surfaceSize: const Size(400, 800),
          child: NaMeFullscreen(
            colorToken: 'color.naMe.green',
            shapeToken: 'diamond',
            label: 'Green Diamond',
            timing: timing,
            effects: effects,
            visualState: state,
            bearingDegrees: 45,
          ),
        );
        await expectNaMeGolden(
          tester,
          'goldens/name_screen_${state.name}_1_0.png',
        );
      });
    }
  });
}
